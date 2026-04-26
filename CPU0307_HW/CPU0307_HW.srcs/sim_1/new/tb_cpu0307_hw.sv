`timescale 1ns / 1ps

module tb_cpu0307_hw();

    // 신호 선언
    logic clk;
    logic rst;
    logic [7:0] out;

    // 테스트할 모듈(DUT: Device Under Test) 인스턴스화
    CPU0307_HW dut (
        .clk(clk),
        .rst(rst),
        .out(out)
    );

    // 10ns 주기의 클럭 생성 (100MHz)
    always #5 clk = ~clk;

    // 테스트 시나리오
    initial begin
        // 초기값 설정
        clk = 0;
        rst = 1; // 리셋 활성화

        // 1. 리셋 인가 (20ns 동안)
        #20;
        rst = 0; // 리셋 해제 -> S0 상태로 진입하여 연산 시작
        $display("--- 연산 시작 ---");

        // 2. 결과 관찰 (out이 55가 될 때까지 대기하거나 1000ns 후 강제 종료)
        fork
            begin
                wait(out == 8'd55);
                $display("성공! 최종 결과 out = %d (0x%h)", out, out);
            end
            begin
                #1000;
                if (out != 8'd55) begin
                    $display("실패: 시간 초과. 현재 out = %d", out);
                end
            end
        join

        // 3. 시뮬레이션 종료
        #50;
        $display("시뮬레이션 종료");
        $finish;
    end

    // 모니터링 (상태 변화 확인용 - 선택 사항)
    // 아래 코드는 시뮬레이션 로그에 현재 out 값을 실시간으로 찍어줍니다.
    initial begin
        $monitor("Time: %0t | rst: %b | out: %d", $time, rst, out);
    end

endmodule