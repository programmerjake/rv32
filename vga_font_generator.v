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

module vga_font_generator(
	input pixel_clock,
    input [15:0] screen_x,
    input [15:0] screen_y,
    input screen_valid,
    input [7:0] screen_char,
	output [7:0] vga_r,
	output [7:0] vga_g,
	output [7:0] vga_b
    );
    
    parameter font_x_size = 8;
    parameter font_y_size = 8;
	
    // ram_style = "block"
    reg [font_x_size - 1 : 0] font8x8[0 : 256 * font_y_size - 1];
    
    initial $readmemh("font8x8.hex", font8x8);
    
    wire [2:0] sub_char_x = screen_x[2:0];
    wire [2:0] sub_char_y = screen_y[2:0];
    wire [15:0] font_address = {screen_char, sub_char_y};
    reg [7:0] font_line;
    reg [2:0] output_sub_char_x;

    initial font_line = 0;
    initial output_sub_char_x = 0;
    
    always @(posedge pixel_clock) begin
        font_line <= font8x8[font_address];
        output_sub_char_x <= sub_char_x;
    end
    
    wire pixel_active = ((font_line >> output_sub_char_x) & 1) == 1;
    assign vga_r = pixel_active ? 255 : 0;
    assign vga_g = pixel_active ? 255 : 0;
    assign vga_b = pixel_active ? 255 : 0;
    
endmodule
