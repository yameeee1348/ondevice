`timescale 1ns / 1ps

module dht11_top (
    input clk,            // Basys3 100MHz
    input rst,            // 중앙 버튼 (btnC) - 리셋
    input btnL,           // 왼쪽 버튼 (btnL) - 측정 시작
    inout dhtio,          // DHT11 데이터 핀
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output [2:0] debug_led,
    output valid_led      // 체크섬 통과 시 점등
);

    // 내부 연결용 와이어
    wire [15:0] w_humidity, w_temperature;
    wire w_btn_start;
    wire w_done, w_valid;

    // --- 1. 버튼 디바운스 및 엣지 검출 모듈 ---
    // btnL을 누르면 한 클락 동안만 1이 되는 w_btn_start 신호 생성
    btn_debounce U_BTN_DEBOUNCE (
        .clk(clk),
        .reset(rst),
        .i_btn(btnL),
        .o_btn(w_btn_start)
    );

    // --- 2. DHT11 Controller 인스턴스 ---
    dht11_ctrl U_DHT_CTRL (
        .clk(clk),
        .rst(rst),
        .start(w_btn_start),      // 디바운싱된 버튼 신호 연결
        .humidity(w_humidity),
        .temperature(w_temperature),
        .DHT11_done(w_done),
        .DHT11_valid(w_valid),
        .debug(debug_led),
        .dhtio(dhtio)
    );

    // --- 3. FND Controller 인스턴스 ---
    fnd_controller U_FND_CTRL (
        .clk(clk),
        .reset(rst),
        .humidity(w_humidity[15:8]),
        .temperature(w_temperature[15:8]),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

    // 유효성 확인 LED 연결
    assign valid_led = w_valid;

endmodule