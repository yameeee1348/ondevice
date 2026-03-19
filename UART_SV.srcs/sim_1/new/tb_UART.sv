`timescale 1ns / 1ps



interface U_interface;

    logic        clk;
    logic        rst;
    logic        uart_rx;
    logic  [7:0] tx_data;
    logic        tx_start;
    logic       rx_done;
    logic [7:0] rx_data;
    logic       uart_tx;
    logic      tx_busy;

endinterface //U_interface


module tb_UART();



TOP_UART dut (
    .clk(),
    .rst(),
    .uart_rx(),
    .tx_data(),
    .tx_start(),
    .rx_done(),
    .rx_data(),
    .uart_tx(),
    .tx_busy()
);
endmodule
