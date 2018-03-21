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
`ifndef cpu_vh_
`define cpu_vh_

`define fetch_action [2:0]

`define fetch_action_default 3'h0
`define fetch_action_fence 3'h1
`define fetch_action_jump 3'h2
`define fetch_action_wait 3'h3
`define fetch_action_error_trap 3'h4
`define fetch_action_noerror_trap 3'h5
`define fetch_action_ack_trap 3'h6

`define fetch_output_state [1:0]

`define fetch_output_state_empty 2'h0
`define fetch_output_state_valid 2'h1
`define fetch_output_state_trap 2'h2

`define decode_action [11:0]

`define decode_action_trap_illegal_instruction 'h1
`define decode_action_load 'h2
`define decode_action_fence 'h4
`define decode_action_fence_i 'h8
`define decode_action_op_op_imm 'h10
`define decode_action_lui_auipc 'h20
`define decode_action_store 'h40
`define decode_action_branch 'h80
`define decode_action_jalr 'h100
`define decode_action_jal 'h200
`define decode_action_trap_ecall_ebreak 'h400
`define decode_action_csr 'h800

`endif

