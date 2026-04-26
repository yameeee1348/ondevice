`timescale 1ns / 1ps
`include "define.vh"


module RV32_CPU (
    input               clk,
    input               rst,
    input  logic [31:0] instr_data,
    input        [31:0] bus_rdata,
    output       [31:0] instr_addr,
    input               bus_ready,
    output              bus_wreq,
    output              bus_rreq,
    output       [ 2:0] o_funct3,
    output       [31:0] bus_addr,
    output       [31:0] bus_wdata


);
    logic pc_en, rf_we, alu_src, jalr_sel, jal_sel;
    logic branch;
    logic [3:0] alu_control;
    logic [2:0] rfwd_src;


    control_unit U_CONTR_UNIT (

        .clk(clk),
        .rst(rst),
        .funct7(instr_data[31:25]),
        .funct3(instr_data[14:12]),
        .opcode(instr_data[6:0]),
        .ready(bus_ready),
        .rf_we(rf_we),
        .alu_control(alu_control),
        .alu_src(alu_src),
        .rfwd_src(rfwd_src),
        .o_funct3(o_funct3),
        .branch(branch),
        .jalr_sel(jalr_sel),
        .jal_sel(jal_sel),
        .pc_en(pc_en),
        .dwe(bus_wreq),
        .dre(bus_rreq)

    );


    rv32i_datapath U_DATAPATH (
        .*
    );



endmodule





module control_unit (
    input              clk,
    input              rst,
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    input              ready,
    output logic       pc_en,
    output logic       alu_src,
    output logic       rf_we,
    output logic       branch,
    output logic [2:0] o_funct3,
    output logic [3:0] alu_control,
    output logic [2:0] rfwd_src,
    output logic       jalr_sel,
    output logic       jal_sel,
    output logic       dwe,
    output logic       dre





);

    typedef enum logic [3:0] {
        FETCH,
        DECODE,
        EXECUTE,
        EX_R,
        EX_I,
        EX_S,
        EX_B,
        EX_L,
        EX_J,
        EX_JL,
        EX_U,
        EX_UA,
        MEM,
        MEM_S,
        MEM_L,
        WB
    } state_e;

    state_e c_state, n_state;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= FETCH;
        end else begin
            c_state <= n_state;
        end
    end

    always_comb begin

        n_state = c_state;
        case (c_state)
            FETCH: begin

                n_state = DECODE;
            end
            DECODE: begin

                n_state = EXECUTE;
            end

            EXECUTE: begin
                case (opcode)
                    `JAL_type,`JALR_type,`AUIPC_type,`LUI_type,`B_type,`I_type,`R_type: begin
                        n_state = FETCH;
                    end
                    `S_type: begin
                        n_state = MEM;
                    end
                    `IL_type: begin
                        n_state = MEM;
                    end

                endcase
            end
            MEM: begin
                case (opcode)
                    `S_type: begin
                        if (ready) begin
                            n_state = FETCH;
                        end
                    end  
                    `IL_type: n_state = WB;

                endcase
            end
            WB: begin
                if (ready) begin
                    
                n_state = FETCH;
                end
            end

           




        endcase
    end




    //output
    always_comb begin
        pc_en       = 1'b0;
        rf_we       = 0;
        jal_sel     = 1'b0;
        jalr_sel    = 1'b0;
        branch      = 1'b0;
        alu_src     = 1'b0;
        alu_control = 4'b0000;
        rfwd_src    = 3'b000;
        o_funct3    = 3'b0;
        dwe         = 1'b0;
        dre         = 1'b0;

        case (c_state)
            FETCH: begin
                pc_en = 1'b1;


            end
            DECODE: begin


            end

            EXECUTE: begin
                case (opcode)
                    `R_type: begin
                        rf_we       = 1'b1;
                        alu_src     = 1'b0;
                        alu_control = {funct7[5], funct3};
                    end
                    `I_type: begin
                        rf_we   = 1'b1;
                        alu_src = 1'b1;
                        if (funct3 == 3'b101) alu_control = {funct7[5], funct3};
                        else alu_control = {1'b0, funct3};


                    end
                    `B_type: begin
                        branch      = 1'b1;
                        alu_src     = 1'b0;
                        alu_control = {1'b0, funct3};

                    end
                    `IL_type: begin
                        alu_control = 4'b0000;
                        alu_src     = 1'b1;

                    end
                    `S_type: begin
                        alu_src     = 1'b1;
                        alu_control = 4'b0000;

                    end
                    `LUI_type: begin
                        rf_we    = 1;
                        rfwd_src = 3'b010;

                    end
                    `AUIPC_type: begin
                        rf_we    = 1;
                        rfwd_src = 3'b011;

                    end
                    `JAL_type, `JALR_type: begin
                        rf_we   = 1;
                        jal_sel = 1;
                        if (opcode == `JALR_type) jalr_sel = 1;
                        else jalr_sel = 0;
                        rfwd_src = 3'b100;

                    end

                endcase
            end
            MEM: begin
                o_funct3 = funct3;
                if (opcode == `S_type) dwe = 1'b1;
                //if (opcode == `IL_type) dre = 1'b1;
                else dre = 1'b1;
            end
            WB: begin
                rf_we = 1'b1;
                rfwd_src = 3'b001;
            end
          
        endcase
    end

   

endmodule





