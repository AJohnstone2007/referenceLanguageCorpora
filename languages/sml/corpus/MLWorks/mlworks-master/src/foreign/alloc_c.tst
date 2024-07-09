/*  ==== ROBUST MEMORY ALLOCATION ====
 *
 *  Copyright 2013 Ravenbrook Limited <http://www.ravenbrook.com/>.
 *  All rights reserved.
 *  
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 *  
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 *  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 *  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  Implementation
 *  --------------
 *  Simple first fit linked list.
 *
 *  Revision Log
 *  ------------
 *  $Log: alloc_c.tst,v $
 *  Revision 1.1  1995/03/13 13:40:53  brianm
 *  new unit
 *  No reason given
 *
 * Revision 1.4  1994/10/14  15:45:55  nickb
 * Change diagnostic level of message given when freeing NULL (it was 0).
 *
 * Revision 1.3  1994/10/03  15:30:09  jont
 * Fix free to handle NULL pointers
 *
 * Revision 1.2  1994/06/09  14:31:38  nickh
 * new file
 *
 * Revision 1.1  1994/06/09  10:56:23  nickh
 * new file
 *
 *  Revision 2.3  1994/01/28  17:21:56  nickh
 *  Moved extern function declarations to header files.
 *
 *  Revision 2.2  1993/04/26  11:47:55  richard
 *  Increased diagnostic level of messages from realloc().
 *
 *  Revision 2.1  1993/01/26  10:29:30  richard
 *  A new version using a simple linked list scheme.  The old version has
 *  bugs in it somewhere, and in any case was very slow.  We are now less
 *  likely to have random memory scrawling bugs -- ML has been running
 *  reliably for some time.
 *
 *  Revision 1.13  1992/10/02  08:38:16  richard
 *  Changed types to become non-standard but compatable with GCC across
 *  platforms.
 *
 *  Revision 1.12  1992/07/20  13:14:22  richard
 *  Removed init_alloc(), and caused allocation to automatically request
 *  an initial area when first called.  This simplifies the interface to
 *  the memory manager.
 *
 *  Revision 1.11  1992/06/30  13:36:04  richard
 *  New areas of C heap are now allocated using a special function to
 *  avoid revealing anything about the memory configuration.
 *
 *  Revision 1.10  1992/04/10  11:17:44  clive
 *  I realloc a call to malloc meant that the side of the object being
 *  reallocated was calculated incorrectly
 *
 *  Revision 1.9  1992/03/27  14:58:54  richard
 *  Corrected several bugs and tidied up.
 *
 *  Revision 1.8  1992/03/12  17:10:31  richard
 *  Changed realloc() to deal with a NULL pointer properly.
 *
 *  Revision 1.7  1992/03/10  13:53:02  richard
 *  Chaned call to allocate_blocks() as memory arrangement has changed.
 *
 *  Revision 1.6  1992/02/13  16:14:17  clive
 *  Forgot to take out my debugging messages
 *
 *  Revision 1.4  1992/02/13  11:42:13  clive
 *  Typo in find_space : (i-1) instead of -1
 *
 *  Revision 1.3  1992/02/13  10:52:08  clive
 *  There was a typo += instead of -= in alloc
 *
 *  Revision 1.2  1992/01/20  13:20:16  richard
 *  Shifted diagnostic level of debugging messages up to 4.
 *
 *  Revision 1.1  1992/01/17  12:17:07  richard
 *  Initial revision
 *
 */


#include "ansi.h"

#include "alloc.h"
#include "mem.h"
#include "diagnostic.h"
#include "extensions.h"

#include <stddef.h>
#include <memory.h>

#define ALIGNMENT		3 		/* number of bits of alignment */
#define ALIGN(x)		(((x) + (1u<<ALIGNMENT) - 1u) & ~((1u<<ALIGNMENT)-1u))

#define MINIMUM_CHUNK_SIZE	0x10000		/* see extend() */
#define FUDGE_FACTOR		ALIGN(0)	/* added to the end of all blocks */
#define SMUDGE_FACTOR		ALIGN(0)	/* added to the beginning of all blocks */
#define MINIMUM_BLOCK_SIZE	ALIGN(0x80)	/* aligned, includes header */
#define BLOCK_TO_P(block)	((char *)(block+1) + SMUDGE_FACTOR)
#define P_TO_BLOCK(p)		((struct header *)((char *)(p) - SMUDGE_FACTOR) - 1)


/*  == Block header structure ==
 *
 *  This header is stored at the start of each block, allocated or
 *  unallocated.  It must be of aligned length.
 */

struct header
{
  struct header *next;		/* pointer to next block on free list */
  size_t size;			/* size of block including header */
};

static struct header *free_list = NULL;


/*  == Extend C heap ==
 *
 *  Calls the storage manager to fetch a new chunk of memory, and
 *  initialises it as one large free block.  It returns the address of that
 *  block.
 */

static inline struct header *extend(size_t required)
{
  struct heap *heap;
  struct header *start;

  heap = make_heap(NULL, required > MINIMUM_CHUNK_SIZE ? required : MINIMUM_CHUNK_SIZE);

  start = (struct header *)((char *)heap + ALIGN(sizeof(struct heap)));

  DIAGNOSTIC(5, "alloc extend(required = 0x%X)", required, 0);
  DIAGNOSTIC(5, "  new memory at 0x%X length 0x%X", heap, heap->size);

  start->next = NULL;
  start->size = heap->size - ALIGN(sizeof(struct heap));

  return(start);
}


/*  == Calculate block length from request ==  */

static inline size_t block_size(size_t request)
{
  size_t rounded = ALIGN(request + sizeof(struct header) + SMUDGE_FACTOR + FUDGE_FACTOR);

  return(rounded < MINIMUM_BLOCK_SIZE ? MINIMUM_BLOCK_SIZE : rounded);
}

extern void call_me_if_you_dare(void);

extern void call_me_if_you_dare(void)
{
   fprintf(stderr,"Me?  I'm supposed to be a SECRET!  You can't call me (oh yes we can)\n");
 }

/*  === ALLOCATE MEMORY ===
 *
 *  Searches the free list for the first block large enough to satisfy the
 *  request.  If the block is much larger than requested it is split into
 *  two.  If the end of the list is reached the C heap is extended by
 *  calling the storage manager.  Note that this version never returns NULL.
 */

char *malloc(size_t requested)
{
  struct header *block, **last;
  size_t required = block_size(requested);

  DIAGNOSTIC(5, "malloc(requested = 0x%X) requires 0x%X", requested, required);
  DIAGNOSTIC(5, "  free_list = 0x%X", free_list, 0);


  fprintf(stderr," --- Harlequin MALLOC called!\n");

  last = &free_list;
  block = free_list;

  for(;;)
  {
    while(block)
    {
      struct header *next = block->next;
      size_t size = block->size;

      if(size >= required)
      {
	DIAGNOSTIC(5, "  found block at 0x%X size 0x%X", block, size);
	DIAGNOSTIC(5, "  last = 0x%X  next = 0x%X", last, next);

	if(size < required + MINIMUM_BLOCK_SIZE)
	  *last = next;
	else
	{
	  struct header *new = (struct header *)((char *)block + required);

	  DIAGNOSTIC(5, "  splitting at 0x%X", new, 0);

	  block->size = required;
	  *last = new;
	  new->next = next;
	  new->size = size - required;
	}

	DIAGNOSTIC(5, "  returning 0x%X", BLOCK_TO_P(block), 0);

	return(BLOCK_TO_P(block));
      }

      last = &block->next;
      block = next;
    }

    block = extend(required);

    *last = block;
  }
}


/*  === ALLOCATE AND CLEAR ===  */

char *calloc(size_t number, size_t size)
{
  size_t total = number * size;
  return(memset(malloc(total), 0, total));
}


/*  == Find nearest blocks on free list ==
 *
 *  Searches the free list for the block immediately preceeding the block
 *  passed.  Returns NULL if there is no preceeding block.
 */

static inline struct header *find(struct header *block)
{
  struct header *b = free_list;

  if(b && b < block)
  {
    while(b->next && b->next < block)
      b = b->next;

    return(b);
  }

  return(NULL);
}


/*  === FREE ALLOCATED BLOCK ===  */

int free(void *p)
{
  if (p == NULL) {
    DIAGNOSTIC(5, "Free: zero pointer", 0, 0);
    return 1;
  } else {
    struct header *block = P_TO_BLOCK(p);
    struct header *prev = find(block);

    DIAGNOSTIC(5, "free(0x%X) free_list = 0x%X", p, free_list);
    DIAGNOSTIC(5, "  block 0x%X  size 0x%X", block, block->size);
  
    if(prev) {
      struct header *next = prev->next;

      DIAGNOSTIC(5, "  prev 0x%X  size 0x%X", prev, prev->size);
      DIAGNOSTIC(5, "  next 0x%X  size 0x%X", next, next ? next->size : 0);

      /* Firstly, insert the block into the free list. */
      prev->next = block;
      block->next = next;

      /* If the block touches the next free block, merge them. */
      if((struct header *)((char *)block + block->size) == next) {
	block->size += next->size;
	block->next = next->next; 
	DIAGNOSTIC(5, "  merged block with next, size now 0x%X", block->size, 0);
      }

      /* If the block touches the previous free block, merge them. */
      if((struct header *)((char *)prev + prev->size) == block) {
	prev->size += block->size;
	prev->next = block->next;
	DIAGNOSTIC(5, "  merged prev with block, size now 0x%X", prev->size, 0);
      }
    } else {
      block->next = free_list;
      free_list = block;
    }
  }
  return(1);
}


/*  === REALLOCATE MEMORY ===
 *
 *  If the requested size is much smaller than the current size the block is
 *  split, otherwise a simple policy of allocating and moving the contents
 *  is followed.  This could be cleverer and steal memory from the following
 *  block instead, but such cases are relatively rare and it's probably not
 *  worth it.
 */

char *realloc(void *p, size_t requested)
{
  struct header *block;
  size_t required = block_size(requested);
  size_t size;

  if(!p)
    return(malloc(requested));

  block = P_TO_BLOCK(p);
  size = block->size;

  DIAGNOSTIC(5, "realloc(p = 0x%X, requested = 0x%X)", p, requested);
  DIAGNOSTIC(5, "  requires 0x%X", required, 0);
  DIAGNOSTIC(5, "  block 0x%X current size 0x%X", block, size);

  if(size >= required)
  {
    if(size >= required + MINIMUM_BLOCK_SIZE)
    {
      struct header *new = (struct header *)((char *)block + required);
      struct header *prev = find(block);

      DIAGNOSTIC(5, "  splitting at 0x%X", new, 0);

      block->size = required;
      new->size = size - required;

      if(prev)
      {
	new->next = prev->next;
	prev->next = new;
      }
      else
      {
	new->next = free_list;
	free_list = new;
      }
    }

    return(p);
  }
  else
  {
    char *new = malloc(requested);

    memcpy(new, p, size - sizeof(struct header) - (SMUDGE_FACTOR + FUDGE_FACTOR));
    free(p);

    return(new);
  }
}  
