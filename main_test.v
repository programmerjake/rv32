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

module main_test;

	// Inputs
	reg clk;
	reg switch_2;
	reg switch_3;

	// Outputs
	wire [7:0] vga_r;
	wire [7:0] vga_g;
	wire [7:0] vga_b;
	wire vga_hsync;
	wire vga_vsync;
	wire vga_blank;
	wire vga_pixel_clock;
	wire led_1;
	wire led_3;


	// Instantiate the Unit Under Test (UUT)
	main uut (
		.clk(clk), 
		.vga_r(vga_r), 
		.vga_g(vga_g), 
		.vga_b(vga_b), 
		.vga_hsync(vga_hsync), 
		.vga_vsync(vga_vsync), 
		.vga_blank(vga_blank), 
		.vga_pixel_clock(vga_pixel_clock),
		.switch_2(switch_2),
		.switch_3(switch_3),
		.led_1(led_1),
		.led_3(led_3)
	);

	initial begin
		// Initialize Inputs
		$dumpvars;
		clk = 0;
		switch_2 = 0;
		switch_3 = 0;

		// Add stimulus here
        
        forever #10 clk = ~clk;
	end
    
    reg [7:0] r;
    reg [7:0] g;
    reg [7:0] b;
    
    always @(posedge vga_pixel_clock) begin
        r = vga_r;
        g = vga_g;
        b = vga_b;
    end
      
endmodule

