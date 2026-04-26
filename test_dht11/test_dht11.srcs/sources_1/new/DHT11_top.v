module DHT11_top(
      input clk, reset_p,
      inout dht11_data,
      output [3:0] com,
      output [7:0] seg_7,
      output [15:0] led);           //보드에 이상이 있는지 확인하기 위함, 2024.7.3
      
      wire [7:0] humidity, temperature;
      DHT11 dht11(clk, reset_p, dht11_data, humidity, temperature, led);
      
      ////////
      wire [15:0] bcd_humi, bcd_tmpr;
      bin_to_dec b2d_humi(.bin({4'b0000, humidity}), .bcd(bcd_humi));
      bin_to_dec b2d_tmpr(.bin({4'b0000, temperature}), .bcd(bcd_tmpr));
      
      wire[15:0] value;
      assign value = {bcd_humi[7:0], bcd_tmpr[7:0]};              
      fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);

endmodule

module bin_to_dec(
        input [11:0] bin,
        output reg [15:0] bcd);

    reg [3:0] i;

    always @(bin) begin                               // always안에 for 는 동작정의
        bcd = 0;
        for (i=0; i<12;i=i+1)begin
            bcd = {bcd[14:0], bin[11-i]};             // 좌시프트
            if(i < 11 && bcd[3:0] > 4) bcd[3:0] = bcd[3:0] + 3;         //최하위 4자리가 5이상이면 3(0011)을 더함
            if(i < 11 && bcd[7:4] > 4) bcd[7:4] = bcd[7:4] + 3;
            if(i < 11 && bcd[11:8] > 4) bcd[11:8] = bcd[11:8] + 3;
            if(i < 11 && bcd[15:12] > 4) bcd[15:12] = bcd[15:12] + 3;
        end
    end
endmodule


module fnd_4digit_cntr (
    input        clk,
    input        reset_p,
    input [15:0] value,     // 4-digit BCD
    output reg [7:0] seg_7, // {dp,g,f,e,d,c,b,a}
    output reg [3:0] com    // digit select
);
    // ---- 설정(보드마다 polarity가 다를 수 있음) ----
    // 대부분 FPGA 실습 보드는 com/seg가 active-low인 경우가 많아서 기본은 active-low로 제공
    localparam ACTIVE_LOW_SEG = 1;
    localparam ACTIVE_LOW_COM = 1;

    // ---- multiplex refresh: 약 1kHz~5kHz per digit면 충분 ----
    // 100MHz / 100_000 = 1kHz tick (전체 스캔은 4kHz)
    reg [16:0] refresh_cnt; // 0~99999
    wire refresh_tick = (refresh_cnt == 17'd99_999);

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) refresh_cnt <= 0;
        else refresh_cnt <= refresh_tick ? 0 : (refresh_cnt + 1);
    end

    reg [1:0] digit_sel;
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) digit_sel <= 2'd0;
        else if (refresh_tick) digit_sel <= digit_sel + 1;
    end

    reg [3:0] bcd;
    always @(*) begin
        case (digit_sel)
            2'd0: bcd = value[3:0];    // LSD
            2'd1: bcd = value[7:4];
            2'd2: bcd = value[11:8];
            2'd3: bcd = value[15:12];  // MSD
        endcase
    end

    // digit enable (one-hot)
    wire [3:0] com_raw =
        (digit_sel == 2'd0) ? 4'b0001 :
        (digit_sel == 2'd1) ? 4'b0010 :
        (digit_sel == 2'd2) ? 4'b0100 :
                              4'b1000 ;

    // 7-seg decode (active-high 기준으로 만든 다음, 필요하면 뒤집음)
    // seg order: {dp,g,f,e,d,c,b,a}
    reg [7:0] seg_raw;
    always @(*) begin
        // dp 기본 off
        case (bcd)
            4'd0: seg_raw = 8'b0_0111111;
            4'd1: seg_raw = 8'b0_0000110;
            4'd2: seg_raw = 8'b0_1011011;
            4'd3: seg_raw = 8'b0_1001111;
            4'd4: seg_raw = 8'b0_1100110;
            4'd5: seg_raw = 8'b0_1101101;
            4'd6: seg_raw = 8'b0_1111101;
            4'd7: seg_raw = 8'b0_0000111;
            4'd8: seg_raw = 8'b0_1111111;
            4'd9: seg_raw = 8'b0_1101111;
            default: seg_raw = 8'b0_0000000; // blank
        endcase
    end

    always @(*) begin
        // polarity 적용
        com  = (ACTIVE_LOW_COM) ? ~com_raw : com_raw;
        seg_7 = (ACTIVE_LOW_SEG) ? ~seg_raw : seg_raw;
    end
endmodule