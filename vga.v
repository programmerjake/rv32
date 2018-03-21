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

module vga(
    input clk,
	output [7:0] vga_r,
	output [7:0] vga_g,
	output [7:0] vga_b,
	output vga_hsync,
	output vga_vsync,
    output vga_blank,
    output vga_pixel_clock,
    input tty_write,
    input [7:0] tty_data,
    output tty_busy
    );
	
    wire pixel_clock;
    
    vga_clock_generator clock_generator(clk, pixel_clock);
    
    wire location_generator_hsync;
    wire location_generator_vsync;
    wire location_generator_blank;
    wire [15:0] location_generator_x;
    wire [15:0] location_generator_y;
    wire location_generator_xy_in_active;
    
    vga_location_generator location_generator(pixel_clock,
        location_generator_hsync,
        location_generator_vsync,
        location_generator_blank,
        location_generator_x,
        location_generator_y,
        location_generator_xy_in_active);
        
    wire [7:0] text_buffer_screen_char;
    reg text_buffer_hsync;
    reg text_buffer_vsync;
    reg text_buffer_blank;
    reg [15:0] text_buffer_x;
    reg [15:0] text_buffer_y;
    reg text_buffer_xy_in_active;
    
    initial text_buffer_hsync = 0;
    initial text_buffer_vsync = 0;
    initial text_buffer_blank = 0;
    initial text_buffer_x = 0;
    initial text_buffer_y = 0;
    initial text_buffer_xy_in_active = 0;
    
    always @(posedge pixel_clock) text_buffer_hsync <= location_generator_hsync;
    always @(posedge pixel_clock) text_buffer_vsync <= location_generator_vsync;
    always @(posedge pixel_clock) text_buffer_blank <= location_generator_blank;
    always @(posedge pixel_clock) text_buffer_x <= location_generator_x;
    always @(posedge pixel_clock) text_buffer_y <= location_generator_y;
    always @(posedge pixel_clock) text_buffer_xy_in_active <= location_generator_xy_in_active;
        
    vga_text_buffer text_buffer(pixel_clock,
        location_generator_x,
        location_generator_y,
        location_generator_xy_in_active,
        text_buffer_screen_char,
        clk,
        tty_write,
        tty_data,
        tty_busy);
        
    wire [7:0] font_generator_r;
    wire [7:0] font_generator_g;
    wire [7:0] font_generator_b;
        
    vga_font_generator font_generator(
        pixel_clock,
        text_buffer_x,
        text_buffer_y,
        text_buffer_xy_in_active,
        text_buffer_screen_char,
        font_generator_r,
        font_generator_g,
        font_generator_b);

    reg font_generator_hsync;
    reg font_generator_vsync;
    reg font_generator_blank;
    
    initial font_generator_hsync = 0;
    initial font_generator_vsync = 0;
    initial font_generator_blank = 0;
    
    always @(posedge pixel_clock) font_generator_hsync <= text_buffer_hsync;
    always @(posedge pixel_clock) font_generator_vsync <= text_buffer_vsync;
    always @(posedge pixel_clock) font_generator_blank <= text_buffer_blank;
    
    assign vga_pixel_clock = ~pixel_clock;
    
    reg output_hsync;
    reg output_vsync;
    reg output_blank;
    reg [7:0] output_r;
    reg [7:0] output_g;
    reg [7:0] output_b;
    
    initial output_hsync = 0;
    initial output_vsync = 0;
    initial output_blank = 0;
    initial output_r = 0;
    initial output_g = 0;
    initial output_b = 0;
    
    always @(posedge pixel_clock) output_hsync = font_generator_hsync;
    always @(posedge pixel_clock) output_vsync = font_generator_vsync;
    always @(posedge pixel_clock) output_blank = font_generator_blank;
    always @(posedge pixel_clock) output_r = font_generator_r;
    always @(posedge pixel_clock) output_g = font_generator_g;
    always @(posedge pixel_clock) output_b = font_generator_b;

	assign vga_r = output_r;
	assign vga_g = output_g;
	assign vga_b = output_b;
    
	reg final_hsync;
	reg final_vsync;
    reg final_blank;
    
    initial final_hsync = 0;
    initial final_vsync = 0;
    initial final_blank = 0;
    
    always @(posedge pixel_clock) final_hsync = output_hsync;
    always @(posedge pixel_clock) final_vsync = output_vsync;
    always @(posedge pixel_clock) final_blank = font_generator_blank;
    
    assign vga_hsync = final_hsync;
    assign vga_vsync = final_vsync;
    assign vga_blank = font_generator_blank;
endmodule
