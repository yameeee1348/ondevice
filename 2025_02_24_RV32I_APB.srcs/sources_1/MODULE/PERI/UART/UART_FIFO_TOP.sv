`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/07/2025 04:11:54 PM
// Design Name: 
// Module Name: UART_FIFO_TOP
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

module periph_uart (
    input  logic        PCLK,          // APB CLK
    input  logic        PRESET,        // APB asynchronous RESET
    // APB Interface Signals
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    input  logic        start_button,
    // Internal Signals
    input  logic        rx,
    output logic        tx
);

    logic [31:0] prescaler;
    logic [31:0] prescaler_16;
    logic [7:0] tx_data, rx_data;
    logic control, clk_out;

    assign prescaler_16 = prescaler / 16;

    
    apb_slave_interface_uart U_APB_SLAVE_INTERFACE (
        .*,
        .control(control),
        .prescaler(prescaler),
        .tx_data(tx_data),
        .rx_data(rx_data)
    );

    clock_gate U_CLOCK_GATE (
        .clk_in (PCLK),
        .enable (control),
        .clk_out(clk_out)
    );

    UART_FIFO_TOP U_UART (
        .clk(clk_out),
        .reset(PRESET),
        .start(start_button),
        .prescaler(prescaler),
        .prescaler_16(prescaler_16),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .rx(rx),
        .tx(tx)
    );
endmodule


module apb_slave_interface_uart (
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
    output logic [31:0] prescaler,
    output logic [ 7:0] tx_data,
    input  logic [ 7:0] rx_data
);

    localparam START_ADDR = 4'h0;
    localparam PRESCALER_ADDR = 4'h4;
    localparam TX_ADDR = 4'h8;
    localparam RX_ADDR = 4'hc;

    logic [31:0] start_reg, prescaler_reg, rx_reg, tx_reg;

    assign control = start_reg[0];
    assign prescaler = prescaler_reg;
    assign tx_data = tx_reg[7:0];
    assign rx_reg  = {24'b0, rx_data};

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            start_reg <= 0; 
            prescaler_reg <= 0;
            tx_reg <= 0;   
        end else begin
            PREADY <= 1'b0;

            if (PSEL && PENABLE && PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0])
                    START_ADDR: start_reg <= PWDATA;
                    PRESCALER_ADDR: prescaler_reg <= PWDATA;
                    TX_ADDR: tx_reg <= PWDATA;
                    default: ;
                endcase
            end else if (PSEL && PENABLE && !PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0])
                    START_ADDR: PRDATA <= start_reg;
                    PRESCALER_ADDR: PRDATA <= prescaler_reg;
                    RX_ADDR: PRDATA <= rx_reg;
                    default: PRDATA = 'x;
                endcase
            end
        end
    end
endmodule


module UART_FIFO_TOP (
    input clk,
    input reset,
    input start,
    input [31:0] prescaler,
    input [31:0] prescaler_16,
    input [7:0] tx_data,
    output [7:0] rx_data,
    input rx,
    output tx
);

    wire [7:0] w_tx_data, w_rx_data;
    wire w_empty, w_full;
    wire w_start;


    wire [7:0] w_fifo_data;

    wire w_tx_busy, w_rx_done;

    /*
    FIFO U_TX_FIFO(
    .clk(clk), .reset(reset),
    .wData(tx_data),
    .wr_en(1),
    .full(),
    .rData(w_tx_data),
    .rd_en(1),
    .empty()
    );
*/

    UART_TOP U_UART (
        .clk(clk),
        .prescaler(prescaler),
        .prescaler_16(prescaler_16),
        .reset(reset),
        .start(start),
        .tx_data(tx_data),
        .rx(rx),
        .tx(tx),
        .rx_data(rx_data),
        .tx_busy(),
        .tx_done(),
        .rx_busy(),
        .rx_done()
    );

    /*
    FIFO U_RX_FIFO(
    .clk(clk), .reset(reset),
    .wData(rx_data),
    .wr_en(1),
    .full(),
    .rData(rx_data),
    .rd_en(1),
    .empty()
    ); 
    */
endmodule
