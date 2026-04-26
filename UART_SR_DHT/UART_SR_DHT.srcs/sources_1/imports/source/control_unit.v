`timescale 1ns / 1ps

module control_unit (
    input            clk,
    input            rst,
    input      [3:0] i_sw_mode,     // sw[3:0]을 한 번에 입력으로 받음
    input            i_run_stop,    // BTNR: 시작/정지
    input            i_clear,       // BTNC: 초기화
    input            i_min_up,      // BTNU: 분 증가
    input            i_hour_up,     // BTND: 시 증가
    input            i_tx_busy,     
    
    output reg       o_tx_start,
    output reg [7:0] o_tx_data,
    output reg       o_run_stop,
    output reg       o_clear,
    output reg       o_min_tick,
    output reg       o_hour_tick
);

    // 상태 정의
    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;
    reg [1:0] current_state, next_state;

    // 상태 전환 (Sequential Logic)
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state <= STOP;
        end else begin
            current_state <= next_state;
        end
    end

    // 제어 로직 (Combinational Logic)
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
                o_run_stop = 1'b0;
                
                // 1. 스탑워치 제어 (sw[3:0] 조건이 맞을 때만 동작 가능하도록 설정 가능)
                if (i_run_stop) begin
                    next_state = RUN;
                    if (!i_tx_busy) begin o_tx_start = 1'b1; o_tx_data = 8'h72; end // 'r'
                end else if (i_clear) begin
                    next_state = CLEAR;
                    if (!i_tx_busy) begin o_tx_start = 1'b1; o_tx_data = 8'h63; end // 'c'
                end
                
                // 2. 시간 조정 모드 (예: i_sw_mode가 4'b1000일 때만 조정 가능)
                if (i_sw_mode == 4'b1000) begin 
                    if (i_min_up) begin 
                        o_min_tick = 1'b1; 
                        if (!i_tx_busy) begin o_tx_start = 1'b1; o_tx_data = 8'h75; end // 'u'
                    end else if (i_hour_up) begin 
                        o_hour_tick = 1'b1;
                        if (!i_tx_busy) begin o_tx_start = 1'b1; o_tx_data = 8'h64; end // 'd'
                    end
                end
            end

            RUN: begin
                o_run_stop = 1'b1;
                if (i_run_stop) begin
                    next_state = STOP;
                    if (!i_tx_busy) begin o_tx_start = 1'b1; o_tx_data = 8'h73; end // 's'
                end
            end

            CLEAR: begin
                o_clear = 1'b1;
                next_state = STOP;
            end

            default: next_state = STOP;
        endcase
    end

endmodule