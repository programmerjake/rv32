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
`include "cpu.vh"

module cpu_fetch_stage(
    input clk,
    input reset,
    output [31:2] memory_interface_fetch_address,
    input [31:0] memory_interface_fetch_data,
    input memory_interface_fetch_valid,
    input `fetch_action fetch_action,
    input [31:0] target_pc,
    output reg [31:0] output_pc,
    output [31:0] output_instruction,
    output reg `fetch_output_state output_state
    );
    
    parameter reset_vector = 32'hXXXXXXXX;
    parameter mtvec = 32'hXXXXXXXX;

    reg [31:0] fetch_pc = reset_vector;
    
    always @(posedge clk or posedge reset) output_pc <= reset ? reset_vector : ((fetch_action == `fetch_action_wait) ? output_pc : fetch_pc);
    
    assign memory_interface_fetch_address = fetch_pc[31:2];

    initial output_pc <= reset_vector;
    initial output_state <= `fetch_output_state_empty;
    
    reg [31:0] delayed_instruction = 0;
    reg delayed_instruction_valid = 0;
    
    always @(posedge clk or posedge reset) delayed_instruction <= reset ? 0 : output_instruction;
    
    assign output_instruction = delayed_instruction_valid ? delayed_instruction : memory_interface_fetch_data;
    
    always @(posedge clk or posedge reset) begin
        if(reset)
            delayed_instruction_valid <= 0;
        else
            delayed_instruction_valid <= fetch_action == `fetch_action_wait;
    end
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            fetch_pc <= reset_vector;
            output_state <= `fetch_output_state_empty;
        end
        else begin
            case(fetch_action)
            `fetch_action_default,
            `fetch_action_ack_trap: begin
                if(memory_interface_fetch_valid) begin
                    fetch_pc <= fetch_pc + 4;
                    output_state <= `fetch_output_state_valid;
                end
                else begin
                    fetch_pc <= mtvec;
                    output_state <= `fetch_output_state_trap;
                end
            end
            `fetch_action_fence: begin
                fetch_pc <= output_pc + 4;
                output_state <= `fetch_output_state_empty;
            end
            `fetch_action_jump: begin
                fetch_pc <= target_pc;
                output_state <= `fetch_output_state_empty;
            end
            `fetch_action_error_trap,
            `fetch_action_noerror_trap: begin
                fetch_pc <= mtvec;
                output_state <= `fetch_output_state_empty;
            end
            `fetch_action_wait: begin
                fetch_pc <= fetch_pc;
                output_state <= `fetch_output_state_valid;
            end
            endcase
        end
    end
endmodule
