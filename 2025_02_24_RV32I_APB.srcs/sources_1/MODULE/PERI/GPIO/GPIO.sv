`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/26/2025 02:01:28 PM
// Design Name: 
// Module Name: GPIO
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

module periph_gpio (
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
    inout  logic [ 7:0] io_data
);

    logic [7:0] control;
    logic [7:0] data_in, data_out;

    apb_slave_interface_gpio U_APB_SLAVE_INTERFACE (
        .*,
        .ddr(control),
        .idr(data_in),
        .odr(data_out)
    );


    gpio U_GPIO (
        .control (control),
        .in_data (data_in),
        .out_data(data_out),
        .io_data (io_data)
    );



endmodule


module apb_slave_interface_gpio (
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
    output logic [ 7:0] ddr,
    input  logic [ 7:0] idr,
    output logic [ 7:0] odr 
);

    localparam DDR_ADDR = 4'h0;
    localparam IDR_ADDR = 4'h4;
    localparam ODR_ADDR = 4'h8;

    logic [31:0] dd_reg, id_reg, od_reg;

    assign ddr    = dd_reg[7:0]; 
    assign id_reg = {24'b0, idr[7:0]};
    assign odr    = od_reg[7:0];

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
                    IDR_ADDR: ;
                    ODR_ADDR: od_reg <= PWDATA; 
                    default:  ;
                endcase
            end else if (PSEL && PENABLE && !PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0])
                    DDR_ADDR: PRDATA <= dd_reg;
                    IDR_ADDR: PRDATA <= id_reg;
                    ODR_ADDR: PRDATA <= od_reg;
                    default:  PRDATA = 'x;
                endcase
            end
        end
    end
endmodule


module gpio (
    input  logic [7:0] control,
    input  logic [7:0] out_data,
    output logic [7:0] in_data,
    inout  logic [7:0] io_data
);

    genvar i;

    generate
        for (i = 0; i < 8; i++) begin
            assign io_data[i] = control[i] ? out_data[i] : 1'bz;
            assign in_data[i] = control[i] ? 1'b0 : io_data[i];
        end
    endgenerate

endmodule
