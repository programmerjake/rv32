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
module block_memory_16kbit(
    input clk,
    input [10:0] port_a_address,
    input port_a_write_enable,
    input [7:0] port_a_write_input,
    output [7:0] port_a_read_output,
    input [10:0] port_b_address,
    output [7:0] port_b_read_output
    );
    
    parameter initial_file = "";

    (* ram_style = "block" *)
    reg [7:0] ram[{11{1'b1}} : 0];
    
    initial $readmemh(initial_file, ram);

    reg [7:0] port_a_read_output_reg;
    reg [7:0] port_b_read_output_reg;
            
    always @(posedge clk) begin
        port_b_read_output_reg <= ram[port_b_address];
        if(port_a_write_enable) begin
            ram[port_a_address] <= port_a_write_input;
        end
        else begin
            port_a_read_output_reg <= ram[port_a_address];
        end
    end
    
    assign port_a_read_output = port_a_read_output_reg;
    assign port_b_read_output = port_b_read_output_reg;

endmodule
