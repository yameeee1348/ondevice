`timescale 1ns / 1ps

// ==========================================
// 1. 테스트용 TOP 모듈
// ==========================================
module top_test (
    input  clk,       // Basys3 100MHz 기본 클럭
    input  rst,       // 리셋 버튼
    input  echo,      // 초음파 센서 Echo 핀
    output trigger,   // 초음파 센서 Trigger 핀
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire w_tick_1us;
    wire [23:0] w_distance;
    
    // 거리값 BCD 변환용
    wire [13:0] dist_sat = (w_distance > 24'd9999) ? 14'd9999 : w_distance[13:0];
    wire [3:0] dist_th, dist_h, dist_t, dist_o;
    
    // 자동 측정용 펄스 (약 0.1초마다 자동으로 Trigger 발생)
    reg [23:0] auto_start_cnt;
    reg w_auto_start;
    
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            auto_start_cnt <= 0;
            w_auto_start <= 0;
        end else begin
            if (auto_start_cnt == 24'd10_000_000 - 1) begin // 100ms
                auto_start_cnt <= 0;
                w_auto_start <= 1'b1;
            end else begin
                auto_start_cnt <= auto_start_cnt + 1;
                w_auto_start <= 1'b0;
            end
        end
    end

    // 1us 틱 생성기
    tick_gen_1uhz U_tick_gen_1us (
        .clk(clk), .rst(rst), .o_tick(w_tick_1us)
    );

    // [수정 완료됨] 초음파 센서 컨트롤러
    sr04_controller U_SR04_CTRL (
        .clk(clk),
        .rst(rst),
        .tick(w_tick_1us),
        .start(w_auto_start),
        .echo(echo),
        .trigger(trigger),
        .distance(w_distance),
        .done()
    );

    // BCD 변환기
    bin14_to_bcd4 U_DIST_BCD(
        .bin(dist_sat), .th(dist_th), .h(dist_h), .t(dist_t), .o(dist_o)
    );

    // [수정 완료됨] FND 컨트롤러
    fnd_controller U_FND_CTRL (
        .clk(clk),
        .rst(rst),
        .sel_display(1'b0),
        .i_clock_mode(1'b0),
        .i_ultra_mode(1'b1), // 초음파 모드 강제 On
        .fnd_in_data({8'd0, dist_th, dist_h, dist_t, dist_o}), // BCD 데이터 입력
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

endmodule


// ==========================================
// 2. 수정된 SR04 컨트롤러 (핵심 로직 수정)
// ==========================================
module sr04_controller (
    input clk, input rst, input tick, input start, input echo,
    output trigger, output [23:0] distance, output done
);
    localparam [2:0] IDLE = 3'd0, WAIT = 3'd1;
    localparam [2:0] TRIG = 3'd2, COUNT = 3'd3, STOP = 3'd4;

    reg [2:0] c_state, n_state;
    reg trigger_reg, trigger_next;
    reg [23:0] distance_reg, distance_next;
    reg [15:0] trig_cnt_reg, trig_cnt_next;
    reg [23:0] echo_cnt_reg, echo_cnt_next;
    reg [15:0] wait_timeout_reg, wait_timeout_next;
    reg [15:0] cycle_wait_reg, cycle_wait_next;
    reg done_reg, done_next;

    assign done = done_reg;
    assign trigger = trigger_reg;
    assign distance = distance_reg;

    localparam integer TRIG_US = 10;
    localparam integer TIMEOUT_US = 30000;
    localparam integer CYCLE_US = 60000;
    localparam integer K = 1131;
    localparam integer SHIFT = 16;

    reg echo_ff1, echo_ff2, echo_d;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            echo_ff1 <= 0; echo_ff2 <= 0; echo_d <= 0;
        end else begin
            echo_ff1 <= echo; echo_ff2 <= echo_ff1; echo_d <= echo_ff2;
        end
    end

    wire echo_sync = echo_ff2;
    wire echo_rise = echo_sync & ~echo_d;
    wire echo_fall = ~echo_sync & echo_d;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            trigger_reg <= 0; distance_reg <= 0; trig_cnt_reg <= 0;
            echo_cnt_reg <= 0; wait_timeout_reg <= 0; cycle_wait_reg <= 0; done_reg <= 0;
        end else begin
            c_state <= n_state;
            trigger_reg <= trigger_next; distance_reg <= distance_next;
            trig_cnt_reg <= trig_cnt_next; echo_cnt_reg <= echo_cnt_next;
            wait_timeout_reg <= wait_timeout_next; cycle_wait_reg <= cycle_wait_next; done_reg <= done_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        trigger_next = trigger_reg; distance_next = distance_reg;
        trig_cnt_next = trig_cnt_reg; echo_cnt_next = echo_cnt_reg;
        wait_timeout_next = wait_timeout_reg; cycle_wait_next = cycle_wait_reg; done_next = done_reg;

        case (c_state)
            IDLE: begin
                trigger_next = 0; trig_cnt_next = 0; echo_cnt_next = 0;
                wait_timeout_next = 0; cycle_wait_next = 0; done_next = 0;
                // [수정 포인트!] distance_next = 0; <-- 이 부분을 지웠습니다! (값 유지)
                if (start) n_state = TRIG;
            end
            TRIG: begin
                trigger_next = 1;
                if (tick) begin
                    if (trig_cnt_reg == TRIG_US - 1) begin
                        trigger_next = 0; trig_cnt_next = 0; n_state = WAIT;
                    end else trig_cnt_next = trig_cnt_reg + 1;
                end
            end
            WAIT: begin
                trigger_next = 0;
                if (echo_rise) begin 
                    echo_cnt_next = 0; n_state = COUNT;
                end else if (tick && (wait_timeout_reg == TIMEOUT_US - 1)) begin
                    wait_timeout_next = 0; n_state = STOP;
                end else if (tick) wait_timeout_next = wait_timeout_reg + 1;
            end
            COUNT: begin
                if (tick && echo_sync) echo_cnt_next = echo_cnt_reg + 1;
                if (echo_fall) begin
                    // [수정 포인트!] 오버플로우 방지
                    distance_next = ({12'd0, echo_cnt_reg} * K) >> SHIFT;
                    done_next = 1; cycle_wait_next = 0; wait_timeout_next = 0; n_state = STOP;
                end
            end
            STOP: begin
                done_next = 0;
                if(tick) begin
                    if (cycle_wait_reg == CYCLE_US - 1) begin
                        cycle_wait_next = 0; n_state = IDLE;
                    end else cycle_wait_next = cycle_wait_reg + 1;
                end
            end
            default: n_state = IDLE;
        endcase
    end
endmodule


// ==========================================
// 3. 수정된 FND 컨트롤러 (클럭 문제 해결)
// ==========================================
module fnd_controller (
    input clk, input rst, input sel_display, input i_clock_mode,
    input i_ultra_mode, input [23:0] fnd_in_data,
    output [3:0] fnd_digit, output [7:0] fnd_data
);
    wire [3:0] w_mux_ultra_out;
    wire [2:0] w_digit_sel;
    wire w_1khz;

    clk_div U_clk_div (.clk(clk), .rst(rst), .o_1khz(w_1khz));

    // [수정 포인트!] 클럭을 메인 clk로, w_1khz를 enable로 사용
    counter_8 U_counter_8 (.clk(clk), .rst(rst), .en(w_1khz), .digit_sel(w_digit_sel));
    
    decoder_2to4 U_decoder_2x4 (.digit_sel(w_digit_sel[1:0]), .fnd_digit(fnd_digit));

    mux_8x1 U_mux_ULTRA (
        .sel(w_digit_sel),
        .digit_1(fnd_in_data[3:0]), .digit_10(fnd_in_data[7:4]),
        .digit_100(fnd_in_data[11:8]), .digit_1000(fnd_in_data[15:12]),
        .digit_dot_1(4'hf), .digit_dot_10(4'hf), .digit_dot_100(4'hf), .digit_dot_1000(4'hf),
        .mux_out(w_mux_ultra_out)
    );

    bcd U_BCD (.bcd(w_mux_ultra_out), .fnd_data(fnd_data));
endmodule

module counter_8 (
    input clk, input rst, input en, output [2:0] digit_sel
);
    reg [2:0] counter_r;
    assign digit_sel = counter_r;
    always @(posedge clk, posedge rst) begin
        if (rst) counter_r <= 0;
        else if (en) counter_r <= counter_r + 1; // Enable 방식 적용
    end
endmodule

module clk_div (
    input clk, input rst, output reg o_1khz
);
    reg [16:0] counter_r;
    always @(posedge clk, posedge rst) begin
        if (rst) begin counter_r <= 0; o_1khz <= 0; end 
        else if (counter_r == 99_999) begin counter_r <= 0; o_1khz <= 1; end 
        else begin counter_r <= counter_r + 1; o_1khz <= 0; end
    end
endmodule

module decoder_2to4 (
    input [1:0] digit_sel, output reg [3:0] fnd_digit
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
    input [2:0] sel, input [3:0] digit_1, input [3:0] digit_10, input [3:0] digit_100,
    input [3:0] digit_1000, input [3:0] digit_dot_1, input [3:0] digit_dot_10,
    input [3:0] digit_dot_100, input [3:0] digit_dot_1000, output reg [3:0] mux_out
);
    always @(*) begin
        case (sel)
            3'b000: mux_out = digit_1;
            3'b001: mux_out = digit_10;
            3'b010: mux_out = digit_100;
            3'b011: mux_out = digit_1000;
            default: mux_out = 4'hf; // 화면 꺼짐 처리
        endcase
    end
endmodule

module bcd (
    input [3:0] bcd, output reg [7:0] fnd_data
);
    always @(bcd) begin
        case (bcd)
            4'd0:  fnd_data = 8'hC0; 4'd1:  fnd_data = 8'hF9; 4'd2:  fnd_data = 8'hA4;
            4'd3:  fnd_data = 8'hB0; 4'd4:  fnd_data = 8'h99; 4'd5:  fnd_data = 8'h92;
            4'd6:  fnd_data = 8'h82; 4'd7:  fnd_data = 8'hF8; 4'd8:  fnd_data = 8'h80;
            4'd9:  fnd_data = 8'h90; default: fnd_data = 8'hFF;
        endcase
    end
endmodule

module tick_gen_1uhz (
    input clk, input rst, output reg o_tick
);
    reg [6:0] counter_r;
    always @(posedge clk, posedge rst) begin
        if (rst) begin counter_r <= 0; o_tick <= 0; end 
        else if (counter_r == 99) begin counter_r <= 0; o_tick <= 1; end 
        else begin counter_r <= counter_r + 1; o_tick <= 0; end
    end
endmodule

module bin14_to_bcd4(
    input  [13:0] bin, output reg [3:0] th, output reg [3:0] h,
    output reg [3:0] t, output reg [3:0] o
);
    integer i;
    reg [29:0] shift; 
    always @(*) begin
        shift = 30'd0; shift[13:0] = bin;
        for (i=0; i<14; i=i+1) begin
            if (shift[17:14] >= 5) shift[17:14] = shift[17:14] + 3;
            if (shift[21:18] >= 5) shift[21:18] = shift[21:18] + 3;
            if (shift[25:22] >= 5) shift[25:22] = shift[25:22] + 3;
            if (shift[29:26] >= 5) shift[29:26] = shift[29:26] + 3;
            shift = shift << 1;
        end
        o = shift[17:14]; t = shift[21:18]; h = shift[25:22]; th = shift[29:26];
    end
endmodule