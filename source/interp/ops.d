/*****************************************************************************
*
*                      Higgs JavaScript Virtual Machine
*
*  This file is part of the Higgs project. The project is distributed at:
*  https://github.com/maximecb/Higgs
*
*  Copyright (c) 2012, Maxime Chevalier-Boisvert. All rights reserved.
*
*  This software is licensed under the following license (Modified BSD
*  License):
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions are
*  met:
*   1. Redistributions of source code must retain the above copyright
*      notice, this list of conditions and the following disclaimer.
*   2. Redistributions in binary form must reproduce the above copyright
*      notice, this list of conditions and the following disclaimer in the
*      documentation and/or other materials provided with the distribution.
*   3. The name of the author may not be used to endorse or promote
*      products derived from this software without specific prior written
*      permission.
*
*  THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
*  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
*  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
*  NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
*  NOT LIMITED TO PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
*  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
*  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
*  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
*****************************************************************************/

module interp.ops;

import std.stdio;
import ir.ir;
import ir.ast;
import interp.interp;
import interp.layout;
import interp.string;

void opSetInt(Interp interp, IRInstr instr)
{
    interp.setSlot(
        instr.outSlot,
        Word.intv(instr.args[0].intVal),
        Type.INT
    );
}

void opSetStr(Interp interp, IRInstr instr)
{
    auto objPtr = instr.args[1].ptrVal;

    // If the string is null, allocate it
    if (objPtr is null)
    {
        auto strVal = getString(interp, instr.args[0].stringVal);
        objPtr = strVal.word.ptrVal;
    }

    interp.setSlot(
        instr.outSlot,
        Word.ptrv(objPtr),
        Type.STRING
    );
}

void opSetTrue(Interp interp, IRInstr instr)
{
    interp.setSlot(
        instr.outSlot,
        TRUE,
        Type.CONST
    );
}

void opSetFalse(Interp interp, IRInstr instr)
{
    interp.setSlot(
        instr.outSlot,
        FALSE,
        Type.CONST
    );
}

void opSetNull(Interp interp, IRInstr instr)
{
    interp.setSlot(
        instr.outSlot,
        NULL,
        Type.CONST
    );
}

void opSetUndef(Interp interp, IRInstr instr)
{
    interp.setSlot(
        instr.outSlot,
        UNDEF,
        Type.CONST
    );
}

void opMove(Interp interp, IRInstr instr)
{
    interp.move(
        instr.args[0].localIdx,
        instr.outSlot
    );
}

void opAdd(Interp interp, IRInstr instr)
{
    auto idx0 = instr.args[0].localIdx;
    auto idx1 = instr.args[1].localIdx;
    auto w0 = interp.getWord(idx0);
    auto w1 = interp.getWord(idx1);
    auto t0 = interp.getType(idx0);
    auto t1 = interp.getType(idx1);

    // If both values are integer
    if (t0 == Type.INT && t1 == Type.INT)
    {
        interp.setSlot(
            instr.outSlot, 
            Word.intv(w0.intVal + w1.intVal),
            Type.INT
        );
    }

    // If either value is a string
    else if (t0 == Type.STRING || t1 == Type.STRING)
    {
        // Evaluate the string value of both arguments
        auto s0 = interp.stringVal(w0, t0);
        auto s1 = interp.stringVal(w1, t1);

        auto l0 = str_get_len(s0.word.ptrVal);
        auto l1 = str_get_len(s1.word.ptrVal);

        auto sO = interp.alloc(str_comp_size(l0+l1));
        str_set_len(sO, l0+l1);

        for (size_t i = 0; i < l0; ++i)
            str_set_data(sO, i, str_get_data(s0.word.ptrVal, i));
        for (size_t i = 0; i < l1; ++i)
            str_set_data(sO, l0+i, str_get_data(s1.word.ptrVal, i));

        interp.setSlot(
            instr.outSlot, 
            Word.ptrv(sO),
            Type.STRING
        );
    }

    else
    {
        assert (false, "unsupported types in add");
    }
}

void opSub(Interp interp, IRInstr instr)
{
    // TODO: support for other types
    auto idx0 = instr.args[0].localIdx;
    auto idx1 = instr.args[1].localIdx;

    auto w0 = interp.getWord(idx0);
    auto w1 = interp.getWord(idx1);

    interp.setSlot(
        instr.outSlot, 
        Word.intv(w0.intVal - w1.intVal),
        Type.INT
    );
}

void opMul(Interp interp, IRInstr instr)
{
    // TODO: support for other types
    auto idx0 = instr.args[0].localIdx;
    auto idx1 = instr.args[1].localIdx;

    auto w0 = interp.getWord(idx0);
    auto w1 = interp.getWord(idx1);

    interp.setSlot(
        instr.outSlot, 
        Word.intv(w0.intVal * w1.intVal),
        Type.INT
    );
}

void opDiv(Interp interp, IRInstr instr)
{
    // TODO: support for other types
    auto idx0 = instr.args[0].localIdx;
    auto idx1 = instr.args[1].localIdx;

    auto w0 = interp.getWord(idx0);
    auto w1 = interp.getWord(idx1);

    // TODO: produce NaN or Inf on 0
    if (w1.intVal == 0)
        throw new Error("division by 0");

    interp.setSlot(
        instr.outSlot, 
        Word.intv(w0.intVal / w1.intVal),
        Type.INT
    );
}

void opMod(Interp interp, IRInstr instr)
{
    // TODO: support for other types
    auto idx0 = instr.args[0].localIdx;
    auto idx1 = instr.args[1].localIdx;

    auto w0 = interp.getWord(idx0);
    auto w1 = interp.getWord(idx1);

    // TODO: produce NaN or Inf on 0
    if (w1.intVal == 0)
        throw new Error("modulo with 0 divisor");

    interp.setSlot(
        instr.outSlot, 
        Word.intv(w0.intVal % w1.intVal),
        Type.INT
    );
}

void opBoolVal(Interp interp, IRInstr instr)
{
    auto idx = instr.args[0].localIdx;

    auto w = interp.getWord(idx);
    auto t = interp.getType(idx);

    bool output;
    switch (t)
    {
        case Type.CONST:
        output = (w == TRUE);
        break;

        case Type.INT:
        output = (w.intVal != 0);
        break;

        case Type.STRING:
        output = (str_get_len(w.ptrVal) != 0);
        break;

        default:
        assert (false, "unsupported type in comparison");
    }

    interp.setSlot(
        instr.outSlot, 
        output? TRUE:FALSE,
        Type.CONST
    );
}

void opCmpSe(Interp interp, IRInstr instr)
{
    // TODO: support for other types
    auto idx0 = instr.args[0].localIdx;
    auto idx1 = instr.args[1].localIdx;

    auto w0 = interp.getWord(idx0);
    auto w1 = interp.getWord(idx1);

    bool output = (w0.intVal == w1.intVal);

    writefln("output: %s", output);

    interp.setSlot(
        instr.outSlot, 
        output? TRUE:FALSE,
        Type.CONST
    );
}

void opCmpLt(Interp interp, IRInstr instr)
{
    // TODO: support for other types
    auto idx0 = instr.args[0].localIdx;
    auto idx1 = instr.args[1].localIdx;

    auto w0 = interp.getWord(idx0);
    auto w1 = interp.getWord(idx1);

    bool output = (w0.intVal < w1.intVal);

    interp.setSlot(
        instr.outSlot, 
        output? TRUE:FALSE,
        Type.CONST
    );
}

void opJump(Interp interp, IRInstr instr)
{
    auto block = instr.args[0].block;
    interp.ip = block.firstInstr;
}

void opJumpTrue(Interp interp, IRInstr instr)
{
    auto valIdx = instr.args[0].localIdx;
    auto block = instr.args[1].block;
    auto wVal = interp.getWord(valIdx);

    if (wVal == TRUE)
        interp.ip = block.firstInstr;
}

void opJumpFalse(Interp interp, IRInstr instr)
{
    auto valIdx = instr.args[0].localIdx;
    auto block = instr.args[1].block;
    auto wVal = interp.getWord(valIdx);

    if (wVal == FALSE)
        interp.ip = block.firstInstr;
}

void opSetArg(Interp interp, IRInstr instr)
{
    auto srcIdx = instr.args[0].localIdx;
    auto dstIdx = -(instr.args[1].intVal + 1);

    auto wArg = interp.getWord(srcIdx);
    auto tArg = interp.getType(srcIdx);

    interp.wsp[dstIdx] = wArg;
    interp.tsp[dstIdx] = tArg;
}

void opCall(Interp interp, IRInstr instr)
{
    auto closIdx = instr.args[0].localIdx;
    auto thisIdx = instr.args[1].localIdx;
    auto numArgs = instr.args[2].intVal;

    // TODO: proper closure object
    // Get the function object
    auto ptr = interp.getWord(closIdx).ptrVal;
    auto fun = cast(IRFunction)ptr;

    assert (
        fun !is null, 
        "null IRFunction pointer"
    );

    // If the function is not yet compiled, compile it now
    if (fun.entryBlock is null)
    {
        astToIR(fun.ast, fun);
    }

    // Get the return address
    auto retAddr = cast(rawptr)instr.next;

    assert (
        retAddr !is null, 
        "next instruction is null"
    );

    // Push stack space for the arguments
    interp.push(numArgs);

    // Push the hidden call arguments
    interp.push(UNDEF, Type.CONST);                     // FIXME:Closure argument
    interp.push(UNDEF, Type.CONST);                     // FIXME:This argument
    interp.push(Word.intv(numArgs), Type.INT);          // Argument count
    interp.push(Word.ptrv(retAddr), Type.RAWPTR);       // Return address

    // Set the instruction pointer
    interp.ip = fun.entryBlock.firstInstr;
}

/// Allocate/adjust the stack frame on function entry
void opPushFrame(Interp interp, IRInstr instr)
{
    auto numParams = instr.args[0].intVal;
    auto numLocals = instr.args[1].intVal;

    // Get the number of arguments passed
    auto numArgs = interp.getWord(1).intVal;

    // If there are not enough arguments
    if (numArgs < numParams)
    {
        auto deltaArgs = numParams - numArgs;

        // Allocate new stack slots for the missing arguments
        interp.push(deltaArgs);

        // Move the hidden arguments to the top of the stack
        for (size_t i = 0; i < NUM_HIDDEN_ARGS; ++i)
            interp.move(deltaArgs + i, i);

        // Initialize the missing arguments to undefined
        for (size_t i = 0; i < deltaArgs; ++i)
            interp.setSlot(NUM_HIDDEN_ARGS + i, UNDEF, Type.CONST);
    }

    // If there are too many arguments
    else if (numArgs > numParams)
    {
        auto deltaArgs = numArgs - numParams;

        // Move the hidden arguments down
        for (size_t i = 0; i < NUM_HIDDEN_ARGS; ++i)
            interp.move(i, deltaArgs + i);

        // Remove superfluous argument slots
        interp.pop(deltaArgs);
    }

    // Allocate slots for the local variables
    auto delta = numLocals - (numParams + NUM_HIDDEN_ARGS);
    //writefln("push_frame adding %s slot", delta);
    interp.push(delta);
}

void opRet(Interp interp, IRInstr instr)
{
    auto retSlot   = instr.args[0].localIdx;
    auto raSlot    = instr.args[1].localIdx;
    auto numLocals = instr.args[2].intVal;

    // Get the return value
    auto retW = interp.wsp[retSlot];
    auto retT = interp.tsp[retSlot];

    // Get the return address
    auto retAddr = interp.getWord(raSlot).ptrVal;

    //writefln("popping num locals: %s", numLocals);

    // Pop all local stack slots
    interp.pop(numLocals);

    // Leave the return value on top of the stack
    interp.push(retW, retT);

    // Set the instruction pointer
    interp.ip = retAddr? (cast(IRInstr)retAddr):null;
}

/// Get the callee's return value after a call
void opGetRet(Interp interp, IRInstr instr)
{
    // Read and pop the value
    auto wRet = interp.getWord(0);
    auto tRet = interp.getType(0);
    interp.pop(1);

    interp.setSlot(
        instr.outSlot, 
        wRet,
        tRet
    );
}

void opNewClos(Interp interp, IRInstr instr)
{
    auto fun = instr.args[0].fun;

    // TODO: create a proper closure
    interp.setSlot(
        instr.outSlot,
        Word.ptrv(cast(rawptr)fun),
        Type.RAWPTR
    );
}

/// Set a global variable
void opSetGlobal(Interp interp, IRInstr instr)
{
    auto strSlot = instr.args[0].localIdx;
    auto valSlot = instr.args[1].localIdx;

    auto wStr = interp.getWord(strSlot);
    auto tStr = interp.getType(strSlot);

    auto wVal = interp.getWord(valSlot);
    auto tVal = interp.getType(valSlot);

    assert (tStr == Type.STRING, "string type should be string");
    auto propStr = wStr.ptrVal;

    // Get the number of global properties
    auto numProps = class_get_num_props(interp.globalClass);

    // Look for the property in the global class
    size_t propIdx;
    for (propIdx = 0; propIdx < numProps; ++propIdx)
    {
        auto nameStr = class_get_prop_name(interp.globalClass, propIdx);
        if (propStr == nameStr)
            break;
    }

    // If this is a new property
    if (propIdx == numProps)
    {
        //writefln("new property");

        // TODO: implement class expansion
        auto capGlobal = class_get_len(interp.globalClass);
        assert (propIdx < capGlobal, "global capacity exceeded");

        // Set the property name
        class_set_prop_name(interp.globalClass, propIdx, propStr);

        // Increment the number of properties in this class
        class_set_num_props(interp.globalClass, numProps + 1);
    }

    //writefln("num props after write: %s", class_get_num_props(interp.globalClass));
    //writefln("prop idx: %s", propIdx);
    //writefln("intval: %s", wVal.intVal);

    // Set the value and its type in the object
    obj_set_word(interp.globalObj, propIdx, wVal.intVal);
    obj_set_type(interp.globalObj, propIdx, tVal);
}

/// Get the value of a global variable
void opGetGlobal(Interp interp, IRInstr instr)
{
    auto strSlot = instr.args[0].localIdx;
    auto wStr = interp.getWord(strSlot);
    auto tStr = interp.getType(strSlot);

    assert (tStr == Type.STRING, "string type should be string");
    auto propStr = wStr.ptrVal;

    // Get the number of global properties
    auto numProps = class_get_num_props(interp.globalClass);

    // Look for the property in the global class
    size_t propIdx;
    for (propIdx = 0; propIdx < numProps; ++propIdx)
    {
        auto nameStr = class_get_prop_name(interp.globalClass, propIdx);
        if (propStr == nameStr)
            break;
    }

    // If the property was not found, produce undefined
    if (propIdx == numProps)
    {
        interp.setSlot(
            instr.outSlot,
            UNDEF,
            Type.CONST
        );

        return;
    }

    //writefln("num props after write: %s", class_get_num_props(interp.globalClass));
    //writefln("prop idx: %s", propIdx);

    auto pWord = obj_get_word(interp.globalObj, propIdx);
    auto pType = obj_get_type(interp.globalObj, propIdx);

    //writefln("pWord: %s", pWord);

    interp.setSlot(
        instr.outSlot,
        Word.intv(pWord),
        cast(Type)pType
    );
}
