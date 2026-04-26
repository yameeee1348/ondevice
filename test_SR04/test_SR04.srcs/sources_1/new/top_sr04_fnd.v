`timescale 1ns / 1ps

module top_sr04_fnd (
    input        clk,      // 100MHz
    input        rst,      // 보드 reset (active-high 가정)
    input        echo,     // SR04 ECHO (3.3V로 레벨시프팅 필수 권장)
    output       trigger,  // SR04 TRIG
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire [23:0] distance;

    // 네가 만든 초음파 모듈 (start=1로 계속 측정)
    SR04_t U_SR04_T (
        .clk     (clk),
        .rst     (rst),
        .echo    (echo),
        .trigger (trigger),
        .distance(distance)
    );

    // 0~9999로 saturate (FND 4자리)
    wire [13:0] dist_sat = (distance > 24'd9999) ? 14'd9999 : distance[13:0];

    // FND 표시 컨트롤러 (거리만 표시)
    fnd_controller_sr04 U_FND (
        .clk      (clk),
        .rst      (rst),
        .dist_bin (dist_sat),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

endmodule


module fnd_controller_sr04 (
    input        clk,
    input        rst,
    input  [13:0] dist_bin,     // 0~9999
    output [3:0]  fnd_digit,
    output [7:0]  fnd_data
);

    // 14bit binary -> 4-digit BCD
    wire [3:0] th, h, t, o;
    bin14_to_bcd4 U_BCD4 (
        .bin(dist_bin),
        .th (th),
        .h  (h),
        .t  (t),
        .o  (o)
    );

    // 1kHz scan tick
    wire w_1khz;
    clk_div_1khz U_DIV (
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );

    // digit select counter (0~3)
    reg [1:0] digit_sel;
    always @(posedge clk or posedge rst) begin
        if (rst) digit_sel <= 2'd0;
        else if (w_1khz) digit_sel <= digit_sel + 2'd1;
    end

    // digit enable (active-low 가정: 1110,1101,1011,0111)
    decoder_2to4 U_DEC (
        .digit_sel(digit_sel),
        .fnd_digit(fnd_digit)
    );

    // current digit value mux
    reg [3:0] cur_digit;
    always @(*) begin
        case (digit_sel)
            2'd0: cur_digit = o;   // 1의 자리
            2'd1: cur_digit = t;   // 10의 자리
            2'd2: cur_digit = h;   // 100의 자리
            2'd3: cur_digit = th;  // 1000의 자리
            default: cur_digit = 4'd0;
        endcase
    end

    // BCD -> 7seg
    bcd U_SEG (
        .bcd(cur_digit),
        .fnd_data(fnd_data)
    );

endmodule


module clk_div_1khz (
    input  clk,
    input  rst,
    output reg o_1khz
);
    // 100MHz / 1kHz = 100,000
    reg [$clog2(100_000)-1:0] cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt   <= 0;
            o_1khz <= 1'b0;
        end else begin
            if (cnt == 100_000-1) begin
                cnt   <= 0;
                o_1khz <= 1'b1;
            end else begin
                cnt   <= cnt + 1;
                o_1khz <= 1'b0;
            end
        end
    end
endmodule


module decoder_2to4 (
    input  [1:0] digit_sel,
    output reg [3:0] fnd_digit
);
    always @(*) begin
        case (digit_sel)
            2'b00: fnd_digit = 4'b1110;
            2'b01: fnd_digit = 4'b1101;
            2'b10: fnd_digit = 4'b1011;
            2'b11: fnd_digit = 4'b0111;
            default: fnd_digit = 4'b1110;
        endcase
    end
endmodule

module bcd (
    input  [3:0] bcd,
    output reg [7:0] fnd_data
);
    always @(*) begin
        case (bcd)
            4'd0:  fnd_data = 8'hC0;
            4'd1:  fnd_data = 8'hF9;
            4'd2:  fnd_data = 8'hA4;
            4'd3:  fnd_data = 8'hB0;
            4'd4:  fnd_data = 8'h99;
            4'd5:  fnd_data = 8'h92;
            4'd6:  fnd_data = 8'h82;
            4'd7:  fnd_data = 8'hF8;
            4'd8:  fnd_data = 8'h80;
            4'd9:  fnd_data = 8'h90;
            default: fnd_data = 8'hFF; // blank
        endcase
    end
endmodule

module bin14_to_bcd4(
    input  [13:0] bin,
    output reg [3:0] th,
    output reg [3:0] h,
    output reg [3:0] t,
    output reg [3:0] o
);
    integer i;
    reg [29:0] shift;
    always @(*) begin
        shift = 30'd0;
        shift[13:0] = bin;

        for (i=0; i<14; i=i+1) begin
            if (shift[17:14] >= 5) shift[17:14] = shift[17:14] + 3;
            if (shift[21:18] >= 5) shift[21:18] = shift[21:18] + 3;
            if (shift[25:22] >= 5) shift[25:22] = shift[25:22] + 3;
            if (shift[29:26] >= 5) shift[29:26] = shift[29:26] + 3;
            shift = shift << 1;
        end

        o  = shift[17:14];
        t  = shift[21:18];
        h  = shift[25:22];
        th = shift[29:26];
    end
endmodule
