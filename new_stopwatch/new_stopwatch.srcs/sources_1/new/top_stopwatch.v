`timescale 1ns / 1ps

// ==========================================
// 1. 마스터 Top 모듈 (모든 기능 통합)
// ==========================================
module top_stopwatch (
    input        clk,
    input        rst,
    input  [4:0] sw,           // sw[4]: 초음파 모드, sw[1]: 시계/스탑워치 모드, sw[0], sw[3] 등
    input        btn_r,        // run/stop
    input        btn_l,        // clear
    input        btn_min_up,   // 분 증가
    input        btn_hour_up,  // 시간 증가
    input        uart_rx,
    input        echo,         // [추가] 초음파 Echo

    output       trigger,      // [추가] 초음파 Trigger
    output       uart_tx,     
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    // --- UART & 제어 신호 와이어 ---
    wire w_run_stop, w_clear, w_mode;
    wire o_btn_run_stop, o_btn_clear;
    wire [23:0] w_stopwatch_time;

    wire [ 4:0] w_watch_hour;
    wire [ 5:0] w_watch_min;
    wire [ 5:0] w_watch_sec;
    wire [23:0] w_watch_time_packed;
    reg  [23:0] w_watch_final_data;
    
    wire c_watch_min_tick, c_watch_hour_tick, watch_clear_pulse;
    wire w_btn_min_up, w_btn_hour_up, w_adj_mode;
    wire w_cnt_r, w_cnt_l, w_cnt_u, w_cnt_d;
    wire w_rx_done;
    wire [7:0] w_rx_data;

    wire w_tx_start, w_tx_busy, w_tx_start_req;
    wire [7:0] w_tx_data, w_tx_data_req;
    wire w_tx_start_to_uart; 
    wire [7:0] w_tx_data_to_uart;

    // --- [추가] 초음파 센서 신호 ---
    wire [23:0] w_distance;
    wire w_tick_1us;
    wire [13:0] dist_sat = (w_distance > 24'd9999) ? 14'd9999 : w_distance[13:0];
    wire [3:0] dist_th, dist_h, dist_t, dist_o;

    wire c_unit_clear;
    wire w_ultra_start;
    

    // --- 기존 모듈 인스턴스화 ---
    top_uart U_UART (
        .clk(clk), .rst(rst), .uart_rx(uart_rx), .tx_start(w_tx_start_to_uart),
        .tx_data(w_tx_data_to_uart), .tx_busy(w_tx_busy), .rx_done(w_rx_done),
        .rx_data(w_rx_data), .uart_tx(uart_tx)
    );

    ascii_sender U_SENDER(
        .clk(clk), .rst(rst), .i_req(w_tx_start_req), .i_data(w_tx_data_req),
        .i_tx_busy(w_tx_busy), .o_tx_start(w_tx_start_to_uart), .o_tx_data(w_tx_data_to_uart)
    );

    ascii_decoder U_ASCII_DECODER (
        .clk(clk), .rst(rst), .rx_done(w_rx_done), .rx_data(w_rx_data),
        .cnt_r(w_cnt_r), .cnt_l(w_cnt_l), .cnt_u(w_cnt_u), .cnt_d(w_cnt_d)
    );

    // --- 디바운스 (수정된 모듈 사용) ---
    btn_debounce U_BD_CLEAR     (.clk(clk), .rst(rst), .i_btn(btn_l), .o_btn(o_btn_clear));
    btn_debounce U_BD_RUN_STOP  (.clk(clk), .rst(rst), .i_btn(btn_r), .o_btn(o_btn_run_stop));
    btn_debounce U_BD_min_UP    (.clk(clk), .rst(rst), .i_btn(btn_min_up), .o_btn(w_btn_min_up));
    btn_debounce U_BD_hour_up   (.clk(clk), .rst(rst), .i_btn(btn_hour_up), .o_btn(w_btn_hour_up));

    // --- 제어부 및 데이터패스 ---
    wire cnt_r = o_btn_run_stop | w_cnt_r;
    wire cnt_l = o_btn_clear | w_cnt_l;
    wire cnt_u = w_btn_min_up | w_cnt_u;
    wire cnt_d = w_btn_hour_up | w_cnt_d;
    assign w_adj_mode = sw[3];
    assign watch_clear_pulse = (sw[1] == 1'b1) ? cnt_l : 1'b0;

    // ===============================================================
    // ✅ 2. btn_l (cnt_l) 분기 로직 (Branch)
    // ===============================================================
  

    // sw[4] == 1 (초음파 모드)일 때는 btn_l을 누르면 초음파 Start!
    assign w_ultra_start = (sw[4] == 1'b1) ? cnt_l : 1'b0;
    
    // sw[4] == 0 (스탑워치/시계 모드)일 때는 btn_l을 누르면 Clear!
    assign c_unit_clear  = (sw[4] == 1'b0) ? cnt_l : 1'b0;
    assign watch_clear_pulse = (sw[1] == 1'b1 && sw[4] == 1'b0) ? cnt_l : 1'b0;

    control_unit U_control_unit (
        .clk(clk), .rst(rst), .i_mode(sw[0]), .i_run_stop(cnt_r), .i_clear(c_unit_clear),
        .i_min_up(cnt_u), .i_hour_up(cnt_d), .i_adj_mode(w_adj_mode), .i_tx_busy(w_tx_busy),
        .o_tx_start(w_tx_start_req), .o_tx_data(w_tx_data_req), .o_mode(w_mode),
        .o_run_stop(w_run_stop), .o_min_tick(c_watch_min_tick), .o_hour_tick(c_watch_hour_tick),
        .o_clear(w_clear)
    );

    watch_datapath U_WATCH_DP (
        .clk(clk), .rst(rst), .sec(w_watch_sec), .min(w_watch_min), .hour(w_watch_hour),
        .i_watch_clear(watch_clear_pulse), .i_adj_mode(w_adj_mode),
        .i_btn_min_up(c_watch_min_tick), .i_btn_hour_up(c_watch_hour_tick)
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk(clk), .rst(rst), .mode(w_mode), .clear(w_clear), .run_stop(w_run_stop),
        .msec(w_stopwatch_time[6:0]), .sec(w_stopwatch_time[12:7]),
        .min(w_stopwatch_time[18:13]), .hour(w_stopwatch_time[23:19])
    );

    // --- [추가] 초음파 모듈 및 BCD 변환기 ---
    tick_gen_1uhz U_tick_gen_1us (.clk(clk), .rst(rst), .o_tick(w_tick_1us));

    sr04_controller U_SR04_CTRL (
        .clk(clk), .rst(rst), .tick(w_tick_1us), .start(w_ultra_start),
        .echo(echo), .trigger(trigger), .distance(w_distance), .done()
    );

    bin14_to_bcd4 U_DIST_BCD(
        .bin(dist_sat), .th(dist_th), .h(dist_h), .t(dist_t), .o(dist_o)
    );

    // 데이터 MUX
    assign w_watch_time_packed = {w_watch_hour, w_watch_min, w_watch_sec, 7'd0};
    
    always @(*) begin
        // sw[4]가 켜져 있으면 초음파 거리 데이터를 우선 표시
        if (sw[4] == 1'b1) begin
            w_watch_final_data = {8'd0, dist_th, dist_h, dist_t, dist_o};
        end else if (sw[1] == 1'b0) begin
            w_watch_final_data = w_stopwatch_time;
        end else begin
            w_watch_final_data = w_watch_time_packed;
        end
    end

    // --- FND 컨트롤러 ---
    fnd_controller U_fnd_cntl (
        .clk(clk), .rst(rst),
        .sel_display((sw[1] == 1'b1) ? 1'b1 : sw[2]),
        .fnd_in_data(w_watch_final_data),
        .i_clock_mode(sw[1]),
        .i_ultra_mode(sw[4]),  // [추가] Ultra 모드 신호 전달
        .fnd_digit(fnd_digit), .fnd_data(fnd_data)
    );

endmodule


// ==========================================
// 2. [필수 수정] btn_debounce 모듈 (클럭 문제 해결)
// ==========================================
module btn_debounce(
    input clk,
    input rst,
    input i_btn,
    output o_btn
);
    parameter CLK_DIV = 100_000;
    parameter F_COUNT = 100_000_000 / CLK_DIV;
    reg [$clog2(F_COUNT)-1:0] counter_reg;
    reg clk_100khz_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            clk_100khz_reg <= 1'b0;
        end else begin
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                clk_100khz_reg <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                clk_100khz_reg <= 1'b0;
            end
        end
    end

    reg [7:0] q_reg, q_next;
    wire debounce;

    // [수정] 메인 clk 사용 및 clk_100khz_reg를 Enable로 사용
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            q_reg <= 0;
        end else if (clk_100khz_reg) begin
            q_reg <= q_next;
        end
    end

    always @(*) begin
        q_next = {i_btn, q_reg[7:1]};
    end
    
    assign debounce = &q_reg;
    reg edge_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) edge_reg <= 1'b0;
        else edge_reg <= debounce;
    end
    assign o_btn = debounce & (~edge_reg);
endmodule




// (주의: sr04_controller 모듈은 이전에 테스트 성공했던 코드를 그대로 붙여넣으시면 됩니다!)
module sr04_controller (
    input clk,
    input rst,
    input tick,
    input start,
    input echo,
    output   trigger,
    output   [23:0] distance
);

    localparam [2:0] IDLE = 3'd0, WAIT = 3'd1;
    localparam [2:0] TRIG = 3'd2, COUNT = 3'd3, STOP = 3'd4;


    reg [ 2:0] c_state;
    reg [ 2:0] n_state;
    reg        trigger_reg, trigger_next;
    reg [23:0] distance_reg, distance_next;


    reg [15:0] trig_cnt_reg, trig_cnt_next;
    reg [23:0] echo_cnt_reg, echo_cnt_next;
    reg [15:0] wait_timeout_reg, wait_timeout_next;
    reg [15:0] cycle_wait_reg, cycle_wait_next;
    // reg [35:0] d_data ;

    localparam integer TRIG_US = 10;
    localparam integer TIMEOUT_US = 30000;
    localparam integer CYCLE_US = 60000;

    localparam integer K = 1131;
    localparam integer SHIFT = 16;

    

 

    assign trigger = trigger_reg;
    assign distance = distance_reg;
    
    reg echo_ff1, echo_ff2;
    reg echo_d;
    
    //2 FF
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            echo_ff1 <= 1'b0;
            echo_ff2 <= 1'b0;
            echo_d <= 1'b0;
            
        end else begin
            echo_ff1 <= echo;
            echo_ff2 <= echo_ff1;
            echo_d <= echo_ff2;
        end
    end

    wire echo_sync = echo_ff2;
    wire echo_rise = echo_sync & ~echo_d;
    wire echo_fall = ~echo_sync & echo_d;
    




    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            trigger_reg <= 1'b0;
            distance_reg <= 24'd0;

            trig_cnt_reg <= 16'd0;
            echo_cnt_reg <= 24'd0;
            wait_timeout_reg <= 16'd0;
            cycle_wait_reg <= 16'd0;

        end else begin
            c_state <= n_state;

            trigger_reg <= trigger_next;
            distance_reg <= distance_next;

            trig_cnt_reg <= trig_cnt_next;
            echo_cnt_reg <= echo_cnt_next;
            wait_timeout_reg <= wait_timeout_next;
            cycle_wait_reg <= cycle_wait_next;

        end
    end

    //next, output
    always @(*) begin
        n_state = c_state;

            trigger_next = trigger_reg;
            distance_next = distance_reg;

            trig_cnt_next = trig_cnt_reg;
            echo_cnt_next = echo_cnt_reg;
            wait_timeout_next = wait_timeout_reg;
            cycle_wait_next = cycle_wait_reg;



        case (c_state)
            IDLE: begin
                trigger_next = 1'b0;
                trig_cnt_next =16'd0;
                echo_cnt_next = 24'd0;
                wait_timeout_next = 16'd0;
                cycle_wait_next = 16'd0;
                distance_next = 24'd0;

                if (start) begin
                    n_state = TRIG;

                end
            end

            TRIG: begin
                trigger_next = 1'b1;

                 if (tick) begin
                        if (trig_cnt_reg == TRIG_US - 1) begin
                         trigger_next  = 1'b0;
                         trig_cnt_next = 16'd0;
                        n_state       = WAIT;
                        end else begin
                        trig_cnt_next = trig_cnt_reg + 1'b1;
                        end
                     end
                end

            WAIT: begin
                trigger_next = 1'b0;

                if (echo_rise)begin 
                echo_cnt_next = 24'd0;

                n_state = COUNT;

                end else if (tick && (wait_timeout_reg == TIMEOUT_US - 1)) begin
                    wait_timeout_next = 16'd0;

                    
                    n_state = STOP;
                end else begin
                    wait_timeout_next = wait_timeout_reg + 1'b1;
                end
            end


            COUNT: begin

                if (tick && echo_sync) begin
                    echo_cnt_next = echo_cnt_reg + 1'b1;
                end

                if (echo_fall) begin
                    distance_next = (echo_cnt_reg * K) >> SHIFT;
                    // distance_next = echo_cnt_reg/58;

                    cycle_wait_next = 16'd0;
                    wait_timeout_next = 16'd0;
                    n_state = STOP;
                end
            end


            STOP: begin
                if(tick) begin
                if (cycle_wait_reg == CYCLE_US - 1) begin
                cycle_wait_next = 16'd0;
                n_state = IDLE;
                end else begin
                end
                cycle_wait_next = cycle_wait_reg + 1'b1;
            
            end
            end
            default: begin
                n_state = IDLE;
            end
        endcase
    end

    // always @(posedge clk , posedge rst) begin
    //     if (rst) begin
    //         trigger <=1'b0;
    //         distance <=24'd0;
    //         trig_cnt <= 16'd0;
    //         echo_cnt <= 24'd0;
    //         wait_timeout <= 16'd0;
    //         cycle_wait <= 16'd0;
    //     end else begin
        
    //         if (tick) begin
    //             case (c_state)
    //                 IDLE : begin
    //                     trigger <=1'b0;
    //                     distance <=24'd0;
    //                     trig_cnt <= 16'd0;
    //                     echo_cnt <= 24'd0;
    //                     wait_timeout <= 16'd0;
    //                     cycle_wait <= 16'd0;
    //                 end

    //                 TRIG: begin
    //                     trigger <= 1'b1;
    //                     trig_cnt <= trig_cnt + 1;

    //                 end

    //                 WAIT: begin
    //                     trigger <=1'b0;
    //                     wait_timeout <= wait_timeout + 1'b1;
    //                 end

    //                 COUNT : begin
    //                     if (echo_sync)
    //                     echo_cnt <= echo_cnt +1;

    //                 end

    //                 STOP: begin
    //                     cycle_wait <= cycle_wait +1;
    //                 end



    //             endcase

    //         end
    //         if (c_state == COUNT && n_state == STOP) begin
    //            // distance <= echo_cnt/58; //////////1/58 = 0.017241379
    //            ///0.01724 * 2^16 = 1131
    //                 d_data <= echo_cnt * 1131;
    //                 distance <= d_data >> 16;
    //         end
    //         if (c_state == TRIG && n_state == WAIT) begin
    //             trigger <=1'b0;
    //         end
    // end
    // end
    

endmodule
module stopwatch_datapath (
    input clk,
    input rst,
    input mode,
    input clear,
    input run_stop,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_tick_100, w_sec_tick, w_min_tick, w_hour_tick;
    wire i_tick;

    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES(60)
    ) hour_counter (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .i_tick(w_hour_tick),
        .o_count(hour),
        .o_tick()
    );
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) min_counter (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .i_tick(w_min_tick),
        .o_count(min),
        .o_tick(w_hour_tick)
    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) sec_counter (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .i_tick(w_sec_tick),
        .o_count(sec),
        .o_tick(w_min_tick)
    );

    tick_counter #(
        .BIT_WIDTH(7),
        .TIMES(100)
    ) msec_counter (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .i_tick(i_tick),
        .o_count(msec),
        .o_tick(w_sec_tick)
    );

    tick_gen_100 U_tick_gen (
        .clk(clk),
        .rst(rst),
        .i_run_stop(run_stop),
        .o_tick_100(i_tick)
    );

endmodule
////수정

module watch_datapath (
    input clk,
    input rst,
    //input mode,
    //input clear,
    //input run_stop,
    input i_adj_mode,
    input i_btn_min_up,
    input i_btn_hour_up,
    input i_watch_clear,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_1hz_tick;
    wire w_sec_tick, w_min_tick;
    reg r_btn_min_d, r_btn_hour_d;
    wire w_pulse_min, w_pulse_hour;
    wire w_hour_tick_in, w_min_tick_in;


    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES(24),
        .INITIAL_VAL(12)  //시뮬용
    ) hour_counter (
        .clk(clk),
        .rst(rst),
        .mode(1'b0),
        .clear(i_watch_clear),
        .run_stop(1'b1),
        .i_tick(w_hour_tick_in),
        .o_count(hour),
        .o_tick()
    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60)
        //.INITIAL_VAL(59) //시뮬용
    ) min_counter (
        .clk(clk),
        .rst(rst),
        .mode(1'b0),
        .clear(i_watch_clear),
        .run_stop(1'b1),
        .i_tick(w_min_tick_in),
        .o_count(min),
        .o_tick(w_min_tick)
    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60)
        //.INITIAL_VAL(58)
    ) sec_counter (
        .clk(clk),
        .rst(rst),
        .mode(1'b0),
        .clear(i_watch_clear),
        .run_stop(1'b1),
        .i_tick(w_1hz_tick),
        .o_count(sec),
        .o_tick(w_sec_tick)
    );

    tick_gen_1hz U_tick_gen_1hz (
        .clk(clk),
        .rst(rst),
        .o_tick(w_1hz_tick)

    );

    // always @(posedge clk) begin
    //     r_btn_min_d  <= i_btn_min_up;
    //     r_btn_hour_d <= i_btn_hour_up;
    // end

    // assign w_pulse_min = i_btn_min_up & ~r_btn_min_d;
    // assign w_pulse_hour = i_btn_hour_up & ~r_btn_hour_d;

    assign w_min_tick_in = (i_adj_mode) ? i_btn_min_up : w_sec_tick;
    assign w_hour_tick_in = (i_adj_mode) ? i_btn_hour_up : w_min_tick;
endmodule
/////////////////////////////////////////////////////////////////////////////////////

module ascii_sender (
    input clk,
    input rst,
    
    input i_req,
    input [7:0] i_data,
    input i_tx_busy,

    output reg        o_tx_start,
    output reg [7:0]  o_tx_data

);

    reg     buff2;
    reg  [7:0] buff2_data;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            buff2 <= 1'b0;
            buff2_data <= 8'h00;
            o_tx_data <= 8'h00;
            o_tx_start <= 1'b0;
        end else begin
            o_tx_start <= 1'b0;

            if (i_req && !buff2) begin
                buff2 <= 1'b1;
                buff2_data <= i_data;

            end

            if (buff2 && !i_tx_busy) begin
                o_tx_data <= buff2_data;
                o_tx_start <= 1'b1;
                buff2     <= 1'b0;
            end
        end
    end
    
    

    
endmodule
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module ascii_decoder (    ///////////수정
    input clk,
    input rst,
    input rx_done,
    input [7:0] rx_data,
    output reg cnt_r,
    output reg cnt_l,
    output reg cnt_u,
    output reg cnt_d

);

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            cnt_r <= 1'b0;
            cnt_l <= 1'b0;
            cnt_u <= 1'b0;
            cnt_d <= 1'b0;

        end else begin
            cnt_r <= 1'b0;
            cnt_l <= 1'b0;
            cnt_u <= 1'b0;
            cnt_d <= 1'b0;
            if (rx_done) begin
                case (rx_data)
                    8'h72: cnt_r <= 1'b1;  //r hex: 72 btn_r
                    8'h6C: cnt_l <= 1'b1;  // l: hex: 6C  btn_l
                    8'h75: cnt_u <= 1'b1;  //u: hex: 75  up
                    8'h64: cnt_d <= 1'b1;  //d: hex: 64  down
                endcase
            end
        end
    end
endmodule

module control_unit (

    input clk,
    input rst,
    input i_mode,
    input i_run_stop,
    input i_clear,
    input i_min_up,
    input i_hour_up,
    input i_adj_mode,
    input i_tx_busy,////////////////////////////////////////////////////////////
    output reg o_tx_start,
    output reg [7:0] o_tx_data,////////////////////////////////////////////////////////////
    output o_mode,
    output reg o_run_stop,
    output reg o_clear,
    output reg o_min_tick,
    output reg o_hour_tick

);


    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'B10, ADJ = 2'b11;

    // reg variable
    reg [1:0] current_state, next_state;
    assign o_mode = i_mode;

    // state register SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state <= STOP;

        end else begin
            current_state <= next_state;

        end
    end

    // next CL
    ////////////////////////////////////////////////////////////////////////////////////////////////
    always @(*) begin
        next_state  = current_state;
        o_run_stop  = 1'b0;
        o_clear     = 1'b0;
        o_tx_start  = 1'b0;
        o_tx_data   = 8'h00;
        o_min_tick  = 1'b0;
        o_hour_tick = 1'b0;
        case (current_state)
            STOP: begin
                // moore output
                o_run_stop = 1'b0;
                o_clear =    1'b0;
                if (i_run_stop) begin
                    next_state = RUN;

                    if (!i_tx_busy) begin
                        o_tx_start = 1'b1; 
                        o_tx_data  = 8'h72;  ///r
                    end
                end else if (i_clear) begin
                    next_state = CLEAR;

                    if (!i_tx_busy) begin
                        o_tx_start = 1'b1; 
                        o_tx_data  = 8'h6C;  //l
                    end
                end else if (i_adj_mode) begin
                    if (i_min_up) begin
                        o_min_tick = 1'b1;
                        if (!i_tx_busy) begin
                            o_tx_start = 1'b1;
                            o_tx_data  = 8'h75;  //u
                        end
                    end else if (i_hour_up) begin
                        o_hour_tick = 1'b1;
                        if (!i_tx_busy) begin
                            o_tx_start = 1'b1;
                            o_tx_data  = 8'h64;  //d
                        end
                    end

                end
            end
            RUN: begin
                o_run_stop = 1'b1;
                o_clear    = 1'b0;
                if (i_run_stop) begin
                    next_state = STOP;

                    if (!i_tx_busy) begin
                        o_tx_start = 1'b1;
                        o_tx_data  = 8'h72;  //r
                    end
                end
            end
            CLEAR: begin
                o_run_stop = 1'b0;
                o_clear = 1'b1;
                next_state = STOP;
            end
        endcase
    end////////////////////////////////////////////////////////////////////////////////
    // always @(posedge clk, posedge rst) begin
    //     if (rst) begin
    //         o_min_tick <=1'b0;
    //         o_hour_tick <= 1'b0;
    //     end else begin
    //         o_min_tick <= 1'b0;
    //         o_hour_tick <= 1'b0;
    //         if (i_adj_mode)begin
    //             if (i_min_up) 
    //             o_min_tick <= 1'b1;

    //             if (i_hour_up)
    //             o_hour_tick <= 1'b1;

    //         end
    //     end
    // end



endmodule

module tick_gen_1uhz (
    input clk,
    input rst,
    output reg o_tick
);
    // 100MHz / 1MHz(1us) = 100 분주
    parameter F_COUNT = 100;
    reg [$clog2(F_COUNT)-1:0] counter_r;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 0;
            o_tick <= 1'b0;
        end else begin
            if (counter_r == F_COUNT - 1) begin
                counter_r <= 0;
                o_tick <= 1'b1;  // 1us마다 딱 1클럭 동안만 High가 됨
            end else begin
                counter_r <= counter_r + 1;
                o_tick <= 1'b0;
            end
        end
    end
endmodule

module bin14_to_bcd4(
    input  [13:0] bin,
    output reg [3:0] th,  // 천의 자리 (Thousands)
    output reg [3:0] h,   // 백의 자리 (Hundreds)
    output reg [3:0] t,   // 십의 자리 (Tens)
    output reg [3:0] o    // 일의 자리 (Ones)
);
    integer i;
    reg [29:0] shift; // [29:14]는 BCD(16bit), [13:0]은 입력 Binary 영역

    always @(*) begin
        // 초기화
        shift = 30'd0;
        shift[13:0] = bin;

        // 14비트이므로 14번 Shift 반복
        for (i=0; i<14; i=i+1) begin
            // Shift 하기 전에 각 BCD 자리가 5 이상인지 검사해서 맞으면 3을 더함 (Add 3)
            if (shift[17:14] >= 5) shift[17:14] = shift[17:14] + 3; // 일의 자리
            if (shift[21:18] >= 5) shift[21:18] = shift[21:18] + 3; // 십의 자리
            if (shift[25:22] >= 5) shift[25:22] = shift[25:22] + 3; // 백의 자리
            if (shift[29:26] >= 5) shift[29:26] = shift[29:26] + 3; // 천의 자리
            
            // 왼쪽으로 1칸 Shift
            shift = shift << 1;
        end

        // 최종 계산된 BCD 값을 각 출력 포트에 할당
        o  = shift[17:14];
        t  = shift[21:18];
        h  = shift[25:22];
        th = shift[29:26];
    end
endmodule

module tick_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100,
    INITIAL_VAL = 0
) (
    input clk,
    input rst,
    input i_tick,
    input mode,
    input clear,
    input run_stop,
    output [BIT_WIDTH-1:0] o_count,
    output reg o_tick
);

    //counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;
    assign o_count = counter_reg;


    // state reg SL
    always @(posedge clk, posedge rst) begin
        if (rst | clear) begin
            counter_reg <= INITIAL_VAL;
        end else begin
            counter_reg <= counter_next;
        end
    end


    //next CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick & run_stop) begin
            if (mode == 1'b1) begin
                //down
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg - 1;
                    o_tick = 1'b0;
                end
            end else begin
                //up
                if (counter_reg == (TIMES - 1)) begin
                    counter_next = 0;
                    o_tick = 1'b1;

                end else begin
                    counter_next = counter_reg + 1;
                    o_tick = 1'b0;
                end

            end
        end
    end
endmodule

module tick_gen_100 (

    input clk,
    input rst,
    input i_run_stop,
    output reg o_tick_100
);
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_r;

    always @(posedge clk, posedge rst) begin

        if (rst) begin

            counter_r  <= 0;
            o_tick_100 <= 1'b0;

        end else begin
            if (i_run_stop) begin
                counter_r <= counter_r + 1;


            end
            if (counter_r == (F_COUNT - 1)) begin
                counter_r  <= 0;
                o_tick_100 <= 1'b1;


            end else begin
                o_tick_100 <= 1'b0;
            end
        end
    end
endmodule

////수정

module tick_gen_1hz (
    input clk,
    input rst,
    output reg o_tick
);
    // 100MHz / 1Hz = 100,000,000 분주

    //시뮬레이션 용 f_count = 10, 빝스트림용 100_000_000
    parameter F_COUNT = 100_000_000;
    reg [$clog2(F_COUNT)-1:0] counter_r;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 0;
            o_tick <= 0;
        end else begin
            if (counter_r == F_COUNT - 1) begin
                counter_r <= 0;
                o_tick <= 1;
            end else begin
                counter_r <= counter_r + 1;
                o_tick <= 0;
            end
        end
    end
endmodule