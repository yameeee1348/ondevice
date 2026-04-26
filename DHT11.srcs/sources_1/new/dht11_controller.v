`timescale 1ns / 1ps



module dht11_controller (
    input         clk,
    input         rst,
    input         start,
    // output [15:0] huminity,
    // output [15:0] temperature,
    // output        DHT11_done,
    // output        DHT11_valid,
    output [2:0] debug,
    inout         dhtio
);

    wire tick_10u;

    ila_0 U_ILA0 (


    .clk(clk),
    .probe0(dhtio),///1bit
    .probe1(debug) ///3bit
    );



    tick_gen_10usec U_TCIK_10u (
        .clk(clk),
        .rst(rst),
        .tick_10u(tick_10u)
    );

    //state
    parameter IDLE = 0, START = 1, WAIT = 2, SYNC_L = 3, SYNC_H = 4, DATA_SYNC= 5 ,DATA_C = 6, STOP =7;
    reg [2:0] c_state, n_state;

    reg dhtio_reg, dhtio_next;
    reg io_sel_reg, io_sel_next;

    //19 msec count
    reg [$clog2(1900)-1:0] tick_cnt_reg, tick_cnt_next;

    assign dhtio = (io_sel_reg) ? dhtio_reg : 1'bz;
    assign debug = c_state;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state    <= 3'b000;
            dhtio_reg  <= 1'b1;
            tick_cnt_reg <= 1'b0;
            io_sel_reg <= 1'b1;
        end else begin
            c_state    <= n_state;
            dhtio_reg  <= dhtio_next;
            io_sel_reg <= io_sel_next;
            tick_cnt_reg<=tick_cnt_next;
        end
    end

    always @(*) begin
        n_state     = c_state;
        tick_cnt_next = tick_cnt_reg;
        dhtio_next  = dhtio_reg;
        io_sel_next = io_sel_reg;

        case (c_state)
            IDLE: begin
                if (start) begin
                    n_state = START;
                end
            end

            START: begin
                dhtio_next = 1'b0;
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 1900) begin
                        tick_cnt_next = 0;
                        n_state = WAIT;

                    end
                end
            end
            WAIT: begin
                dhtio_next = 1'b1;
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 3) begin
                        //for output to high-z
                        n_state = SYNC_L;
                        io_sel_next = 1'b0;
                    end
                end
            end
            SYNC_L: begin
                if (tick_10u) begin
                    if (dhtio == 1) begin
                        n_state = SYNC_H;
                    end
                end
            end
            SYNC_H: begin
                if (tick_10u) begin
                    if (dhtio == 0) begin
                        n_state = DATA_SYNC;
                    end
                end
            end
            DATA_SYNC: begin
                if (tick_10u) begin
                    if (dhtio == 1) begin
                        n_state = DATA_C;
                    end
                end
            end
            DATA_C: begin
                if (tick_10u) begin
                    if (dhtio == 1) begin
                        //
                        tick_cnt_next = tick_cnt_reg + 1;
                    end else begin
                        n_state = STOP;
                    end
                end
            end
            STOP: begin
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 5) begin
                        //output mode
                        dhtio_next = 1'b1;
                        io_sel_next = 1'b1;
                        n_state = IDLE;
                    end
                end
            end

        endcase
    end

endmodule





module tick_gen_10usec (
    input      clk,
    input      rst,
    output reg tick_10u
);

    parameter F_COUNT = 100_000_000 / 100_000;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_10u    <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_10u <= 1'b1;


            end else begin
                tick_10u <= 1'b0;
            end
        end
    end
endmodule
