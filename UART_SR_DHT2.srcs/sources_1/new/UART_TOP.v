`timescale 1ns / 1ps



module UART_TOP (
    input        clk,
    input        rst,
    input        uart_rx,
    input        i_tx_start_req, 
    input  [7:0] i_tx_data_req, 
    output       uart_tx,  
    output       o_tx_busy,      //
    output       o_rx_done,      // 데
    output [7:0] o_rx_data       // 
);

    // 내부 와이어 연결 (SENDER -> UART_PHY)
    wire       w_tx_start_to_phy;
    wire [7:0] w_tx_data_to_phy;

    // 1. ASCII Sender: 송신 요청을 받아 Busy를 체크하고 실제 UART로 전달
    ascii_sender U_SENDER (
        .clk       (clk),
        .rst       (rst),
        .i_req     (i_tx_start_req),
        .i_data    (i_tx_data_req),
        .i_tx_busy (o_tx_busy),
        .o_tx_start(w_tx_start_to_phy),
        .o_tx_data (w_tx_data_to_phy)
    );

    // 2. UART Physical Layer: 실제 비트 단위 전송 및 수신 처리
    top_uart U_UART_PHY (
        .clk     (clk),
        .rst     (rst),
        .uart_rx (uart_rx),
        .uart_tx (uart_tx),
        .tx_start(w_tx_start_to_phy),
        .tx_data (w_tx_data_to_phy),
        .tx_busy (o_tx_busy),
        .rx_done (o_rx_done),
        .rx_data (o_rx_data)
    );

endmodule