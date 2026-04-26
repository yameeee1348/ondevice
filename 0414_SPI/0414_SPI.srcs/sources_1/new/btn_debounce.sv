`timescale 1ns / 1ps

module btn_debounce #(
    parameter int CLK_DIV = 100_000,
    parameter int F_COUNT = 100_000_000 / CLK_DIV
)(
    input  logic clk,
    input  logic reset,
    input  logic i_btn,
    output logic o_btn
);

    // ==========================================
    // 1. Clock Enable Pulse 생성기 (100kHz)
    // ==========================================
    logic [$clog2(F_COUNT)-1:0] counter_reg;
    logic tick_100khz; // 이전의 clk_100khz_reg를 펄스(Enable) 용도로 변경

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            tick_100khz <= 1'b0;
        end else begin
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_100khz <= 1'b1; // 딱 1클럭 동안만 High 유지
            end else begin
                counter_reg <= counter_reg + 1;
                tick_100khz <= 1'b0;
            end
        end
    end

    // ==========================================
    // 2. 8-tap Shift Register (디바운싱)
    // ==========================================
    logic [7:0] q_reg;
    logic       debounce;

    // 💡 핵심 수정: 별도의 클럭이 아닌 메인 clk 사용 + tick_100khz를 Enable로 사용
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            q_reg <= 8'b0;
        end else if (tick_100khz) begin 
            // 100kHz 타이밍이 될 때마다 한 칸씩 시프트!
            q_reg <= {i_btn, q_reg[7:1]};
        end
    end
    
    // 8개 비트가 모두 1일 때만 debounce 완료 (안정화)
    assign debounce = &q_reg;

    // ==========================================
    // 3. Edge Detection (One-Shot Pulse 생성)
    // ==========================================
    logic edge_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    // 과거에는 0이었고 지금은 1인 순간 잡아내기
    assign o_btn = debounce & (~edge_reg);

endmodule