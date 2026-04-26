`timescale 1ns / 1ps
`include "define.vh"


module RV32_CPU (
    input               clk,
    input               rst,
    input  logic [31:0] instr_data,
    input        [31:0] drdata,
    output       [31:0] instr_addr,
    output              dwe,
    output       [ 2:0] o_funct3,
    output       [31:0] daddr,
    output       [31:0] dwdata

);
    logic rf_we, alu_src,jalr_sel,jal_sel;
    logic branch;
    logic [3:0] alu_control;
    logic [2:0] rfwd_src;

    control_unit U_CONTR_UNIT (


        .funct7(instr_data[31:25]),
        .funct3(instr_data[14:12]),
        .opcode(instr_data[6:0]),
        .rf_we(rf_we),
        .alu_control(alu_control),
        .alu_src(alu_src),
        .rfwd_src(rfwd_src),
        .o_funct3(o_funct3),
        .dwe(dwe),
        .branch(branch),
        .jalr_sel(jalr_sel),
        .jal_sel(jal_sel)
    );


    rv32i_datapath U_DATAPATH (.*);



endmodule





module control_unit (
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    output logic       alu_src,
    output logic       rf_we,
    output logic       branch,
    output logic [2:0] o_funct3,
    output logic       dwe,
    output logic [3:0] alu_control,
    output logic [2:0] rfwd_src,
    output logic       jalr_sel,
    output logic       jal_sel
     


);


    always_comb begin
        rf_we       = 0;
        alu_control = 4'b0000;
        alu_src     = 1'b0;
        dwe         = 1'b0;
        rfwd_src    = 3'b000;
        o_funct3    = 3'b0;
        branch      = 1'b0;
        jalr_sel    = 1'b0;
        jal_sel     = 1'b0;

        case (opcode)
            `R_type: begin
                rf_we       = 1;
                alu_src     = 1'b0;
                alu_control = {funct7[5], funct3};
                dwe         = 1'b0;
                rfwd_src    = 3'b000;
                o_funct3    = 3'b0;
                branch      = 1'b0;
                
            end
            `B_type: begin
                rf_we       = 0;
                alu_src     = 1'b0;
                alu_control = {1'b1, funct3}; 
                rfwd_src    = 3'b000;
                dwe         = 1'b0;
                o_funct3    = funct3;
                branch      = 1'b1;
                
            end
            `S_type: begin
                rf_we       = 0;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                dwe         = 1'b1;
                rfwd_src    = 3'b000;
                branch      = 1'b0;
                o_funct3    = funct3;
                

            end
            `IL_type: begin
                rf_we       = 1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                branch      = 1'b0;
                rfwd_src    = 3'b001;
                dwe         = 1'b0;
                o_funct3    = funct3;
                
            end
            `I_type: begin
                rf_we   = 1;
                branch      = 1'b0;
                alu_src = 1'b1;
                if (funct3 == 3'b101) 
                alu_control = {funct7[5], funct3};
                else alu_control = {1'b0, funct3};
                rfwd_src = 3'b000;
                dwe      = 1'b0;
                o_funct3 = funct3;
                
            end

            `LUI_type: begin
                rf_we       = 1;
                alu_src     = 1'b1;
                alu_control = 4'b1111;
                branch      = 1'b0;
                rfwd_src    = 3'b010;
                dwe         = 1'b0;
               
                
            end
            `AUIPC_type: begin
                rf_we       = 1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                branch      = 1'b0;
                rfwd_src    = 3'b011;  // ★ 수정: ALU 결과(PC+Imm)를 레지스터로 보내야 하므로 0
                dwe         = 1'b0;
                o_funct3 = funct3;
            end
            `JAL_type : begin
                rf_we       = 1;
                alu_src     = 1'b0;
                alu_control = 4'b1110;
                branch      = 1'b0;
                rfwd_src    = 3'b100;
                dwe         = 1'b0;
                jal_sel     = 1'b1;
            end
            `JALR_type : begin
                rf_we       = 1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                branch      = 1'b0;
                rfwd_src    = 3'b100;
                dwe         = 1'b0;
                jalr_sel    = 1'b1;
                jal_sel     = 1'b1;
               
            end
            default: begin
                
            rf_we = 0;
            dwe =0;
            branch = 0;        
            end 
        endcase

    end

endmodule



