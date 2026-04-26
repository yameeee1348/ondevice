`timescale 1ns / 1ps



module fnd_controller_dht (
    input            clk,
    input            rst,
    input      [7:0] humidity,    // DHT11의 습도 정수부
    input      [7:0] temperature, // DHT11의 온도 정수부
    output     [3:0] fnd_digit,
    output     [7:0] fnd_data
);

    wire [3:0] w_hum_10, w_hum_1;
    wire [3:0] w_temp_10, w_temp_1;
    wire [3:0] w_mux_out;
    wire [1:0] w_sel;
    wire       w_1khz;

    // 1. 습도와 온도를 각각 자릿수별로 분리
    // [습도10][습도1][온도10][온도1] 형태로 배치하기 위함
    digit_spliter_dht U_digit_spl (
        .hum_in(humidity),
        .temp_in(temperature),
        .hum_10(w_hum_10),   // FND digit 3 (가장 왼쪽)
        .hum_1(w_hum_1),     // FND digit 2
        .temp_10(w_temp_10), // FND digit 1
        .temp_1(w_temp_1)    // FND digit 0 (가장 오른쪽)
    );

    clk_div_DHT U_clk_div (
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );

    counter_4 U_counter_4 (
        .clk(w_1khz),
        .rst(rst),
        .digit_sel(w_sel)
    );

    decoder_2to4_DHT U_decoder_2x4 (
        .digit_sel(w_sel),
        .fnd_digit(fnd_digit)
    );

    // 2. 선택된 자리에 맞는 데이터를 출력
    mux_4x1 U_mux_4 (
        .sel(w_sel),
        .digit_1(w_temp_1),   // AN0 자리
        .digit_10(w_temp_10),  // AN1 자리
        .digit_100(w_hum_1),   // AN2 자리
        .digit_1000(w_hum_10), // AN3 자리
        .mux_out(w_mux_out)
    );

    bcd_DHT U_BCD (
        .bcd(w_mux_out),
        .fnd_data(fnd_data)
    );
endmodule


module clk_div_DHT (
    input clk,
    input rst,
    output reg o_1khz
);

    reg [$clog2(100_000):0] counter_r;



    always @(posedge clk, posedge rst) begin

        if (rst) begin
            counter_r <= 0;
            o_1khz <= 1'b0;
        end else begin
            if (counter_r == 99_999) begin
                counter_r <= 0;
                o_1khz <= 1'b1;
            end else begin
                counter_r <= counter_r + 1;
                o_1khz <= 1'b0;
            end

        end


    end

endmodule


module counter_4 (

    input clk,
    input rst,
    output [1:0] digit_sel

);
    reg [1:0] counter_r;
    assign digit_sel = counter_r;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            //init counter_r
            counter_r <= 0;
        end else begin
            counter_r <= counter_r + 1;


        end

    end

endmodule





module decoder_2to4_DHT (
    input [1:0] digit_sel,
    output reg [3:0] fnd_digit
);


    always @(digit_sel) begin
        case (digit_sel)
            2'b00: fnd_digit = 4'b1110;
            2'b01: fnd_digit = 4'b1101;
            2'b10: fnd_digit = 4'b1011;
            2'b11: fnd_digit = 4'b0111;

        endcase
    end

endmodule



module mux_4x1 (

    input [1:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    output reg [3:0] mux_out

);


    always @(*) begin

        case (sel)

            2'b00: mux_out = digit_1;
            2'b01: mux_out = digit_10;
            2'b10: mux_out = digit_100;
            2'b11: mux_out = digit_1000;

        endcase

    end
endmodule

module bcd_DHT (
    input [3:0] bcd,
    output reg [7:0] fnd_data


);

    always @(bcd) begin
        case (bcd)
            4'd0: fnd_data = 8'hC0;
            4'd1: fnd_data = 8'hF9;
            4'd2: fnd_data = 8'hA4;
            4'd3: fnd_data = 8'hB0;
            4'd4: fnd_data = 8'h99;
            4'd5: fnd_data = 8'h92;
            4'd6: fnd_data = 8'h82;
            4'd7: fnd_data = 8'hF8;
            4'd8: fnd_data = 8'h80;
            4'd9: fnd_data = 8'h90;

            default: fnd_data = 8'hFF;
        endcase

    end
endmodule

module digit_spliter_dht (
    input  [7:0] hum_in,
    input  [7:0] temp_in,
    output [3:0] hum_10,
    output [3:0] hum_1,
    output [3:0] temp_10,
    output [3:0] temp_1
);
    // 습도 분리 (0~99)
    assign hum_10 = hum_in / 10;
    assign hum_1  = hum_in % 10;

    // 온도 분리 (0~99)
    assign temp_10 = temp_in / 10;
    assign temp_1  = temp_in % 10;
endmodule