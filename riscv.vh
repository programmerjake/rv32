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
`ifndef riscv_vh_
`define riscv_vh_

`define cause_instruction_address_misaligned 'h0
`define cause_instruction_access_fault 'h1
`define cause_illegal_instruction 'h2
`define cause_breakpoint 'h3
`define cause_load_address_misaligned 'h4
`define cause_load_access_fault 'h5
`define cause_store_amo_address_misaligned 'h6
`define cause_store_amo_access_fault 'h7
`define cause_user_environment_call 'h8
`define cause_supervisor_environment_call 'h9
`define cause_machine_environment_call 'hB
`define cause_instruction_page_fault 'hC
`define cause_load_page_fault 'hD
`define cause_store_amo_page_fault 'hF

`define opcode_load 7'h03
`define opcode_load_fp 7'h07
`define opcode_custom_0 7'h0B
`define opcode_misc_mem 7'h0F
`define opcode_op_imm 7'h13
`define opcode_auipc 7'h17
`define opcode_op_imm_32 7'h1B
`define opcode_48b_escape_0 7'h1F

`define opcode_store 7'h23
`define opcode_store_fp 7'h27
`define opcode_custom_1 7'h2B
`define opcode_amo 7'h2F
`define opcode_op 7'h33
`define opcode_lui 7'h37
`define opcode_op_32 7'h3B
`define opcode_64b_escape 7'h3F

`define opcode_madd 7'h43
`define opcode_msub 7'h47
`define opcode_nmsub 7'h4B
`define opcode_nmadd 7'h4F
`define opcode_op_fp 7'h53
`define opcode_reserved_10101 7'h57
`define opcode_rv128_0 7'h5B
`define opcode_48b_escape_1 7'h5F

`define opcode_branch 7'h63
`define opcode_jalr 7'h67
`define opcode_reserved_11010 7'h6B
`define opcode_jal 7'h6F
`define opcode_system 7'h73
`define opcode_reserved_11101 7'h77
`define opcode_rv128_1 7'h7B
`define opcode_80b_escape 7'h7F

`define funct3_jalr 3'h0
`define funct3_beq 3'h0
`define funct3_bne 3'h1
`define funct3_blt 3'h4
`define funct3_bge 3'h5
`define funct3_bltu 3'h6
`define funct3_bgeu 3'h7
`define funct3_lb 3'h0
`define funct3_lh 3'h1
`define funct3_lw 3'h2
`define funct3_lbu 3'h4
`define funct3_lhu 3'h5
`define funct3_sb 3'h0
`define funct3_sh 3'h1
`define funct3_sw 3'h2
`define funct3_addi 3'h0
`define funct3_slli 3'h1
`define funct3_slti 3'h2
`define funct3_sltiu 3'h3
`define funct3_xori 3'h4
`define funct3_srli_srai 3'h5
`define funct3_ori 3'h6
`define funct3_andi 3'h7
`define funct3_add_sub 3'h0
`define funct3_sll 3'h1
`define funct3_slt 3'h2
`define funct3_sltu 3'h3
`define funct3_xor 3'h4
`define funct3_srl_sra 3'h5
`define funct3_or 3'h6
`define funct3_and 3'h7
`define funct3_fence 3'h0
`define funct3_fence_i 3'h1
`define funct3_ecall_ebreak 3'h0
`define funct3_csrrw 3'h1
`define funct3_csrrs 3'h2
`define funct3_csrrc 3'h3
`define funct3_csrrwi 3'h5
`define funct3_csrrsi 3'h6
`define funct3_csrrci 3'h7

`define csr_ustatus 12'h000
`define csr_fflags 12'h001
`define csr_frm 12'h002
`define csr_fcsr 12'h003
`define csr_uie 12'h004
`define csr_utvec 12'h005
`define csr_uscratch 12'h040
`define csr_uepc 12'h041
`define csr_ucause 12'h042
`define csr_utval 12'h043
`define csr_uip 12'h044
`define csr_cycle 12'hC00
`define csr_time 12'hC01
`define csr_instret 12'hC02
`define csr_cycleh 12'hC80
`define csr_timeh 12'hC81
`define csr_instreth 12'hC82

`define csr_sstatus 12'h100
`define csr_sedeleg 12'h102
`define csr_sideleg 12'h103
`define csr_sie 12'h104
`define csr_stvec 12'h105
`define csr_scounteren 12'h106
`define csr_sscratch 12'h140
`define csr_sepc 12'h141
`define csr_scause 12'h142
`define csr_stval 12'h143
`define csr_sip 12'h144
`define csr_satp 12'h180

`define csr_mvendorid 12'hF11
`define csr_marchid 12'hF12
`define csr_mimpid 12'hF13
`define csr_mhartid 12'hF14
`define csr_mstatus 12'h300
`define csr_misa 12'h301
`define csr_medeleg 12'h302
`define csr_mideleg 12'h303
`define csr_mie 12'h304
`define csr_mtvec 12'h305
`define csr_mcounteren 12'h306
`define csr_mscratch 12'h340
`define csr_mepc 12'h341
`define csr_mcause 12'h342
`define csr_mtval 12'h343
`define csr_mip 12'h344
`define csr_mcycle 12'hB00
`define csr_minstret 12'hB02
`define csr_mcycleh 12'hB80
`define csr_minstreth 12'hB82

`define csr_dcsr 12'h7B0
`define csr_dpc 12'h7B1
`define csr_dscratch 12'h7B2

`endif

