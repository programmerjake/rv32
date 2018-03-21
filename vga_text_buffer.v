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

module vga_text_buffer(
    input pixel_clock,
    input [15:0] screen_x,
    input [15:0] screen_y,
    input screen_valid,
    output reg [7:0] screen_char,
    input clk,
    input tty_write,
    input [7:0] tty_data,
    output reg tty_busy
    );
    
    parameter font_x_size = 8;
    parameter font_y_size = 8;
    parameter screen_x_size = 800;
    parameter screen_y_size = 600;
    parameter text_x_size = screen_x_size / font_x_size;
    parameter text_y_size = screen_y_size / font_y_size;
    parameter ram_x_size = 128;
    parameter ram_y_size = 128;
    
    // ram_style = "block"
    reg [7:0] text_ram[ram_x_size * ram_y_size - 1 : 0];

    initial $readmemh("text_initial.hex", text_ram);

    initial tty_busy = 1;
    
    initial screen_char = 0;
    
    reg [11:0] scroll_amount;
    
    initial scroll_amount = 0;
    
    always @(posedge pixel_clock) begin
        screen_char <= screen_valid ? text_ram[ram_x_size * ((screen_y / font_y_size) + scroll_amount) + (screen_x / font_x_size)] : 0;
    end
    
    reg [11:0] cursor_x;
    reg [11:0] cursor_y;
    
    initial cursor_x = 0;
    initial cursor_y = 0;
    
    reg [2:0] state;
    
    initial state = 0;
    
    wire [11:0] cursor_x_after_tab_unwrapped = ((cursor_x >> 3) + 1) << 3;
    wire [11:0] cursor_x_after_tab = (cursor_x_after_tab_unwrapped == text_x_size ? 0 : cursor_x_after_tab_unwrapped);
    
    reg [15:0] text_ram_write_address;
    reg text_ram_write_enable;
    reg [7:0] text_ram_write_data;
    
    always @(posedge clk) begin
        if(text_ram_write_enable)
            text_ram[text_ram_write_address] <= text_ram_write_data;
    end
    
    parameter space_char = 'h20;
    parameter escape_char = 'h1B;
    parameter left_bracket_char = 'h5B;
    parameter capital_H_char = 'h48;
    
    always @(posedge clk) begin
        text_ram_write_enable = 0;
        case(state)
            0: begin
                cursor_x <= 0;
                cursor_y <= 0;
                tty_busy <= 1;
                state <= 1;
                scroll_amount <= 0;
            end
            1: begin
                if(cursor_x != ram_x_size - 1) begin
                    tty_busy <= 1;
                    text_ram_write_enable = 1;
                    text_ram_write_address = ram_x_size * (cursor_y + scroll_amount) + cursor_x;
                    text_ram_write_data = space_char;
                    cursor_x <= cursor_x + 1;
                end
                else if(cursor_y != ram_y_size - 1) begin
                    tty_busy <= 1;
                    text_ram_write_enable = 1;
                    text_ram_write_address = ram_x_size * (cursor_y + scroll_amount) + cursor_x;
                    text_ram_write_data = space_char;
                    cursor_x <= 0;
                    cursor_y <= cursor_y + 1;
                end
                else begin
                    text_ram_write_enable = 1;
                    text_ram_write_address = ram_x_size * (cursor_y + scroll_amount) + cursor_x;
                    text_ram_write_data = space_char;
                    tty_busy <= 0;
                    state <= 2;
                    cursor_x <= 0;
                    cursor_y <= 0;
                end
            end
            2: begin
                if(tty_write) begin
                    case (tty_data)
                        'h0A: begin
                            if(cursor_y != text_y_size - 1) begin
                                cursor_x <= 0;
                                cursor_y <= cursor_y + 1;
                                tty_busy <= 0;
                            end
                            else begin
                                cursor_x <= 0;
                                tty_busy <= 1;
                                state <= 3;
                                scroll_amount <= scroll_amount + 1;
                            end
                        end
                        'h1B: begin
                            tty_busy <= 0;
                            state <= 4;
                        end
                        'h0D: begin
                            cursor_x <= 0;
                            tty_busy <= 0;
                        end
                        'h09: begin
                            cursor_x <= cursor_x_after_tab;
                            tty_busy <= 0;
                        end
                        default: begin
                            text_ram_write_enable = 1;
                            text_ram_write_address = ram_x_size * (cursor_y + scroll_amount) + cursor_x;
                            text_ram_write_data = tty_data;
                            if(cursor_x != text_x_size - 1) begin
                                cursor_x <= cursor_x + 1;
                                tty_busy <= 0;
                            end
                            else if(cursor_y != text_y_size - 1) begin
                                cursor_x <= 0;
                                cursor_y <= cursor_y + 1;
                                tty_busy <= 0;
                            end
                            else begin
                                cursor_x <= 0;
                                cursor_y <= text_y_size - 1;
                                tty_busy <= 1;
                                state <= 3;
                                scroll_amount <= scroll_amount + 1;
                            end
                        end
                    endcase
                end
                else begin
                    tty_busy <= 0;
                end
            end
            3: begin
                if(cursor_x != ram_x_size - 1) begin
                    tty_busy <= 1;
                    text_ram_write_enable = 1;
                    text_ram_write_address = ram_x_size * (cursor_y + scroll_amount) + cursor_x;
                    text_ram_write_data = space_char;
                    cursor_x <= cursor_x + 1;
                end
                else begin
                    text_ram_write_enable = 1;
                    text_ram_write_address = ram_x_size * (cursor_y + scroll_amount) + cursor_x;
                    text_ram_write_data = space_char;
                    tty_busy <= 0;
                    state <= 2;
                    cursor_x <= 0;
                end
            end
            4: begin
                if(tty_write) begin
                    case (tty_data)
                        'h52: begin // "R": reset
                            tty_busy <= 1;
                            state <= 0;
                        end
                        left_bracket_char: begin
                            tty_busy <= 0;
                            state <= 5;
                        end
                        default: begin
                            text_ram_write_enable = 1;
                            text_ram_write_address = ram_x_size * (cursor_y + scroll_amount) + cursor_x;
                            text_ram_write_data = tty_data;
                            if(cursor_x != text_x_size - 1) begin
                                cursor_x <= cursor_x + 1;
                                tty_busy <= 0;
                                state <= 2;
                            end
                            else if(cursor_y != text_y_size - 1) begin
                                cursor_x <= 0;
                                cursor_y <= cursor_y + 1;
                                tty_busy <= 0;
                                state <= 2;
                            end
                            else begin
                                cursor_x <= 0;
                                cursor_y <= text_y_size - 1;
                                tty_busy <= 1;
                                state <= 3;
                                scroll_amount <= scroll_amount + 1;
                            end
                        end
                    endcase
                end
                else begin
                    tty_busy <= 0;
                end
            end
            5: begin
                if(tty_write) begin
                    case (tty_data)
                        capital_H_char: begin // move to top left
                            tty_busy <= 0;
                            state <= 2;
                            cursor_x <= 0;
                            cursor_y <= 0;
                        end
                        default: begin
                            text_ram_write_enable = 1;
                            text_ram_write_address = ram_x_size * (cursor_y + scroll_amount) + cursor_x;
                            text_ram_write_data = tty_data;
                            if(cursor_x != text_x_size - 1) begin
                                cursor_x <= cursor_x + 1;
                                tty_busy <= 0;
                                state <= 2;
                            end
                            else if(cursor_y != text_y_size - 1) begin
                                cursor_x <= 0;
                                cursor_y <= cursor_y + 1;
                                tty_busy <= 0;
                                state <= 2;
                            end
                            else begin
                                cursor_x <= 0;
                                cursor_y <= text_y_size - 1;
                                tty_busy <= 1;
                                state <= 3;
                                scroll_amount <= scroll_amount + 1;
                            end
                        end
                    endcase
                end
                else begin
                    tty_busy <= 0;
                end
            end
            default: state <= 0;
        endcase
    end

endmodule
