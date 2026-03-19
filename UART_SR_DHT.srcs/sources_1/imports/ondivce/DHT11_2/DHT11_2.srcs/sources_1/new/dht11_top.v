`timescale 1ns / 1ps

module dht11_top (
    input clk,            
    input rst,            // 중앙 버튼 (btnC) - 리셋
    input btnL,           // 왼쪽 버튼 (btnL) - 측정 시작
    inout dhtio,          // DHT11 데이터 핀
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output [2:0] debug_led,
    output [23:0] dht11_fnd_data,  // 체크섬 통과 시 점등
    output valid_led    
);

    // 내부 연결용 와이어
    wire [15:0] w_humidity, w_temperature;
    
    wire w_done, w_valid;
    assign dht11_fnd_data = {w_temperature[15:11], w_temperature[10:5], w_humidity[15:10], w_humidity[9:3]};

  
   

    // --- 2. DHT11 Controller 인스턴스 ---
    dht11_ctrl U_DHT_CTRL (
        .clk(clk),
        .rst(rst),
        .start(),      // 디바운싱된 버튼 신호 연결
        .humidity(w_humidity),
        .temperature(w_temperature),
        .DHT11_done(w_done),
        .DHT11_valid(w_valid),
        .debug(debug_led),
        .dhtio(dhtio)
    );

   

    // 유효성 확인 LED 연결
    assign valid_led = w_valid;

endmodule