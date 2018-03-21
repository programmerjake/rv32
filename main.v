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
`timescale 1ns / 100ps

module main(
    input clk,
    output [7:0] vga_r,
	output [7:0] vga_g,
	output [7:0] vga_b,
	output vga_hsync,
	output vga_vsync,
    output vga_blank,
    output vga_pixel_clock,
    input switch_2,
    input switch_3,
    output led_1,
    output led_3
    );
    
    wire tty_write;
    wire [7:0] tty_write_data;
    wire tty_write_busy;
    reg reset = 1;
    
	vga vga1(
        .clk(clk),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_blank(vga_blank),
        .vga_pixel_clock(vga_pixel_clock),
        .tty_write(tty_write),
        .tty_data(tty_write_data),
        .tty_busy(tty_write_busy)
        );
    
    cpu cpu1(
        .clk(clk),
        .reset(reset),
        .tty_write(tty_write),
        .tty_write_data(tty_write_data),
        .tty_write_busy(tty_write_busy),
        .switch_2(switch_2),
        .switch_3(switch_3),
        .led_1(led_1),
        .led_3(led_3)
        );
    
    reg [31:0] reset_counter = 256;
    
    always @(posedge clk)
        if(reset_counter == 0)
            reset <= 0;
        else
            reset_counter <= reset_counter - 1;

endmodule
