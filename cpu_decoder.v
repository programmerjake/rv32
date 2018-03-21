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
`include "riscv.vh"
`include "cpu.vh"

module cpu_decoder(
    input [31:0] instruction,
    output [6:0] funct7,
    output [2:0] funct3,
    output [4:0] rd,
    output [4:0] rs1,
    output [4:0] rs2,
    output [31:0] immediate,
    output [6:0] opcode,
    output `decode_action decode_action
    );
    
    assign funct7 = instruction[31:25];
    assign funct3 = instruction[14:12];
    assign rd = instruction[11:7];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign opcode = instruction[6:0];
    
    function [31:0] calculate_immediate(input [31:0] instruction, input [6:0] opcode);
    begin
        case(opcode)
        `opcode_amo,
        `opcode_op,
        `opcode_op_32,
        `opcode_op_fp:
            // R-type: no immediate
            calculate_immediate = 32'hXXXXXXXX;
        `opcode_load,
        `opcode_load_fp,
        `opcode_misc_mem,
        `opcode_op_imm,
        `opcode_op_imm_32,
        `opcode_jalr,
        `opcode_system:
            // I-type
            calculate_immediate = {{20{instruction[31]}}, instruction[31:20]};
        `opcode_store,
        `opcode_store_fp:
            // S-type
            calculate_immediate = {{21{instruction[31]}}, instruction[30:25], instruction[11:7]};
        `opcode_branch:
            // B-type
            calculate_immediate = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        `opcode_auipc,
        `opcode_lui:
            // U-type
            calculate_immediate = {instruction[31:12], 12'b0};
        `opcode_jal:
            // J-type
            calculate_immediate = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:25], instruction[24:21], 1'b0};
        `opcode_madd,
        `opcode_msub,
        `opcode_nmsub,
        `opcode_nmadd:
            // R4-type: no immediate
            calculate_immediate = 32'hXXXXXXXX;
        `opcode_custom_0,
        `opcode_48b_escape_0,
        `opcode_custom_1,
        `opcode_64b_escape,
        `opcode_reserved_10101,
        `opcode_rv128_0,
        `opcode_48b_escape_1,
        `opcode_reserved_11010,
        `opcode_reserved_11101,
        `opcode_rv128_1,
        `opcode_80b_escape:
            // unknown
            calculate_immediate = 32'hXXXXXXXX;
        default:
            calculate_immediate = 32'hXXXXXXXX;
        endcase
    end
    endfunction
    
    assign immediate = calculate_immediate(instruction, opcode);
    
    function `decode_action calculate_action(
        input [6:0] funct7,
        input [2:0] funct3,
        input [4:0] rd,
        input [4:0] rs1,
        input [4:0] rs2,
        input [31:0] immediate,
        input [6:0] opcode);
    begin
        case(opcode)
        `opcode_load: begin
            case(funct3)
            `funct3_lb,
            `funct3_lbu,
            `funct3_lh,
            `funct3_lhu,
            `funct3_lw:
                calculate_action = `decode_action_load;
            default:
                calculate_action = `decode_action_trap_illegal_instruction;
            endcase
        end
        `opcode_misc_mem: begin
            if(funct3 == `funct3_fence) begin
                if((immediate[11:8] == 0) & (rs1 == 0) & (rd == 0))
                    calculate_action = `decode_action_fence;
                else
                    calculate_action = `decode_action_trap_illegal_instruction;
            end
            else if(funct3 == `funct3_fence_i) begin
                if((immediate[11:0] == 0) & (rs1 == 0) & (rd == 0))
                    calculate_action = `decode_action_fence_i;
                else
                    calculate_action = `decode_action_trap_illegal_instruction;
            end
            else
            begin
                calculate_action = `decode_action_trap_illegal_instruction;
            end
        end
        `opcode_op_imm,
        `opcode_op: begin
            if(funct3 == `funct3_slli) begin
                if(funct7 == 0)
                    calculate_action = `decode_action_op_op_imm;
                else
                    calculate_action = `decode_action_trap_illegal_instruction;
            end
            else if(funct3 == `funct3_srli_srai) begin
                if(funct7 == 0 || funct7 == 7'h20)
                    calculate_action = `decode_action_op_op_imm;
                else
                    calculate_action = `decode_action_trap_illegal_instruction;
            end
            else begin
                calculate_action = `decode_action_op_op_imm;
            end
        end
        `opcode_lui,
        `opcode_auipc: begin
            calculate_action = `decode_action_lui_auipc;
        end
        `opcode_store: begin
            case(funct3)
            `funct3_sb,
            `funct3_sh,
            `funct3_sw:
                calculate_action = `decode_action_store;
            default:
                calculate_action = `decode_action_trap_illegal_instruction;
            endcase
        end
        `opcode_branch: begin
            case(funct3)
            `funct3_beq,
            `funct3_bne,
            `funct3_blt,
            `funct3_bge,
            `funct3_bltu,
            `funct3_bgeu:
                calculate_action = `decode_action_branch;
            default:
                calculate_action = `decode_action_trap_illegal_instruction;
            endcase
        end
        `opcode_jalr: begin
            if(funct3 == `funct3_jalr)
                calculate_action = `decode_action_jalr;
            else
                calculate_action = `decode_action_trap_illegal_instruction;
        end
        `opcode_jal: begin
            calculate_action = `decode_action_jal;
        end
        `opcode_system: begin
            case(funct3)
            `funct3_ecall_ebreak:
                if((rs1 != 0) | (rd != 0) | ((immediate & ~32'b1) != 0))
                    calculate_action = `decode_action_trap_illegal_instruction;
                else
                    calculate_action = `decode_action_trap_ecall_ebreak;
            `funct3_csrrw,
            `funct3_csrrs,
            `funct3_csrrc,
            `funct3_csrrwi,
            `funct3_csrrsi,
            `funct3_csrrci:
                calculate_action = `decode_action_csr;
            default:
                calculate_action = `decode_action_trap_illegal_instruction;
            endcase
        end
        `opcode_load_fp,
        `opcode_custom_0,
        `opcode_op_imm_32,
        `opcode_48b_escape_0,
        `opcode_store_fp,
        `opcode_custom_1,
        `opcode_amo,
        `opcode_op_32,
        `opcode_64b_escape,
        `opcode_madd,
        `opcode_msub,
        `opcode_nmsub,
        `opcode_nmadd,
        `opcode_op_fp,
        `opcode_reserved_10101,
        `opcode_rv128_0,
        `opcode_48b_escape_1,
        `opcode_reserved_11010,
        `opcode_reserved_11101,
        `opcode_rv128_1,
        `opcode_80b_escape: begin
            calculate_action = `decode_action_trap_illegal_instruction;
        end
        default:
            calculate_action = `decode_action_trap_illegal_instruction;
        endcase
    end
    endfunction
    
    assign decode_action = calculate_action(funct7,
                                            funct3,
                                            rd,
                                            rs1,
                                            rs2,
                                            immediate,
                                            opcode);
    
endmodule
