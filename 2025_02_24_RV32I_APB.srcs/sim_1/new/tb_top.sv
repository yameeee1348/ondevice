`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/25/2025 02:03:47 PM
// Design Name: 
// Module Name: tb_top
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


module tb_top;

    logic clk, reset;
    logic rx, tx, button;

    MCU dut (
        .clk  (clk),
        .reset(reset),
        .uart_transmit_button(button),
        .rx(rx),
        .tx(tx)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1; button = 0;
        #10 reset = 0;
        #100000;
        button = 1;
        @(posedge clk);
        button = 0;
    end
endmodule
