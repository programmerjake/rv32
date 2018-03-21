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
module cpu_memory_interface(
    input clk,
    input reset,
    input [31:2] fetch_address,
    output [31:0] fetch_data,
    output fetch_valid,
    input [31:2] rw_address,
    input [3:0] rw_byte_mask,
    input rw_read_not_write,
    input rw_active,
    input [31:0] rw_data_in,
    output [31:0] rw_data_out,
    output rw_address_valid,
    output rw_wait,
    output reg tty_write,
    output reg [7:0] tty_write_data,
    input tty_write_busy,
    input switch_2,
    input switch_3,
    output led_1,
    output led_3
    );

    parameter ram_size = 32'hXXXXXXXX;
    parameter ram_start = 32'hXXXXXXXX;
    parameter tty_location = 32'h8000_0000;
    parameter gpio_location = 32'h8000_0010;
    
    wire ram_a_write_enable = ~reset & ~ignore_after_delay & rw_active & rw_address_in_mem_space & ~rw_read_not_write;
    
    wire [31:0] ram_a_ram_address = rw_address_in_mem_space ? rw_address - ram_start / 4 : 0;
    wire [3:0] ram_a_write_enable_bytes = {4{ram_a_write_enable}} & rw_byte_mask;
    wire [31:0] ram_a_write_input = rw_data_in;
    wire [31:0] ram_a_read_output;
    wire [31:0] ram_b_ram_address = fetch_address_valid ? fetch_address - ram_start / 4 : 0;
    wire [31:0] ram_b_read_output;
    
    block_memory ram(
        .clk(clk),
        .a_ram_address(ram_a_ram_address),
        .a_write_enable(ram_a_write_enable_bytes),
        .a_write_input(ram_a_write_input),
        .a_read_output(ram_a_read_output),
        .b_ram_address(ram_b_ram_address),
        .b_read_output(ram_b_read_output)
        );
    
    wire fetch_address_valid = (fetch_address >= ram_start / 4) & (fetch_address < (ram_start + ram_size) / 4);
    wire rw_address_is_tty = (rw_address == tty_location / 4) & (rw_read_not_write | rw_byte_mask == 4'h1);
    wire rw_address_is_gpio = rw_address == gpio_location / 4;
    wire rw_address_in_io_space = rw_address_is_tty | rw_address_is_gpio;
    wire rw_address_in_mem_space = (rw_address >= ram_start / 4) & (rw_address < (ram_start + ram_size) / 4);
    assign rw_address_valid = rw_address_in_mem_space | rw_address_in_io_space;
    
    reg delay_done = 0;
    
    assign fetch_data = ram_b_read_output;

    assign fetch_valid = ~reset & fetch_address_valid;
    
    assign rw_wait = (rw_address_in_mem_space
                     ? (rw_read_not_write 
                        ? ~delay_done
                        : 1'b0)
                     : ~delay_done) | reset;
                     
    reg ignore_after_delay = 0;
    
    reg [31:0] io_read_output_register;
    reg last_read_was_ram;
    
    assign rw_data_out = last_read_was_ram ? ram_a_read_output : io_read_output_register;
    
    reg [7:0] gpio_input_sync_first = 0;
    reg [7:0] gpio_input = 0;
    always @(posedge clk) gpio_input_sync_first <= {5'b0, ~switch_3, ~switch_2, 1'b0};
    always @(posedge clk) gpio_input <= gpio_input_sync_first;
    reg [7:0] gpio_output = 0;
    assign led_1 = ~gpio_output[0];
    assign led_3 = ~gpio_output[2];
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            delay_done <= 0;
            tty_write <= 0;
            ignore_after_delay <= 0;
            io_read_output_register <= 'hXXXXXXXX;
            last_read_was_ram <= 1'hX;
            gpio_output <= 0;
        end
        else begin
            delay_done <= 0;
            tty_write <= 0;
            if(ignore_after_delay) begin
                ignore_after_delay <= 0;
            end
            else if(rw_active & rw_address_in_mem_space) begin
                if(rw_read_not_write) begin
                    delay_done <= 1;
                    ignore_after_delay <= 1;
                    last_read_was_ram <= 1;
                end
                else begin
                    last_read_was_ram <= 1;
                end
            end
            else if(rw_active & rw_address_in_io_space) begin
                if(rw_address_is_tty) begin
                    if(rw_read_not_write) begin
                        last_read_was_ram <= 0;
                        io_read_output_register <= 0;
                        delay_done <= 1;
                        ignore_after_delay <= 1;
                    end
                    else begin
                        if(tty_write_busy) begin
                            delay_done <= 0;
                        end
                        else begin
                            tty_write <= 1;
                            tty_write_data <= rw_data_in[7:0];
                            delay_done <= 1;
                            ignore_after_delay <= 1;
                        end
                        last_read_was_ram <= 0;
                        io_read_output_register <= 'hXXXXXXXX;
                    end
                end
                else if(rw_address_is_gpio) begin
                    if(rw_read_not_write) begin
                        last_read_was_ram <= 0;
                        io_read_output_register <= {16'b0, gpio_input, gpio_output};
                        delay_done <= 1;
                        ignore_after_delay <= 1;
                    end
                    else begin
                        if(rw_byte_mask[0])
                            gpio_output <= rw_data_in[7:0];
                        delay_done <= 1;
                        ignore_after_delay <= 1;
                        last_read_was_ram <= 0;
                        io_read_output_register <= 'hXXXXXXXX;
                    end
                end
                else begin
                    //TODO finish implementing I/O
                    last_read_was_ram <= 0;
                    io_read_output_register <= 'hXXXXXXXX;
                end
            end
            else begin
                last_read_was_ram <= 0;
                io_read_output_register <= 'hXXXXXXXX;
            end
        end
    end

endmodule
