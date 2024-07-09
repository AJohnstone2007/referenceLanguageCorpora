/* ==== I386 CODE MANIPULATION ====
 * 
 * Copyright 2013 Ravenbrook Limited <http://www.ravenbrook.com/>.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Description
 * -----------
 * This module contains any and all code for examining and
 * manipulating I386 code sequences.
 *
 * At various points in the runtime we have to crawl over Intel
 * code. For instance, when we get an asynchronous event and want to
 * say something about where we are (e.g. time profiling, fatal signal
 * handling). For another instance, when we want to modify a piece of
 * code to allow space profiling. The code to do this is ugly and
 * hacky almost beyond belief (it mirrors the x86 architecture);
 * without a doubt it is the worst code anywhere in the MLWorks
 * runtime. It is quarantined in this file.
 * 
 * Revision Log
 * ------------
 * $Log: i386_code.c,v $
 * Revision 1.11  1998/09/17 14:20:14  jont
 * [Bug #70143]
 * Fix compiler warnings in is_closure
 *
 * Revision 1.10  1998/08/17  16:48:07  jont
 * [Bug #70143]
 * Fix is_closure to understand about DLL based code and closures
 *
 * Revision 1.9  1998/07/15  10:07:22  jont
 * [Bug #70073]
 * Remove support for unaligned esp during float sequences
 * as we've stoped the code generator making them
 *
 * Revision 1.8  1998/02/13  14:57:01  jont
 * [Bug #30242]
 * pc_in_clousre now made available to non-i386 code
 *
 * Revision 1.7  1998/01/30  15:27:02  jont
 * [Bug #70025]
 * Remove unused name near_tail
 *
 * Revision 1.6  1998/01/23  17:49:57  jont
 * [Bug #70025]
 * Fix some compilation errors detected by linux
 *
 * Revision 1.5  1998/01/23  11:04:53  jont
 * [Bug #70025]
 * Allow retn to indicate function epilog
 * Add call sequence handling
 * Deal with extension to function prolog
 * Fix some bugs
 *
 * Revision 1.4  1996/10/31  15:02:51  nickb
 * Add some more documentation.
 *
 * Revision 1.3  1995/12/13  12:43:01  nickb
 * Some problem with read_instr tables, and also with error messages.
 *
 * Revision 1.2  1995/12/12  17:49:31  nickb
 * Add general intel instruction parser, to enable space profiling.
 *
 * Revision 1.1  1995/11/24  11:38:54  nickb
 * new unit
 * I386 code mangling.
 *
 */

#include "utils.h"
#include "types.h"
#include "values.h"
#include "mem.h"
#include "state.h"
#include "interface.h"
#include "stacks.h"
#include "arena.h"
#include "ml_utilities.h"
#include "i386_code.h"

/* When we get an asynchronous event and want to say something about
   what's on the stack, we need to have meaningful stack frames to
   examine, regardless of what code we have interrupted. Since we push
   and pop stack frames one word at a time, we have to grovel over the
   code which was interrupted to check whether we're in the middle of
   pushing or popping a frame, and accordingly construct fake stack
   frames if necessary */

typedef unsigned char 		uint8;
typedef unsigned short		uint16;
typedef unsigned long		uint32;
typedef long int32;

#define TRUE			1
#define FALSE			0

/* This stuff is based on the following sketchy notes about entry/exit
   sequences:

- Before all of the entry instructions, ebp is a non-leaf closure and
eip is in that closure's code item.

- All the entry instructions except the overflow block come before
'mov ebp, edi'.

- The instructions in the overflow block are 'around' a 'call
extend(thread)' instruction.

- The size of the step 'back' to a valid stack frame is computable
from the entry instructions executed so far.

- The exit instructions are all 'pop' or 'add esp, immediate',
or lea esp, n[esp] (this will be changed).

Stack reconstruction:

First:     if not in ML, use ml_sp.
Second:    if stack not aligned, use (edi,esp+2)
Otherwise: examine instruction:
	DEFINITE ENTRY
	DEFINITE EXIT
	DEFINITE TAIL
	DEFINITE CALL SEQUENCE
	POSSIBLE ENTRY
	POSSIBLE EXIT
	POSSIBLE TAIL
	POSSIBLE CALL SEQUENCE
	NOT ANY OF ABOVE

We catch these cases as follows. In the sequences given below, there
are some alternative sequences, to catch cases such as having to
compute the framesize before testing for overflow. Such cases are
presented side by side.

1. non-leaf entry:

1.0. possible stack extension to cope with tail exit needing larger frame

59	pop	ecx
57	push	edi ; Possibly several of these
51	push	ecx

1.1. stack overflow test:
	-				8d4c24xxlea	ecx, -framesize(esp)
					8d8c24xxxxxxxx
3b6664	cmp	esp,slimit(thread)	3b4e64	cmp	ecx, slimit(thread)
72xx	jcc	overflow		72xx	jcc	overflow
0f82xxxxxxxx				0f82xxxxxxxx
1.2. skip non-GC part of frame:

post_overflow:
83ecxx	sub	esp, non_gc_framesize
81ecxxxxxxxx

1.3. push zeroes for GC spill slots:
33c9	-		xor	ecx,ecx 33c9	xor	ecx,ecx
51	-		push 	ecx	83c1xx	add	ecx, size
					81c1xxxxxxxx
...	-		...			loop:
51	-		push	ecx	6a00	pushl	0
	-		-		e2fc	loop 	loop

1.4. save GC saves:			
52	-		-			push edx
50	-		push eax		push eax

1.5. push linkage (caller's closure, frame pointer)
57		push	edi
8d4c24xx	lea	ecx, framesize-4(esp)
8d8c24xxxxxxxx
51		push	ecx

1.6. move callee's closure into closure
8bfd		mov	ebp, edi

1.7. separate block to call stack overflow code:	

overflow:
b9xxxxxxxx	mov	ecx, framesize
ff5610		call	extend(thread)
ebxx		jmp	post_overflow
e9xxxxxxxx

2. non-leaf exit:

2.1. discard frame pointer:
59	pop	ecx

2.2. retrieve caller's closure:
5f	pop	edi


2.3. pop GC saves:
58	-		pop	eax		pop	eax
5a	-		-			pop	edx


2.4. pop rest of frame:
	-	83c4xx		add	esp, rest_of_frame
		81c4xxxxxxxx

2.5. return:
c3	ret


3. tail call:

3.1. if non-leaf, discard frame

3.1.1. discard fp slot
5f	pop	edi

3.1.2. restore caller's closure
5f	pop	edi

3.1.3. pop GC saves
58	-		pop	eax		pop	eax
5a	-		-			pop	edx

3.1.4. ditch rest of frame
83c4xx	-			add	esp, rest_of_frame
81c4xxxxxxxx
3.1.5. ditch possible extra stack arguments
8f0424  pop [esp]          8f0524xx    pop n[esp]
                           83c4xx      add esp, #n
3.2. tail

8d4903	lea	ecx, reg+3			-
ffe1	jmp	reg			ebxx	jmp tag
					e9xxxxxxxx

4. call sequence:

4.1. Set up stacked parameters
50 - 57 push rn
or
                                        57      push edi ; May be several
                                        89xxxxxx mov n[esp], rn
then
8d4903	lea	ecx, ecx+3              -
ffd1    call    ecx                     e8xxxxxxxx call tag

4.2. Acquire closure
8bxxxx mov ebp, m32 - 8d6fxx/8dafxxxxxxxx lea ebp, n[edi] - 8bef/89fd mov ebp, edi

4.3. Acquire address
8b4dff  mov     ecx, -1[ebp]
8d4903	lea	ecx, ecx+3			-
*/

/* first we have a function instruction_type(ipp, amount).  This
   classifies the instruction found at **ipp into one of a number of
   types, and identifies it more specifically within each of those
   types. So, for instance, it might say "this is a jump instruction
   of a kind which may be found in a function prelude". If it
   recognises the instruction, it also increments *ipp to point after
   the instruction, and sets *amount to an associated 'amount': a
   'push' amount in a prologue, a 'pop' amount in an epilogue, a jump
   distance for a jump instruction. */

/* low LOCATION_BITS bits show where the instruction might be found */

#define LOCATION_BITS		8
#define LOCATION_MASK		((1 << LOCATION_BITS)-1)
#define LOCATION(type)		((type) & LOCATION_MASK)

#define BODY			0	/* not recognised */
#define POSSIBLE		1	/* not a certain identification */
#define PROLOG			2	/* a prologue instruction */
#define OVERFLOW		4	/* an overflow block instruction */
#define EPILOG			8	/* an epilogue instruction */
#define END_PROLOG		16	/* this instruction ends a prologue */
#define CALL_SEQ		32	/* an instruction in a call setup */

#define POSSIBLE_PROLOG		(POSSIBLE+PROLOG)
#define POSSIBLE_OVERFLOW	(POSSIBLE+OVERFLOW)
#define POSSIBLE_EPILOG		(POSSIBLE+EPILOG)
#define POSSIBLE_CALL_SEQ       (POSSIBLE+CALL_SEQ)

/* high bits identify particular instructions */

#define INSTR_SHIFT		LOCATION_BITS
#define INSTR(type)		((type) >> INSTR_SHIFT)
#define MAKE_INSTR(instr,loc)	(((instr) << INSTR_SHIFT) + (loc))

#define PLAIN			0	/* not special */
#define JMP_OR_RET		1	/* a jump or ret instruction */
#define PUSHL0			2	/* pushl 0 */
#define LOOP			3	/* loop -4 */
#define ADD_ECX_SIZE		4	/* add ecx, immediate */
#define POP_EDI			5	/* pop edi */
#define POP_ECX			6	/* pop ecx */
#define PUSH_ECX		7	/* push ecx */
#define PUSH_EDI		8	/* push edi */
#define RETN			9	/* ret n */
#define TAIL_POP		11	/* pop [esp] */
#define TAIL_POPN		12	/* pop n[esp] */

#define ARGS_SIZE(clos) ((CCODEARGS(FIELD((clos), 0)))*4)

static uint32 instruction_type(uint8 **ipp, int32 *amount)
{
  uint8 *ip = *ipp;
  uint8 op = *ip;
  switch(op) {
  case 0x0f:					/* two-byte opcode */
    if (ip[1] == 0x82) {			/* jb overflow */
      *amount = *(uint32*)(ip+2);		/* jump amount */
      *ipp = ip+6;
      return MAKE_INSTR(JMP_OR_RET,POSSIBLE_PROLOG);
    }
    break;
  case 0x31:
  case 0x33:
    if (ip[1] == 0xc9) {      			/* xor ecx,ecx */
      *amount = 0;
      *ipp = ip+2;
      return POSSIBLE_PROLOG;
    }
    break;
  case 0x3b:
    if ((ip[2] == 0x60 || ip[2] == 0x64) &&
	((ip[1] == 0x4e) || (ip[1] == 0x66))) { /*cmp ecx|esp,slimit(thread) */
      *amount = 0;
      *ipp = ip+3;
      return PROLOG;
    }
    break;
  case 0x50:	/* push eax */
    *amount = -4;
    *ipp = ip+1;
    return POSSIBLE_PROLOG | POSSIBLE_CALL_SEQ;
  case 0x51:	/* push ecx */
    *amount = -4;
    *ipp = ip+1;
    return MAKE_INSTR(PUSH_ECX, POSSIBLE_PROLOG | POSSIBLE_CALL_SEQ);
  case 0x52:	/* push edx */
    *amount = -4;
    *ipp = ip+1;
    return POSSIBLE_PROLOG | POSSIBLE_CALL_SEQ;
  case 0x53:	/* push ebx */
    *amount = -4;
    *ipp = ip+1;
    return POSSIBLE_PROLOG | POSSIBLE_CALL_SEQ;
  case 0x55:	/* push ebp */
    *amount = -4;
    *ipp = ip+1;
    return POSSIBLE_PROLOG | POSSIBLE_CALL_SEQ;
  case 0x57:	/* push edi */
    *amount = -4;
    *ipp = ip+1;
    return MAKE_INSTR(PUSH_EDI, POSSIBLE_PROLOG | POSSIBLE_CALL_SEQ);
  case 0x58:	/* pop eax */
    *amount = 4;
    *ipp = ip+1;
    return POSSIBLE_EPILOG;
  case 0x59:	/* pop ecx */
    *amount = 4;
    *ipp = ip+1;
    return MAKE_INSTR(POP_ECX, POSSIBLE_EPILOG | POSSIBLE_PROLOG);
  case 0x5a:	/* pop edx */
    *amount = 4;
    *ipp = ip+1;
    return POSSIBLE_EPILOG;
  case 0x5d:    /* pop ebp */
    *amount = 4;
    *ipp = ip+1;
    return POSSIBLE_CALL_SEQ;
    /* This can happen when we run out of temporaries for unspilling */
  case 0x5f:	/* pop edi */
    *amount = 4;
    *ipp = ip+1;
    return MAKE_INSTR(POP_EDI,EPILOG);
  case 0x68:
    *amount = -4;		/* parameter push immediate */
    *ipp = ip+5;
    return CALL_SEQ;
    break;
  case 0x6a:
    if (ip[1] == 0x00) {	/* pushl 0 */
      *amount = -4;
      *ipp = ip+2;
      return MAKE_INSTR(PUSHL0, POSSIBLE_PROLOG | POSSIBLE_CALL_SEQ);
    }
    break;
  case 0x72:		/* jb overflow */
    *amount = ip[1];
    *ipp = ip+2;
    return MAKE_INSTR(JMP_OR_RET,POSSIBLE_PROLOG);
  case 0x81:		/* add 32-bit immediate */
    {
      int32 change = *(int32*)(ip+2);
      *ipp = ip+6;
      switch (ip[1]) {
      case 0xc1:		/* add ecx, size */
	*amount = change;
	return MAKE_INSTR(ADD_ECX_SIZE,POSSIBLE_PROLOG);
      case 0xc4:		/* add esp, rest_of_frame */
	*amount = change;
	return EPILOG;
      case 0xec:		/* sub esp, non_gc_framesize */
	*amount = -change;
	return PROLOG;
      default:
	break;
      }
      break;
    }
  case 0x83:		/* add 8-bit immediate */
    {
      int32 change = ip[2];
      switch (ip[1]) {
      case 0xc1:		/* add ecx, size */
	*amount = change;
	*ipp = ip+3;
	return MAKE_INSTR(ADD_ECX_SIZE,POSSIBLE_PROLOG);
      case 0xc4:		/* add esp, rest_of_frame */
	*amount = change;
	*ipp = ip+3;
	return EPILOG;
      case 0xec:		/* sub esp, non_gc_framesize */
	*amount = -change;
	*ipp = ip+3;
	return PROLOG;
      default:
      break;
      }
    }
    break;
  case 0x89:		/* mov r/m32, r32 */
    *amount = 0;
    switch (ip[1] & 0xc7) {
    case 4:
    case 0x44:
    case 0x84:		/* esp relative addressing with sib */
      if ((ip[2] & 7) == 4) {
	switch (ip[1] & 0xc7) {
	case 4:
	  *ipp = ip+3;	/* No displacement */
	  break;
	case 0x44:
	  *ipp = ip+4;	/* 8 bit displacement */
	  break;
	case 0x84:
	  *ipp = ip+7;	/* 32 bit displacement */
	  break;
	default:
	  error("Code generation error when i386_code.c compiled");
	}
	return POSSIBLE_CALL_SEQ;
      } else {
	/* Not esp relative, no problem */
	break;
      }
    default:
      switch (ip[1] & 0xc0) {
      case 0x00:
	/* mov 0[rm], rn */
	*ipp = ip + 2;	/* No displacement */
	return POSSIBLE_CALL_SEQ;
      case 0x40:
	/* mov n[rm], rn */
	*ipp = ip + 3;	/* 8 bit displacement */
	return POSSIBLE_CALL_SEQ;
      case 0x80:
	/* mov n[rm], rn */
	*ipp = ip + 6;	/* 32 bit displacement */
	return POSSIBLE_CALL_SEQ;
      case 0xc0:
	/* mov <rn>, <rm> */
	*ipp = ip+2;
	return POSSIBLE_CALL_SEQ;
      }
    }
    break;
  case 0x8b:
    *amount = 0;
    if (ip[1] == 0xfd) {	/* mov edi, ebp */
      *ipp = ip+2;
      return END_PROLOG;
    }
    if ((ip[1] & 0xc0) == 0xc0) {
			/* mov <rn>, <rm> */
      *ipp = ip+2;
      return POSSIBLE_CALL_SEQ;
    }
    if ((ip[1] & 0xf8) == 0x48 && ip[1] != 0x4c && ip[1] != 0x4e && ip[2] == 0xff) {
				/* mov ecx, -1[<reg>] */
      *ipp = ip+3;
      return POSSIBLE_CALL_SEQ;
    }
    if ((ip[1] & 0xc7) == 0x04 && ip[2] == 0x24) {
				/* mov rn, 0[esp] ; unspill */
      *ipp = ip+3;
      return POSSIBLE_CALL_SEQ;
    }
    if ((ip[1] & 0xc7) == 0x44 && ip[2] == 0x24) {
				/* mov rn, n[esp] ; unspill */
      *ipp = ip+4;
      return POSSIBLE_CALL_SEQ;
    }
    if ((ip[1] & 0xc7) == 0x84 && ip[2] == 0x24) {
				/* mov rn, n[esp] ; unspill */
      *ipp = ip+7;
      return POSSIBLE_CALL_SEQ;
    }
    if ((ip[1] & 0x1c) == 0x14) {
				/* mov ebp, m32 */
      switch (ip[1] & 0xc0) {
      case 0x00:		/* mov ebp, [<reg>] */
	*ipp = ip+2;
	switch (ip[1] & 7) {
	case 4:
	  /* sib case */
	  *ipp = ip+3;
	  break;
	case 5:
	  /* disp32 case */
	  *ipp = ip+5;
	  break;
	default:
	  break;
	}
	break;
      case 0x40:		/* mov ebp, n[<reg>] */
	if ((ip[1] & 7) == 4) {
	  /* sib case */
	  *ipp = ip+4;
	} else {
	  /* Normal case */
	  *ipp = ip+3;
	}
	break;
      case 0x80:		/* mov ebp, n[<reg>] ; n large */
	if ((ip[1] & 7) == 4) {
	  /* sib case */
	  *ipp = ip+7;
	} else {
	  /* Normal case */
	  *ipp = ip+6;
	}
	break;
      case 0xc0:		/* mov ebp, <reg> */
	*ipp = ip+2;
	break;
      }
      return POSSIBLE_CALL_SEQ;
    }
    break;
  case 0x8d:			/* lea */
    *amount = 0;
    if (ip[1] == 0x49 && ip[2] == 0x03) { /* lea ecx, 3[ecx] */
      *ipp = ip+3;
      return POSSIBLE_EPILOG | POSSIBLE_CALL_SEQ;
    } else if (ip[1] == 0x4c && ip[2] == 0x24) { /* lea ecx, framesize(esp) */
      /* This can also be stack allocation */
      /* The test is the alignment of the addend */
      /* 0 for PROLOG, 1 for BODY or CALL_SEQ */
      *ipp = ip+4;
      if ((ip[3] & 3) == 0) return PROLOG;
      return POSSIBLE_CALL_SEQ;
    } else if (ip[1] == 0x8c && ip[2] == 0x24) { /* lea ecx, framesize(esp) */
      /* This can also be stack allocation */
      /* The test is the alignment of the addend */
      /* 0 for PROLOG, 1 for BODY */
      *ipp = ip+7;
      if ((ip[3] & 3) == 0) return PROLOG;
      return POSSIBLE_CALL_SEQ;
    } else if (ip[1] == 0x64 && ip[2] == 0x24) { /* lea esp n[esp] */
      *ipp = ip + 4;
      *amount = ip[3];
      return EPILOG;
    } else if (ip[1] == 0x6f) { /* lea ebp n[edi] */
      /* Potential call sequence into vector from same set (n is disp8) */
      *ipp = ip + 3;
      return POSSIBLE_CALL_SEQ;
    } else if (ip[1] == 0xaf) { /* lea ebp n[edi] */
      /* Potential call sequence into vector from same set (n is disp32) */
      *ipp = ip + 6;
      return POSSIBLE_CALL_SEQ;
    }
    break;
  case 0x8f:
    /* pop general amount (used during tail) */
    if ((ip[1] & 0x38) == 0) {
      *amount = 4;
      *ipp = ip + 3 + (((ip[1] & 0xc0) == 0) ? 0 : 1);
      return ((ip[1] & 0xc0) == 0) ?
	MAKE_INSTR(TAIL_POP, EPILOG) :
	MAKE_INSTR(TAIL_POPN, EPILOG);
    } else {
      break;
    }
  case 0xb9:			/* mov ecx, framesize */
    *amount = 0;
    *ipp = ip+5;
    return POSSIBLE_OVERFLOW;
    break;
  case 0xc2:                    /* retn */
    *amount = ip[1] + (ip[2] << 8); /* pop this much */
    *ipp = ip + 3;              /* 3 byte instruction */
    /*1
    message("retn pop amount 0x%x from 0x%x and 0x%x", *amount, ip[1], ip[2]);
    2*/
    return MAKE_INSTR(RETN,EPILOG);
    break;
  case 0xc3:			/* ret */
    *amount = 0;
    *ipp = ip+1;
    return MAKE_INSTR(JMP_OR_RET,EPILOG);
    break;
  case 0xc7:			/* mov r/m32, imm32 */
    if ((ip[1] & 0x3f) == 0x20 &&
	(ip[1] & 0xc0) != 0xc0 && (ip[2] & 7) == 0) {
      /* Confirmed move into stack */
      *amount = 0;
      switch (ip[1] &  0xc0) {
      case 0x00:		/* mov [esp], imm32 */
	*ipp = ip + 7;
	break;
      case 0x40:		/* mov n[esp], imm32 */
	*ipp = ip + 8;
	break;
      case 0x80:		/* mov n[esp], imm32 n large */
	*ipp = ip + 11;
	break;
      default:
	error("Code generation error when i386_code.c compiled");
      }
      return POSSIBLE_CALL_SEQ;
    }
    break;
  case 0xe2:
    if (ip[1] == 0xfc) {       	/* loop -4 */
      *amount = 0;
      *ipp = ip+2;
      return MAKE_INSTR(LOOP,POSSIBLE_PROLOG);
    }
    break;
  case 0xe8:			/* call rel */
    *amount = 0;		/* Not worried about this */
    *ipp = ip+5;
    return MAKE_INSTR(JMP_OR_RET, CALL_SEQ);
  case 0xe9:			/* jmp rel32 */
    *amount = *(uint32*)(ip+1);
    *ipp = ip+5;
    return MAKE_INSTR(JMP_OR_RET,POSSIBLE_PROLOG+EPILOG);
    break;
  case 0xeb:	/* jmp rel8 */
    *amount = ip[1];
    *ipp = ip+2;
    return MAKE_INSTR(JMP_OR_RET,POSSIBLE_PROLOG+EPILOG);
    break;
  case 0xff:			/* jmp, call or push */
    if  (ip[1] == 0xe1) {	/* jmp ecx */
      *amount = 0;
      *ipp = ip+2;
      return MAKE_INSTR(JMP_OR_RET,POSSIBLE_EPILOG);
    } else if (ip[1] == 0xd1) {	/* call ecx */
      *amount = 0;
      *ipp = ip+2;
      return MAKE_INSTR(JMP_OR_RET,CALL_SEQ);
    } else if (ip[1] == 0x56 && ip[2] == 0x10) {
				/* jmp 16(thread) */
      *ipp = ip+3;
      return MAKE_INSTR(JMP_OR_RET,OVERFLOW);
    } else if ((ip[1] & 0x38) == 0x30) {
				/* push r/m32 */
      *amount = -4;
      switch (ip[1] & 0xc0) {
      case 0x00:		/* push [<reg>] */
	*ipp = ip + 2;
	break;
      case 0x40:		/* push n[<reg>] */
	*ipp = ip + 3;
	break;
      case 0x80:		/* push n[<reg>] ; n large */
	*ipp = ip + 6;
	break;
      case 0xc0:		/* push <reg> ; Should never happen */
	*ipp = ip + 2;
	break;
      }
      if ((ip[1] & 7) == 4 && (ip[1] & 0xc0) != 0xc0) {
	*ipp += 1;
      }
      return POSSIBLE_CALL_SEQ;
    }
    break;
  default:
    break;
  }
  *amount = 0;
  return BODY;
}

/* This function computes the amount of stacked parameters passed to
   a function with closure in the function parameter. */

static uint32 compute_args_size(word ebp)
{
  uint32 change = ARGS_SIZE(ebp);
  /* Total size including tailees from here */
  uint8 *ip = (uint8 *)(CCODESTART(FIELD(ebp, 0))); /* Code pointer */
  int32 amount;
  uint32 type = instruction_type(&ip,&amount);
  /*1
  message("compute_args_size starts at %d", change);
  2*/
  if (INSTR(type) == POP_ECX) {
    while (1) {
      type = instruction_type(&ip,&amount);
      if (INSTR(type) == PUSH_EDI) {
	change += amount;
      } else {
	break;
      }
    }
  }
  /*1
  message("compute_args_size returns %d", change);
  2*/
  return change;
}

/* This tells us whether a given ML value is a valid closure */

static int is_closure(mlval clos, int diagnose)
{
  /* first check that it is an ML pointer into a valid memory area */
  if (ISORDPTR(clos)) {
    if (validate_ml_address((void *) clos)) {
      /* next check that it indicates a record, or a shared closure */
      mlval header = GETHEADER(clos);
      if (header == 0 || SECONDARY(header) == RECORD) {
	/* then check that the first field is a pointer */
	mlval code = FIELD(clos,0);
	if (PRIMARY(code) == POINTER && validate_ml_address((void *)code)) {
	  /* Looks ok and is valid */
	  /* If it's on the heap we must be more careful */
	  /* it's possible at this point that we have a partially allocated
	   * record, so this 'code' value could be completely bogus */
	  int  type = SPACE_TYPE(code);
	  if (type == TYPE_FREE) {
	    /* On the heap but not in use */
	    /* Shouldn't happen */
	    if (diagnose)
	      printf("is_closure fails because code 0x%x is in a free area\n", code);
	    return 0;
	  } else {
	    /* Either not on the heap at all, assumed static */
	    /* Or on the heap */
	    /* Either way, ok, if it points to a code item */
	    if (diagnose && (SECONDARY(GETHEADER(code)) != BACKPTR))
	      printf("is_closure fails because code 0x%x has a bad BACKPTR\n", code);
	    return (SECONDARY(GETHEADER(code)) == BACKPTR);
	  } 
	} else {
	  if (diagnose)
	    printf("is_closure fails because code 0x%x is bad\n", code);
	}
      } else {
	if (diagnose)
	  printf("is_closure fails because ebp does not have a valid header\n");
      }
    } else {
      if (diagnose)
	printf("is_closure fails because ebp is not a valid address\n");
    }
  } else {
    if (diagnose)
      printf("is_closure fails because ebp is not a pointer\n");
  }
  return 0;
}

/* this function is called if we think we are in the prologue. It
   determines the amount of stack frame pushed so far and computes an
   sp accordingly. */

static word fixup_sp_prologue(word eip, word esp, word ebp, word edi, word ecx,
			     int *psure, int in_ebp, word *clos1, word *clos2)
{
  int sure = *psure;
  /*1
  message("enter fixup_sp_prologue with esp = 0x%x, eip = 0x%x, ecx = 0x%x" , esp, eip, ecx);
  2*/
  if (!in_ebp) {
    if (sure) {
      (void)is_closure(ebp, 1);
      *(int *)0 = 0;
      error("profiler found prologue instruction outside ebp closure, sure was %d\nbyte sequence 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, ip = 0x%x, ebp[0] = 0x%x",
	    sure, *(uint8 *)eip, ((uint8 *)eip)[1], ((uint8 *)eip)[2],
	    ((uint8 *)eip)[3], ((uint8 *)eip)[4], ((uint8 *)eip)[5],
	    ((uint8 *)eip)[6], ((uint8 *)eip)[7], eip, FIELD(ebp, 0));
    }
    else {
      /*1
      message("exit fixup_sp_prologue unsure not in ebp");
      2*/
      return 0;
    }
  } else {
    uint32 zeroed = 0;
    uint8 *ip = (uint8*)CCODESTART(FIELD(ebp,0));
    /* start of the function */
    int offset = 4;
    /* account for the return address */
    uint32 type, change;
    int32 amount;

    /* First calculate how much the stack will have changed before entry */

    /*1
    while ((unsigned int)ip < eip) {
      message("0x%x ", *ip);
      ip++;
    }
    2*/
    change = compute_args_size(ebp);
    offset += change; /* Add in amount of pushed arguments */
    /*1
    message("Stack change before entry found to be %d, offset now %d", change, offset);
    2*/

    ip = (uint8*)CCODESTART(FIELD(ebp,0)); /* back to start of the function */
    while((word)ip != eip) { /* scan through instructions in the function */
      type = instruction_type(&ip,&amount);
      if (LOCATION(type) & PROLOG) {
	if ((LOCATION(type) & POSSIBLE) == 0)
	  sure = TRUE;
	switch (INSTR(type)) {
	  /* these next few cases do the right thing if we land inside
	   * a frame-zeroing loop */
	case ADD_ECX_SIZE:
	  zeroed = amount;
	  offset += (zeroed - ecx) * 4;
	  break;
	case PUSHL0:
	  offset += 4;
	  break;
	case LOOP:
	  offset -= 4;
	  break;
	case JMP_OR_RET:
	  /* amount here is the branch distance, not a stack amount */
	  break;
	default:
	  if (zeroed) {		/* we've finished a zeroing loop */
	    offset += ecx * 4;
	    zeroed = 0;
	  }
	  /* the general case: a pushed amount */
	  offset -= amount;
	  break;
	}
	/*1
	message("Scanning instruction type 0x%x, amount = %d, offset changed to 0x%x", type, amount, offset);
	2*/
      } else {
	if (*psure)
	  error("non-prologue instruction 0x%x 0x%x 0x%xfound before profile point"
		" in a function prologue", *ip, ip[1], ip[2]);
	else {
	  return 0;
	}
      }
    }
    *psure = sure;
    *clos2 = edi;
    *clos1 = ebp;
    /*1
    message("exit fixup_sp_prologue with esp = 0x%x", esp+offset);
    2*/
    return  esp+offset;
  }
}

/* this function is called when we think we are in a stack overflow
   block. It checks that we are indeed in an overflow block and
   figures out closures accordingly */

#define MAX_OVERFLOW_BLOCK_SIZE		13

static word fixup_sp_overflow(word esp, word eip, word edi, word ebp,
			      int in_ebp, int sure, word *clos1, word *clos2)
{
  /*1
  message("enter fixup_sp_overflow, esp = 0x%x, eip = 0x%x, ebp = 0x%x", esp, eip, ebp);
  2*/
  if (!in_ebp) {
    if (sure)
      error("profiler found overflow instruction outside ebp closure");
    else
      return 0;
  } else {
    uint8* ip = (uint8*) CCODESTART(FIELD(ebp,0));
    uint32 type;
    int32 amount;

    do {		/* find the entry branch to overflow block */
      type =instruction_type(&ip,&amount);
    } while (type != MAKE_INSTR(JMP_OR_RET,POSSIBLE_PROLOG));
    ip += amount;
    if ((word)ip > eip || (word)ip + MAX_OVERFLOW_BLOCK_SIZE < eip) {
      /* we're not in the overflow block */
      if (sure)
	error("profiler found overflow instruction outside overflow block");
      else {
	return 0;
      }
    }
    *clos2 = edi;
    *clos1 = ebp;
    /*1
    message("exit fixup_sp_overflow returning esp = 0x%x", esp+ARGS_SIZE(ebp)+4);
    2*/
    return esp+ARGS_SIZE(ebp)+4; /* Account for stacked parameters and return address*/
  }
}

/* this function is called if we think we are in a call sequence. It
   figures out how much of a stack frame has been added. The closures are
   as for the general case */

static word fixup_sp_call_seq(word esp, word eip, word edi, word ebp,
		  int *sure, uint32 type, int32 amount)
{
  uint8 *ip = (uint8 *)eip;
  /*1
  message("Checking potential call sequence, esp = 0x%x, eip = 0x%x, edi = 0x%x, type = 0x%x", esp, eip, edi, type);
   2*/
  if (edi == STACK_RAISE) {
    /* Inside interface.S, so no multi-arg passing */
    /* So we can treat this as a general body */
    return 0;
  }
  if (!*sure) {
    /* Scan forward until we become sure */
    while (LOCATION(type) & CALL_SEQ) {
      if ((LOCATION(type) & POSSIBLE)) {
	type = instruction_type(&ip, &amount);
      } else {
	*sure = TRUE;
	break;
      }
    }
  }
  /*1
  message("Checking potential call sequence phase 1 complete");
  2*/
  if (*sure) {
    /* Now scan forward from the proc start to see how much stack is pushed */
    /* This is tedious, but I can't see a better way of doing it */
    ip = (uint8 *)CCODESTART(FIELD(edi, 0));  /* Back to start of function */
    /*1
    message("Checking potential call sequence sure, start = 0x%x", ip);
    2*/
    while ((word)ip < eip) {
      /* First look for a call sequence start */
      uint8 *start_ip = ip;
      int ok = TRUE;
      /*1
      message("Trying for call sequence start at 0x%x", start_ip);
      2*/
      while ((word)ip < eip) {
	uint8 *ipp = ip;
	type = instruction_type(&ipp, &amount);
	if (!(LOCATION(type) & CALL_SEQ)) {
	  ok = FALSE;
	  /* Use read_instr to increment ip */
	  if (read_instr(&ip)) {
	    break;
	  } else {
	    message("fixup_sp_call_seq fails because read_instr fails at ip = 0x%x", ipp);
	    return 0;
	  }
	  break;
	} else {
	  ip = ipp;
	  /* We might have reached the end of a previous call sequence */
	  if (INSTR(type) == JMP_OR_RET) {
	    if ((word)ip < eip) {
	      ok = FALSE;
	      break;
	    } else {
	      start_ip = ip;
	      /* This should now drop naturally out of the loop */
	    }
	  }
	}
      }
      if (ok && (word)ip == eip) {
	/* Exited the loop at the instruction we were interrupted at */
	/* Now scan forward from start_ip to eip adding in stack amounts */
	uint32 offset = 0;
	/*1
	message("Found the call sequence, computing stack change");
	2*/
	ip = start_ip;
	while ((word)ip != eip) {
	  type = instruction_type(&ip, &amount);
	  offset -= amount;
	}
	/*1
	message("fixup_sp_call_seq exits with offset %d added to esp giving 0x%x", offset, esp+offset);
	2*/
	return esp+offset;
      }
      /* Not the right call sequence, so continue looking */
    }
    /*1
       message("fixup_sp_call_seq fails to find call sequence");
     2*/
    return 0;
  } else {
    /*1
    message("fixup_sp_call_seq return unsure");
    2*/
    return 0; /* We never were sure */
  }
}

static word sign_extend(uint8 disp)
{
  return (disp >= 128) ? -disp : disp;
}

/* this function is called if we think we are in an epilogue. It
   figures out how much of a stack frame remains to be popped, and
   where the closures reside. */

static word fixup_sp_epilogue(word eip, word esp, word edi, word ebp, word ecx,
			       uint8* ip, uint32 type, uint32 amount,
			       int *psure, word *clos1, word *clos2)
{
  uint32 offset = 0, old_type = type;
  int sure = *psure;
  uint8 *old_ip = ip;
  uint32 types[256];
  uint8 *ptrs[256];
  int i = 0;
  /*1
  message("enter fixup_sp_epilogue, sure = %d, esp = 0x%x, eip = 0x%x, ebp = 0x%x", sure, esp, ip, ebp);
  2*/
  if (INSTR(type) == POP_EDI) {
    /* pop edi instructions change where the closures live */
    offset += amount;
    ptrs[i] = ip;
    type = instruction_type(&ip,&amount);
    types[i++] = type;
    *clos1 = edi;
    if (INSTR(type) == POP_EDI) {
      *clos2 = *(uint32*)(esp+4);
    } else {
      *clos2 = *(uint32*)esp;
    }
  } else {
    *clos2 = edi;
  }
  /* scan through from this point, adding up any pop amounts */
  while(INSTR(type) != JMP_OR_RET && INSTR(type) != RETN) {
    offset += amount;
    ptrs[i] = ip;
    type = instruction_type(&ip, &amount);
    types[i++] = type;
    if ((LOCATION(type) & EPILOG)) {
      if ((LOCATION(type) & POSSIBLE)== 0)
	sure = TRUE;
    } else {
      if (sure)
	error("non-exit instruction of type %d found after profile point in exit, sure was %d\nbyte sequence 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x, types 0x%x, 0x%x, 0x%x, 0x%x, ptrs 0x%x, 0x%x, 0x%x, 0x%x, ip = 0x%x, old_ip = 0x%x, silly = 0x%x",
	      type, *psure, *old_ip, old_ip[1], old_ip[2], old_ip[3],
	      old_ip[4], old_ip[5], old_ip[6], old_ip[7],
	      types[0], types[1], types[2], types[3], ptrs[0],
	      ptrs[1], ptrs[2], ptrs[3], ip, old_ip, ip[1] & 0x38);
      else {
	return 0;
      }
    }
  }
  if (INSTR(type) == RETN) {
    offset += amount; /* Cut stack back by amount we will pop */
    /*1
    message("fixup_sp_epilog handles retn case, offset changes by %d to %d", amount, offset);
    2*/
  } else if (LOCATION(type) & POSSIBLE) {
    if (sure) {
      /* We need to compute how many arguments will be passed to the tailee
       * There are two possible cases
       * 1. We are before the pop edi
       * In this case, we have not started retracting the stack, so
       * # (args passed) = ARGS_SIZE(edi) - retracted
       * retracted can be computed by scanning forward looking for the pop n[esp] stuff
       * 2. We are after the pop edi
       * In this case, ebp contains the new closure
       * So we compute ARGS_SIZE(ebp) - amount pushed by new closure PROLOG
       */
      int edi_count = 0;
      ip = old_ip;
      /* Back to interruption point. First scan to determine case 1 or 2 */
      type = old_type;
      /*1
      message("fixup_sp_epilog handling tail case, offset = %d", offset);
      2*/
      while (INSTR(type) != JMP_OR_RET) {
	if (INSTR(type) == POP_EDI) edi_count++;
	type = instruction_type(&ip, &amount);
      }
      if (edi_count < 2) {
	offset += compute_args_size(ebp);
	/*1
	message("fixup_sp_epilog handling tail case post pop edi, offset changes to %d", offset);
	2*/
      } else {
	uint32 full_stack_size = ARGS_SIZE(edi);
	/*1
	message("fixup_sp_epilog handling tail case pre pop edi, full size %d", full_stack_size);
	2*/
	/* Here we scan forward to find how much gets retracted (may be nothing at all) */
	ip = old_ip;
	type = old_type;
	while (INSTR(type) != JMP_OR_RET && INSTR(type) != RETN) {
	  if (INSTR(type) == TAIL_POPN) {
	    /* Several args thrown away */
	    full_stack_size -= 4+ip[-1];
	    /*1
	    message("full_stack_size reduced by pop n to %d", full_stack_size);
	    2*/
	    break;
	  } else if (INSTR(type) == TAIL_POP) {
	    /* One arg thrown away */
	    full_stack_size -= 4;
	    /*1
	    message("full_stack_size reduced by pop to %d", full_stack_size);
	    2*/
	    break;
	  }
	  type = instruction_type(&ip, &amount);
	}
	offset += full_stack_size;
	/*1
	message("fixup_sp_epilog handling tail case pre pop edi, offset changes to %d", offset);
	2*/
      }
    } else if (INSTR(old_type) == JMP_OR_RET || INSTR(type) == JMP_OR_RET) {
      /* We have arrived close to a possible tail instruction */
      /* We check to see if we're going somewhere given by ebp */
      if (is_closure(ebp, 0)) {
	/* We may be in business. Amount remaining on stack = */
	/* ARGS_SIZE(ebp) - amount pushed by new closure PROLOG*/
	/* First check that where we're going is where ebp says */
	word target = (word)CCODESTART(FIELD(ebp, 0));
	/*
	int near_tail = 0;
	*/
	ip = (uint8 *)eip;
	if (INSTR(old_type) != JMP_OR_RET) {
	  /* Move ip up to the JMP_OR_RET */
	  /* We have already adjusted offset correctly */
	  /* So no need to do that again here */
	  /*1
	    message("Dealing with break near tail");
	    near_tail = 1;
	    2*/
	  type = old_type;
	  /* We need to deal with the possibility that */
	  /* some of these instructions will change ecx */
	  while(INSTR(type) != JMP_OR_RET) {
	    old_ip = ip;
	    type = instruction_type(&ip, &amount);
	  }
	  ip = old_ip; /* Point to the JMP_OR_RET */
	}
	switch(*ip) {
	case 0xe9:
	  if (target != (word)ip + 5 + *(unsigned int *)(ip+1)) {
	    /*1
	    message("Relative branch tail fails with target = 0x%x, ip = 0x%x, *(ip+1) = 0x%x", target, ip, *(unsigned int *)(ip+1));
	    2*/
	    return 0;
	    /* The jmp rel32 case */
	  } else {
	    break;
	  }
	case 0xeb:
	  if (target != (word)ip + 2 + sign_extend(ip[1])) {
	    return 0;
	    /* The jmp rel8 case */
	  } else {
	    break;
	  }
	case 0xff:
	  if (ip[1] != 0xe1 || ((ecx + 3) & ~3) != target) {
	    /* Allow for being before the lea ecx, 3[ecx] */
	    return 0;
	    /* The jmp ecx case */
	  } else {
	    break;
	  }
	default:
	  return 0;
	}
	/*1
	if (near_tail) message("Dealt with break near tail");
	2*/
	offset += compute_args_size(ebp);
	sure = TRUE;
      } else {
	return 0;
      }
    } else {
      /*1
      message("fixup_sp_epilog returns unsure");
      2*/
      return 0;
    }
  } else {
    /*1
    message("fixup_sp_epilog handles ret 0 case");
    2*/
  }
  *psure = sure;
  /*1
  message("exit fixup_sp_epilogue with esp = 0x%x", esp+offset+4);
  2*/
  return esp+offset+4;	/* +4 for the return address */
}

/* If we have a possible sp value, this function checks that it
   indicates a reasonable frame-pointer chain */

static int check_possible_sp(word sp)
{
  int i = 4;	/* check a few stack frames */
  while (i-- && sp && sp != (word)CURRENT_THREAD->ml_state.stack_top) {
    if (sp & 3)
      return FALSE;
    else if (!is_ml_stack((word*)sp))
      return FALSE;
    sp = *(word*)sp;
  }
  return TRUE;
}

/* Up to two 'stack frames' of interest to the profiler or to a fatal
   signal backtrace may be kept in registers. We diagnose the current
   state from the registers and build fake frames if necessary */

static struct stack_frame signal_fake_frames[2];

/* This is the controlling function for all this gruesome
   stack-frame stuff. It returns a putative stack pointer */

extern word i386_fixup_sp(word esp, word eip, word edi, word ebp, word ecx)
{
  word clos1 = MLUNIT;
  word clos2 = MLUNIT;
  int in_ebp = FALSE;
  uint32 type, location;
  int32 amount;
  word sp = 0;
  uint8 *ip;
  int sure, accurate = TRUE;

  /*1
  message("enter i386_fixup_sp with esp = 0x%x", esp);
  2*/
  switch (global_state.in_ML) {
  case 2:			/* not in ML; ml_sp is not valid */
    sp = 0;
    break;
  case 0:			/* not in ML; ml_sp is valid */
    sp = CURRENT_THREAD->ml_state.sp;
    break;
  case 1:			/* in ML; figure out sp from registers */
    /*1
    message("enter i386_fixup_sp case 1");
    2*/
    if (is_closure(ebp, 0) && pc_in_closure(eip,ebp)) {
      if (CCODELEAF(FIELD(ebp,0))) {
	clos2 = ebp;
	sp = esp+4+ARGS_SIZE(ebp);	/* +4 for the return address */
	/*1
	  message("enter i386_fixup_sp case 1 leaf in ebp (0x%x), sp changed to 0x%x", ebp, sp);
	  2*/
	break;
      } else
	in_ebp = TRUE;
    }
    /*1
    message("enter i386_fixup_sp aligned not leaf");
    2*/
    /* in ML, with sp aligned, and not in a leaf function */
    ip = (uint8*)eip;
    /*1
    message("i386_fixup_sp call instruction_type");
    2*/
    type = instruction_type(&ip,&amount);
    /*1
    message("i386_fixup_sp done instruction_type");
    2*/
    location = LOCATION(type);
    sure = TRUE;
    switch (location) {
      /* first deal with the sure cases */
    case END_PROLOG:
      clos2 = ebp;
      sp = esp;
      break;
    case PROLOG:
      sp = fixup_sp_prologue (eip,esp,ebp,edi,ecx,&sure,in_ebp,&clos1,&clos2);
      break;
    case EPILOG:
      sp = fixup_sp_epilogue (eip,esp,edi,ebp,ecx,ip,type,amount,&sure,&clos1,&clos2);
      break;
    case OVERFLOW:
      sp = fixup_sp_overflow (esp,eip,edi, ebp, in_ebp, sure, &clos1, &clos2);
      break;
    case BODY:
      clos2 = edi;
      sp = esp;
      accurate = FALSE;
      break;
    case CALL_SEQ:
      sp = fixup_sp_call_seq(esp, eip, edi, ebp, &sure, type, amount);
      clos2 = edi;
      esp = sp;
      break;
    default:
      /* we are left with the unsure cases, which may possibly be in a
       * special sequence */
      sure = FALSE;
      
      if (location & PROLOG) {
	sp = fixup_sp_prologue (eip, esp, ebp, edi, ecx,
				&sure, in_ebp, &clos1, &clos2);
	if (sp && (sure || check_possible_sp(sp))) {
	  break;
	}
      }
      if (location & EPILOG) {
	sp = fixup_sp_epilogue (eip,esp,edi,ebp,ecx,ip,type,amount,&sure,&clos1,&clos2);
	if (sp && (sure || check_possible_sp(sp))) {
	  break;
	}
	clos1 = MLUNIT;
	clos2 = MLUNIT;
      }
      if (location & OVERFLOW) {
	sp = fixup_sp_overflow (esp,eip,edi,ebp,in_ebp,sure,&clos1,&clos2);
	if (sp && check_possible_sp(sp)) {
	  break;
	}
      }
      if (location & CALL_SEQ) {
	sp = fixup_sp_call_seq(esp, eip, edi, ebp, &sure, type, amount);
	if (sp && sure) {
	  /* We treat this a bit like a body, but there can't have been */
	  /* any temporary pushes */
	  clos2 = edi;
	  esp = sp;
	  break;
	}
      }
      clos2 = edi;
      sp = esp;
      accurate = FALSE;
      break;
    }
    break;
  default:
    message("flag 'in_ML' corrupted, preventing profiling");
    sp = 0;
    break;
  }
  if (!accurate) {
    int i;
    word potential_fp;
    /* possibly adjust the sp by a small multiple of 4 */
    /*1
    message("Dealing with inaccurate case");
    2*/
    for(i=4 ; i ; i--, sp+= 4) {
      potential_fp = *(word*)sp;
      if (((potential_fp & 3) == 0) &&
	  (is_ml_stack((word*)potential_fp) ||
	   potential_fp == (CURRENT_THREAD->ml_state.stack_top)))
	break;
    }
    if (i == 0) {
      sp = 0;	/* give up */
      /*1
      message("esp = 0x%x, eip = 0x%x, edi = 0x%x, ebp = 0x%x, ecx = 0x%x, location = 0x%x", esp, eip, edi, ebp, ecx, location);
      ip = (uint8 *)eip;
      for (i = 0; i < 40; i++) message("0x%x ", ip[i]);
      for (i = 0; i < 4; i++) {
	message("esp[%d] = 0x%x", i, ((unsigned int *)esp)[i]);
      }
      2*/
#if 0
      if (is_closure(edi) && pc_in_closure(eip,edi)) {
	message("in code vector %s", CSTRING(CCODENAME(FIELD(edi, 0))));
	message("profiler unable to interpret stack contents");
      } else {
	message("Not in edi");
	message("profiler unable to interpret stack contents");
      }
#else
      message("profiler unable to interpret stack contents");
#endif
    }
  }

  if (clos2 != MLUNIT) { 
    signal_fake_frames[1].closure = clos2;
    signal_fake_frames[1].fp = (struct stack_frame *)sp;
    
    sp = (word)(signal_fake_frames+1);
  }
  if (clos1 != MLUNIT) {
    signal_fake_frames[0].closure = clos1;
    signal_fake_frames[0].fp = (struct stack_frame *)sp;
    sp = (word)(signal_fake_frames);
  }
  /*1
  message("exit fixup_sp with sp = 0x%x", sp);
  2*/
  return sp;
}

/*
 * We need to be able to scan through x86 machine code, for instance
 * when looking for particular sequences. This file defines a
 * table-driven function, read_instr, which skips over a single x86
 * instruction.
 *
 * If read_instr(&p) succeeds, it increments p by one instruction and
 * returns SUCCESS (== 1). If it fails, it prints a message to the
 * message stream and does not change p, returning FAILURE (== 0).
 * 
 * There should be no false positives or negatives. The tables are
 * derived from the 386/387 reference manuals, so include no 'secret'
 * instructions and no new instructions for the 486, Pentium, Pentium
 * Pro. &c.  */

#define FAILURE 0
#define SUCCESS 1

#define GROUP_BITS		3
#define TYPE_BITS		4
#define PFX_BITS		1
#define GROUP_SHIFT		TYPE_BITS
#define PFX_SHIFT		(GROUP_SHIFT + GROUP_BITS)
#define TYPE_MASK		((1 << TYPE_BITS)-1)
#define GROUP_MASK		(((1 << GROUP_BITS)-1)<<GROUP_SHIFT)
#define PFX			(1 << (PFX_SHIFT))

#define NONE			0	/* no operands */
#define IMMEDIATE8		1	/* 8 bit immediate operand */
#define IMMEDIATE16		2	/* 16 bit immediate operand */
#define IMMEDIATE24		3	/* 24 bit immediate operand */
#define IMMEDIATE32		4	/* 32 bit immediate operand */
#define IMMEDIATE		5	/* 16 or 32 bit immediate operand */
#define MODRM			6	/* modrm operand */
#define MODRM_IMMEDIATE		7	/* modrm and immediate operands */
#define MODRM_IMMEDIATE8	8	/* modrm and 8 bit immediate */
#define ADDRESS			9	/* 16 or 32 bit address operand */
#define FAR_ADDRESS		10	/* 16 bit segment, then an address */
#define BAD			15	/* reserved opcode */

/* groups 2,4,5,6,7,8 of instructions are treated specially */

#define MAKE_GROUP(n,type)	((((n)-1) << GROUP_SHIFT)+(type))
#define GET_GROUP(type)		(((type) & GROUP_MASK) >> GROUP_SHIFT)
#define GET_TYPE(type)		((type) & TYPE_MASK)

#define PREFIX			(PFX+0)	/* e.g. REP */
#define AD_PREFIX		(PFX+1)	/* address-size prefix */
#define OP_PREFIX		(PFX+2)	/* operand-size prefix */
#define NEXT_BYTE		(PFX+3)	/* 0x0f: second byte lookup needed */
#define GROUP3A			(PFX+4) /* group 3: type depends on modrm */
#define GROUP3B			(PFX+5) /* group 3: type depends on modrm */
#define FP			(PFX+6)	/* floating point instruction */

/* the first byte is looked up in this table */

static byte opcode_type [] = 
{
  /* 0x0n */
  MODRM,	/* add	rm8, r8 */
  MODRM,	/* add	rm, r */
  MODRM,	/* add	r8, rm8 */
  MODRM,	/* add	r, rm */
  IMMEDIATE8,	/* add	al, i8 */
  IMMEDIATE,	/* add	[e]ax, i */
  NONE,		/* push	es */
  NONE,		/* pop	es */
  MODRM,	/* or	rm8, r8 */
  MODRM,	/* or	rm, r */
  MODRM,	/* or	r8, rm8 */
  MODRM,	/* or	r, rm */
  IMMEDIATE8,	/* or	al, i8 */
  IMMEDIATE,	/* or	[e]ax, i */
  NONE,		/* push	cs */
  NEXT_BYTE,
  /* 0x1n */
  MODRM, 	/* adc	rm8, r8 */
  MODRM,	/* adc	rm, r */
  MODRM,	/* adc	r8,rm8 */
  MODRM,	/* adc	r, rm */
  IMMEDIATE8,	/* adc	al, i8 */
  IMMEDIATE,	/* adc	[e]ax, i */
  NONE,		/* push	ss */
  NONE,		/* pop	ss */
  MODRM,	/* sbb	rm8, r8 */
  MODRM,	/* sbb	rm, r */
  MODRM,	/* sbb	r8, rm8 */
  MODRM,	/* sbb	r, rm */
  IMMEDIATE8,	/* sbb	al, i8 */
  IMMEDIATE,	/* sbb	[e]ax, i */
  NONE,		/* push	ds */
  NONE,		/* pop	ds */
  /* 0x2n */
  MODRM,	/* and	rm8, r8 */
  MODRM,	/* and	rm, r */
  MODRM,	/* and	r8,rm8 */
  MODRM,	/* and	r,rm */
  IMMEDIATE8,	/* and	al,i8 */
  IMMEDIATE,	/* and	 [e]ax,i */
  PREFIX,
  NONE,		/* daa */
  MODRM, 	/* sub	rm8,r8 */
  MODRM, 	/* sub	rm,r */
  MODRM,	/* sub	r8,rm8 */
  MODRM, 	/* sub	r,rm */
  IMMEDIATE8,	/* sub	al,i8 */
  IMMEDIATE,	/* sub	 [e]ax,i */
  PREFIX,
  NONE,		/* das */
  /* 0x3n */
  MODRM,	/* xor	rm8,r8 */
  MODRM, 	/* xor	rm,r */
  MODRM, 	/* xor	r8,rm8 */
  MODRM, 	/* xor	r,rm */
  IMMEDIATE8,	/* xor	al,i8 */
  IMMEDIATE,	/* xor	[e]ax,i */
  PREFIX,
  NONE, 	/* aaa */
  MODRM,	/* cmp	rm8,r8 */
  MODRM,	/* cmp	rm,r */
  MODRM,	/* cmp	r8,rm8 */
  MODRM,	/* cmp	r,rm */
  IMMEDIATE8,	/* cmp	al,i8 */
  IMMEDIATE,	/* cmp	 [e]ax,i */
  PREFIX,
  NONE,		/* aas */
  /* 0x4n */
  NONE, 	/* inc	 [e]ax */
  NONE, 	/* inc	 [e]cx */
  NONE,		/* inc	 [e]dx */
  NONE,		/* inc	 [e]bx */
  NONE,		/* inc	 [e]sp */
  NONE,		/* inc	 [e]bp */
  NONE,		/* inc	 [e]si */
  NONE, 	/* inc	 [e]di */
  NONE, 	/* dec	 [e]ax */
  NONE, 	/* dec	 [e]cx */
  NONE,		 /* dec	 [e]dx */
  NONE,		/* dec	 [e]bx */
  NONE,		/* dec	 [e]sp */
  NONE,		/* dec	 [e]bp */
  NONE,		/* dec	 [e]si */
  NONE,		/* dec	 [e]di */
  /* 0x5n */
  NONE,		/* push	 [e]ax */
  NONE,		/* push	 [e]cx */
  NONE,		/* push	 [e]dx */
  NONE,		/* push	 [e]bx */
  NONE,		/* push	 [e]sp */
  NONE,		/* push	 [e]bp */
  NONE,		/* push	 [e]si */
  NONE,		/* push	 [e]di */
  NONE,		/* pop	 [e]ax */
  NONE,		/* pop	 [e]cx */
  NONE,		/* pop	 [e]dx */
  NONE,		/* pop	 [e]bx */
  NONE,		/* pop	 [e]sp */
  NONE,		/* pop	 [e]bp */
  NONE,		/* pop	 [e]si */
  NONE,		/* pop	 [e]di */
  /* 0x6n */
  NONE,		/* pusha */
  NONE,		/* popa	 */
  MODRM,	/* bound r,rm */
  MODRM,	/* arpl	 rm16, r16 */
  PREFIX,
  PREFIX,
  OP_PREFIX,
  AD_PREFIX,
  IMMEDIATE,	/* push	i */
  MODRM_IMMEDIATE, /* imul r,rm,i */
  IMMEDIATE8,	/* push	i8 */
  MODRM_IMMEDIATE8, /* imul r,rm,i8 */
  NONE,		/* insb	*/
  NONE,		/* ins[wd] */
  NONE,		/* outsb */
  NONE, 	/* outs[wd] */
  /* 0x7n */
  IMMEDIATE8,	/* jo	rel8 */
  IMMEDIATE8,	/* jno	rel8 */
  IMMEDIATE8,	/* jb	rel8 */
  IMMEDIATE8,	/* jnb	rel8 */
  IMMEDIATE8,	/* jz	rel8 */
  IMMEDIATE8,	/* jnz	rel8 */
  IMMEDIATE8,	/* jbe	rel8 */
  IMMEDIATE8,	/* jnbe	rel8 */
  IMMEDIATE8,	/* js	rel8 */
  IMMEDIATE8,	/* jns	rel8 */
  IMMEDIATE8,	/* jp	rel8 */
  IMMEDIATE8,	/* jnp	rel8 */
  IMMEDIATE8,	/* jl	rel8 */
  IMMEDIATE8,	/* jnl	rel8 */
  IMMEDIATE8,	/* jle	rel8 */
  IMMEDIATE8,	/* jnle	rel8 */
  /* 0x8n */
  MODRM_IMMEDIATE8,	/* group1 rm8, i8 */
  MODRM_IMMEDIATE,	/* group1 rm,i */
  BAD,		/* not an instruction */
  MODRM_IMMEDIATE8,	/* group1 rm,i8 */
  MODRM,	/* test	rm8,r8 */
  MODRM,	/* test	rm,r */
  MODRM,	/* xchg	rm8,r8 */
  MODRM,	/* xchg	rm,r */
  MODRM,	/* mov	rm8,r8 */
  MODRM,	/* mov	rm,r */
  MODRM,	/* mov	r8,rm8 */
  MODRM,	/* mov	r,rm */
  MODRM,	/* mov	rm16,seg */
  MODRM,	/* lea	r,rm */
  MODRM,	/* mov	seg,rm16 */
  MODRM,	/* pop	rm */
  /* 0x9n */
  NONE,		/* nop	 */
  NONE,		/* xchg	 eax	[e]cx */
  NONE,		/* xchg	 [e]ax	[e]dx */
  NONE,		/* xchg	 [e]ax	[e]bx */
  NONE,		/* xchg	 [e]ax	[e]sp */
  NONE,		/* xchg	 [e]ax	[e]bp */
  NONE,		/* xchg	 [e]ax	[e]si */
  NONE,		/* xchg	 [e]ax	[e]di */
  NONE,		/* cbw	 */
  NONE,		/* cwd	 */
  FAR_ADDRESS,	/* call ptr16:p */
  NONE,		/* wait	 */
  NONE,		/* pushf */
  NONE,		/* popf */
  NONE,		/* sahf	 */
  NONE,		/* lahf	 */
  /* 0xAn */
  ADDRESS,	/* mov	al,m */
  ADDRESS,	/* mov	[e]ax, m */
  ADDRESS,	/* mov	m,al */
  ADDRESS,	/* mov	m,[e]ax */
  NONE,		/* movsb */
  NONE,		/* movs[wd] */
  NONE,		/* cmpsb */
  NONE,		/* cmps[wd] */
  IMMEDIATE8,	/* test	al,i8 */
  IMMEDIATE,	/* test	 [e]ax,i */
  NONE,		/* stosb */
  NONE,		/* stos[wd] */
  NONE,		/* lodsb */
  NONE,		/* lods[wd] */
  NONE,		/* scasb */
  NONE,		/* scas[wd] */
  /* 0xBn */
  IMMEDIATE8,	/* mov	AL,i8 */
  IMMEDIATE8,	/* mov	CL,i8 */
  IMMEDIATE8,	/* mov	DL,i8 */
  IMMEDIATE8,	/* mov	BL,i8 */
  IMMEDIATE8,	/* mov	AH,i8 */
  IMMEDIATE8,	/* mov	CH,i8 */
  IMMEDIATE8,	/* mov	DH,i8 */
  IMMEDIATE8,	/* mov	DL,i8 */
  IMMEDIATE, 	/* mov	[e]ax,i */
  IMMEDIATE, 	/* mov	[e]cx,i */
  IMMEDIATE, 	/* mov	[e]dx,i */
  IMMEDIATE, 	/* mov	[e]bx,i */
  IMMEDIATE, 	/* mov	[e]sp,i */
  IMMEDIATE, 	/* mov	[e]bp,i */
  IMMEDIATE, 	/* mov	[e]si,i */
  IMMEDIATE, 	/* mov	[e]di,i */
  /* 0xCn */
  MAKE_GROUP(2,MODRM_IMMEDIATE8),  /* group2 rm8,i8 */
  MAKE_GROUP(2,MODRM_IMMEDIATE8),  /* group2 rm,i8 */
  IMMEDIATE16,		/* ret n */
  NONE,		/* ret	 */
  MODRM,	/* les */
  MODRM,	/* lds */
  MODRM_IMMEDIATE8,	/* mov	rm8,i8 */
  MODRM_IMMEDIATE,	/* mov	rm,i */
  IMMEDIATE24,		/* enter i16,i8 */
  NONE,		/* leave	 */
  IMMEDIATE16,	/* ret n */
  NONE,		/* ret */
  NONE,		/* int	3 */
  IMMEDIATE8,	/* int i */
  NONE,		/* into	 */
  NONE,		/* iret	 */
  /* 0xDn */
  MAKE_GROUP(2,MODRM),	/* group2 rm8,1 */
  MAKE_GROUP(2,MODRM),	/* group2 rm,1 */
  MAKE_GROUP(2,MODRM),	/* group2 rm8,CL */
  MAKE_GROUP(2,MODRM),	/* group2 rm,CL */
  IMMEDIATE8,	/* aam	 */
  IMMEDIATE8,	/* aad	 */
  BAD,		/* not an instruction: 0xd6 */
  NONE,		/* xlat	 */
  FP,		/* floating point instructions */
  FP,
  FP,
  FP,
  FP,
  FP,
  FP,
  FP,
  /* 0xEn */
  IMMEDIATE8,	/* loopne rel8 */
  IMMEDIATE8,	/* loope  rel8 */
  IMMEDIATE8,	/* loop   rel8 */
  IMMEDIATE8,	/* jcxj	rel8 */
  IMMEDIATE8,	/* in	al,i8 */
  IMMEDIATE8,	/* in	[e]ax,i8 */
  IMMEDIATE8,	/* out	i8,al */
  IMMEDIATE8,	/* out	i8, [e]ax */
  ADDRESS,	/* call */
  IMMEDIATE,	/* jmp */
  FAR_ADDRESS,	/* jmp */
  IMMEDIATE8,	/* jmp */
  NONE,		/* in	AL,DX */
  NONE,		/* in	 eAX,DX */
  NONE,		/* out	DX,AL */
  NONE,		/* out	DX	eAX */
  /* 0xFn */
  PREFIX,
  BAD,		/* not an instruction 0xf1 */
  PREFIX,
  PREFIX,
  NONE,		/* hlt	 */
  NONE,		/* cmc	 */
  GROUP3A,	
  GROUP3B,	
  NONE,		/* clc	 */
  NONE,		/* stc	 */
  NONE,		/* cli	 */
  NONE,		/* sti	 */
  NONE,		/* cld	 */
  NONE,		/* std	 */
  MAKE_GROUP(4,MODRM),	/* group4 rm8 */
  MAKE_GROUP(5,MODRM)	/* group5 rm */
};

/* following an 0x0f first byte, the second byte is looked up in this table */

static byte second_byte[] =
{
  /* 0x0n */
  MAKE_GROUP(6,MODRM),	/* group6 */
  MAKE_GROUP(7,MODRM),	/* group7 */
  MODRM,	/* lar r,rm */
  MODRM,	/* lsl r,rm */
  BAD,
  BAD,
  NONE,		/* clts */
  BAD,

  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  /* 0x1n */
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  /* 0x2n */
  IMMEDIATE8,	/* mov r,cr */
  IMMEDIATE8,	/* mov r,dr */
  IMMEDIATE8,	/* mov cr,r */
  IMMEDIATE8,	/* mov dr,r */
  IMMEDIATE8,	/* mov r,tr */
  BAD,
  IMMEDIATE8,	/* mov tr,r */
  BAD,

  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  /* 0x3n */
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  /* 0x4n */
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  /* 0x5n */
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  /* 0x6n */
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  /* 0x7n */
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  /* 0x8n */
  IMMEDIATE, IMMEDIATE, IMMEDIATE, IMMEDIATE, /* Jcc rel */
  IMMEDIATE, IMMEDIATE, IMMEDIATE, IMMEDIATE,
  IMMEDIATE, IMMEDIATE, IMMEDIATE, IMMEDIATE,
  IMMEDIATE, IMMEDIATE, IMMEDIATE, IMMEDIATE,
  /* 0x9n */
  MODRM, MODRM, MODRM, MODRM, MODRM, MODRM, MODRM, MODRM, /* Setcc rm8 */
  MODRM, MODRM, MODRM, MODRM, MODRM, MODRM, MODRM, MODRM,
  /* 0xAn */
  NONE,
  NONE,
  BAD,
  MODRM,	/* bt rm,r */
  MODRM_IMMEDIATE8,	/* shld rm,r,i8 */
  MODRM,	/* shld rm,r,cl */
  BAD,
  BAD,

  NONE,		/* push gs */
  NONE,		/* pop gs */
  BAD,
  MODRM,	/* bts rm,r */
  MODRM_IMMEDIATE8,	/* shrd rm,r,i8 */
  MODRM,		/* shrd rm,r,cl */
  BAD,
  MODRM,	/* imul r,rm */
  /* 0xBn */
  BAD,
  BAD,
  MODRM,	/* lss */
  MODRM_IMMEDIATE,	/* btr rm,r */
  MODRM,	/* lfs */
  MODRM,	/* lgs */
  MODRM,	/* movzx */
  MODRM,	/* movzx */

  BAD,
  BAD,
  MAKE_GROUP(8,MODRM_IMMEDIATE8),	/* group8 rm, i8 */
  MODRM_IMMEDIATE8,	/* btc	rm, i8 */
  MODRM,	/* bsf r,rm */
  MODRM,	/* bsr r,rm */
  MODRM,	/* movsx r,rm8 */
  MODRM,	/* movsx r,rm16 */
  /* 0xCn */
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  /* 0xDn */
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  /* 0xEn */
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  /* 0xFn */
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD,
  BAD, BAD, BAD, BAD, BAD, BAD, BAD, BAD
};

static byte group3a[] =
{
  MODRM_IMMEDIATE8,	/* test rm,i8 */
  BAD,
  MODRM,		/* not rm */
  MODRM,		/* neg rm */
  MODRM,		/* mul r,rm */
  MODRM,		/* imul r,rm */
  MODRM,		/* div r,rm */
  MODRM			/* idiv r,rm */
};

static byte group3b[] =
{
  MODRM_IMMEDIATE,	/* test rm,i */
  BAD,
  MODRM,		/* not rm */
  MODRM,		/* neg rm */
  MODRM,		/* mul r,rm */
  MODRM,		/* imul r,rm */
  MODRM,		/* div r,rm */
  MODRM			/* idiv r,rm */
};

/* (group_mask[group] & (1 << REG(modrm))) indicates a reserved instruction */

static byte group_masks[] = 
{
  0x00,	     /* group 1 not treated, so this value not used */
  0x40,
  0x02,	     /* group 3 treated separately, so this value not used */
  0xfc,
  0x80,
  0xc0,
  0xa0,
  0x0f
};

/* It is difficult to determine whether a floating-point byte sequence
   is reserved. 

   If mod=3, there are no additional bytes, and 
     if float_double_lookup[op-0xd8] then
       reserved = float_double_lookup[op-0xd8][reg] & (1 << rm)
     else
       reserved = float_single_lookup_2[op-0xd8] & (1 << reg)
   else modrm controls the additional bytes, and
       reserved = float_single_lookup_1[op-0xd8] & (1 << reg)
*/

static byte float_d9[] =
{  0x00,  0x00,  0xfe,  0xff,  0xcc,  0x80,  0x00,  0x00 };

static byte float_da[] =
{  0xff,  0xff,  0xff,  0xff,  0xff,  0xfd,  0xff,  0xff };

static byte float_db[] = 
{  0xff,  0xff,  0xff,  0xff,  0xe0,  0xff,  0xff,  0xff };

static byte float_de[] =
{  0x00,  0x00,  0xff,  0xfd,  0x00,  0x00,  0x00,  0x00 };

static byte float_df[] = 
{  0xff,  0xff,  0xff,  0xff,  0xfe,  0xff,  0xff,  0xff };

static byte* float_double_lookup[] =
{
  NULL,		/* single lookup */
  float_d9,
  float_da,
  float_db,
  NULL,		/* single lookup */
  NULL,		/* single lookup */
  float_de,
  float_df
};

/* when mod != 3 */

static byte float_single_lookup_1[] = 
{
  0x00,	/* d8 */
  0x02,	/* d9 */
  0x00,	/* da */
  0x52, /* db */
  0x00, /* dc */
  0x22, /* dd */
  0x00, /* de */
  0x02, /* df */
};

/* when mod == 3 */

static byte float_single_lookup_2[] = 
{
  0x00,	/* d8 */
  0xff,	/* d9 */
  0xff,	/* da */
  0xff, /* db */
  0x0c, /* dc */
  0xc2, /* dd */
  0xff, /* de */
  0xff, /* df */
};

#define SIZE16 0
#define SIZE32 2

#define SWITCH_SIZE(s)	(SIZE32-(s))
#define SIZE_BYTES(s)	(s+2)

#define MOD(modrm) ((modrm)>>6)
#define REG(modrm) (((modrm)>>3)&7)
#define RM(modrm)  ((modrm)&7)

static byte *read_modrm (byte *ptr, int *pgot_modrm, int *pmodrm, int more)
{
  int modrm;
  if (!*pgot_modrm) {
    *pmodrm = *ptr++;
    *pgot_modrm = 1;
  }
  modrm = *pmodrm;
  
  if (MOD(modrm) != 3) {
    if (MOD(modrm) == 0 && RM(modrm) == 5)
      ptr += 4;
    else {
      if (RM(modrm) == 4 && RM(*ptr++) == 5 && MOD(modrm) == 0)
	ptr += 4;
      if (MOD(modrm) == 1)
	ptr += 1;
      else if (MOD(modrm) == 2)
	ptr += 4;
    }
  }
  return ptr+more;
}

extern int read_instr (byte **pptr)
{
  byte *ptr = *pptr;
  byte op = *ptr++;
  byte type = opcode_type[op];
  int group = 0;
  int got_modrm = 0;
  int modrm = 0;

  int address_size = SIZE32;
  int operand_size = SIZE32;

  while (type & PFX) {
    switch (type) {
    case PREFIX:
      op = *ptr++;
      type = opcode_type[op];
      break;
    case AD_PREFIX:
      address_size = SWITCH_SIZE(address_size);
      op = *ptr++;
      type = opcode_type[op];
      break;
    case OP_PREFIX:
      operand_size = SWITCH_SIZE(operand_size);
      op = *ptr++;
      type = opcode_type[op];
      break;
    case NEXT_BYTE:
      op = *ptr++;
      type = second_byte[op];
      break;
    case GROUP3A:
      modrm = *ptr++;
      got_modrm = 1;
      type = group3a[REG(modrm)];
      break;
    case GROUP3B:
      modrm = *ptr++;
      got_modrm = 1;
      type = group3b[REG(modrm)];
      break;
    case FP:
      modrm = *ptr++;
      got_modrm = 1;
      if (MOD(modrm) != 3) {
	if (float_single_lookup_1[op-0xd8] & (1 << REG(modrm))) {
	  message("Float op 0x%02x has reserved second byte 0x%02x",
		  op,modrm);
	  *(int *)0 = 0;
	  return FAILURE;
	}
	type = MODRM;
      } else {
	byte* double_lookup = float_double_lookup[op - 0xd8];
	int reserved =
	  double_lookup ? 
	    double_lookup[REG(modrm)] & (1 << RM(modrm)) :
	      float_single_lookup_2[op - 0xd8] & (1 << REG(modrm));
	if (reserved) {
	  message("Float op 0x%02x has reserved second byte 0x%02x",
		  op,modrm);
	  *(int *)0 = 0;
	  return FAILURE;
	}
	type = NONE;
      }
      break;
    default:
      message("Bad type %d obtained for byte 0x%02x found at 0x%08x",
	      type,op,ptr-1);
      return FAILURE;
    }
  }
  switch (GET_TYPE(type)) {
  case NONE:
    break;
  case IMMEDIATE8:
    ptr++;
    break;
  case IMMEDIATE16:
    ptr+=2;
    break;
  case IMMEDIATE24:
    ptr+=3;
    break;
  case IMMEDIATE32:
    ptr+=4;
    break;
  case IMMEDIATE:
    ptr+= SIZE_BYTES(operand_size);
    break;
  case MODRM_IMMEDIATE:
    ptr = read_modrm (ptr,&got_modrm,&modrm,SIZE_BYTES(operand_size));
    break;
  case MODRM_IMMEDIATE8:
    ptr = read_modrm (ptr,&got_modrm,&modrm,1);
    break;
  case MODRM:
    ptr = read_modrm (ptr,&got_modrm,&modrm,0);
    break;
  case FAR_ADDRESS:
    ptr+= 2;
    /* fall through */
  case ADDRESS:
    ptr+= SIZE_BYTES(address_size);
    break;
  default:
    message("Bad type %d obtained for byte 0x%02x found at 0x%08x",
	    type,op,ptr-1);
    return FAILURE;
  }
  group = GET_GROUP(type);
  if (group) {
    if (!got_modrm) {
      message("Broken tables: byte 0x%02x has group but doesn't get modrm",
	     op);
      return FAILURE;
    }
    if (group_masks[group] & (1<<REG(modrm))) {
      message("reg field of modrm byte 0x%02x indicates "
	      "reserved instruction 0x%02x", modrm,op);
      return FAILURE;
    }
  }
  *pptr = ptr;
  return SUCCESS;
}

/* example of use: 

extern void list (byte *ptr, byte *end)
{
  while(ptr < end) {
    printf("0x%08x\n",ptr);
    if (!read_instr(&ptr)) {
      printf("bad!\n");
      ptr++;
    }
  }
}

*/

