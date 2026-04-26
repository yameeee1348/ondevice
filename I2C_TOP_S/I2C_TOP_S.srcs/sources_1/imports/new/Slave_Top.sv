//
//`timescale 1ns / 1ps
//
//module Slave_Top(
//    input  logic clk,
//    input  logic reset,    // 가운데 버튼 (U18)
//    output logic [7:0] led,  // 수신 데이터 표시용 LED
//    input  logic jc_scl,     // 슬레이브 SCL 입력
//    inout  wire  jc_sda      // 슬레이브 SDA 양방향
//);
//    //logic reset;
//    //assign reset = reset_n; 
//
//    logic [7:0] rx_data;
//    logic rx_valid;
//
//    // --- I2C 슬레이브 인스턴스 ---
//    I2C_Slave u_slave (
//        .clk(clk), 
//        .reset(reset),
//        .slave_addr(7'h50),
//        .rx_data(rx_data), 
//        .rx_valid(rx_valid),
//        .scl(jc_scl), 
//        .sda(jc_sda), 
//        .tx_data(8'h00) // 마스터가 Read를 요청할 때 줄 값 (지금은 안 씀)
//    );
//
//    // --- 수신 데이터 LED 출력 ---
//    always_ff @(posedge clk) begin
//        if (reset) led <= 8'h00;
//        else if (rx_valid) led <= rx_data;
//    end
//endmodule


`timescale 1ns / 1ps

module Slave_Top(
    input  logic clk,
    input  logic reset,       // 가운데 버튼 (U18)
    input  logic [7:0] switch,  // ★ 추가: 슬레이브 보드의 스위치 입력 (SW0~SW7)
    output logic [7:0] led,     // 마스터가 Write한 데이터를 표시할 LED
    input  logic scl,           // 마스터로부터 받는 SCL
    inout  wire  sda            // 반드시 wire로 선언
);

  //  logic reset;
  //  assign reset = reset_n; 

    logic [7:0] rx_data;
    logic rx_valid;

    // --- 스위치 입력 레지스터 (안정성을 위한 동기화) ---
    logic [7:0] switch_reg;
    always_ff @(posedge clk) begin
        if (reset) switch_reg <= 8'h00;
        else       switch_reg <= switch;
    end

    // --- I2C 슬레이브 인스턴스 ---
    I2C_Slave u_i2c_slave_inst (
        .clk(clk),
        .reset(reset),
        .slave_addr(7'h50),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .tx_data(switch_reg), // ★ 고정값(8'h77) 대신 슬레이브의 스위치 값을 전달!
        .scl(scl),
        .sda(sda)
    );

    // --- 수신 데이터 LED 출력 (마스터가 Write 했을 때 동작) ---
    always_ff @(posedge clk) begin
        if (reset) led <= 8'h00;
        else if (rx_valid) led <= rx_data;
    end

endmodule