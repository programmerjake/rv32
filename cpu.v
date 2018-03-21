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
`include "riscv.vh"
`include "cpu.vh"

module cpu(
    input clk,
    input reset,
    output tty_write,
    output [7:0] tty_write_data,
    input tty_write_busy,
    input switch_2,
    input switch_3,
    output led_1,
    output led_3
    );

    parameter ram_size = 'h8000;
    parameter ram_start = 32'h1_0000;
    parameter reset_vector = ram_start;
    parameter mtvec = ram_start + 'h40;

    reg [31:0] registers[31:1];

    wire [31:2] memory_interface_fetch_address;
    wire [31:0] memory_interface_fetch_data;
    wire memory_interface_fetch_valid;
    wire [31:2] memory_interface_rw_address;
    wire [3:0] memory_interface_rw_byte_mask;
    wire memory_interface_rw_read_not_write;
    wire memory_interface_rw_active;
    wire [31:0] memory_interface_rw_data_in;
    wire [31:0] memory_interface_rw_data_out;
    wire memory_interface_rw_address_valid;
    wire memory_interface_rw_wait;

    cpu_memory_interface #(
        .ram_size(ram_size),
        .ram_start(ram_start)
        ) memory_interface(
        .clk(clk),
        .reset(reset),
        .fetch_address(memory_interface_fetch_address),
        .fetch_data(memory_interface_fetch_data),
        .fetch_valid(memory_interface_fetch_valid),
        .rw_address(memory_interface_rw_address),
        .rw_byte_mask(memory_interface_rw_byte_mask),
        .rw_read_not_write(memory_interface_rw_read_not_write),
        .rw_active(memory_interface_rw_active),
        .rw_data_in(memory_interface_rw_data_in),
        .rw_data_out(memory_interface_rw_data_out),
        .rw_address_valid(memory_interface_rw_address_valid),
        .rw_wait(memory_interface_rw_wait),
        .tty_write(tty_write),
        .tty_write_data(tty_write_data),
        .tty_write_busy(tty_write_busy),
        .switch_2(switch_2),
        .switch_3(switch_3),
        .led_1(led_1),
        .led_3(led_3)
        );

    wire `fetch_action fetch_action;
    wire [31:0] fetch_target_pc;
    wire [31:0] fetch_output_pc;
    wire [31:0] fetch_output_instruction;
    wire `fetch_output_state fetch_output_state;

    cpu_fetch_stage #(
        .reset_vector(reset_vector),
        .mtvec(mtvec)
        ) fetch_stage(
        .clk(clk),
        .reset(reset),
        .memory_interface_fetch_address(memory_interface_fetch_address),
        .memory_interface_fetch_data(memory_interface_fetch_data),
        .memory_interface_fetch_valid(memory_interface_fetch_valid),
        .fetch_action(fetch_action),
        .target_pc(fetch_target_pc),
        .output_pc(fetch_output_pc),
        .output_instruction(fetch_output_instruction),
        .output_state(fetch_output_state)
        );

    wire [6:0] decoder_funct7;
    wire [2:0] decoder_funct3;
    wire [4:0] decoder_rd;
    wire [4:0] decoder_rs1;
    wire [4:0] decoder_rs2;
    wire [31:0] decoder_immediate;
    wire [6:0] decoder_opcode;
    wire `decode_action decode_action;

    cpu_decoder decoder(
        .instruction(fetch_output_instruction),
        .funct7(decoder_funct7),
        .funct3(decoder_funct3),
        .rd(decoder_rd),
        .rs1(decoder_rs1),
        .rs2(decoder_rs2),
        .immediate(decoder_immediate),
        .opcode(decoder_opcode),
        .decode_action(decode_action));

    wire [31:0] register_rs1 = (decoder_rs1 == 0) ? 0 : registers[decoder_rs1];
    wire [31:0] register_rs2 = (decoder_rs2 == 0) ? 0 : registers[decoder_rs2];

    wire [31:0] load_store_address = decoder_immediate + register_rs1;

    wire [1:0] load_store_address_low_2 = decoder_immediate[1:0] + register_rs1[1:0];

    function get_load_store_misaligned(
        input [2:0] funct3,
        input [1:0] load_store_address_low_2
        );
    begin
        case(funct3[1:0])
        `funct3_sb:
            get_load_store_misaligned = 0;
        `funct3_sh:
            get_load_store_misaligned = load_store_address_low_2[0] != 0;
        `funct3_sw:
            get_load_store_misaligned = load_store_address_low_2[1:0] != 0;
        default:
            get_load_store_misaligned = 1'bX;
        endcase
    end
    endfunction

    wire load_store_misaligned = get_load_store_misaligned(decoder_funct3, load_store_address_low_2);

    assign memory_interface_rw_address = load_store_address[31:2];

    wire [3:0] unshifted_load_store_byte_mask = {decoder_funct3[1] ? 2'b11 : 2'b00, (decoder_funct3[1] | decoder_funct3[0]) ? 1'b1 : 1'b0, 1'b1};

    assign memory_interface_rw_byte_mask = unshifted_load_store_byte_mask << load_store_address_low_2;

    assign memory_interface_rw_data_in[31:24] = load_store_address_low_2[1]
                                                ? (load_store_address_low_2[0] ? register_rs2[7:0] : register_rs2[15:8])
                                                : (load_store_address_low_2[0] ? register_rs2[23:16] : register_rs2[31:24]);
    assign memory_interface_rw_data_in[23:16] = load_store_address_low_2[1] ? register_rs2[7:0] : register_rs2[23:16];
    assign memory_interface_rw_data_in[15:8] = load_store_address_low_2[0] ? register_rs2[7:0] : register_rs2[15:8];
    assign memory_interface_rw_data_in[7:0] = register_rs2[7:0];

    wire [31:0] unmasked_loaded_value;

    assign unmasked_loaded_value[7:0] = load_store_address_low_2[1]
                                        ? (load_store_address_low_2[0] ? memory_interface_rw_data_out[31:24] : memory_interface_rw_data_out[23:16])
                                        : (load_store_address_low_2[0] ? memory_interface_rw_data_out[15:8] : memory_interface_rw_data_out[7:0]);
    assign unmasked_loaded_value[15:8] = load_store_address_low_2[1] ? memory_interface_rw_data_out[31:24] : memory_interface_rw_data_out[15:8];
    assign unmasked_loaded_value[31:16] = memory_interface_rw_data_out[31:16];

    wire [31:0] loaded_value;

    assign loaded_value[7:0] = unmasked_loaded_value[7:0];
    assign loaded_value[15:8] = decoder_funct3[1:0] == 0 ? ({8{~decoder_funct3[2] & unmasked_loaded_value[7]}}) : unmasked_loaded_value[15:8];
    assign loaded_value[31:16] = decoder_funct3[1] == 0 ? ({16{~decoder_funct3[2] & (decoder_funct3[0] ? unmasked_loaded_value[15] : unmasked_loaded_value[7])}}) : unmasked_loaded_value[31:16];

    assign memory_interface_rw_active = ~reset
                                        & (fetch_output_state == `fetch_output_state_valid)
                                        & ~load_store_misaligned
                                        & ((decode_action & (`decode_action_load | `decode_action_store)) != 0);

    assign memory_interface_rw_read_not_write = ~decoder_opcode[5];

    wire [31:0] alu_a = register_rs1;
    wire [31:0] alu_b = decoder_opcode[5] ? register_rs2 : decoder_immediate;
    wire [31:0] alu_result;

    cpu_alu alu(
        .funct7(decoder_funct7),
        .funct3(decoder_funct3),
        .opcode(decoder_opcode),
        .a(alu_a),
        .b(alu_b),
        .result(alu_result)
        );

    wire [31:0] lui_auipc_result = decoder_opcode[5] ? decoder_immediate : decoder_immediate + fetch_output_pc;

    assign fetch_target_pc[31:1] = ((decoder_opcode != `opcode_jalr ? fetch_output_pc[31:1] : register_rs1[31:1]) + decoder_immediate[31:1]);
    assign fetch_target_pc[0] = 0;

    wire misaligned_jump_target = fetch_target_pc[1];

    wire [31:0] branch_arg_a = {register_rs1[31] ^ ~decoder_funct3[1], register_rs1[30:0]};
    wire [31:0] branch_arg_b = {register_rs2[31] ^ ~decoder_funct3[1], register_rs2[30:0]};

    wire branch_taken = decoder_funct3[0] ^ (decoder_funct3[2] ? branch_arg_a < branch_arg_b : branch_arg_a == branch_arg_b);

    reg [31:0] mcause = 0;
    reg [31:0] mepc = 32'hXXXXXXXX;
    reg [31:0] mscratch = 32'hXXXXXXXX;

    reg mstatus_mpie = 1'bX;
    reg mstatus_mie = 0;
    parameter mstatus_mprv = 0;
    parameter mstatus_tsr = 0;
    parameter mstatus_tw = 0;
    parameter mstatus_tvm = 0;
    parameter mstatus_mxr = 0;
    parameter mstatus_sum = 0;
    parameter mstatus_xs = 0;
    parameter mstatus_fs = 0;
    parameter mstatus_mpp = 2'b11;
    parameter mstatus_spp = 0;
    parameter mstatus_spie = 0;
    parameter mstatus_upie = 0;
    parameter mstatus_sie = 0;
    parameter mstatus_uie = 0;

    reg mie_meie = 1'bX;
    reg mie_mtie = 1'bX;
    reg mie_msie = 1'bX;
    parameter mie_seie = 0;
    parameter mie_ueie = 0;
    parameter mie_stie = 0;
    parameter mie_utie = 0;
    parameter mie_ssie = 0;
    parameter mie_usie = 0;

    task reset_to_initial;
    begin
        mcause = 0;
        mepc = 32'hXXXXXXXX;
        mscratch = 32'hXXXXXXXX;
        mstatus_mie = 0;
        mstatus_mpie = 1'bX;
        mie_meie = 1'bX;
        mie_mtie = 1'bX;
        mie_msie = 1'bX;
        registers['h01] <= 32'hXXXXXXXX;
        registers['h02] <= 32'hXXXXXXXX;
        registers['h03] <= 32'hXXXXXXXX;
        registers['h04] <= 32'hXXXXXXXX;
        registers['h05] <= 32'hXXXXXXXX;
        registers['h06] <= 32'hXXXXXXXX;
        registers['h07] <= 32'hXXXXXXXX;
        registers['h08] <= 32'hXXXXXXXX;
        registers['h09] <= 32'hXXXXXXXX;
        registers['h0A] <= 32'hXXXXXXXX;
        registers['h0B] <= 32'hXXXXXXXX;
        registers['h0C] <= 32'hXXXXXXXX;
        registers['h0D] <= 32'hXXXXXXXX;
        registers['h0E] <= 32'hXXXXXXXX;
        registers['h0F] <= 32'hXXXXXXXX;
        registers['h10] <= 32'hXXXXXXXX;
        registers['h11] <= 32'hXXXXXXXX;
        registers['h12] <= 32'hXXXXXXXX;
        registers['h13] <= 32'hXXXXXXXX;
        registers['h14] <= 32'hXXXXXXXX;
        registers['h15] <= 32'hXXXXXXXX;
        registers['h16] <= 32'hXXXXXXXX;
        registers['h17] <= 32'hXXXXXXXX;
        registers['h18] <= 32'hXXXXXXXX;
        registers['h19] <= 32'hXXXXXXXX;
        registers['h1A] <= 32'hXXXXXXXX;
        registers['h1B] <= 32'hXXXXXXXX;
        registers['h1C] <= 32'hXXXXXXXX;
        registers['h1D] <= 32'hXXXXXXXX;
        registers['h1E] <= 32'hXXXXXXXX;
        registers['h1F] <= 32'hXXXXXXXX;
    end
    endtask

    task write_register(input [4:0] register_number, input [31:0] value);
    begin
        if(register_number != 0)
            registers[register_number] <= value;
    end
    endtask

    function [31:0] evaluate_csr_funct3_operation(input [2:0] funct3, input [31:0] previous_value, input [31:0] written_value);
    begin
        case(funct3)
        `funct3_csrrw, `funct3_csrrwi:
            evaluate_csr_funct3_operation = written_value;
        `funct3_csrrs, `funct3_csrrsi:
            evaluate_csr_funct3_operation = written_value | previous_value;
        `funct3_csrrc, `funct3_csrrci:
            evaluate_csr_funct3_operation = ~written_value & previous_value;
        default:
            evaluate_csr_funct3_operation = 32'hXXXXXXXX;
        endcase
    end
    endfunction

    parameter misa_a = 1'b0;
    parameter misa_b = 1'b0;
    parameter misa_c = 1'b0;
    parameter misa_d = 1'b0;
    parameter misa_e = 1'b0;
    parameter misa_f = 1'b0;
    parameter misa_g = 1'b0;
    parameter misa_h = 1'b0;
    parameter misa_i = 1'b1;
    parameter misa_j = 1'b0;
    parameter misa_k = 1'b0;
    parameter misa_l = 1'b0;
    parameter misa_m = 1'b0;
    parameter misa_n = 1'b0;
    parameter misa_o = 1'b0;
    parameter misa_p = 1'b0;
    parameter misa_q = 1'b0;
    parameter misa_r = 1'b0;
    parameter misa_s = 1'b0;
    parameter misa_t = 1'b0;
    parameter misa_u = 1'b0;
    parameter misa_v = 1'b0;
    parameter misa_w = 1'b0;
    parameter misa_x = 1'b0;
    parameter misa_y = 1'b0;
    parameter misa_z = 1'b0;
    parameter misa = {
        2'b01,
        4'b0,
        misa_z,
        misa_y,
        misa_x,
        misa_w,
        misa_v,
        misa_u,
        misa_t,
        misa_s,
        misa_r,
        misa_q,
        misa_p,
        misa_o,
        misa_n,
        misa_m,
        misa_l,
        misa_k,
        misa_j,
        misa_i,
        misa_h,
        misa_g,
        misa_f,
        misa_e,
        misa_d,
        misa_c,
        misa_b,
        misa_a};

    parameter mvendorid = 32'b0;
    parameter marchid = 32'b0;
    parameter mimpid = 32'b0;
    parameter mhartid = 32'b0;

    function [31:0] make_mstatus(input mstatus_tsr,
        input mstatus_tw,
        input mstatus_tvm,
        input mstatus_mxr,
        input mstatus_sum,
        input mstatus_mprv,
        input [1:0] mstatus_xs,
        input [1:0] mstatus_fs,
        input [1:0] mstatus_mpp,
        input mstatus_spp,
        input mstatus_mpie,
        input mstatus_spie,
        input mstatus_upie,
        input mstatus_mie,
        input mstatus_sie,
        input mstatus_uie);
    begin
        make_mstatus = {(mstatus_xs == 2'b11) | (mstatus_fs == 2'b11),
            8'b0,
            mstatus_tsr,
            mstatus_tw,
            mstatus_tvm,
            mstatus_mxr,
            mstatus_sum,
            mstatus_mprv,
            mstatus_xs,
            mstatus_fs,
            mstatus_mpp,
            2'b0,
            mstatus_spp,
            mstatus_mpie,
            1'b0,
            mstatus_spie,
            mstatus_upie,
            mstatus_mie,
            1'b0,
            mstatus_sie,
            mstatus_uie};
    end
    endfunction

    wire mip_meip = 0; // TODO: implement external interrupts
    parameter mip_seip = 0;
    parameter mip_ueip = 0;
    wire mip_mtip = 0; // TODO: implement timer interrupts
    parameter mip_stip = 0;
    parameter mip_utip = 0;
    parameter mip_msip = 0;
    parameter mip_ssip = 0;
    parameter mip_usip = 0;

    wire csr_op_is_valid;

    function `fetch_action get_fetch_action(
        input `fetch_output_state fetch_output_state,
        input `decode_action decode_action,
        input load_store_misaligned,
        input memory_interface_rw_address_valid,
        input memory_interface_rw_wait,
        input branch_taken,
        input misaligned_jump_target,
        input csr_op_is_valid
        );
    begin
        case(fetch_output_state)
        `fetch_output_state_empty:
            get_fetch_action = `fetch_action_default;
        `fetch_output_state_trap:
            get_fetch_action = `fetch_action_ack_trap;
        `fetch_output_state_valid: begin
            if((decode_action & `decode_action_trap_illegal_instruction) != 0) begin
                get_fetch_action = `fetch_action_error_trap;
            end
            else if((decode_action & `decode_action_trap_ecall_ebreak) != 0) begin
                get_fetch_action = `fetch_action_noerror_trap;
            end
            else if((decode_action & (`decode_action_load | `decode_action_store)) != 0) begin
                if(load_store_misaligned | ~memory_interface_rw_address_valid) begin
                    get_fetch_action = `fetch_action_error_trap;
                end
                else if(memory_interface_rw_wait) begin
                    get_fetch_action = `fetch_action_wait;
                end
                else begin
                    get_fetch_action = `fetch_action_default;
                end
            end
            else if((decode_action & `decode_action_fence_i) != 0) begin
                get_fetch_action = `fetch_action_fence;
            end
            else if((decode_action & `decode_action_branch) != 0) begin
                if(branch_taken) begin
                    if(misaligned_jump_target) begin
                        get_fetch_action = `fetch_action_error_trap;
                    end
                    else begin
                        get_fetch_action = `fetch_action_jump;
                    end
                end
                else
                begin
                    get_fetch_action = `fetch_action_default;
                end
            end
            else if((decode_action & (`decode_action_jal | `decode_action_jalr)) != 0) begin
                if(misaligned_jump_target) begin
                    get_fetch_action = `fetch_action_error_trap;
                end
                else begin
                    get_fetch_action = `fetch_action_jump;
                end
            end
            else if((decode_action & `decode_action_csr) != 0) begin
                if(csr_op_is_valid)
                    get_fetch_action = `fetch_action_default;
                else
                    get_fetch_action = `fetch_action_error_trap;
            end
            else begin
                get_fetch_action = `fetch_action_default;
            end
        end
        default:
            get_fetch_action = 32'hXXXXXXXX;
        endcase
    end
    endfunction

    assign fetch_action = get_fetch_action(
        fetch_output_state,
        decode_action,
        load_store_misaligned,
        memory_interface_rw_address_valid,
        memory_interface_rw_wait,
        branch_taken,
        misaligned_jump_target,
        csr_op_is_valid
        );

    task handle_trap;
    begin
        mstatus_mpie = mstatus_mie;
        mstatus_mie = 0;
        mepc = (fetch_action == `fetch_action_noerror_trap) ? fetch_output_pc + 4 : fetch_output_pc;
        if(fetch_action == `fetch_action_ack_trap) begin
            mcause = `cause_instruction_access_fault;
        end
        else if((decode_action & `decode_action_trap_illegal_instruction) != 0) begin
            mcause = `cause_illegal_instruction;
        end
        else if((decode_action & `decode_action_trap_ecall_ebreak) != 0) begin
            mcause = decoder_immediate[0] ? `cause_machine_environment_call : `cause_breakpoint;
        end
        else if((decode_action & `decode_action_load) != 0) begin
            if(load_store_misaligned)
                mcause = `cause_load_address_misaligned;
            else
                mcause = `cause_load_access_fault;
        end
        else if((decode_action & `decode_action_store) != 0) begin
            if(load_store_misaligned)
                mcause = `cause_store_amo_address_misaligned;
            else
                mcause = `cause_store_amo_access_fault;
        end
        else if((decode_action & (`decode_action_branch | `decode_action_jal | `decode_action_jalr)) != 0) begin
            mcause = `cause_instruction_address_misaligned;
        end
        else begin
            mcause = `cause_illegal_instruction;
        end
    end
    endtask

    wire [11:0] csr_number = decoder_immediate;
    wire [31:0] csr_input_value = decoder_funct3[2] ? decoder_rs1 : register_rs1;
    wire csr_reads = decoder_funct3[1] | (decoder_rd != 0);
    wire csr_writes = ~decoder_funct3[1] | (decoder_rs1 != 0);

    function get_csr_op_is_valid(input [11:0] csr_number, input csr_reads, input csr_writes);
    begin
        case(csr_number)
        `csr_ustatus,
        `csr_fflags,
        `csr_frm,
        `csr_fcsr,
        `csr_uie,
        `csr_utvec,
        `csr_uscratch,
        `csr_uepc,
        `csr_ucause,
        `csr_utval,
        `csr_uip,
        `csr_sstatus,
        `csr_sedeleg,
        `csr_sideleg,
        `csr_sie,
        `csr_stvec,
        `csr_scounteren,
        `csr_sscratch,
        `csr_sepc,
        `csr_scause,
        `csr_stval,
        `csr_sip,
        `csr_satp,
        `csr_medeleg,
        `csr_mideleg,
        `csr_dcsr,
        `csr_dpc,
        `csr_dscratch:
            get_csr_op_is_valid = 0;
        `csr_cycle,
        `csr_time,
        `csr_instret,
        `csr_cycleh,
        `csr_timeh,
        `csr_instreth,
        `csr_mvendorid,
        `csr_marchid,
        `csr_mimpid,
        `csr_mhartid:
            get_csr_op_is_valid = ~csr_writes;
        `csr_misa,
        `csr_mstatus,
        `csr_mie,
        `csr_mtvec,
        `csr_mscratch,
        `csr_mepc,
        `csr_mcause,
        `csr_mip:
            get_csr_op_is_valid = 1;
        `csr_mcounteren,
        `csr_mtval,
        `csr_mcycle,
        `csr_minstret,
        `csr_mcycleh,
        `csr_minstreth:
            // TODO: CSRs not implemented yet
            get_csr_op_is_valid = 0;
        endcase
    end
    endfunction
    
    assign csr_op_is_valid = get_csr_op_is_valid(csr_number, csr_reads, csr_writes);

    wire [63:0] cycle_counter = 0; // TODO: implement cycle_counter
    wire [63:0] time_counter = 0; // TODO: implement time_counter
    wire [63:0] instret_counter = 0; // TODO: implement instret_counter

    always @(posedge clk) begin:main_block
        if(reset) begin
            reset_to_initial();
            disable main_block;
        end
        case(fetch_output_state)
        `fetch_output_state_empty: begin
        end
        `fetch_output_state_trap: begin
            handle_trap();
        end
        `fetch_output_state_valid: begin:valid
            if((fetch_action == `fetch_action_error_trap) | (fetch_action == `fetch_action_noerror_trap)) begin
                handle_trap();
            end
            else if((decode_action & `decode_action_load) != 0) begin
                if(~memory_interface_rw_wait)
                    write_register(decoder_rd, loaded_value);
            end
            else if((decode_action & `decode_action_op_op_imm) != 0) begin
                write_register(decoder_rd, alu_result);
            end
            else if((decode_action & `decode_action_lui_auipc) != 0) begin
                write_register(decoder_rd, lui_auipc_result);
            end
            else if((decode_action & (`decode_action_jal | `decode_action_jalr)) != 0) begin
                write_register(decoder_rd, fetch_output_pc + 4);
            end
            else if((decode_action & `decode_action_csr) != 0) begin:csr
                reg [31:0] csr_output_value;
                reg [31:0] csr_written_value;
                csr_output_value = 32'hXXXXXXXX;
                csr_written_value = 32'hXXXXXXXX;
                case(csr_number)
                `csr_cycle: begin
                    csr_output_value = cycle_counter[31:0];
                end
                `csr_time: begin
                    csr_output_value = time_counter[31:0];
                end
                `csr_instret: begin
                    csr_output_value = instret_counter[31:0];
                end
                `csr_cycleh: begin
                    csr_output_value = cycle_counter[63:32];
                end
                `csr_timeh: begin
                    csr_output_value = time_counter[63:32];
                end
                `csr_instreth: begin
                    csr_output_value = instret_counter[63:32];
                end
                `csr_mvendorid: begin
                    csr_output_value = mvendorid;
                end
                `csr_marchid: begin
                    csr_output_value = marchid;
                end
                `csr_mimpid: begin
                    csr_output_value = mimpid;
                end
                `csr_mhartid: begin
                    csr_output_value = mhartid;
                end
                `csr_misa: begin
                    csr_output_value = misa;
                end
                `csr_mstatus: begin
                    csr_output_value = make_mstatus(mstatus_tsr,
                                                    mstatus_tw,
                                                    mstatus_tvm,
                                                    mstatus_mxr,
                                                    mstatus_sum,
                                                    mstatus_mprv,
                                                    mstatus_xs,
                                                    mstatus_fs,
                                                    mstatus_mpp,
                                                    mstatus_spp,
                                                    mstatus_mpie,
                                                    mstatus_spie,
                                                    mstatus_upie,
                                                    mstatus_mie,
                                                    mstatus_sie,
                                                    mstatus_uie);
                    csr_written_value = evaluate_csr_funct3_operation(decoder_funct3, csr_output_value, csr_input_value);
                    if(csr_writes) begin
                        mstatus_mpie = csr_written_value[7];
                        mstatus_mie = csr_written_value[3];
                    end
                end
                `csr_mie: begin
                    csr_output_value = 0;
                    csr_output_value[11] = mie_meie;
                    csr_output_value[9] = mie_seie;
                    csr_output_value[8] = mie_ueie;
                    csr_output_value[7] = mie_mtie;
                    csr_output_value[5] = mie_stie;
                    csr_output_value[4] = mie_utie;
                    csr_output_value[3] = mie_msie;
                    csr_output_value[1] = mie_ssie;
                    csr_output_value[0] = mie_usie;
                    csr_written_value = evaluate_csr_funct3_operation(decoder_funct3, csr_output_value, csr_input_value);
                    if(csr_writes) begin
                        mie_meie = csr_written_value[11];
                        mie_mtie = csr_written_value[7];
                        mie_msie = csr_written_value[3];
                    end
                end
                `csr_mtvec: begin
                    csr_output_value = mtvec;
                end
                `csr_mscratch: begin
                    csr_output_value = mscratch;
                    csr_written_value = evaluate_csr_funct3_operation(decoder_funct3, csr_output_value, csr_input_value);
                    if(csr_writes)
                        mscratch = csr_written_value;
                end
                `csr_mepc: begin
                    csr_output_value = mepc;
                    csr_written_value = evaluate_csr_funct3_operation(decoder_funct3, csr_output_value, csr_input_value);
                    if(csr_writes)
                        mepc = csr_written_value;
                end
                `csr_mcause: begin
                    csr_output_value = mcause;
                    csr_written_value = evaluate_csr_funct3_operation(decoder_funct3, csr_output_value, csr_input_value);
                    if(csr_writes)
                        mcause = csr_written_value;
                end
                `csr_mip: begin
                    csr_output_value = 0;
                    csr_output_value[11] = mip_meip;
                    csr_output_value[9] = mip_seip;
                    csr_output_value[8] = mip_ueip;
                    csr_output_value[7] = mip_mtip;
                    csr_output_value[5] = mip_stip;
                    csr_output_value[4] = mip_utip;
                    csr_output_value[3] = mip_msip;
                    csr_output_value[1] = mip_ssip;
                    csr_output_value[0] = mip_usip;
                end
                endcase
                if(csr_reads)
                    write_register(decoder_rd, csr_output_value);
            end
            else if((decode_action & (`decode_action_fence | `decode_action_fence_i | `decode_action_store | `decode_action_branch)) != 0) begin
                // do nothing
            end
        end
        endcase
    end

endmodule
