`timescale 1ns / 1ps

module top_stopwatch_watch (
    input clk,
    input reset,
    input  [ 3:0] sw,            // sw[0] up/down, [1]: watch/stopwatch, [2]: sms/hm, [3]: watch/sensor
    input btn_r,  // i_run_stop or digit_right
    input btn_c,  // i_clear
    input btn_l,  // digit_left
    input btn_u,  // time_up
    input btn_d,  // time_down
    input [3:0] cmd_tick,
    input [3:0] cmd_switch,
    input echo,
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output [15:0] display_data,  // for UART time display
    output trigger,
    inout dhtio,
    output dht11_valid,
    output [3:0] dht11_debug
);
    wire w_mode, w_run_stop, w_clear;
    wire o_btn_run_stop, o_btn_clear;
    wire [23:0] w_stopwatch_time;
    wire [23:0] w_mux_time_fnd;
    wire [23:0] w_mux_watch;
    wire [23:0] w_mux_stopwatch;
    wire [23:0] w_dist;
    wire [15:0] w_display_data;


    wire [23:0] w_dht11_data;
    wire [ 3:0] w_dht_debug;
    // sw[2] 1: temp, 0: hum

    wire [15:0] w_humidity, w_temperature;
    wire w_dht11_done, w_dht11_valid;

    assign dht11_valid  = w_dht11_valid;
    assign dht11_debug  = w_dht_debug;

    assign w_dht11_data = (sw[2] | cmd_switch[2]) ? w_temperature : w_humidity;



    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(o_btn_run_stop)
    );
    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_c),
        .o_btn(o_btn_clear)
    );
    btn_debounce U_BD_DIGIT_LEFT (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(o_btn_digit_left)
    );
    btn_debounce U_BD_DIGIT_RIGHT (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(o_btn_digit_right)
    );
    btn_debounce U_BD_TIME_UP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_u),
        .o_btn(o_btn_time_up)
    );
    btn_debounce U_BD_TIME_DOWN (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_d),
        .o_btn(o_btn_time_down)
    );

    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_mode(sw[0] | cmd_switch[0]),
        .i_run_stop((o_btn_run_stop | cmd_tick[0])),
        .i_clear(o_btn_clear),
        .o_mode(w_mode),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear)
    );
    watch_datapath U_WATCH_DATAPATH (
        .clk(clk),
        .reset(reset),
        .mode(w_mode),
        .clear(w_clear),
        .sel_display(sw[2] | cmd_switch[2]),
        .digit_l((o_btn_digit_left | cmd_tick[1])),
        .digit_r((o_btn_digit_right | cmd_tick[0])),
        .time_up((o_btn_time_up | cmd_tick[2])),
        .time_down((o_btn_time_down | cmd_tick[3])),
        .msec(w_mux_watch[6:0]),
        .sec(w_mux_watch[12:7]),
        .min(w_mux_watch[18:13]),
        .hour(w_mux_watch[23:19])
    );
    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk(clk),
        .reset(reset),
        .mode(w_mode),
        .clear(w_clear),
        .run_stop(w_run_stop),
        .msec(w_mux_stopwatch[6:0]),  // 7 bit
        .sec(w_mux_stopwatch[12:7]),  // 6 bit
        .min(w_mux_stopwatch[18:13]),  // 6 bit
        .hour(w_mux_stopwatch[23:19])  // 5 bit
    );

    top_sr04 U_TOP_SR04_CONTROLLER (
        .clk(clk),
        .rst(reset),
        .start((o_btn_digit_right | cmd_tick[0])),  // button input
        .echo(echo),
        .trigger(trigger),
        .distance(w_dist)
    );

    dht11_controller U_DHT11_CONTROLLER (
        .clk(clk),
        .rst(reset),
        .start((o_btn_digit_right | cmd_tick[0])),
        .humidity(w_humidity),  // sw[2] 0: humidity, 1: temperatur
        .temperature(w_temperature),
        .dht11_done(w_dht11_done),  ////////////
        .dht11_valid(w_dht11_valid),  ///////////
        .debug(w_dht_debug),
        .dhtio(dhtio)
    );

    // device_sel_mux_2x1 U1_MUX_2X1 (
    //     .sel(sw[1] | cmd_switch[1]),
    //     .i_sel0(w_mux_watch),
    //     .i_sel1(w_mux_stopwatch),
    //     .o_mux(w_mux_time_fnd)
    // );


    device_sel_mux_4x1 U1_MUX_4X1 (
        .sel({(sw[3]| cmd_switch[3]), (sw[1] | cmd_switch[1])}),
        .i_sel0(w_mux_watch),
        .i_sel1(w_mux_stopwatch),
        .i_sel2(w_dist),
        // .i_sel3(w_dist),  // sw[3], !sw[1]: sr04
        .i_sel3(w_dht11_data),  // sw[3], sw[1]: dht11
        .o_mux(w_mux_time_fnd)
    );

    fnd_controller U_FND_CNTL (
        .fnd_in_data(w_mux_time_fnd),
        // .distance_in_data(w_mux_time_fnd[13:0]),  //////////////////////////////
        .clk(clk),
        .reset(reset),
        .sel_display(sw[2] | cmd_switch[2]),
        .sel_sensor(sw[1] | cmd_switch[1]),
        .sw_3(sw[3]| cmd_switch[3]),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data),
        .display_data(w_display_data)
    );

    fifo_param_bit U_FIFO_16BIT (
        .clk(clk),
        .i_data(w_display_data),
        .o_data(display_data)
    );

endmodule

module fifo_param_bit #(
    parameter WIDTH = 16
) (
    input clk,
    // input rst,
    input [WIDTH-1:0] i_data,
    output reg [WIDTH-1:0] o_data
);
    always @(posedge clk) begin  //, posedge rst) begin
        // if (rst) begin
        // end else begin
        o_data <= i_data;
        // end
    end

endmodule

module device_sel_mux_4x1 (
    input [1:0] sel,
    input [23:0] i_sel0,
    input [23:0] i_sel1,
    input [23:0] i_sel2,
    input [23:0] i_sel3,
    output reg [23:0] o_mux
);
    // sel 1: i_sel1, 0: i_sel0
    // assign o_mux = (sel) ? i_sel1 : i_sel0;
    always @(*) begin
        case (sel)
            2'b00: o_mux = i_sel0;
            2'b01: o_mux = i_sel1;
            2'b10: o_mux = i_sel2;
            2'b11: o_mux = i_sel3;
        endcase
    end
endmodule

module device_sel_mux_2x1 (
    input sel,
    input [23:0] i_sel0,
    input [23:0] i_sel1,
    output [23:0] o_mux
);
    // sel 1: i_sel1, 0: i_sel0
    assign o_mux = (sel) ? i_sel1 : i_sel0;
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
    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES(24)
    ) hour_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_hour_tick),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(hour),
        .o_tick()
    );
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) min_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_min_tick),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(min),
        .o_tick(w_hour_tick)
    );
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) sec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_sec_tick),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(sec),
        .o_tick(w_min_tick)
    );
    tick_counter #(
        .BIT_WIDTH(7),
        .TIMES(100)
    ) msec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        .mode(mode),
        .clear(clear),
        .run_stop(run_stop),
        .o_count(msec),
        .o_tick(w_sec_tick)
    );

    tick_gen_100hz U_TICK_10HZ (
        .clk(clk),  // 100MHz
        .reset(reset),
        .i_run_stop(run_stop),
        .o_tick_100hz(w_tick_100hz)  // 10Hz
    );


endmodule

// msec, sec, min, hour
module tick_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input                      clk,
    input                      reset,
    input                      i_tick,
    input                      mode,
    input                      clear,
    input                      run_stop,
    output     [BIT_WIDTH-1:0] o_count,
    output reg                 o_tick
);
    // counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;

    // State reg SL
    always @(posedge clk, posedge reset) begin
        if (reset || clear) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // next state + output CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick && run_stop) begin
            if (mode) begin
                // down
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg - 1;
                    o_tick = 1'b0;
                end
            end else begin
                // up
                if (counter_reg == TIMES - 1) begin
                    counter_next = 1'b0;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg + 1;
                    o_tick = 1'b0;
                end
            end
        end
    end
endmodule


module tick_gen_100hz (
    input clk,  // 100MHz
    input reset,
    input i_run_stop,
    output reg o_tick_100hz  // 100Hz
);
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 1'b0;
            o_tick_100hz <= 1'b0;
        end else begin
            if (i_run_stop) begin
                if (counter == (F_COUNT - 1)) begin
                    counter <= 1'b0;
                    o_tick_100hz <= 1'b1;
                end else begin
                    counter <= counter + 1'b1;
                    o_tick_100hz <= 1'b0;
                end
            end
        end
    end
endmodule
