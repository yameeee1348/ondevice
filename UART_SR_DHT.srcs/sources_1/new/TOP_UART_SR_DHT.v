`timescale 1ns / 1ps
module TOP_UART_SR_DHT (

    input        clk,
    input        rst,
    input  [6:0] sw,           //up/down   
    input        btn_r,        //i_run_stop
    input        btn_c,
    input        btn_l,        //i_clear
    input        btn_min_up,   //분 증가
    input        btn_hour_up,  //시간 증가
    input        uart_rx, 
    input        echo,

    output       uart_tx,
    output       trigger,
    output       valid_led,
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    inout        dhtio   
);

    //스탑워치
    wire w_run_stop, w_clear, w_mode, w_measure;
    wire o_btn_run_stop, o_btn_clear;
    wire o_sw_2;
    wire [23:0] w_stopwatch_time;

    ////시계
    wire [ 4:0] w_watch_hour;
    wire [ 5:0] w_watch_min;
    wire [ 5:0] w_watch_sec;
    wire [23:0] w_watch_time_packed;
    reg  [23:0] w_watch_final_data;///////////////////////
    wire [23:0] w_dht11_fnd_raw;
    wire [23:0] w_sr04_fnd_raw;
    wire        c_watch_min_tick;
    wire        c_watch_hour_tick;///
    wire watch_clear_pulse;

    wire w_btn_min_up, w_btn_hour_up;
    wire w_adj_mode;
    

    
    

    wire [23:0] w_dht11_data;
    wire [ 3:0] w_dht_debug;
    // sw[2] 1: temp, 0: hum

    wire [15:0] w_humidity, w_temperature;
    wire w_dht11_done, w_dht11_valid;

    assign dht11_valid  = w_dht11_valid;
    assign dht11_debug  = w_dht_debug;

    assign w_dht11_data = (o_sw_2) ? w_temperature : w_humidity;

    wire w_cnt_r;
    wire w_cnt_l;
    wire w_cnt_u;
    wire w_cnt_d;
    wire w_rx_done;
    wire [7:0] w_rx_data;


    wire        w_tx_start ;
    wire        [7:0] w_tx_data ;
    wire        w_tx_busy;
    wire        w_tx_start_req;   // control_unit이 만드는 요청 펄스
    wire [7:0]  w_tx_data_req;

    wire        w_tx_start_to_uart; // sender가 만든 최종 tx_start
    wire [7:0]  w_tx_data_to_uart;

    wire sr04_start_sig = (sw[3:0] == 4'b1000) && w_btn_measure;
    wire dht11_start_sig = (sw[3:0] == 4'b1001) && w_btn_measure;

SR04 U_SR04(

    .clk(clk),
    .rst(rst),
    .echo(echo),
    .start(sr04_start_sig),
    .trigger(trigger),
    .distance(w_sr04_fnd_raw)


);


dht11_ctrl1 U_DHT11_CTRL(
    .clk(clk),
    .rst(rst),
    .start(dht11_start_sig),
    .humidity(w_humidity),   
    .temperature(w_temperature), 
    .DHT11_done(w_dht11_done),
    .DHT11_valid(w_dht11_valid),
    .debug(w_dht_debug),
    .dhtio(dhtio)
);


    top_uart U_UART (
        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx),
        .tx_start(w_tx_start_to_uart),
        .tx_data (w_tx_data_to_uart),
        .tx_busy (w_tx_busy),
        .rx_done(w_rx_done),
        .rx_data(w_rx_data),
        .uart_tx(uart_tx)

    );

    ascii_sender U_SENDER(
    .clk      (clk),
    .rst      (rst),
    .i_req    (w_tx_start_req),
    .i_data   (w_tx_data_req),
    .i_tx_busy(w_tx_busy),
    .o_tx_start(w_tx_start_to_uart),
    .o_tx_data (w_tx_data_to_uart)
    
    

);

    ascii_decoder U_ASCII_DECODER (
        .clk(clk),
        .rst(rst),
        .rx_done(w_rx_done),
        .rx_data(w_rx_data),
        .cnt_r(w_cnt_r),
        .cnt_l(w_cnt_l),
        .cnt_u(w_cnt_u),
        .cnt_d(w_cnt_d)

    );



    btn_debounce U_BD_MEAS  (
        .clk(clk), 
        .rst(rst), 
        .i_btn(btn_l), 
        .o_btn(w_btn_measure));

    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_c),
        .o_btn(o_btn_clear)
    );

    btn_debounce U_BD_RUN_STOP (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_r),
        .o_btn(o_btn_run_stop)
    );
    //////////수정

    btn_debounce U_BD_min_UP (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_min_up),
        .o_btn(w_btn_min_up)
    );

    btn_debounce U_BD_hour_up (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_hour_up),
        .o_btn(w_btn_hour_up)
    );

    ////수정    

////////////////////////////////////////////////////////////
    control_unit U_control_unit (

        .clk       (clk),
        .rst       (rst),
        .i_sw_mode  (sw[3:0]),
        .i_run_stop(cnt_r),
        .i_clear   (cnt_l),
        .i_min_up   (cnt_u),
        .i_hour_up  (cnt_d),
        .i_tx_busy  (w_tx_busy),
        .o_tx_start (w_tx_start_req),
        .o_tx_data  (w_tx_data_req),
        // .o_mode    (w_mode),
        .o_run_stop(w_run_stop),
        .o_min_tick(c_watch_min_tick),
        .o_hour_tick(c_watch_hour_tick),
        .o_clear   (w_clear)

    );
//////////////////////////////////////////////////////////////////////////////////////////
    watch_datapath U_WATCH_DP (
        .clk(clk),
        .rst(rst),
        .sec(w_watch_sec),
        .min(w_watch_min),
        .hour(w_watch_hour),
        //수정
        .i_watch_clear(watch_clear_pulse),
        .i_adj_mode(w_adj_mode),
        .i_btn_min_up(c_watch_min_tick),
        .i_btn_hour_up(c_watch_hour_tick)
        //수정
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk     (clk),
        .rst     (rst),
        .mode    (w_mode),
        .clear   (w_clear),
        .run_stop(w_run_stop),
        .msec    (w_stopwatch_time[6:0]),    //7bit
        .sec     (w_stopwatch_time[12:7]),   //6bit
        .min     (w_stopwatch_time[18:13]),  //6bit
        .hour    (w_stopwatch_time[23:19])   //6bit
    );

    fnd_controller1 U_fnd_cntl (
        .clk(clk),
        .rst(rst),
        ////수정
        .sel_display((sw[1] == 1'b1) ? 1'b1 : sw[2]),
        .fnd_in_data(w_watch_final_data),
        .i_clock_mode(sw[1]),
        .i_mode_sel(sw[5:4]),           // [추가] 00:기본, 01:SR04, 10:DHT11
        .i_sr04_data(w_sr04_fnd_raw),     // [추가]
        .i_dht11_data(w_dht11_fnd_raw),   // [추가]
        ////수정
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );
    ////수정

    assign w_adj_mode = sw[3];
    assign w_watch_time_packed = {w_watch_hour, w_watch_min, w_watch_sec, 7'd0};

    // always @(*) begin
    //     if (sw[1] == 1'b0) begin
    //         w_watch_final_data = w_stopwatch_time;
    //     end else begin
    //         w_watch_final_data = w_watch_time_packed;
    //     end
    // end


//////////////////////////////////////////////////////////////////////////////////////////
    assign cnt_r = o_btn_run_stop | w_cnt_r;
    assign cnt_l = o_btn_clear | w_cnt_l;
    assign cnt_u = w_btn_min_up | w_cnt_u;
    assign cnt_d = w_btn_hour_up | w_cnt_d;
//////////////////////////////////////////////////////////////////////////////////////////
    always @(*) begin
        case (sw[3:0])
            4'b1000: w_watch_final_data = w_sr04_fnd_raw;    // 초음파 모드
            4'b1001: w_watch_final_data = w_dht11_fnd_raw;   // 온습도 모드
            4'b0010, 4'b1010: w_watch_final_data = w_watch_time_packed; // 시계 및 조정 모드
            4'b0100: w_watch_final_data = w_watch_time_packed; // 시간 표시 모드
            default: w_watch_final_data = w_stopwatch_time;  // 기본(Up/Down 스탑워치 등)
        endcase
    end

    assign watch_clear_pulse = (sw[1] == 1'b1) ? cnt_l : 1'b0;
    

    // wire w_run_stop, w_clear, w_mode;
    //     wire o_btn_run_stop, o_btn_clear;
    //     wire [23:0] w_stopwatch_time;/

endmodule
//


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

////////////////////////////////////////////////////////////////////////////////////////////////////////////수정




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

////수정


