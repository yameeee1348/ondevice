`timescale 1ns / 1ps

// 1. TOP_UART (수정됨)
module TOP_UART (
    input        clk,
    input        rst,
    input        uart_rx,
    input  [7:0] tx_data,
    input        tx_start,

    output       rx_done,   // 이제 "데이터가 있음"을 의미
    output [7:0] rx_data,   // FIFO에서 나온 최종 데이터
    output       uart_tx,
    output       tx_busy
);

    wire w_b_tick;
    wire w_rx_done;          // UART_RX가 데이터를 다 받았을 때의 펄스
    wire [7:0] w_rx_data;    // UART_RX에서 나온 8비트 데이터
    
    wire [7:0] w_tx_fifo_pop_data;
    wire w_tx_fifo_empty, w_tx_fifo_full;
    wire w_tx_done;          // UART_TX가 전송을 마쳤을 때 나오는 신호
    wire w_tx_busy;          // UART_TX 모듈 내부 상태

    assign tx_busy = w_tx_busy;

    // --- RX FIFO ---
    wire w_rx_fifo_empty;
    fifo U_FIFO_RX (
        .clk(clk),
        .rst(rst),
        .push(w_rx_done),         // UART_RX 수신 완료 시 저장
        .pop(1'b0),               // 외부 제어 전까지는 0 (필요 시 수정)
        .push_data(w_rx_data),
        .pop_data(rx_data),
        .full(),
        .empty(w_rx_fifo_empty)
    );
    // 중요: empty가 0일 때(데이터가 있을 때) rx_done이 1이 되도록 수정
    assign rx_done = ~w_rx_fifo_empty;

    // --- UART RX ---
    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    // --- TX FIFO ---
    fifo U_FIFO_TX (
        .clk(clk),
        .rst(rst),
        .push(tx_start),          // 외부에서 데이터 넣을 때
        .pop(w_tx_done),          // UART_TX가 전송을 끝내면 다음 데이터 pop
        .push_data(tx_data),
        .pop_data(w_tx_fifo_pop_data),
        .full(w_tx_fifo_full),
        .empty(w_tx_fifo_empty)
    );

    // --- UART TX ---
    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .tx_start(~w_tx_fifo_empty), // FIFO에 데이터가 있으면 전송 시작
        .b_tick(w_b_tick),
        .tx_data(w_tx_fifo_pop_data),
        .tx_busy(w_tx_busy),
        .tx_done(w_tx_done),         // 전송 완료 시 펄스 발생
        .uart_tx(uart_tx)
    );

    // --- BAUD TICK ---
    baud_tick U_BAUD_TICK (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)
    );

endmodule

// ---------------------------------------------------------
// 아래는 질문자님이 작성한 모듈들입니다. (동일하게 유지)
// ---------------------------------------------------------

module uart_rx (
    input clk, input rst, input rx, input b_tick,
    output [7:0] rx_data, output rx_done
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [3:0] bit_cnt_next, bit_cnt_reg;
    reg done_reg, done_next;
    reg [7:0] buf_reg, buf_next;

    assign rx_data = buf_reg;
    assign rx_done = done_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE; b_tick_cnt_reg <= 0; bit_cnt_reg <= 0;
            done_reg <= 0; buf_reg <= 0;
        end else begin
            c_state <= n_state; b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg <= bit_cnt_next; done_reg <= done_next; buf_reg <= buf_next;
        end
    end

    always @(*) begin
        n_state = c_state; b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next = bit_cnt_reg; done_next = 1'b0; buf_next = buf_reg;

        case (c_state)
            IDLE: if (b_tick & !rx) n_state = START;
            START: if (b_tick) begin
                if (b_tick_cnt_reg == 7) begin
                    b_tick_cnt_next = 0; n_state = DATA;
                end else b_tick_cnt_next = b_tick_cnt_reg + 1;
            end
            DATA: if (b_tick) begin
                if (b_tick_cnt_reg == 15) begin
                    b_tick_cnt_next = 0;
                    buf_next = {rx, buf_reg[7:1]};
                    if (bit_cnt_reg == 7) begin
                        bit_cnt_next = 0; n_state = STOP;
                    end else bit_cnt_next = bit_cnt_reg + 1;
                end else b_tick_cnt_next = b_tick_cnt_reg + 1;
            end
            STOP: if (b_tick) begin
                if (b_tick_cnt_reg == 15) begin
                    done_next = 1'b1; n_state = IDLE; b_tick_cnt_next = 0;
                end else b_tick_cnt_next = b_tick_cnt_reg + 1;
            end
        endcase
    end
endmodule

module uart_tx (
    input clk, input rst, input tx_start, input b_tick, input [7:0] tx_data,
    output uart_tx, output tx_busy, output tx_done
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg [1:0] c_state, n_state;
    reg tx_reg, tx_next, done_reg, done_next, busy_reg, busy_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [7:0] data_in_buf_reg, data_in_buf_next;

    assign uart_tx = tx_reg; assign tx_busy = busy_reg; assign tx_done = done_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE; tx_reg <= 1; bit_cnt_reg <= 0; b_tick_cnt_reg <= 0;
            busy_reg <= 0; done_reg <= 0; data_in_buf_reg <= 0;
        end else begin
            c_state <= n_state; tx_reg <= tx_next; bit_cnt_reg <= bit_cnt_next;
            b_tick_cnt_reg <= b_tick_cnt_next; done_reg <= done_next;
            busy_reg <= busy_next; data_in_buf_reg <= data_in_buf_next;
        end
    end

    always @(*) begin
        n_state = c_state; tx_next = tx_reg; bit_cnt_next = bit_cnt_reg;
        b_tick_cnt_next = b_tick_cnt_reg; busy_next = busy_reg; done_next = 1'b0;
        data_in_buf_next = data_in_buf_reg;

        case (c_state)
            IDLE: begin
                tx_next = 1; busy_next = 0;
                if (tx_start) begin
                    n_state = START; busy_next = 1; data_in_buf_next = tx_data;
                end
            end
            START: begin
                tx_next = 0;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        n_state = DATA; b_tick_cnt_next = 0;
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1;
                end
            end
            DATA: begin
                tx_next = data_in_buf_reg[0];
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            bit_cnt_next = 0; n_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                            data_in_buf_next = {1'b0, data_in_buf_reg[7:1]};
                        end
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1;
                end
            end
            STOP: begin
                tx_next = 1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        done_next = 1'b1; n_state = IDLE; b_tick_cnt_next = 0;
                    end else b_tick_cnt_next = b_tick_cnt_reg + 1;
                end
            end
        endcase
    end
endmodule

module baud_tick (
    input clk, input rst, output reg b_tick
);
    parameter BAUDRATE = 9600 * 16;
    parameter F_count = 100_000_000 / BAUDRATE;
    reg [$clog2(F_count)-1:0] counter_reg;
    always @(posedge clk, posedge rst) begin
        if (rst) begin counter_reg <= 0; b_tick <= 0; end
        else if (counter_reg == (F_count - 1)) begin counter_reg <= 0; b_tick <= 1; end
        else begin counter_reg <= counter_reg + 1; b_tick <= 0; end
    end
endmodule