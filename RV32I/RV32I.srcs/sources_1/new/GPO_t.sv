`timescale 1ns / 1ps


module GPO_t(
    input  logic PCLK,
    input  logic PRESET,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic PWRITE,
    input  logic PENABLE,
    input  logic PSEL,
    output  logic PRDATA,
    output logic  PREADY,
    output logic  GPO0,
    output logic  GPO1,
    output logic  GPO2,
    output logic  GPO3,
    output logic  GPO4,
    output logic  GPO5,
    output logic  GPO6,
    output logic  GPO7


    );

    logic [7:0] gpo_data_reg;
    logic [7:0] gpo_ctrl_reg;

    logic apb_write_en;
    assign apb_write_en = PSEL & PENABLE & PWRITE;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            gpo_data_reg <= 8'b0;
            gpo_ctrl_reg <= 8'b0;

        end else if (apb_write_en) begin
            case (PADDR[7:0])
                8'h00: gpo_data_reg <= PWDATA[7:0];
                8'h00: gpo_ctrl_reg <= PWDATA[7:0];
                default: ;


            endcase
        end
    end


    logic [7:0] final_gpo_out;
    assign final_gpo_out = gpo_data_reg & gpo_ctrl_reg;

    assign {GPO7, GPO6, GPO5, GPO4, GPO3, GPO2, GPO1, GPO0} = final_gpo_out;

    assign PREADY = 1'b1;


endmodule
