`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/27/2025 03:27:15 PM
// Design Name: 
// Module Name: FND_TOP
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

module periph_fnd (
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
    output logic [3:0] fndCom,
    output logic [7:0] fndFont
);

    logic [31:0] fndData;
    logic control;
    logic clk_out;

    apb_slave_interface_fnd U_APB_SLAVE_INTERFACE(
        .*,
        .control(control),
        .fndData(fndData)
    );

    clock_gate U_CLOCK_GATE(
        .clk_in(PCLK),    
        .enable(control),    
        .clk_out(clk_out)
    );

    fndController U_FND( 
        .clk(clk_out), .reset(PRESET),
        .fndData(fndData),
        .control(control),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );
endmodule 
     

module apb_slave_interface_fnd (
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
    output logic        control,
    output logic [31:0] fndData 
);

    localparam START_ADDR = 4'h0;
    localparam FND_DATA_ADDR = 4'h4;

    logic [31:0] fndData_reg, start_reg; 

    assign fndData = fndData_reg;
    assign control = start_reg[0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            start_reg <= 0;
            fndData_reg <= 0;
        end else begin
            PREADY <= 1'b0; 

            if (PSEL && PENABLE && PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0])
                    START_ADDR: start_reg <= PWDATA;
                    FND_DATA_ADDR : fndData_reg <= PWDATA;
                    default:  ;
                endcase
            end else if (PSEL && PENABLE && !PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0])
                    START_ADDR: PRDATA <= start_reg;
                    FND_DATA_ADDR : PRDATA <= fndData_reg;
                    default:  PRDATA = 'x;
                endcase
            end
        end
    end
endmodule


module fndController ( 
    input clk, reset,
    input  [31:0] fndData,
    input  control,
    output [3:0] fndCom,
    output [7:0] fndFont
);

    wire [3:0] digit_1, digit_10, digit_100, digit_1000;
    wire [3:0] bcdData;
    wire [1:0] digit_sel;
    wire tick_1KHz;


    counter_2bit U_Counter_2bit (
        .clk  (clk),
        .reset(reset),
        .tick (tick_1KHz),
        .count(digit_sel)
    );

    clk_div_fnd U_ClkDivFnd (
        .clk  (clk),
        .reset(reset),
        .tick (tick_1KHz)
    );

    digit_splitter U_DigitSplitter (
        .digit(fndData),
        .digit_1   (digit_1),
        .digit_10  (digit_10),
        .digit_100 (digit_100),
        .digit_1000(digit_1000)
    );

    mux_4x1 U_MUX_4X1 (
        .sel(digit_sel),
        .x0(digit_1),
        .x1(digit_10),
        .x2(digit_100),
        .x3(digit_1000),
        .y(bcdData)
    );

    decoder_2x4 U_Decoder_2x4 (
        .x(digit_sel),
        .control(control),
        .y(fndCom)
    );

    BCDtoSEG_decoder U_BcdToSeg (
        .bcd(bcdData), .sel(digit_sel),
        .seg(fndFont)
    );

endmodule

