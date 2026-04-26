`timescale 1ns / 1ps

module tb_dut;

    // 입력 신호 선언
    reg  clk;
    reg  reset;
    reg  i_dbit;

    // 출력 신호 선언
    wire out_dbit;

    // DUT 인스턴스화 
    fsm_moore_HW dut (
        .clk(clk),
        .reset(reset),
        .i_dbit(i_dbit),
        .out_dbit(out_dbit)
    );

    always #5 clk = ~clk;

    initial begin
        // 초기값 설정
        clk = 0;
        reset = 1;
        i_dbit = 0;

        // 리셋 신호
        #10;
        reset = 0;
        #10;
        // 입력 신호 패턴
        #10 i_dbit = 1;
        #10 i_dbit = 0;
        #10 i_dbit = 1;
        #10 i_dbit = 0;
        #10 i_dbit = 1;
        #10 i_dbit = 0;
        #20 i_dbit = 1;
        #20 i_dbit = 0;
        #10 i_dbit = 1;
        #10 i_dbit = 0;
        #20 i_dbit = 1;
        #20 i_dbit = 0;
        // 시뮬레이션 종료
        #100 $stop;
    end


endmodule
