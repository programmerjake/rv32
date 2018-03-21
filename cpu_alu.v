/*
 * Copyright 2018 Jacob Lifshay
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */
`timescale 1ns / 1ps
`include "riscv.vh"

module cpu_alu(
    input [6:0] funct7,
    input [2:0] funct3,
    input [6:0] opcode,
    input [31:0] a,
    input [31:0] b,
    output [31:0] result
    );
    
    wire is_sub = funct7[5] & opcode[5];
    wire [31:0] add_sub_result = a + (is_sub ? ~b : b) + is_sub;
    wire [31:0] shift_left_result = a << b[4:0];
    wire [31:0] shift_right_result = funct7[5] ? $unsigned($signed(a) >>> b[4:0]) : a >> b[4:0];
    wire [31:0] xor_result = a ^ b;
    wire [31:0] or_result = a | b;
    wire [31:0] and_result = a & b;
    wire [31:0] lt_arg_flip = {~funct3[0], 31'b0};
    wire [31:0] lt_result = ((a ^ lt_arg_flip) < (b ^ lt_arg_flip)) ? 32'b1 : 32'b0;
    
    function [31:0] mux8(
        input [2:0] select,
        input [31:0] v0,
        input [31:0] v1,
        input [31:0] v2,
        input [31:0] v3,
        input [31:0] v4,
        input [31:0] v5,
        input [31:0] v6,
        input [31:0] v7);
        begin
            case(select)
            0: mux8 = v0;
            1: mux8 = v1;
            2: mux8 = v2;
            3: mux8 = v3;
            4: mux8 = v4;
            5: mux8 = v5;
            6: mux8 = v6;
            7: mux8 = v7;
            default: mux8 = 32'hXXXXXXXX;
            endcase
        end
    endfunction
    
    assign result = mux8(funct3,
                         add_sub_result,
                         shift_left_result,
                         lt_result,
                         lt_result,
                         xor_result,
                         shift_right_result,
                         or_result,
                         and_result);
    
endmodule
