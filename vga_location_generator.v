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

module vga_location_generator(
    input pixel_clock,
	output reg hsync,
	output reg vsync,
    output reg blank,
    output reg [15:0] x,
    output reg [15:0] y,
    output reg xy_in_active
    );
	
	parameter x_front_porch = 56;
	parameter x_active = 800;
	parameter x_back_porch = 64;
	parameter x_sync = 120;
	parameter y_front_porch = 37;
	parameter y_active = 600;
	parameter y_back_porch = 23;
	parameter y_sync = 6;
	 
    wire x_at_end = (x == x_active + x_back_porch + x_sync + x_front_porch);
    wire y_at_end = (y == y_active + y_back_porch + y_sync + y_front_porch);
    wire [15:0] next_x = x_at_end ? 0 : x + 1;
    wire [15:0] next_y = x_at_end ? (y_at_end ? 0 : y + 1) : y;
    wire next_xy_in_active = (next_x < x_active) & (next_y < y_active);

    initial begin
        hsync = 0;
        vsync = 0;
        blank = 0;
        x = 0;
        y = 0;
    end

	always @(posedge pixel_clock) begin
		x <= next_x;
        y <= next_y;
        blank <= next_xy_in_active;
        hsync <= ((x >= x_active + x_back_porch) & (x < x_active + x_back_porch + x_sync));
        vsync <= ((y >= y_active + y_back_porch) & (y < y_active + y_back_porch + y_sync));
        xy_in_active <= next_xy_in_active;
	end
endmodule
