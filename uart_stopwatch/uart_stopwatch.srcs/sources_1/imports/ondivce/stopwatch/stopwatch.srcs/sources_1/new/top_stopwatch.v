`timescale 1ns / 1ps



module top_stopwatch (

    input        clk,
    input        reset,
    input  [3:0]      sw,    //up/down   
    input        btn_r,      //i_run_stop
    input        btn_l,      //i_clear
    input       btn_min_up,   //분 증가
    input       btn_hour_up, //시간 증가
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

   //스탑워치
    wire w_run_stop, w_clear, w_mode;
    wire o_btn_run_stop, o_btn_clear;
    wire [23:0] w_stopwatch_time;

////시계
    wire [4:0] w_watch_hour;           
    wire [5:0] w_watch_min;
    wire [5:0] w_watch_sec;
    wire [23:0] w_watch_time_packed;
    reg [23:0] w_watch_final_data;
///

    wire w_btn_min_up, w_btn_hour_up;
    wire w_adj_mode;


    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(o_btn_clear)
    );

    btn_debounce U_BD_RUN_STOP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(o_btn_run_stop)
    );
//////////수정
   
    btn_debounce U_BD_min_UP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_min_up),
        .o_btn(w_btn_min_up)
    );

    btn_debounce U_BD_hour_up (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_hour_up),
        .o_btn(w_btn_hour_up)
    );

////수정    
    

    control_unit U_control_unit (

        .clk       (clk),
        .reset     (reset),
        .i_mode    (sw[0]),
        .i_run_stop(o_btn_run_stop),
        .i_clear   (o_btn_clear),
        .o_mode    (w_mode),
        .o_run_stop(w_run_stop),
        .o_clear   (w_clear)

    );

    watch_datapath U_WATCH_DP (
        .clk(clk),
        .reset(reset),
        .sec(w_watch_sec),
        .min(w_watch_min),
        .hour(w_watch_hour),
        //수정
        .i_adj_mode(w_adj_mode),
        .i_btn_min_up(w_btn_min_up),
        .i_btn_hour_up(w_btn_hour_up)
        //수정
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk     (clk),
        .reset   (reset),
        .mode    (w_mode),
        .clear   (w_clear),
        .run_stop(w_run_stop),
        .msec    (w_stopwatch_time[6:0]),    //7bit
        .sec     (w_stopwatch_time[12:7]),   //6bit
        .min     (w_stopwatch_time[18:13]),  //6bit
        .hour    (w_stopwatch_time[23:19])   //6bit
    );

    fnd_controller U_fnd_cntl (
        .clk(clk),
        .reset(reset),
        ////수정
        .sel_display((sw[1] == 1'b1) ? 1'b1 : sw[2]),
        .fnd_in_data(w_watch_final_data),
        ////수정
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );
////수정

assign w_adj_mode = sw[3]; 
assign w_watch_time_packed = {w_watch_hour, w_watch_min, w_watch_sec, 7'd0};

always @(*) begin
    if (sw[1] == 1'b0) begin
        w_watch_final_data = w_stopwatch_time;
    end else begin
        w_watch_final_data = w_watch_time_packed;
    end
end
////수정
endmodule



module stopwatch_datapath (
    input clk,
    input reset,
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
        .BIT_WIDTH(6),
        .TIMES(60)
    ) hour_counter (
        .clk(clk),
        .reset(reset),
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
        .reset(reset),
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
        .reset(reset),
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
        .reset(reset),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .i_tick(i_tick),
        .o_count(msec),
        .o_tick(w_sec_tick)
    );

    tick_gen_100 U_tick_gen (
        .clk(clk),
        .reset(reset),
        .i_run_stop(run_stop),
        .o_tick_100(i_tick)
    );

endmodule
////수정

module watch_datapath (
    input clk,
    input reset,
    //input mode,
    //input clear,
    //input run_stop,
    input i_adj_mode,
    input i_btn_min_up,
    input i_btn_hour_up,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_1hz_tick;
    wire w_sec_tick, w_min_tick;
    reg r_btn_min_d, r_btn_hour_d;
    wire  w_pulse_min, w_pulse_hour;
    wire w_hour_tick_in, w_min_tick_in;
    

    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES(24),
        .INITIAL_VAL(23)//시뮬용
    ) hour_counter (
        .clk(clk),
        .reset(reset),
        .mode(1'b0),
        .clear(1'b0),
        .run_stop(1'b1),
        .i_tick(w_hour_tick_in),
        .o_count(hour),
        .o_tick()
    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .INITIAL_VAL(59) //시뮬용
    ) min_counter (
        .clk(clk),
        .reset(reset),
        .mode(1'b0),
        .clear(1'b0),
        .run_stop(1'b1),
        .i_tick(w_min_tick_in),
        .o_count(min),
        .o_tick(w_min_tick)
    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .INITIAL_VAL(58)
    ) sec_counter (
        .clk(clk),
        .reset(reset),
        .mode(1'b0),
        .clear(1'b0),
        .run_stop(1'b1),
        .i_tick(w_1hz_tick),
        .o_count(sec),
        .o_tick(w_sec_tick)
    );

    tick_gen_1hz U_tick_gen_1hz (
        .clk(clk),
        .reset(reset),
        .o_tick(w_1hz_tick)

    );

    always @(posedge clk) begin
        r_btn_min_d <= i_btn_min_up;
        r_btn_hour_d <= i_btn_hour_up;
    end

    assign w_pulse_min = i_btn_min_up & ~r_btn_min_d;
    assign w_pulse_hour = i_btn_hour_up & ~r_btn_hour_d;

    assign w_min_tick_in  = (i_adj_mode) ? w_pulse_min : w_sec_tick;
    assign w_hour_tick_in = (i_adj_mode) ? w_pulse_hour : w_min_tick;
endmodule


////수정
    




module tick_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100,
    INITIAL_VAL = 0
) (
    input clk,
    input reset,
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
    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <=INITIAL_VAL;
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
    input reset,
    input i_run_stop,
    output reg o_tick_100
);
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_r;

    always @(posedge clk, posedge reset) begin

        if (reset) begin

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
    input reset,
    output reg o_tick
);
    // 100MHz / 1Hz = 100,000,000 분주

    //시뮬레이션 용 f_count = 10, 빝스트림용 100_000_000
    parameter F_COUNT = 100_000_000;
    reg [$clog2(F_COUNT)-1:0] counter_r;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            counter_r <= 0;
            o_tick <= 0;
        end else begin
            if(counter_r == F_COUNT - 1) begin
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