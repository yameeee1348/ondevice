`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/25/2025 03:07:35 PM
// Design Name: 
// Module Name: GPO
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

module periph_gpo (
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
    output logic [7:0] outport
);

    logic [7:0] control;
    logic [7:0] data;

    apb_slave_interface_gpo U_APB_SLAVE_INTERFACE(
        .*,
        .ddr(control),
        .odr(data)
    );
   
    gpo U_GPO(
    .control(control),
    .data(data),
    .outport(outport)
    );

endmodule

module apb_slave_interface_gpo (
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
    output logic [7:0] odr
);

    localparam DDR_ADDR = 4'h0;
    localparam ODR_ADDR = 4'h4;

    logic [31:0] dd_reg, od_reg;
    
    assign ddr = dd_reg[7:0];
    assign odr = od_reg[7:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            dd_reg <= 0;
            od_reg <= 0;
        end else begin
            PREADY <= 1'b0;

            if (PSEL && PENABLE && PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0]) 
                    DDR_ADDR: dd_reg <= PWDATA;
                    ODR_ADDR: od_reg <= PWDATA;
                    default:  ;
                endcase
            end else if (PSEL && PENABLE && !PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0])
                    DDR_ADDR: PRDATA <= dd_reg;
                    ODR_ADDR: PRDATA <= od_reg;
                    default:  PRDATA = 'x;
                endcase
            end
        end
    end
endmodule




module gpo (
    input logic [7:0] control,
    input logic [7:0] data,
    output logic [7:0] outport
);

    genvar i;
    generate
        for(i = 0; i < 8; i++) begin
            assign outport[i] = control[i] ? data[i] : 'z;
        end
    endgenerate

endmodule