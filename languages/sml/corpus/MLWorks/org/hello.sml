(* Hello example ML FI interface code.
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
 *)

require "$.foreign.__interface";

(* ML FI structure mapping *)

local
   structure Store  = Interface.Store
   structure Structure  = Interface.C.Structure
   structure Signature  = Interface.C.Signature
   structure Function  = Interface.C.Function
   structure Type  = Interface.C.Type
   structure Value  = Interface.C.Value
in
   val ALIGNED_4     = Store.ALIGNED_4
   val BREAK         = Store.BREAK
   val RDWR_STATUS   = Store.RDWR_STATUS
   val store         = Store.store

   val loadObjectFile = Structure.loadObjectFile
   val IMMEDIATE_LOAD   = Structure.IMMEDIATE_LOAD

   val newSignature = Signature.newSignature
   val defEntry     = Signature.defEntry
   val FUN_DECL      = Signature.FUN_DECL

   val defineForeignFun = Function.defineForeignFun
   val call               = Function.call

   type c_type = Type.c_type

   val VOID_TYPE     = Type.VOID_TYPE
   val STRING_TYPE   = Type.STRING_TYPE
   val INT_TYPE      = Type.INT_TYPE
   val CHAR_TYPE     = Type.CHAR_TYPE
   val ptrType       = Type.ptrType

   val object           = Value.object
   val setString       = Value.setString
   val getString       = Value.getString
   val setInt          = Value.setInt
   val getInt          = Value.getInt
   val setPtrType     = Value.setPtrType
   val setPtrAddrOf  = Value.setPtrAddrOf
   val castPtrType    = Value.castPtrType
end


(* Loading a Structure *)
   val hello_struct = loadObjectFile("foreign\\samples\\hello.dll",IMMEDIATE_LOAD);
   (* the filename is relative to the current directory that MLWorks is using *)



(* Building a store *)

    val hello_store =
          store{ alloc    = ALIGNED_4,
                 overflow = BREAK,
                 size     = 60,
                 status   = RDWR_STATUS   };


(* Creating objects *)

   val void_object =
         object { ctype  = VOID_TYPE,
                  store  = hello_store };

   val str_object =
         object { ctype  = STRING_TYPE{ length = 30 },
                  store  = hello_store };

   val int_object1 =
         object { ctype  = INT_TYPE,
                  store  = hello_store };

   val int_object2 =
         object { ctype  = INT_TYPE,
                  store  = hello_store };

   val ptr_object =
         object { ctype  = ptrType(VOID_TYPE),
                  store  = hello_store };



(* Initialising object values - these will be our arguments *)

   setString(str_object, "What is 65 - 42? ---- Ans is ");
   setInt(int_object1, 23);

(* Examining object values *)

   getString(str_object);
   getInt(int_object1);


(* Defining a c_signature object *)

   val hello_sig = newSignature();


(* Adding a new Signature entry *)

   defEntry(hello_sig,
             FUN_DECL { name = "hello",
                        source = [ptrType(CHAR_TYPE), INT_TYPE] : c_type list,
                        target = INT_TYPE }
	     );


(* Make a `callable object' lookup function for our foreign code *)

   val def_hello = defineForeignFun( hello_struct, hello_sig );


(* Extract a foreign function object as an ML value *) 

   val hello = def_hello "hello";;


(* Setting up string pointers ... *)

     setPtrType    { ptr = ptr_object, data = str_object };
     setPtrAddrOf { ptr = ptr_object, data = str_object };
     castPtrType   { ptr = ptr_object, ctype = CHAR_TYPE };


(* Call the foreign function *)

   call hello ( [ptr_object,int_object1], int_object2 );


(* Extracting the result data *)

   getInt(int_object2);
