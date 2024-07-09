/*  ==== HEAP EXPLORATION ====
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
 *  This file implements the 'explorer': a debugging tool which allows one
 *  to navigate an MLWorks heap. It's intended for internal use by MLWorkers.
 *
 * $Log: explore.c,v $
 * Revision 1.15  1998/05/18 11:29:05  jont
 * [Bug #70018]
 * Ensure addresses are read as unsigned longs
 *
 * Revision 1.14  1998/04/23  14:19:10  jont
 * [Bug #70034]
 * Rationalising names in mem.h
 *
 * Revision 1.13  1997/09/12  11:19:10  nickb
 * Add creation-space analysis.
 *
 * Revision 1.12  1996/10/25  14:58:38  nickb
 * Add more messages and some consistency checks.
 *
 * Revision 1.11  1996/08/01  08:31:47  stephenb
 * [Bug #1520]
 * Move the offending strtol declaration off to ansi.h (ugh) where
 * necessary.
 *
 * Revision 1.10  1996/07/11  16:33:22  nickb
 * Allow the explorer to exit the runtime and to explore executable images.
 *
 * Revision 1.9  1996/07/11  13:44:54  nickb
 * Add '>' command.
 *
 * Revision 1.8  1996/07/11  12:40:56  nickb
 * Add 'a', 'i', 'v' commands.
 *
 * Revision 1.6  1996/06/03  16:26:26  nickb
 * Add argument to explore() dictating whether the stacks should be examined.
 *
 * Revision 1.5  1996/05/13  15:38:49  nickb
 * Make this compile for windows.
 *
 * Revision 1.4  1996/04/26  14:34:16  nickb
 * Add string searching.
 *
 * Revision 1.3  1996/02/22  13:10:14  nickb
 * Exploring of ints not working well.
 *
 * Revision 1.2  1996/02/15  13:04:47  jont
 * ISPTR becomes MLVALISPTR
 *
 * Revision 1.1  1996/02/14  14:06:12  nickb
 * new unit
 * The explorer.
 *
 */
#ifdef EXPLORER

#include <string.h>

#include "ansi.h"
#include "tags.h"
#include "values.h"
#include "interface.h"
#include "alloc.h"
#include "utils.h"
#include "mem.h"
#include "gc.h"
#include "state.h"
#include "stacks.h"
#include "explore.h"


static void describe(mlval what, int verbosity);

/* This next macro is ripped off from the profiler, with which we
 * share allocation patterns (i.e. gradual accumulation, sudden
 * freeing). explore_allocator(foo) declares a bunch of things, of
 * which these three are of interest:
 * 
 * static struct foo *make_foo(void);
 * static void free_foo_list(void);
 * 
 * It also declares the following "internal" values:
 * static struct foo_table *foo_list, *current_foo;
 * static struct foo_table *make_foo_table(void);
 */

#define explore_allocator(struct_name)					\
									\
/* keep the structs in tables which are about page-size */		\
									\
static struct struct_name ## _table					\
{									\
  size_t nr_entries;							\
  struct struct_name ## _table *next;					\
  struct struct_name table[4060 / sizeof (struct struct_name)];		\
} *struct_name ## _list = NULL,						\
  *current_ ## struct_name;						\
									\
static struct struct_name ## _table *					\
   make_ ## struct_name ## _table(void)					\
{									\
  struct struct_name ## _table *result =				\
    (struct struct_name ## _table *)					\
      alloc_zero(sizeof(struct struct_name ## _table),			\
		 "Table of "						\
                 # struct_name						\
		 " explorer records");					\
  return result;							\
}									\
									\
static struct struct_name *make_ ## struct_name(void)			\
{									\
  if (current_ ## struct_name == NULL) {				\
    current_ ## struct_name = make_ ## struct_name ## _table();		\
    struct_name ## _list = current_ ## struct_name;			\
  }									\
  if (current_ ## struct_name->nr_entries ==				\
      4060 / sizeof(struct struct_name)) {				\
    current_ ## struct_name->next = make_ ## struct_name ## _table();	\
    current_ ## struct_name = current_## struct_name ->next;		\
  }									\
  return &(current_ ## struct_name->table				\
	   [current_ ## struct_name->nr_entries++]);			\
}									\
									\
static void free_ ## struct_name ## _list(void)				\
{									\
  struct struct_name ## _table *this = struct_name ## _list, *next;	\
									\
  while (this != NULL) {						\
    next = this->next;							\
    free(this);								\
    this = next;							\
  }									\
  struct_name ## _list = NULL;						\
  current_ ## struct_name = NULL;					\
}

/* a 'heap_info' is a root or an area of memory which is of interest
 * to the explorer. The first thing we do when entering the explorer
 * is to find and record all of these */

enum explore_type {
  EXPLORE_ROOT,			/* a root */
  EXPLORE_STACK_REGISTERS,	/* an area of saved registers on the stack */
  EXPLORE_STACK_AREA,		/* a stack-allocated area */
  EXPLORE_HEAP_AREA		/* an area of the heap */
};

struct heap_info {
  enum explore_type type;
  union {
    struct {
      mlval *base, *top;
      struct ml_heap *gen;
    } heap;
    struct {
      mlval *base, *top;
      struct thread_state *thread;
      struct stack_frame *frame;
    } stack;
    mlval *root;
  } the;
};

/* a 'place' is somewhere (an mlval) which has been visited by the
 * explorer. There are pointers to navigate, and for the explorer's
 * history. Additional info is in the place_info.
 */

struct place {
  mlval where;
  struct heap_info *heap;
  struct place *next, *previous;	/* memory -- each place appears once */
  struct place *forward, *back;		/* navigation -- changes as you move */
};

explore_allocator(place)
explore_allocator(heap_info)

static struct place *history = NULL;
static struct place *latest = NULL;
static struct place *place = NULL;

/* explore_free_all() frees everything and resets the pointers */

static void explore_free_all(void)
{
  free_place_list();
  free_heap_info_list();
  history = NULL;
  latest = NULL;
  place = NULL;
}

/* the next few functions are responsible for getting all the heap
 * info from the other parts of the MLWorks runtime */

extern void explore_root(mlval *root)
{
  struct heap_info *info = make_heap_info();
  info->type = EXPLORE_ROOT;
  info->the.root = root;
  printf(".");
  fflush(stdout);
}

extern void explore_stack_registers(struct thread_state *thread,
				    struct stack_frame *frame,
				    mlval *base, mlval *top)
{
  struct heap_info *info = make_heap_info();
  info->type = EXPLORE_STACK_REGISTERS;
  info->the.stack.base = base;
  info->the.stack.top = top;
  info->the.stack.thread = thread;
  info->the.stack.frame = frame;
  printf(".");
  fflush(stdout);
}

extern void explore_stack_allocated(struct thread_state *thread,
				    struct stack_frame *frame,
				    mlval *base, mlval *top)
{
  if (base != top) {
    struct heap_info *info = make_heap_info();
    info->type = EXPLORE_STACK_AREA;
    info->the.stack.base = base;
    info->the.stack.top = top;
    info->the.stack.thread = thread;
    info->the.stack.frame = frame;
    printf(".");
    fflush(stdout);
  }
}

extern void explore_heap_area(struct ml_heap *gen, mlval *base, mlval *top)
{
  if (base != top) {
    struct heap_info *info = make_heap_info();
    info->type = EXPLORE_HEAP_AREA;
    info->the.heap.base = base;
    info->the.heap.top = top;
    info->the.heap.gen = gen;
    printf("%d.",gen->number);
    fflush(stdout);
  }
}

static void explore_get_heap_info(int use_stacks)
{
  if (use_stacks) {
    printf("stack.");
    explore_stacks();
    printf("\n");
    fflush(stdout);
  }
  printf("root.");
  explore_roots();
  printf("\nheap.");
  fflush(stdout);
  explore_heap();
  printf("\n");
  fflush(stdout);
}

/* Now some functions for checking the broad consistency of the heap */

static mlval *explore_consist_on_heap(mlval value)
{
  if (is_ml_stack((void*)value) ||
      is_ml_heap((void*)value)) {
    /* check it points to a GC-able area */
    struct heap_info_table *this = heap_info_list;
    while (this != NULL) {
      int i=0;
      while (i < (int) (this->nr_entries)) {
	struct heap_info *item = &this->table[i];
	switch(item->type) {
	case EXPLORE_HEAP_AREA:
	  if ((value > (mlval)item->the.heap.base) &&
	      (value < (mlval)item->the.heap.top))
	    return item->the.heap.base;
	  break;
	case EXPLORE_STACK_AREA:
	  if ((value > (mlval)item->the.stack.base) &&
	      (value < (mlval)item->the.stack.top))
	    return item->the.stack.base;
	  break;
	case EXPLORE_STACK_REGISTERS:
	  break;
	case EXPLORE_ROOT:
	  break;
	default:
	  printf("Explorer internal data structures broken\n.");
	  return NULL;
	}
	i++;
      }
      this = this->next;
    }
  }
  return NULL;
}

static int explore_consist_item(mlval *where, const char *name)
{
  mlval value = *where;
  mlval primary = PRIMARY(value);
  mlval header, secondary, length;
  mlval *area_base;
  /* do primary tag checks first */
  if (primary == HEADER || primary == PRIMARY6 || primary == PRIMARY7) {
    printf("0x%08x at 0x%08x (%s) has bad primary\n", value, (word)where, name);
    return 0;
  }
  if (!MLVALISPTR(value))
    /* then it's valid */
    return 1;
  if (value == stub_c || value == stub_asm)
    /* valid pointer off the heap */
    return 1;
  area_base = explore_consist_on_heap(value);
  if (area_base == NULL) {
    printf("0x%08x at 0x%08x (%s) points but not to ML data\n",
	   value, (word)where, name);
    return 0;
  }
  if (primary == PAIRPTR) {
    /* nothing else to check */
    return 1;
  }
  header = *OBJECT(value);
  secondary = SECONDARY(header);
  length = LENGTH(header);
  if (primary == POINTER && secondary == RECORD)
    return 1;
  if (primary == POINTER && secondary == STRING)
    return 1;
  if (primary == REFPTR && secondary == ARRAY)
    return 1;
  if (primary == POINTER && secondary == BYTEARRAY && length == 12) /* float */
    return 1;
  if (primary == POINTER && secondary == CODE)
    return 1;
  if (primary == REFPTR && secondary == BYTEARRAY)
    return 1;
  if (primary == REFPTR && secondary == WEAKARRAY)
    return 1;
  if (primary == POINTER && header == 0) { /* shared closure */
    word offset = 0;
    while (header == 0) {
      offset += 2;
      value -= 8;
      if (value < (mlval)area_base) {
	printf("0x%08x at 0x%08x (%s): shared closure with no header\n",
	       *where, (word)where, name);
	return 0;
      }
      header = GETHEADER(value);
    }
    secondary = SECONDARY(header);
    length = LENGTH(header);
    if (secondary != RECORD || length <= offset) {
      printf("0x%08x at 0x%08x (%s): shared closure with bad header 0x%08x at 0x%08x\n",
	     *where, (word)where, name, header, value);
      return 0;
    }
    return 1;
  }
  if (primary == POINTER && secondary == BACKPTR) {
    /* check backptr */
    mlval codevector = FOLLOWBACK(value);
    if (codevector > (mlval)area_base) {
      mlval codeheader = GETHEADER(codevector);
      word codelength = LENGTH(codeheader);
      secondary = SECONDARY(codeheader);
      if (secondary != CODE || (codelength * sizeof(mlval)) <= length) {
	printf("0x%08x at 0x%08x (%s): code pointer with bad vector header 0x%08x at 0x%08x\n",
	       value, (word)where, name, codeheader, codevector);
	return 0;
      }
    } else {
      printf("0x%08x at 0x%08x (%s): backpointer escapes heap area",
	     value, (word)where, name);
      return 1;
    }
    return 0;
  }
  printf("0x%08x at 0x%08x (%s), header 0x%08x has mismatched tags\n",
	 value, (word)where, name, header);
  return 0;
}

static void explore_consist_vector(mlval *start, mlval *end, char *name)
{
  while (start < end) {
    (void)explore_consist_item(start,name);
    start++;
  }
}

static void explore_consist_area(mlval *start, mlval *end, char *name)
{
  while (start < end) {
    mlval value = *start;

    if (PRIMARY(value) == HEADER) {
      switch(SECONDARY(value)) {
      case RECORD: {
	word length = LENGTH(value);
	explore_consist_vector(start+1,start+length, name);
	start = (mlval *)double_align(start+length+1);
	break;
      }
      case STRING:
      case BYTEARRAY:
	start = (mlval *)double_align((byte *)start +
				      LENGTH(value) + sizeof(mlval));
	break;
      case CODE: {
	word length = LENGTH(value);
	if (length < 4)
	  printf("Code vector at 0x%08x (%s) has length < 4\n",(word)start, name);
	else {
	  /* ancillary checking is quite complex */
	  if (explore_consist_item(start+1, name)) {
	    mlval ancill = start[1];
	    if (PRIMARY(ancill) == POINTER) {
	      mlval header = GETHEADER(ancill);
	      if (SECONDARY(header) == RECORD && LENGTH(header) == 3) {
		mlval names = FIELD(ancill,0);
		mlval profs = FIELD(ancill,1);
		mlval inters = FIELD(ancill,2);
		if (PRIMARY(names) == POINTER &&
		    PRIMARY(profs) == POINTER &&
		    PRIMARY(inters) == REFPTR) {
		  const char *anc_name = "ancillary item";
		  if (explore_consist_item(&FIELD(ancill,0), anc_name) &&
		      explore_consist_item(&FIELD(ancill,1), anc_name) &&
		      explore_consist_item(&FIELD(ancill,2), anc_name)) {
		    mlval h1 = GETHEADER(names);
		    mlval h2 = GETHEADER(profs);
		    mlval h3 = *OBJECT(inters);
		    word len = LENGTH(h1);
		    if (SECONDARY(h1) != RECORD ||
			SECONDARY(h2) != RECORD ||
			SECONDARY(h3) != ARRAY ||
			LENGTH(h2) != len ||
			LENGTH(h3) != len) {
		      printf("inconsistent ancillary headers 0x%08x, 0x%08x, 0x%08x at 0x%08x for code vector at 0x%08x",
			     h1,h2,h3,ancill,(word)start);
		    }
		  }
		} else if (PRIMARY(names) == PAIRPTR &&
			   PRIMARY(profs) == PAIRPTR &&
			   PRIMARY(inters) == REFPTR) {
		  const char *anc_name = "ancillary item";
		  if (explore_consist_item(&FIELD(ancill,0), anc_name) &&
		      explore_consist_item(&FIELD(ancill,1), anc_name) &&
		      explore_consist_item(&FIELD(ancill,2), anc_name)) {
		    mlval h3 = *OBJECT(inters);
		    if (SECONDARY(h3) != ARRAY ||
			LENGTH(h3) != 2) {
		      printf("inconsistent intercept header 0x%08x at 0x%08x for paired code vector at 0x%08x",
			     h3, ancill, (word)start);
		    }
		  }
		} else {
		  printf("inconsistent ancillary pointers 0x%08x, 0x%08x, 0x%08x at 0x%08x for code vector at 0x%08x",
			 names, profs, inters, ancill, (word)start);
		}
	      } else {
		printf("bad ancillary header 0x%08x at 0x%08x for code vector at 0x%08x",
		       header, ancill, (word)start);
	      }
	    } else if (PRIMARY(ancill) == PAIRPTR) {
	      mlval names = FIELD(ancill,0);
	      mlval profs = FIELD(ancill,1);
	      if (PRIMARY(names) == POINTER &&
		  PRIMARY(profs) == POINTER) {
		const char *anc_name = "ancillary item";
		if (explore_consist_item(&FIELD(ancill,0), anc_name) &&
		    explore_consist_item(&FIELD(ancill,1), anc_name)) {
		  mlval h1 = GETHEADER(names);
		  mlval h2 = GETHEADER(profs);
		  if (SECONDARY(h1) != RECORD ||
		      SECONDARY(h2) != RECORD ||
		      LENGTH(h1) != LENGTH(h2)) {
		    printf("inconsistent ancillary headers 0x%08x, 0x%08x at 0x%08x for code vector at 0x%08x",
			   h1,h2,ancill,(word)start);
		    }
		  }
		} else if (PRIMARY(names) != PAIRPTR ||
			   PRIMARY(profs) != PAIRPTR) {
		  printf("inconsistent ancillary pointers 0x%08x, 0x%08x at 0x%08x for code vector at 0x%08x",
			 names, profs, ancill, (word)start);
		}
	    }
	  }
	}
	start = (mlval*)double_align (start+LENGTH(value)+1);
	break;
      }
      case ARRAY: {
	word length = LENGTH(value);
	explore_consist_vector(start+3,start+length+2, name);
	start = (mlval *)double_align(start+length+3);
	break;
      }
      case WEAKARRAY: {
	word length = LENGTH(value);
	int i = 0;
	start += 3;	/* skip over entry list slots */
	while (i < (int) length) {
	  mlval entry = *start;
	  if (entry != DEAD)
	    (void)explore_consist_item(start, name);
	  start++;
	  i++;
	}
	start = (mlval*)double_align(start);
	break;
      }
      default:
	printf("bad header 0x%08x at 0x%08x (%s)\n",value, (word)start, name);
      }
    } else {
      (void)explore_consist_item(start++, name);
      (void)explore_consist_item(start++, name);
    }
  }
  if (start > end)
    printf("object before 0x%08x oversteps heap area end\n",(word)end);
      
}

static void explore_consistency(void)
{
  char buffer[100];
  struct heap_info_table *this = heap_info_list;
  while (this != NULL) {
    int i=0;
    while (i < (int) (this->nr_entries)) {
      struct heap_info *item = &this->table[i];
      switch(item->type) {
      case EXPLORE_HEAP_AREA:
	sprintf(buffer,"gen %d",item->the.heap.gen->number);
	explore_consist_area(item->the.heap.base, item->the.heap.top, buffer);
	break;
      case EXPLORE_STACK_AREA:
	sprintf(buffer,"stack %d frame 0x%08x",
		item->the.stack.thread->number, (word)(item->the.stack.frame));
	explore_consist_area(item->the.stack.base, item->the.stack.top,
			     buffer);
	break;
      case EXPLORE_STACK_REGISTERS:
	sprintf(buffer, "stack %d frame 0x%08x registers",
		item->the.stack.thread->number, (word)(item->the.stack.frame));
	explore_consist_vector(item->the.stack.base, item->the.stack.top,
			       buffer);
	break;
      case EXPLORE_ROOT: {
	/* some roots point into the runtime, some are DEAD */
	if (SPACE_TYPE(*item->the.root) != TYPE_RESERVED)
	  explore_consist_item(item->the.root, "root");
	break;
      }
      default:
	printf("Explorer internal data structures broken\n.");
      }
      i++;
    }
    this = this->next;
  }
}

/* explore_make_place(where, heap) makes a new place, on the end of
 * the history, with a backpointer to the current place */

static struct place *explore_make_place(mlval where, struct heap_info *heap)
{
  struct place *new = make_place();
  new->where = where;
  new->heap = heap;
  new->forward = NULL;
  new->back = place;
  new->next = NULL;
  if (latest)
    latest->next = new;
  new->previous = latest;
  latest = new;
  if (history == NULL)
    history = new;
  return new;
}

/* Now a bunch of code to validate any random address as an ML
 * value. This is done by scanning each heap area in turn.
 */

/* This scans a heap area from 'base' to 'top', looking for 'value'.
 * It returns the closest value, or DEAD if there is no close value. */

static mlval check_valid_area(mlval *base, mlval *top, mlval value)
{
  mlval *obj = OBJECT(value);

  if ((value < (mlval) base) ||
      (value >= (mlval) top))
    return DEAD;

  while (base <= obj) {
    mlval header = *base;
    if (obj == base) {	/* there is an object here; either we're OK or
			 * we pick a different primary tag */
      switch(PRIMARY(value)) {
      case PAIRPTR:	/* we're looking for a pair */
	switch (PRIMARY(header)) {
	case PAIRPTR:
	case POINTER:
	case REFPTR:
	case INTEGER0:
	case INTEGER1:
	  return value;	/* it's a pair */
	case HEADER:	/* not a pair */
	  if ((SECONDARY(header) == ARRAY) ||
	      (SECONDARY(header) == WEAKARRAY) ||
	      (SECONDARY(header) == BYTEARRAY && LENGTH(header) != 12))
	    return MLPTR(obj,REFPTR);
	  else
	    return MLPTR(obj,POINTER);
	  break;
	case PRIMARY6:
	case PRIMARY7:
	default:
	  printf("Error in heap data at 0x%08x\n",(word)base);
	  return DEAD;
	}
	break;
      case POINTER:	/* we're looking for an immutable object */
	if (PRIMARY(header) == HEADER) {
	  if ((SECONDARY(header) == ARRAY) ||
	      (SECONDARY(header) == WEAKARRAY) ||
	      (SECONDARY(header) == BYTEARRAY && LENGTH(header) != 12))
	    return MLPTR(obj,REFPTR);
	  else
	    return value;
	} else
	  return MLPTR(obj,PAIRPTR);
	break;
      case REFPTR:	/* we're looking for a mutable object */
	if (PRIMARY(header) == HEADER) {
	  if ((SECONDARY(header) != ARRAY) &&
	      (SECONDARY(header) != WEAKARRAY) &&
	      (SECONDARY(header) != BYTEARRAY))
	    return MLPTR(obj,POINTER);
	  else
	    return value;
	} else
	  return MLPTR(obj,PAIRPTR);
	break;
      default:
	printf("Internal error in explorer");
	return DEAD;
      }
    } else { /* not here; check for embedded pointers and then skip */
      switch (PRIMARY(header)) {
      case PAIRPTR:
      case POINTER:
      case INTEGER0:
      case INTEGER1:
      case REFPTR:
	base += 2;	/* it's a pair, skip it */
	break;
      case HEADER: {	/* could be a shared closure or a code object */
	mlval *newbase;
	word secondary = SECONDARY(header);
	word length = LENGTH(header);
	if (secondary == RECORD) {	/* check for shared closure */
	  newbase = base;
	  while (newbase[2] == 0 && newbase < base + length) {
	    newbase += 2;
	    if (obj == newbase) {
	      return MLPTR(newbase,POINTER);
	    }
	  }
	} else if (secondary == CODE) {	/* check for embedded pointer */
	  if (obj < base + length) {
	    mlval header2 = obj[0];
	    if ((SECONDARY(header2) == BACKPTR) &&
		((word)obj - (word)base) == LENGTH(header2)) {
	      return MLPTR(obj,POINTER);
	    }
	  }
	}
	/* not an embedded pointer; skip over */
	newbase = (mlval*)(((word)base) + OBJECT_SIZE(secondary, length));
	if (obj < newbase) {
	  if ((secondary == ARRAY) ||
	      (secondary == WEAKARRAY) ||
	      ((secondary == BYTEARRAY) && (length != 12)))
	    return MLPTR(base,REFPTR);
	  else
	    return MLPTR(base,POINTER);
	}
	base = newbase;
      }
	break;
      case PRIMARY6: 
      case PRIMARY7:
      default:
	printf("Error in heap data at 0x%08x\n",(word)base);
      }
    }      
  }
  return DEAD;
}

/* validate_mlval(&v) checks that v is a (non-immediate) ML object.
   - If v is an object, it returns the heap
   - If v is nearly an object, it sets v to the nearby object and returns
     the heap
   - if v is not even nearly an object, it sets v to DEAD and returns NULL
*/

static struct heap_info * validate_mlval(mlval *pvalue)
{
  struct heap_info *result = NULL;
  struct heap_info_table *this;
  mlval value = *pvalue;
  mlval newvalue = DEAD;
  mlval primary = PRIMARY(value);
  if (primary == PRIMARY6 || primary == PRIMARY7) {
    printf("0x%08x has bad primary; trying POINTER primary\n", value);
    value = MLPTR(OBJECT(value),POINTER);
  } else if (!MLVALISPTR(value)) {
    printf("0x%08x is not a pointer; trying POINTER primary\n", value);
    value = MLPTR(OBJECT(value),POINTER);
  }

  if (!is_ml_stack((void*)value) &&
      !is_ml_heap((void*)value)) {
    printf("0x%08x not on heap or stack\n", value);
    *pvalue = DEAD;
    return NULL;
  }
      
  this = heap_info_list;
  while (newvalue == DEAD && this != NULL) {
    unsigned int i=0;
    while (newvalue == DEAD && i < this->nr_entries) {
      result = &this->table[i];
      switch(result->type) {
      case EXPLORE_HEAP_AREA:
	newvalue = check_valid_area(result->the.heap.base,
				    result->the.heap.top, value);
	break;
      case EXPLORE_STACK_AREA:
	newvalue = check_valid_area(result->the.stack.base,
				    result->the.stack.top, value);
	break;
      case EXPLORE_STACK_REGISTERS:
      case EXPLORE_ROOT:
      default:
	/* empty statement here required by VC++ */ ;
      }
      i++;
    }
    this = this->next;
  }

  *pvalue = newvalue;
  if (newvalue == DEAD)
    printf("0x%08x does not point to an object, or even close.\n", value);
  else if (newvalue != value)
    printf("0x%08x does not point to an object, but 0x%08x does.\n",
	   value, newvalue);
  return result;
}

static int explore_check_history(mlval where)
{
  struct place *here = history;
  int index = 0;
  while (here != NULL && here->where != where) {
    here = here->next;
    index++;
  }
  if (here != NULL) {
    printf("revisiting item %d on history\n", index);
    here->back = place;
    place->forward = here;
    place = here;
    return 1;
  } else
    return 0;
}

/* explore_go(where) goes to that ML value, if it is a valid ML
 * value. If it has already been visited, it is revisited. Otherwise
 * it is visited for the first time. */

static int explore_go(mlval where)
{
  struct heap_info *heap;
  if (explore_check_history(where))
    return 1;
  heap = validate_mlval(&where);
  if (where == DEAD)
    return 0;
  if (explore_check_history(where))
    return 1;
  place = explore_make_place(where, heap);
  return 1;
}

static void explore_start(mlval where)
{
  if (MLVALISPTR(where)) {
    if (explore_go(where))
      return;
    where = 0;
  }
  place = explore_make_place(where, NULL);
}
    
/* explore_forward() moves forward, or returns 0 */

static int explore_forward(void)
{
  struct place *new = place->forward;
  if (new == NULL)
    return 0;
  /* 'back' here is already set */
  place = new;
  return 1;
}

/* explore_back() moves back, or returns 0 */

static int explore_back(void)
{
  struct place *new = place->back;
  if (new == NULL)
    return 0;
  /* do not set 'back' again; that is what "forward" is for */
  place = new;
  return 1;
}

/* explore_next() moves to the next item on the history, or returns 0 */

static int explore_next(void)
{
  struct place *new = place->next;
  if (new == NULL)
    return 0;
  place->forward = new;
  new->back = place;
  place = new;
  return 1;
}

/* explore_previous() moves to the previous item on the history,
 * or returns 0 */

static int explore_previous(void)
{
  struct place *new = place->previous;
  if (new == NULL)
    return 0;
  place->forward = new;
  new->back = place;
  place = new;
  return 1;
}

/* explore_repeat(n) moves to the nth item on the history,
 * or returns 0 */

static int explore_repeat(int index)
{
  struct place *where = history;
  if (index < 0)
    return 0;
  while (index--) {
    if (where->next == NULL)
      return 0;
    where = where->next;
  }
  place->forward = where;
  where->back = place;
  place = where;
  return 1;
}

/* explore_show_history lists the whole history */

static void explore_show_history(void)
{
  int index = 0;
  struct place *where = history;
  printf("Exploration history : "); 
  while (where != NULL) {
    printf("\n%d : ",index++);
    describe(where->where,1);
    where = where->next;
  }
  printf("\n");
}

/* explore_child(n) explores the nth child of the current object.
 * If it is a code object, and n = 0, the ancillaries are explored.
 * If it is a backptr, and n = 0, the backptr is followed.
 * If it is a shared closure, and n = -1, we move to the head of the closure */

static int explore_child(int index)
{
  mlval current = place->where;
  mlval new;
  switch(PRIMARY(current)) {
  case PAIRPTR:
    if (index < 0 || index >= 2)
      return 0;
    new = FIELD(current,index);
    break;
  case POINTER: {
    mlval header = GETHEADER(current);
    word secondary = SECONDARY(header);
    word length = LENGTH(header);
    if (index == -1 && header == 0) {
      int back = 0;
      new = current;
      while (header == 0) {
	new -= 8;
	back++;
	header = GETHEADER(new);
      }
      printf("Moving back %d steps to head of shared closure\n", back);
      break;
    } else if (index == 0 && secondary == BACKPTR) {
      new = FOLLOWBACK(current);
      printf("Back to head of code vector\n");
      break;
    } else if ((index >= 0) &&
	       (index < (int) length) &&
	       ((secondary == RECORD) ||
		(secondary == CODE))) {
      new = FIELD(current,index);
      break;
    }
    return 0;
  }
  case REFPTR: {
    mlval header = ARRAYHEADER(current);
    word secondary = SECONDARY(header);
    word length = LENGTH(header);
    if((index >= 0) &&
       (index < (int) length) &&
       ((secondary == ARRAY) ||
	(secondary == WEAKARRAY))) {
      new = MLSUB(current,index);
      break;
    }
      return 0;
    }
    case INTEGER0:
    case INTEGER1:
    case HEADER:
    case PRIMARY6:
    case PRIMARY7:
    default:
      return 0;
    }
  return explore_go(new);
}

static int explore_search_vector(mlval *start, mlval *end,
				 int index, mlval above, mlval below,
				 char *name)
{
  while (start < end) {
    mlval value = *start;
    if (MLVALISPTR(value) && (value >= above) && (value < below))
      printf(" %4d : 0x%08x at 0x%08x in %s\n",
	     index++, value, (word)start, name);
    start++;
  }
  return index;
}

static int explore_search_area(mlval *start, mlval *end,
			       int index, mlval above, mlval below,
			       char *name)
{
  while (start < end) {
    mlval value = *start;

    if (PRIMARY(value) == HEADER) {
      switch(SECONDARY(value)) {
      case RECORD: {
	word length = LENGTH(value);
	int i=0;
	mlval where = ((mlval)start)+POINTER;
	start++;
	while (i < (int) length) {
	  mlval found = *start++;
	  if (MLVALISPTR(found) && found >= above && found < below)
	    printf(" %4d : 0x%08x at record 0x%08x [%d] in %s\n",
		   index++, found, where, i, name);
	  i++;
	}
	start = (mlval*)double_align(start);
	break;
      }
      case STRING:
      case BYTEARRAY:
	start = (mlval *)double_align((byte *)start +
				      LENGTH(value) + sizeof(mlval));
	break;
      case CODE: {
	mlval found = start[1];
	if (MLVALISPTR(found) && found >= above && found < below)
	  printf(" %4d : 0x%08x at code item 0x%08x [0] in %s\n",
		 index++, found, ((mlval)start)+POINTER, name);
	start = (mlval*)double_align (start+LENGTH(value)+1);
	break;
      }
      case ARRAY:
      case WEAKARRAY: {
	const char *weak = (SECONDARY(value) == WEAKARRAY ? "weak" : "");
	word length = LENGTH(value);
	int i = 0;
	mlval where = ((mlval)start)+REFPTR;
	start += 3;	/* skip over entry list slots */
	while (i < (int) length) {
	  mlval found = *start++;
	  if (MLVALISPTR(found) && found >= above && found < below)
	    printf(" %4d : 0x%08x in %sarray 0x%08x [%d] in %s\n",
		   index++, found, weak, where, i, name);
	  i++;
	}
	start = (mlval*)double_align(start);
	break;
      }
      default:
	printf("explorer found bad header at 0x%08x in %s\n",
	       (word)start, name);
	return index;
      }
    } else { /* a pair */
      if (MLVALISPTR(value) && value >= above && value < below)
	printf(" %4d : 0x%08x in pair 0x%08x[0] in %s\n",
	       index++, value, ((mlval)start) + PAIRPTR, name);
      start++;
      value = *start;
      if (MLVALISPTR(value) && value >= above && value < below)
	printf(" %4d : 0x%08x in pair 0x%08x[1] in %s\n",
	       index++, value, ((mlval)start) + PAIRPTR-4, name);
      start++;
    }
  }
  return index;
}

static int explore_search_heap_item(struct heap_info *item,
				    int index, mlval above, mlval below)
{
  char buffer[100];
  switch(item->type) {
  case EXPLORE_HEAP_AREA:
    sprintf(buffer,"gen %d",item->the.heap.gen->number);
    index = explore_search_area(item->the.heap.base, item->the.heap.top,
				index, above, below, buffer);
    break;
  case EXPLORE_STACK_AREA:
    sprintf(buffer,"stack %d frame 0x%08x",
	    item->the.stack.thread->number, (word)(item->the.stack.frame));
    index = explore_search_area(item->the.stack.base, item->the.stack.top,
				index, above, below, buffer);
    break;
  case EXPLORE_STACK_REGISTERS:
    sprintf(buffer, "stack %d frame 0x%08x registers",
	    item->the.stack.thread->number, (word)(item->the.stack.frame));
    index = explore_search_vector(item->the.stack.base, item->the.stack.top,
				  index, above, below, buffer);
    break;
  case EXPLORE_ROOT: {
    mlval root = *item->the.root;
    if (MLVALISPTR(root) && root >= above && root < below)
      printf(" %4d : 0x%08x in root 0x%08x\n",
	     index++,root,(word)(item->the.root));
    break;
  }
  default:
    printf("Explorer internal data structures broken\n.");
  }
  return index;
}

static void explore_search(void)
{
  int index = 0;
  mlval value = place->where;
  if (MLVALISPTR(value)) {
    struct heap_info_table *this = heap_info_list;
    mlval obj = (mlval) OBJECT(value), next_obj;
    mlval header = *(mlval*)obj;
    if (PRIMARY(header) == HEADER)
      next_obj = obj + OBJECT_SIZE(SECONDARY(header),LENGTH(header));
    else
      next_obj = obj+8;
    while (this != NULL) {
      int i=0;
      while (i < (int) (this->nr_entries)) {
	index = explore_search_heap_item(&this->table[i], index,
					 obj, next_obj);
	i++;
      }
      this = this->next;
    }
  } else
    printf("Will not search for parents of an immediate value\n");
}

static int explore_find_string_area(mlval *start, mlval *end,
			       int index, char *string, word slength, 
			       char *name)
{
  while (start < end) {
    mlval value = *start;

    if (PRIMARY(value) == HEADER) {
      	word length = LENGTH(value);
	word secondary = SECONDARY(value);
	word size = OBJECT_SIZE(secondary,length)/sizeof(mlval);
	switch(SECONDARY(value)) {
	case STRING: 
	  if (length >= slength) {
	    char *startptr = (char*)(start+1);
	    word pos = length-slength;
	    while (pos > 0) {
	      char *searchptr = string;
	      char *endptr = startptr;
	      while ((*searchptr == *endptr) &&
		     (*searchptr != 0)) {
		endptr++;
		searchptr++;
	      }
	      if (*searchptr == 0) {
		printf(" %4d : 0x%08x, length %d in %s\n",
		       index++, MLPTR(POINTER,start), length, name);
		pos = 1;
	      }
	      pos--;
	      startptr++;
	    }
	      
	  }
	  /* drop through */
	case RECORD: 
	case BYTEARRAY:
	case CODE: 
	case ARRAY:
	case WEAKARRAY:
	  start += size;
	  break;
	default:
	  printf("explorer found bad header at 0x%08x in %s\n",
		 (word)start, name);
	  return index;
	}
    } else
      start += 2; /* a pair */
  }
  return index;
}

static int explore_find_string_heap_item(struct heap_info *item,
				    int index, char *string, word length)
{
  char buffer[100];
  switch(item->type) {
  case EXPLORE_HEAP_AREA:
    sprintf(buffer,"gen %d",item->the.heap.gen->number);
    index = explore_find_string_area(item->the.heap.base, item->the.heap.top,
				     index, string, length, buffer);
    break;
  case EXPLORE_STACK_AREA:
  case EXPLORE_STACK_REGISTERS:
  case EXPLORE_ROOT:
    /* we don't find strings there */
    break;
  default:
    printf("Explorer internal data structures broken\n.");
  }
  return index;
}

static void explore_find_string(char *string, word length)
{
  if (length > 0) {
    int index = 0;
    struct heap_info_table *this = heap_info_list;
    while (this != NULL) {
      int i=0;
      while (i < (int) (this->nr_entries)) {
	index = explore_find_string_heap_item(&this->table[i], index, string,
					      length);
	i++;
      }
      this = this->next;
    }
  } else
    printf("Will not search for string of length 0.\n");
}

static int explore_up(void)
{
  mlval value = place->where;
  struct heap_info *heap = place->heap;

  if ((heap == NULL) || (!MLVALISPTR(value))) {
    printf("Value not on the heap\n");
    return 0;
  } else {
    mlval *try = OBJECT(value);
    word primary = PRIMARY(value);
    if (primary == PAIRPTR)
      try += 2;
    else {
      mlval header = *try;
      while (header == 0) { /* skip back */
	try -= 2;
	header = *try;
      }
      if (SECONDARY(header) == BACKPTR) {
	try = (mlval*)(((word)try)-LENGTH(header));
	header = *try;
      }
      if (PRIMARY(header) != HEADER) {
	printf("Bad header 0x%08x at 0x%08x\n", header, (word)try);
	return 0;
      }
      switch (SECONDARY(header)) {
      case RECORD:
      case CODE:
	try = (mlval*) double_align(try+LENGTH(header)+1);
	break;
      case STRING:
      case BYTEARRAY:
	try = (mlval *)double_align((byte *)try +
				    LENGTH(header) + sizeof(mlval));
	break;
      case ARRAY:
      case WEAKARRAY:
	try = (mlval*) double_align(try+LENGTH(header)+3);
	break;
      default:
	printf("Bad header 0x%08x at 0x%08x\n", header, (word)try);
	return 0;
      }
    }
    if (try >= heap->the.heap.top) {
      printf("Object at top of a heap area\n");
      return 0;
    } else {
      mlval header = *try;
      if (PRIMARY(header) != HEADER)
	value = MLPTR(try,PAIRPTR);
      else if ((SECONDARY(header) == ARRAY) ||
	       (SECONDARY(header) == WEAKARRAY) ||
	       (SECONDARY(header) == BYTEARRAY && LENGTH(header) != 12))
	value = MLPTR(try,REFPTR);
      else
	value = MLPTR(try,POINTER);
      return explore_go(value);
    }
  }
}

static int explore_down(void)
{
  mlval value = place->where;
  struct heap_info *heap = place->heap;

  if ((heap == NULL) || (!MLVALISPTR(value))) {
    printf("Value not on the heap\n");
    return 0;
  } else {
    mlval *obj = OBJECT(value);
    mlval *ptr = heap->the.heap.base, *newptr;
    if (obj == ptr) {
      printf("Object at base of a heap area\n");
      return 0;
    } else {	/* scan forwards from bottom of heap area */
      while (ptr <= obj) {
	mlval header = *ptr;
	if (PRIMARY(header) != HEADER) {
	  newptr = ptr + 2;
	  if (newptr >= obj)
	    return explore_go(MLPTR(ptr,PAIRPTR));
	} else {
	  word secondary = SECONDARY(header);
	  word length = LENGTH(header);
	  newptr = (mlval*)(((word)ptr) + OBJECT_SIZE(secondary, length));
	  if (newptr >= obj) {
	    if ((secondary == ARRAY) ||
		(secondary == WEAKARRAY) ||
		((secondary == BYTEARRAY) && (length != 12)))
	      return explore_go(MLPTR(ptr,REFPTR));
	    else
	      return explore_go(MLPTR(ptr,POINTER));
	  }
	}
	ptr = newptr;
      }
      printf("Explorer error: object not found in heap area\n");
      return 0;
    }
  }
}

static mlval explore_largest_area(mlval *base, mlval *top, size_t *pbytes)
{
  size_t bytes = *pbytes;
  mlval result = DEAD;
  if (bytes > ((top-base)*sizeof(mlval)))
    return result;
  while (base < top) {
    mlval header = *base;
    if (PRIMARY(header) != HEADER) {
      if (bytes < 8) {
	bytes = 8;
	result = MLPTR(base,PAIRPTR);
      }
      base += 2;
    } else {
      word secondary = SECONDARY(header);
      word length = LENGTH(header);
      size_t size = OBJECT_SIZE(secondary, length);
      if (bytes < size) {
	bytes = size;
	if ((secondary == ARRAY) ||
	    (secondary == WEAKARRAY) ||
	    ((secondary == BYTEARRAY) && (length != 12)))
	  result = MLPTR(base,REFPTR);
	else
	  result = MLPTR(base,POINTER);
      }
      base = (mlval*)(((word)(base)) + size);
    }
  }
  *pbytes = bytes;
  return result;
}

static int explore_largest(void)
{
  struct heap_info_table *this = heap_info_list;
  mlval value = DEAD;
  size_t bytes = 0;
  while (this != NULL) {
    int i = 0;
    while (i < (int)(this->nr_entries)) {
      struct heap_info *heap = &this->table[i];
      switch(heap->type) {
      case EXPLORE_HEAP_AREA:
	value = explore_largest_area(heap->the.heap.base,
				     heap->the.heap.top, &bytes);
	break;
      case EXPLORE_STACK_AREA:
	value = explore_largest_area(heap->the.stack.base,
				     heap->the.stack.top, &bytes);
	break;
      case EXPLORE_STACK_REGISTERS:
      case EXPLORE_ROOT:
      default:
	/* VC++ requires an empty statement here */ ;
      }
      i++;
    }
    this = this->next;
  }
  if (value == DEAD) {
    printf("No values of any size found!\n");
    return 0;
  }
  printf("value of size %ld bytes found\n", (long)bytes);
  return explore_go(value);
}

static void explore_greater_area(mlval *base, mlval *top, size_t bytes,
				 size_t *countp)
{
  size_t count = *countp;
  if (bytes > ((top-base)*sizeof(mlval)))
    return;
  while (base < top) {
    mlval header = *base;
    if (PRIMARY(header) != HEADER) {
      if (bytes < 8)
	printf(" %4d : 0x%08x size      8\n",(int)count++,
	       ((mlval)base)+PAIRPTR);
      base += 2;
    } else {
      word secondary = SECONDARY(header);
      word length = LENGTH(header);
      size_t size = OBJECT_SIZE(secondary, length);
      if (size > bytes) {
	mlval obj;
	if ((secondary == ARRAY) ||
	    (secondary == WEAKARRAY) ||
	    ((secondary == BYTEARRAY) && (length != 12)))
	  obj = MLPTR(base,REFPTR);
	else
	  obj = MLPTR(base,POINTER);
	printf(" %4d : 0x%08x size %6d\n",(int)count++, obj, (int)size);
      }
      base = (mlval*)(((word)(base)) + size);
    }
  }
  *countp = count;
}

static void explore_greater(size_t bytes)
{
  struct heap_info_table *this = heap_info_list;
  size_t count = 0;
  while (this != NULL) {
    int i = 0;
    while (i < (int)(this->nr_entries)) {
      struct heap_info *heap = &this->table[i];
      switch(heap->type) {
      case EXPLORE_HEAP_AREA:
	explore_greater_area(heap->the.heap.base,
			     heap->the.heap.top, bytes, &count);
	break;
      case EXPLORE_STACK_AREA:
	explore_greater_area(heap->the.stack.base,
			     heap->the.stack.top, bytes, &count);
	break;
      case EXPLORE_STACK_REGISTERS:
      case EXPLORE_ROOT:
      default:
	/* VC++ requires an empty statement here */ ;
      }
      i++;
    }
    this = this->next;
  }
  if (count == 0)
    printf("No objects larger than %d bytes\n", (int)bytes);
  else
    printf("%d objects found\n",(int)count);
}

static void explore_list_code_names_area(mlval *base, mlval *top, size_t *countp)
{
  size_t count = *countp;
  while (base < top) {
    mlval header = *base;
    if (PRIMARY(header) != HEADER)
      base += 2;
    else {
      word secondary = SECONDARY(header);
      word length = LENGTH(header);
      size_t size = OBJECT_SIZE(secondary, length);

      if (secondary == CODE) {
	mlval ancill = base[1];
	mlval names = FIELD(ancill,0);
	size_t number, i;
	if (PRIMARY(names) == PAIRPTR)
	  number = 2;
	else
	  number = LENGTH(GETHEADER(names));
	for (i = 0; i < number; i ++)
	  printf(" %4d : 0x%08x %s\n", (int)count++, FIELD(names,i),
		 CSTRING(FIELD(names,i)));
      }
      base = (mlval*)(((word)(base)) + size);
    }
  }
  *countp = count;
}

static void explore_list_code_names(void)
{
  struct heap_info_table *this = heap_info_list;
  size_t count = 0;
  while (this != NULL) {
    int i = 0;
    while (i < (int)(this->nr_entries)) {
      struct heap_info *heap = &this->table[i];
      switch(heap->type) {
      case EXPLORE_HEAP_AREA:
	explore_list_code_names_area(heap->the.heap.base,
				     heap->the.heap.top, &count);
	break;
      case EXPLORE_STACK_AREA:
      case EXPLORE_STACK_REGISTERS:
      case EXPLORE_ROOT:
      default:
	/* VC++ requires an empty statement here */ ;
      }
      i++;
    }
    this = this->next;
  }
}

static void explore_show_byte(byte what)
{
  if ((what > 31) && (what < 127))
    putchar(what);
  else {
    byte hi = what / 16;
    byte lo = what % 16;
    printf("\\x");
    putchar(hi > 9 ? hi - 10 + 'a' : hi + '0');
    putchar(lo > 9 ? lo - 10 + 'a' : lo + '0');
  }
}

static void explore_view_string(byte *from, byte *to)
{
  while (from+32 < to) {
    byte *index = from;
    printf("0x%08x: ",(word)from);
    from += 32;
    while(index < from)
      explore_show_byte(*index++);
    printf("\n");
  }
  if (from < to) {
    printf("0x%08x: ", (word)from);
    while (from < to)
      explore_show_byte(*from++);
    printf("\n");
  }
}

static void explore_view_words(mlval *from, mlval *to)
{
  while (from+3 < to) {
    printf("0x%08x: 0x%08x 0x%08x 0x%08x 0x%08x\n",
	   (word)from, from[0], from[1], from[2], from[3]);
    from += 4;
  }
  if (from < to) {
    printf("0x%08x: ", (word) from);
    while (from < to)
      printf("0x%08x ",*from++);
    printf("\n");
  }
}

static void explore_view(void)
{
  mlval what = place->where;
  switch(PRIMARY(what)) {
  case INTEGER0:
  case INTEGER1:
  case PRIMARY6:
  case PRIMARY7:
  case HEADER:
    printf("Nothing to view\n");
    break;
  case PAIRPTR:
    explore_view_words((mlval*)(what-PAIRPTR), (mlval*)(what+8-PAIRPTR));
    break;
  case POINTER: {
    mlval *ptr = OBJECT(what);
    mlval header = *ptr;
    word secondary = SECONDARY(header);
    word length = LENGTH(header);
    switch(secondary) {
    case CODE:
    case RECORD:
      explore_view_words(ptr+1, ptr+1+length);
      break;
    case STRING:
      explore_view_string((byte*)(ptr+1), (byte*)((word)(ptr+1)+length));
      break;
    case BYTEARRAY:
      explore_view_words(ptr+1, (mlval*)((word)(ptr+1)+length));
      break;
    case BACKPTR:
      printf("Can't view single code item; use 'c 0' to go to vector\n");
      break;
    default:
      printf("Can't view broken object\n");
      break;
    }
    break;
  }
  case REFPTR: {
    mlval *ptr = OBJECT(what);
    mlval header = *ptr;
    word secondary = SECONDARY(header);
    word length = LENGTH(header);
    switch(secondary) {
    case WEAKARRAY:
    case ARRAY:
      explore_view_words(ptr+3, ptr+3+length);
      break;
    case BYTEARRAY:
      explore_view_words(ptr+1, (mlval*)((word)(ptr+1)+length));
      break;
    default:
      printf("Can't view broken object\n");
      break;
    }
    break;
    }
  }
}

#define LOOP_CONTINUE	0	/* go around the loop */
#define LOOP_FINISH	1	/* exit the explorer with zero */
#define LOOP_EXIT	2	/* exit the explorer with non-zero */


static int explore_command(void)
{
  char buffer[100];
  char *end;
  word argument;
  int display = 0;
  if (fgets(buffer,100,stdin)) {
    switch(buffer[0]) {
				/* Commands for recently-seen values */
    case 'b':			/* back */
      display = explore_back();
      if (display == 0)
	printf("Can't go back!\n");
      break;
    case 'f':			/* forward */
      display = explore_forward();
      if (display == 0)
	printf("Can't go forward!\n");
      break;
				/* History commands */
    case 'n':			/* next */
      display = explore_next();
      if (display == 0)
	printf("No more history!\n");
      break;
    case 'p':			/* previous */
      display = explore_previous();
      if (display == 0)
	printf("Already at the start of history!\n");
      break;
    case 'h':			/* history */
      explore_show_history();
      break;
    case 'r':			/* repeat <n> */
      argument = strtoul(buffer+2,&end,0);
      if (end != buffer+2) {
	display = explore_repeat((int)argument);
	if (display == 0)
	  printf("Can't repeat item %d\n",argument);
      } else 
	printf("Can't parse repeat count\n");
      break;
				/* Navigation commands */
    case 'c':			/* child <n> */
      argument = strtoul(buffer+2,&end,0);
      if (end != buffer+2) {
	display = explore_child((int)argument);
	if (display == 0)
	  printf("Can't go to child %d\n",argument);
	} else
	  printf("Can't parse child number\n");
      break;
    case 's':			/* search for occurences */
      explore_search();
      break;
    case '$': {			/* find string */
      word length = strlen (buffer+1);
      buffer[length] = 0;
      explore_find_string(buffer+1, length-1);
      break;
    }
    case 'g':			/* goto <x> */
      argument = strtoul(buffer+2,&end,0);
      if (end != buffer+2) {
	display = explore_go(argument);
	if (display == 0)
	  printf("Can't go to ML value 0x%08x\n",argument);
      } else
	printf("Can't parse value\n");
      break;
    case 'l':			/* find largest object */
      display = explore_largest();
      if (display == 0)
	printf("No largest object\n");
      break;
    case '>':			/* find largest object */
      argument = strtoul(buffer+2,&end,0);
      if (end != buffer+2)
	explore_greater((size_t)argument);
      else
	printf("Can't parse size\n");
      break;
    case 'u':			/* up in heap */
      display = explore_up();
      if (display == 0)
	printf("Can't move up\n");
      break;
    case 'd':			/* down in heap */
      display = explore_down();
      if (display == 0)
	printf("Can't move down\n");
      break;
				/* Misc */
    case 'a':			/* analyse */
      gc_analyse_heap();
      break;
    case 'i':			/* list all code names */
      explore_list_code_names();
      break;
    case '!':			/* global consistency check */
      explore_consistency();
      break;
    case '.':			/* reshow */
      display = 1;
      break;
    case 'v':			/* view */
      explore_view();
      break;
    case 'w':                   /* watch */
      gc_analyse_creation_start();
      break;
    case 'o':                   /* output */
      gc_analyse_creation_stop();
      break;
    case 'q':			/* quit */
      return LOOP_FINISH;
      break;
    case 'x': 			/* exit */
      return LOOP_EXIT;	
      break;
    default:
      printf("Unknown explorer command \"%s\"\n",buffer);
    case '?':
      printf("Explorer help:                                  \n"
             " Previously-seen values:                        \n"
             "   b     - backwards        f - forwards        \n"
             "\n"
             " History:                                       \n"
             "   p     - previous         n - next            \n"
             "   r <n> - repeat item      h - show history    \n"
             "\n"
             " Navigation:                                    \n"
             "   c <n> - goto child       s - search for roots\n"
             "   g <x> - goto ML value    l - find largest object\n"
             "   > <n> - find objects larger than <n> bytes   \n"
             "   $ab   - find string 'ab'                     \n"
             "   u     - up in heap       d - down in heap    \n"
             "\n"
             " Misc:                                          \n"
             "   . - reshow current item                      \n"
             "   a - display image analysis report            \n"
             "   w - watch (analyse) allocation               \n"
             "   o - output allocation analysis               \n"
             "   i - list all code names                      \n"
             "   v - view contents of current object          \n"
	     "   ! - perform global consistency check         \n"
             "   q - quit                 x - exit runtime    \n"
             "   ? - help                                     \n"
	     /* e,j,k,m,t,y,z unused */);
      break;
    }
    if (display)
      describe(place->where,2);
    return LOOP_CONTINUE;
  } else return LOOP_FINISH;
}

/* The main exploring function */
extern int explore(mlval where, int use_stacks)
{
  int looping = LOOP_CONTINUE;
  printf("Entering explorer...\n");
  explore_get_heap_info(use_stacks);
  explore_start(where);
  printf("Exploring.\n");
  printf("\ncurrent value : ");
  describe(place->where, 2);
  while (looping == LOOP_CONTINUE) {
    printf("\nexplore> ");
    looping = explore_command();
  }
  explore_free_all();
  return (looping == LOOP_EXIT);
}

/* Printing object descriptions */

static void describe_record(mlval what, int verbosity, word length)
{
  word i;
  for (i = 0; i < length; i++) {
    printf("\n  %d : ",i);
    describe(FIELD(what,i),verbosity-1);
  }
}

static void describe_array(mlval what, int verbosity, word length)
{
  word i;
  for (i = 0; i < length; i++) {
    printf("\n  %d : ",i);
    describe(MLSUB(what,i),verbosity-1);
  }
}

static void describe_object(mlval what,int verbosity)
{
  word primary = PRIMARY(what);
  mlval header = GETHEADER(what);
  int closure = 0;

  printf("0x%08x : ",what);

  /* check for closures */
  if (header == 0 || SECONDARY(header) == RECORD) {
    mlval code = FIELD(what,0);
    if (PRIMARY(code) == POINTER) {
      closure = 1;
      if (code == stub_c)
	printf("closure of stub_c");
      else if (code == stub_asm)
	printf("closure of stub_asm");
      else if (SECONDARY(GETHEADER(code)) == BACKPTR)
	printf("closure of %s",CSTRING(CCODENAME(code)));
      else
	closure = 0;
    }
  }
  if (closure) {
    if (verbosity < 2)
      return;
    else {
      int back = 0;
      printf(": ");
      while (header == 0) {
	what -= 8;
	back++;
	header = GETHEADER(what);
      }
      if (back)
	printf("back %d to ", back);
    }
  }
  if (primary == PAIRPTR) {
    if (verbosity < 2)
      printf("pair (0x%08x, 0x%08x)",FIELD(what,0),FIELD(what,1));
    else {
      printf("pair ");
      describe_record(what,verbosity,2);
    }
    return;
  } else {
    word secondary = SECONDARY(header);
    word length = LENGTH(header);
    switch(secondary) {
    case RECORD:
      if (verbosity < 2) {
	switch(length) {
	case 1:
	  printf("singleton (0x%08x)",FIELD(what,0));
	  return;
	case 2:
	  printf("record (0x%08x, 0x%08x)",FIELD(what,0), FIELD(what,1));
	  return;
	case 3:
	  printf("record (0x%08x, 0x%08x, 0x%08x)",
		 FIELD(what,0), FIELD(what,1), FIELD(what,2));
	  return;
	default:
	  printf("record length %d: (0x%08x, 0x%08x, ...)",length,
		 FIELD(what,0),FIELD(what,1));
	  return;
	}
      } else {
	printf("record ");
	describe_record(what,verbosity,length);
	return;
      }
    case STRING:
      if (verbosity < 2) {
	if (length <= 25)
	  printf("\"%s\"",CSTRING(what));
	else {
	  char buf[25];
	  memcpy(buf,CSTRING(what),24);
	  buf[24] = '\0';
	  printf("string length %d: \"%s...\"",length,buf);
	}
      } else
	printf("string length %d: \"%s\"",length,CSTRING(what));
      return;
    case CODE: {
      int elements = NFIELDS(FIELD(FIELD(what,0),0));
      printf("code vector length %d, %d items",length, elements);
      if (verbosity >= 2)
	printf(" (first item %s)",CSTRING(FIELD(FIELD(FIELD(what,0),0),0)));
      return;
    }
    case BACKPTR:
      printf("code for %s",CSTRING(CCODENAME(what)));
      return;
    case BYTEARRAY:
      if (length == 12) {
	printf("real %.16G",GETREAL(what));
	return;
      } else {
	printf("data error: regular ptr to a bytearray");
	return;
      }
    case ARRAY:
      printf("data error: regular ptr to an array");
      return;
    case HEADER50:
      printf("illegal header 50");
      return;
    case WEAKARRAY:
      printf("data error: regular ptr to a weakarray");
      return;
   default:
      printf("data error: regular ptr to an invalid header 0x%08x",header);
      return;
    }
  }
}

static void describe_ref(mlval what,int verbosity)
{
  mlval *ptr = OBJECT(what);
  mlval header = *ptr;
  word secondary = SECONDARY(header);
  word length = LENGTH(header);

  printf("0x%08x : ",what);

  switch(secondary) {
  case WEAKARRAY:
    printf("weak ");
  case ARRAY:
    if (verbosity < 2) {
      switch(length) {
      case 1:
	printf("ref [0x%08x]",MLSUB(what,0));
	return;
      case 2:
	printf("array [0x%08x, 0x%08x]",
	       MLSUB(what,0),MLSUB(what,1));
	return;
      default:
	printf("array length %d: [0x%08x, 0x%08x, ...]",length,
	       MLSUB(what,0),MLSUB(what,1));
	return;
      }
    } else {
      printf("array length %d:",length);
      describe_array(what,verbosity,length);
      return;
    }
  case BYTEARRAY: {
    byte* bytes = CBYTEARRAY(what);
    printf("bytearray length %d: [%02x, %02x, %02x,...]",length,
	   bytes[0],bytes[1],bytes[2]);
    return;
  }
  default:
    printf("data error: ref ptr to bad header 0x%08x",header);
    return;
  }
}

extern void describe(mlval what, int verbosity)
{
  if (verbosity < 0)
    return;
  switch(PRIMARY(what)) {
  case INTEGER0:
  case INTEGER1:
    printf("%d",CINT(what));
    return;
  case PRIMARY6:
    if (what == DEAD) {
      printf("DEAD");
      return;
    }
  case PRIMARY7:
    printf("non-ML: 0x%08x",what);
    return;
  case POINTER:
  case PAIRPTR:
    if (verbosity < 1)
      printf("ptr   : 0x%08x",what);
    else
      describe_object(what,verbosity);
    return;
  case REFPTR:
    if (verbosity < 1)
      printf("ref   : 0x%08x",what);
    else
      describe_ref(what,verbosity);
    return;
  case HEADER:
    printf("hdr: 0x%08x",what);
    return;
  }
}

#endif /* EXPLORER */
