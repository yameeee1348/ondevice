`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/26/2025 10:37:55 AM
// Design Name: 
// Module Name: GPI
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
 
module periph_gpi (
    input  logic        PCLK,     // APB CLK
    input  logic        PRESET,   // APB asynchronous RESET
    // APB Interface Signals
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // Internal Signals
    input logic [7:0] inport
);

    logic [7:0] control;
    logic [7:0] data;

    apb_slave_interface_gpi U_APB_SLAVE_INTERFACE(
        .*,
        .ddr(control),
        .idr(data)
    );
   
    gpi U_GPI(
        .control(control),
        .data(data),
        .inport(inport)
    );

endmodule 


module apb_slave_interface_gpi (
    input  logic        PCLK,     // APB CLK
    input  logic        PRESET,   // APB asynchronous RESET
    // APB Interface Signals
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // Internal Signals
    output logic [7:0] ddr,
    input  logic [31:0] idr
);

    localparam DDR_ADDR = 4'h0;
    localparam IDR_ADDR = 4'h4;

    logic [31:0] dd_reg, id_reg;
    
    assign ddr = dd_reg[7:0];
    assign id_reg = {24'b0, idr[7:0]};

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            dd_reg <= 0;
        end else begin
            PREADY <= 1'b0;

            if (PSEL && PENABLE && PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0])
                    DDR_ADDR: dd_reg <= PWDATA;
                    IDR_ADDR: ;
                    default:  ;
                endcase
            end else if (PSEL && PENABLE && !PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0])
                    DDR_ADDR: PRDATA <= dd_reg;
                    IDR_ADDR: PRDATA <= id_reg;
                    default:  PRDATA = 'x;
                endcase
            end
        end
    end
endmodule
 

module gpi (
    input logic [7:0] control,
    input logic [7:0] inport,
    output logic [7:0] data
);

    genvar i;
    generate
        for(i = 0; i < 8; i++) begin
            assign data[i] = control[i] ? inport[i] : 'z;
        end
    endgenerate

endmodule