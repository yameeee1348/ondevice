`timescale 1ns / 1ps


module Top_SingleBoard_Test(
        input logic  clk,
        input logic reset,
        input logic [3:0] btn,

        input  logic [7:0] sw,        
        output logic [7:0] led,
        output logic jb_sclk,
        output logic jb_mosi,
        output logic jb_cs_n,
        input logic jb_miso,

        input logic jc_sclk,
        input logic jc_mosi,
        input logic jc_cs_n,
        output logic jc_miso,

        output logic [3:0] fnd_digit,
        output logic [7:0] fnd_data
    );

    // 1. 마스터 인스턴스 (JB 포트로 신호 출력)
    Top_Master u_master (
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .led(led),
        .sclk(jb_sclk),
        .mosi(jb_mosi),
        .cs_n(jb_cs_n),
        .miso(jb_miso)
    );

    // 2. 슬레이브 인스턴스 (JC 포트에서 신호 수신)
    Top_Slave u_slave (
        .clk(clk),
        .reset(reset),
        .sclk(jc_sclk),
        .sw(sw),
        .mosi(jc_mosi),
        .cs_n(jc_cs_n),
        .miso(jc_miso),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );
endmodule
