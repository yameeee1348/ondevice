//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/25/2025 10:32:10 AM
// Design Name: 
// Module Name: tb_APB
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


`timescale 1ns / 1ps

module tb_apb_master ();
    logic        PCLK;  // APB Clock
    logic        PRESET;  // APB 비동기 RESET

    logic        PENABLE;
    logic        PWRITE;
    logic [31:0] PADDR;
    logic [31:0] PWDATA;

    logic        PSEL_RAM;
    logic        PSEL_GPO;
    logic        PSEL_GPI;
    logic        PSEL_GPIO;

    logic [31:0] PRDATA_RAM;
    logic [31:0] PRDATA_GPO;
    logic [31:0] PRDATA_GPI;
    logic [31:0] PRDATA_GPIO;

    logic        PREADY_RAM;
    logic        PREADY_GPO;
    logic        PREADY_GPI;
    logic        PREADY_GPIO;


    logic        write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        req;
    logic        ready;

    APB_Master_Interface dut (.*);


always #5 PCLK = ~PCLK;

    initial begin
        PCLK = 0; PRESET = 1;
        #10 PRESET = 0;
        @(posedge PCLK);
        #1;
        write = 1'b1; addr = 32'h1000_0000; wdata = 32'h0000_1111; req = 1'b1;
        @(posedge PCLK);
        #1;
        req = 1'b0;
        @(PSEL_RAM && PENABLE); PREADY_RAM = 1;
        @(posedge PCLK); PREADY_RAM = 0;
    end
endmodule
