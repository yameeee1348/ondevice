`timescale 1ns / 1ps



module fnd_controller (

    input         clk,
    input         rst,
    input         sel_display,
    input         i_clock_mode,
    input         i_ultra_mode,
    input  [23:0] fnd_in_data,
    output [ 3:0] fnd_digit,
    output [ 7:0] fnd_data
);

    wire [3:0] w_digit_msec_1, w_digit_sec_1, w_digit_min_1, w_digit_hour_1;
    wire [3:0] w_digit_msec_10, w_digit_sec_10, w_digit_min_10, w_digit_hour_10;
    wire [3:0] w_mux_hour_min_out, w_mux_sec_msec_out;
    wire [3:0] w_mux_2x1_out;
    wire [2:0] w_digit_sel;
    wire w_1khz;
    wire [3:0] w_mux_ultra_out;
    wire [3:0] w_mux_final_out;

    reg [3:0] div5_cnt;
    reg [6:0] blink_msec;
    wire [6:0] msec_sel;
    wire       w_dot_onoff;

    //hour
    digit_spliter #(
        .BIT_WIDTH(5)
    ) U_HOUR_DS (
        .in_data (fnd_in_data[23:19]),
        .digit_1 (w_digit_hour_1),
        .digit_10(w_digit_hour_10)
    );
    //min
    digit_spliter #(
        .BIT_WIDTH(6)
    ) U_MIN_DS (
        .in_data (fnd_in_data[18:13]),
        .digit_1 (w_digit_min_1),
        .digit_10(w_digit_min_10)
    );

    //sec
    digit_spliter #(
        .BIT_WIDTH(6)
    ) U_SEC_DS (
        .in_data (fnd_in_data[12:7]),
        .digit_1 (w_digit_sec_1),
        .digit_10(w_digit_sec_10)
    );
    //msec
    digit_spliter #(
        .BIT_WIDTH(7)
    ) U_MSEC_DS (
        .in_data (fnd_in_data[6:0]),
        .digit_1 (w_digit_msec_1),
        .digit_10(w_digit_msec_10)
    );
 
    clk_div U_clk_div (
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );

   counter_8 U_counter_8 (
        .clk(clk),         // 메인 클럭 연결
        .rst(rst),
        .en(w_1khz),       // Enable로 w_1khz 연결
        .digit_sel(w_digit_sel)
    );

    decoder_2to4 U_decoder_2x4 (
        .digit_sel(w_digit_sel[1:0]),
        .fnd_digit(fnd_digit)
    );

    mux_8x1 U_mux_ULTRA (
    .sel           (w_digit_sel),
    .digit_1       (fnd_in_data[3:0]),
    .digit_10      (fnd_in_data[7:4]),
    .digit_100     (fnd_in_data[11:8]),
    .digit_1000    (fnd_in_data[15:12]),
    .digit_dot_1   (4'hf),
    .digit_dot_10  (4'hf),
    .digit_dot_100 (4'hf),
    .digit_dot_1000(4'hf),
    .mux_out       (w_mux_ultra_out)
);

    mux_8x1 U_mux_MIN_HOUR (

        .sel           (w_digit_sel),
        .digit_1       (w_digit_min_1),
        .digit_10      (w_digit_min_10),
        .digit_100     (w_digit_hour_1),
        .digit_1000    (w_digit_hour_10),
        .digit_dot_1   (4'hf),
        .digit_dot_10  (4'hf),
        .digit_dot_100 ({3'b111,w_dot_onoff}), ///수정 항상 켜짐
        .digit_dot_1000(4'hf),
        .mux_out       (w_mux_hour_min_out)
    );
    mux_8x1 U_mux_SEC_MSEC (

        .sel           (w_digit_sel),
        .digit_1       (w_digit_msec_1),
        .digit_10      (w_digit_msec_10),
        .digit_100     (w_digit_sec_1),
        .digit_1000    (w_digit_sec_10),
        .digit_dot_1   (4'hf),
        .digit_dot_10  (4'hf),
        .digit_dot_100 ({3'b111,w_dot_onoff}),
        .digit_dot_1000(4'hf),
        .mux_out       (w_mux_sec_msec_out)

    );

    mux2x1 U_MUX_2x1 (
        .sel   (sel_display),
        .i_sel0(w_mux_sec_msec_out),
        .i_sel1(w_mux_hour_min_out),
        .o_mux (w_mux_2x1_out)
    );

    dot_onoff_com U_DOT_COMP (
        .msec(msec_sel),
        .dot_onoff(w_dot_onoff)
    );

     assign w_mux_final_out = (i_ultra_mode) ? w_mux_ultra_out : w_mux_2x1_out;

    bcd U_BCD (
        .bcd(w_mux_final_out),
        .fnd_data(fnd_data)
    );

    
   

  always @(posedge clk or posedge rst) begin
        if (rst) begin
            div5_cnt   <= 4'd0;        
            blink_msec <= 7'd0;        
        end else begin
            if (w_1khz) begin
                if (div5_cnt == 4'd9) begin
                    div5_cnt <= 4'd0;
                    if (blink_msec == 7'd99)
                        blink_msec <= 7'd0;
                    else
                        blink_msec <= blink_msec + 1;
                end else begin
                    div5_cnt <= div5_cnt + 1;
                end
            end
        end
    end

    assign msec_sel = (i_clock_mode) ? blink_msec : 7'd0;   

    


endmodule


module mux2x1 (
    input sel,
    input [3:0] i_sel0,
    input [3:0] i_sel1,
    output [3:0] o_mux
);
    //sel 1: output i_sel1, 0:i_sel0
    assign o_mux = (sel) ? i_sel1 : i_sel0;


endmodule

module clk_div (
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

module counter_8 (
    input clk,
    input rst,
    input en,          // Enable 핀 추가
    output [2:0] digit_sel
);
    reg [2:0] counter_r;
    assign digit_sel = counter_r;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 0;
        end else if (en) begin // Enable 신호가 들어올 때만 카운트
            counter_r <= counter_r + 1;
        end
    end
endmodule
// module counter_8 (

//     input clk,
//     input rst,
//     output [2:0] digit_sel

// );
//     reg [2:0] counter_r;
//     assign digit_sel = counter_r;

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             //init counter_r
//             counter_r <= 0;
//         end else begin
//             counter_r <= counter_r + 1;


//         end

//     end

// endmodule


module dot_onoff_com (
    input [6:0] msec,
    output dot_onoff
);

    assign dot_onoff = (msec < 50);


endmodule


module decoder_2to4 (
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



module mux_8x1 (

    input [2:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    input [3:0] digit_dot_1,
    input [3:0] digit_dot_10,
    input [3:0] digit_dot_100,
    input [3:0] digit_dot_1000,
    output reg [3:0] mux_out

);


    always @(*) begin

        case (sel)

            3'b000: mux_out = digit_1;
            3'b001: mux_out = digit_10;
            3'b010: mux_out = digit_100;
            3'b011: mux_out = digit_1000;
            3'b100: mux_out = digit_dot_1;
            3'b101: mux_out = digit_dot_10;
            3'b110: mux_out = digit_dot_100;
            3'b111: mux_out = digit_dot_1000;
            default: mux_out = digit_1;
        endcase

    end
endmodule

module digit_spliter #(
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH -1:0] in_data,
    output [3:0] digit_1,
    output [3:0] digit_10

);

    assign digit_1  = in_data % 10;
    assign digit_10 = (in_data / 10) % 10;

endmodule





module bcd (
    input [3:0] bcd,
    output reg [7:0] fnd_data


);

    always @(bcd) begin
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
            4'd10: fnd_data = 8'hff;
            4'd11: fnd_data = 8'hff;
            4'd12: fnd_data = 8'hff;
            4'd13: fnd_data = 8'hff;
            4'd14: fnd_data = 8'h7f;
            4'd15: fnd_data = 8'hff;

            default: fnd_data = 8'hFF;
        endcase

    end
endmodule
