`timescale 1ns / 1ps



module top_uart (
    input clk,
    input rst,
    input btn_down,

    output uart_tx

);

    wire w_b_tick;
    wire w_tx_start;

    btn_debounce U_BD_TX_START (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_down),
        .o_btn(w_tx_start)

    );

    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .tx_start(w_tx_start),
        .b_tick(w_b_tick),
        .tx_data(8'h30),
        .tx_busy(),
        .tx_done(),
        .uart_tx(uart_tx)
    );



    baud_tick U_BAUD_TICK (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)

    );
endmodule



module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,
    input        b_tick,     // 16배 빠른 기본 틱
    input  [7:0] tx_data,
    output       uart_tx,
    output       tx_busy,
    output       tx_done
);

    localparam IDLE = 3'd0, WAIT = 3'd1, START = 3'd2;
    localparam DATA = 3'd3, STOP = 3'd4;

    reg [2:0] c_state, n_state;
    reg tx_reg, tx_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [3:0] tick_count_16_reg, tick_count_16_next; // 16배 빠른 틱을 세는 카운터
    reg busy_reg, busy_next;
    reg done_reg, done_next;
    reg [7:0] data_in_buf_reg, data_in_buf_next;

    assign uart_tx = tx_reg;
    assign tx_busy = busy_reg;
    assign tx_done = done_reg;

    // SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state            <= IDLE;
            tx_reg             <= 1'b1;
            bit_cnt_reg        <= 3'b0;
            tick_count_16_reg  <= 4'b0;
            busy_reg           <= 1'b0;
            done_reg           <= 1'b0;
            data_in_buf_reg    <= 8'h00;
        end else begin
            c_state            <= n_state;
            tx_reg             <= tx_next;
            bit_cnt_reg        <= bit_cnt_next;
            tick_count_16_reg  <= tick_count_16_next;   //16배 틱의 상태 레지스터 
            busy_reg           <= busy_next;
            done_reg           <= done_next;
            data_in_buf_reg    <= data_in_buf_next;
        end
    end

    // CL
    always @(*) begin
        n_state           = c_state;
        tx_next           = tx_reg;
        bit_cnt_next      = bit_cnt_reg;
        tick_count_16_next = tick_count_16_reg;
        busy_next         = busy_reg;
        done_next         = 1'b0;
        data_in_buf_next  = data_in_buf_reg;

        case (c_state)
            IDLE: begin
                tx_next = 1'b1;
                bit_cnt_next = 0;
                tick_count_16_next = 0;
                if (tx_start) begin
                    busy_next = 1'b1;
                    data_in_buf_next = tx_data;
                    n_state = START;
                end else begin
                    busy_next = 1'b0;
                end
            end

            WAIT: begin
                // tx_next =1'b2
                if (b_tick) begin
                    n_state = START;
                end
            end

            START: begin
                tx_next = 1'b0; 
                if (b_tick) begin
                    if (tick_count_16_reg == 15) begin   //16배 틱이 15까지 세어지도록
                        tick_count_16_next = 0;
                        n_state = DATA;
                    end else begin
                        tick_count_16_next = tick_count_16_reg + 1;
                    end
                end
            end

            DATA: begin
                tx_next = data_in_buf_reg[bit_cnt_reg];
                if (b_tick) begin
                    if (tick_count_16_reg == 15) begin //16배 틱이 15까지 세어지고  bit_cnt가 7까지 세어지도록
                        tick_count_16_next = 0;
                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        tick_count_16_next = tick_count_16_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1; 
                if (b_tick) begin
                    if (tick_count_16_reg == 15) begin //16배 틱이 15까지 세어지도록
                        tick_count_16_next = 0;
                        done_next = 1'b1;
                        n_state = IDLE;
                    end else begin
                        tick_count_16_next = tick_count_16_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule




module baud_tick (
    input clk,
    input rst,
    output reg b_tick
);

    parameter BAUDRATE = 9600;
    parameter F_count = 100_000_000 / (BAUDRATE*16); //16배 빠른 틱 생성
    //reg for counter
    reg [$clog2(F_count)-1:0] counter_reg;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            b_tick <= 1'b0;
            
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (F_count - 1)) begin
                counter_reg <= 0;
                b_tick <= 1'b1;
            end else begin
                b_tick <= 1'b0;
            end
        end
    end
endmodule
