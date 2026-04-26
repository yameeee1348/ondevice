`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/05/2025 05:16:43 PM
// Design Name: 
// Module Name: UART_TOP
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


module UART_TOP(
    input clk, reset, 
    input [31:0] prescaler,
    input [31:0] prescaler_16,
    input start,
    input [7:0] tx_data,
    input  rx,
    output tx,
    output [7:0]rx_data,
    output tx_busy, tx_done,
    output rx_busy, rx_done
    );


    wire w_tick, w_tick_16;


    tick_generator U_TICK_TX
    (
        .clk(clk), .reset(reset),
        .prescaler(prescaler),
        .clk_out(w_tick)
    );

    tick_generator U_TICK_TX_16
    (
        .clk(clk), .reset(reset),
        .prescaler(prescaler_16),
        .clk_out(w_tick_16)
    );


    TRANSMITTER U_TRANSMITTER(
    .clk(clk), .reset(reset),
    .start(start), .br_tick(w_tick), .br_tick_16_divide(w_tick_16),
    .tx_DATA(tx_data),
    .tx_busy(tx_busy), .tx_done(tx_done),
    .tx(tx)
    );

    RECEIVER U_RECEIVER(
    .clk(clk), .reset(reset),
    .rx_data(rx), .br_tick(w_tick), .br_tick_16_divide(w_tick_16),
    .rx_done(rx_done), .rx_busy(rx_busy),
    .rx(rx_data)
    );


endmodule
