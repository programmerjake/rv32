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

module block_memory(
    input clk,
    input [31:0] a_ram_address,
    input [3:0] a_write_enable,
    input [31:0] a_write_input,
    output reg [31:0] a_read_output,
    input [31:0] b_ram_address,
    output reg [31:0] b_read_output
    );

    wire a_enable_0 = a_ram_address[31:11] == 0;
    wire b_enable_0 = b_ram_address[31:11] == 0;
    wire [3:0] a_write_enable_0 = {4{a_enable_0}} & a_write_enable;
    wire [31:0] a_read_output_0;
    wire [31:0] b_read_output_0;
    block_memory_16kbit #(
        .initial_file("software/ram_0_byte0.hex")
        ) ram_0_byte0(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_0[0]),
        .port_a_write_input(a_write_input[7:0]),
        .port_a_read_output(a_read_output_0[7:0]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_0[7:0])
        );

    block_memory_16kbit #(
        .initial_file("software/ram_0_byte1.hex")
        ) ram_0_byte1(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_0[1]),
        .port_a_write_input(a_write_input[15:8]),
        .port_a_read_output(a_read_output_0[15:8]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_0[15:8])
        );

    block_memory_16kbit #(
        .initial_file("software/ram_0_byte2.hex")
        ) ram_0_byte2(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_0[2]),
        .port_a_write_input(a_write_input[23:16]),
        .port_a_read_output(a_read_output_0[23:16]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_0[23:16])
        );

    block_memory_16kbit #(
        .initial_file("software/ram_0_byte3.hex")
        ) ram_0_byte3(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_0[3]),
        .port_a_write_input(a_write_input[31:24]),
        .port_a_read_output(a_read_output_0[31:24]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_0[31:24])
        );


    wire a_enable_1 = a_ram_address[31:11] == 1;
    wire b_enable_1 = b_ram_address[31:11] == 1;
    wire [3:0] a_write_enable_1 = {4{a_enable_1}} & a_write_enable;
    wire [31:0] a_read_output_1;
    wire [31:0] b_read_output_1;
    block_memory_16kbit #(
        .initial_file("software/ram_1_byte0.hex")
        ) ram_1_byte0(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_1[0]),
        .port_a_write_input(a_write_input[7:0]),
        .port_a_read_output(a_read_output_1[7:0]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_1[7:0])
        );

    block_memory_16kbit #(
        .initial_file("software/ram_1_byte1.hex")
        ) ram_1_byte1(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_1[1]),
        .port_a_write_input(a_write_input[15:8]),
        .port_a_read_output(a_read_output_1[15:8]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_1[15:8])
        );

    block_memory_16kbit #(
        .initial_file("software/ram_1_byte2.hex")
        ) ram_1_byte2(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_1[2]),
        .port_a_write_input(a_write_input[23:16]),
        .port_a_read_output(a_read_output_1[23:16]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_1[23:16])
        );

    block_memory_16kbit #(
        .initial_file("software/ram_1_byte3.hex")
        ) ram_1_byte3(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_1[3]),
        .port_a_write_input(a_write_input[31:24]),
        .port_a_read_output(a_read_output_1[31:24]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_1[31:24])
        );


    wire a_enable_2 = a_ram_address[31:11] == 2;
    wire b_enable_2 = b_ram_address[31:11] == 2;
    wire [3:0] a_write_enable_2 = {4{a_enable_2}} & a_write_enable;
    wire [31:0] a_read_output_2;
    wire [31:0] b_read_output_2;
    block_memory_16kbit #(
        .initial_file("software/ram_2_byte0.hex")
        ) ram_2_byte0(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_2[0]),
        .port_a_write_input(a_write_input[7:0]),
        .port_a_read_output(a_read_output_2[7:0]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_2[7:0])
        );

    block_memory_16kbit #(
        .initial_file("software/ram_2_byte1.hex")
        ) ram_2_byte1(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_2[1]),
        .port_a_write_input(a_write_input[15:8]),
        .port_a_read_output(a_read_output_2[15:8]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_2[15:8])
        );

    block_memory_16kbit #(
        .initial_file("software/ram_2_byte2.hex")
        ) ram_2_byte2(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_2[2]),
        .port_a_write_input(a_write_input[23:16]),
        .port_a_read_output(a_read_output_2[23:16]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_2[23:16])
        );

    block_memory_16kbit #(
        .initial_file("software/ram_2_byte3.hex")
        ) ram_2_byte3(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_2[3]),
        .port_a_write_input(a_write_input[31:24]),
        .port_a_read_output(a_read_output_2[31:24]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_2[31:24])
        );


    wire a_enable_3 = a_ram_address[31:11] == 3;
    wire b_enable_3 = b_ram_address[31:11] == 3;
    wire [3:0] a_write_enable_3 = {4{a_enable_3}} & a_write_enable;
    wire [31:0] a_read_output_3;
    wire [31:0] b_read_output_3;
    block_memory_16kbit #(
        .initial_file("software/ram_3_byte0.hex")
        ) ram_3_byte0(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_3[0]),
        .port_a_write_input(a_write_input[7:0]),
        .port_a_read_output(a_read_output_3[7:0]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_3[7:0])
        );

    block_memory_16kbit #(
        .initial_file("software/ram_3_byte1.hex")
        ) ram_3_byte1(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_3[1]),
        .port_a_write_input(a_write_input[15:8]),
        .port_a_read_output(a_read_output_3[15:8]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_3[15:8])
        );

    block_memory_16kbit #(
        .initial_file("software/ram_3_byte2.hex")
        ) ram_3_byte2(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_3[2]),
        .port_a_write_input(a_write_input[23:16]),
        .port_a_read_output(a_read_output_3[23:16]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_3[23:16])
        );

    block_memory_16kbit #(
        .initial_file("software/ram_3_byte3.hex")
        ) ram_3_byte3(
        .clk(clk),
        .port_a_address(a_ram_address[10:0]),
        .port_a_write_enable(a_write_enable_3[3]),
        .port_a_write_input(a_write_input[31:24]),
        .port_a_read_output(a_read_output_3[31:24]),
        .port_b_address(b_ram_address[10:0]),
        .port_b_read_output(b_read_output_3[31:24])
        );


    always @* begin
        case(a_ram_address[31:11])
        0: a_read_output = a_read_output_0;
        1: a_read_output = a_read_output_1;
        2: a_read_output = a_read_output_2;
        3: a_read_output = a_read_output_3;
        default: a_read_output = 32'hXXXXXXXX;
        endcase
    end

    always @* begin
        case(b_ram_address[31:11])
        0: b_read_output = b_read_output_0;
        1: b_read_output = b_read_output_1;
        2: b_read_output = b_read_output_2;
        3: b_read_output = b_read_output_3;
        default: b_read_output = 32'hXXXXXXXX;
        endcase
    end
endmodule
