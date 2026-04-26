//`timescale 1ns / 1ps
//
//
//
//module Slave_Top(
//    input logic clk,
//    input logic reset_n,
//    output logic [7:0] led,
//    input logic scl,
//    inout logic sda
//    );
//    logic reset;
//    assign reset = !reset_n;
//
//    logic [7:0] rx_data;
//    logic rx_valid;
//
//    I2C_Slave u_i2c_slave_inst (
//        .clk(clk),
//        .reset(reset),
//        .slave_addr(7'h50), // 슬레이브 주소 설정
//        .rx_data(rx_data),
//        .rx_valid(rx_valid),
//        .tx_data(8'h00),    // 여기서는 Read 대응 안 함
//        .scl(scl),
//        .sda(sda)
//    );
//
//    always_ff @(posedge clk) begin
//        if (reset) led <= 8'h00;
//        else if (rx_valid) led <= rx_data;
//    end
//endmodule


`timescale 1ns / 1ps

module Slave_Top(
    input  logic clk,
    input  logic reset,   // 보드의 리셋 버튼 (U18 등)
    output logic [7:0] led, // 마스터가 Write한 데이터를 표시할 LED
    input  logic scl,       // 마스터로부터 받는 SCL
    inout  wire  sda        // ★ 반드시 wire로 선언 (IOBUF 처리)
);

    // ★ 보드의 버튼 극성에 맞게 수정 (Basys3처럼 누를 때 1이면 아래처럼)
    //logic reset;
    //assign reset = reset_n; 

    logic [7:0] rx_data;
    logic rx_valid;

    // --- I2C 슬레이브 인스턴스 ---
    I2C_Slave u_i2c_slave_inst (
        .clk(clk),
        .reset(reset),
        .slave_addr(7'h50), // 슬레이브 주소
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .tx_data(8'h55),    // ★ 마스터가 Read(읽기)를 요청하면 보낼 데이터!
        .scl(scl),
        .sda(sda)
    );

    // --- 수신 데이터 LED 출력 (마스터가 Write 했을 때 동작) ---
    always_ff @(posedge clk) begin
        if (reset) led <= 8'h00;
        else if (rx_valid) led <= rx_data;
    end

endmodule