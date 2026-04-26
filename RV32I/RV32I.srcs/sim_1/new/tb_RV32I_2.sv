`timescale 1ns / 1ps



//module tb_RV32I_2();
//   logic clk,rst ;
//   logic [7:0] GPI;
//   wire [7:0] GPO;
//   wire [15:0] GPIO;
//   wire [7:0] fnd_data;
//   wire [3:0] fnd_digit;
//   //logic rx;
//   //wire tx;
//
//   
//   RV32I_TOP dut(
//       .clk(clk),
//       .rst(rst),
//       .GPI(GPI),
//       .GPO(GPO),
//       .GPIO(GPIO),
//       .fnd_data(fnd_data),
//       .fnd_digit(fnd_digit)
//       //.rx(rx),
//       //.tx(tx)
//);
//
//
//   always #5 clk = ~clk;
//
//  initial begin
//      clk = 0;
//      rst = 1;
//      GPI = 8'h0000;
//      //GPO = 16'h0000;
//      //GPIO = 16'h0000;
//     
//      @(negedge clk);
//      @(negedge clk);
//      rst = 0;
//      
//      GPI = 8'h00aa;
//      
//      repeat(2000)
//      @(negedge clk);
//      $stop;
//  end
//
////   initial begin
////        // 메모리에 C 펌웨어(기계어) 로드 (경로 및 메모리 배열 이름은 본인 환경에 맞게 수정할 것)
////        // $readmemh("firmware.hex", dut.U_BRAM.bmem); 
////        // $readmemh("firmware.hex", dut.U_INSTRUCTION_MEM.mem);
//
////        clk = 0;
////        rst = 1;
////        GPI = 8'h00;
////        rx  = 1'b1; // [수정] RX 핀 Idle 상태(1) 강제 인가
//
////        @(negedge clk);
////        @(negedge clk);
////        rst = 0;
//       
////        GPI = 8'hAA;
//       
////        // [수정] UART 통신이 완료될 때까지 충분한 시간 부여 (50만 클럭)
////        repeat(500000) @(negedge clk);
//       
////        $stop;
////    end
//endmodule





// `timescale 1ns / 1ps

// module tb_RV32I_2();

//     // 1. 신호 선언
//     logic clk;
//     logic rst;
//     logic [7:0] GPI;      // 안 쓰지만 포트 연결용
//     logic [7:0] GPO;      // 안 쓰지만 포트 연결용
    
//     wire  [15:0] GPIO;    // [핵심] 양방향 핀은 반드시 wire로 선언
    
//     logic [7:0] fnd_data;
//     logic [3:0] fnd_digit;
//     logic rx;
//     logic tx;

//     // 테스트벤치에서 스위치 입력을 조작하기 위한 레지스터
//     logic [7:0] tb_switches;

//     // 2. 외부 환경(보드) 모사
//     // 하위 8비트[7:0]: 테스트벤치(사람)가 스위치 값을 SoC로 밀어넣음
//     // 상위 8비트[15:8]: SoC가 LED 값을 내보내야 하므로 테스트벤치는 간섭하지 않음 (High-Z)
//     assign GPIO[7:0]  = tb_switches;
//     assign GPIO[15:8] = 8'bz; 

//     // 3. Top 모듈 인스턴스화
//     RV32I_TOP U_TOP (
//         .clk(clk),
//         .rst(rst),
//         .GPI(GPI),
//         .GPO(GPO),
//         .GPIO(GPIO),
//         .fnd_data(fnd_data),
//         .fnd_digit(fnd_digit),
//         .rx(rx),
//         .tx(tx)
//     );

//     // 4. 100MHz 클럭 생성 (1주기 = 10ns)
//     always #5 clk = ~clk;

//     // 5. 시뮬레이션 시나리오
//     initial begin
//         // 초기화
//         clk = 0;
//         rst = 1;
//         rx = 1;
//         tb_switches = 8'h00; // 스위치 다 내린 상태

//         // [중요] C 코드를 변환한 Hex 파일을 메모리에 로드
//         // 파일 이름과 내부 모듈 경로(U_INSTRUCTION_MEM.mem 등)는 네 프로젝트에 맞게 수정해라.
//         // $readmemh("firmware.hex", U_TOP.U_INSTRUCTION_MEM.mem_array);
//         // $readmemh("firmware.hex", U_TOP.U_BRAM.mem_array); 

//         // 시스템 리셋 해제 (CPU 부팅 시작)
//         #100;
//         rst = 0;

//         // CPU가 sys_init()을 끝내고 while 루프에 진입할 시간을 기다림
//         #5000; 

//         // 스위치 조작 테스트 1
//         $display("Switch Input: 0x55");
//         tb_switches = 8'h55; 
//         #20000; // 파형 관찰 대기

//         // 스위치 조작 테스트 2
//         $display("Switch Input: 0xAA");
//         tb_switches = 8'hAA;
//         #20000;

//         // 시뮬레이션이 너무 오래 도는 것을 방지
//         #100000; 
//         $finish;
//     end

// endmodule


`timescale 1ns / 1ps

module tb_RV32I_2();

    // 1. 시스템 신호 선언
    logic clk;
    logic rst;

    // 2. 포트 연결용 신호 선언
    logic [7:0] GPI;
    wire  [7:0] GPO;      // [핵심] 칩에서 나오는 값을 관찰해야 하므로 wire 타입
    wire [15:0] GPIO;     // [핵심] 양방향 포트이므로 반드시 wire 타입
    
    logic [7:0] fnd_data;
    logic [3:0] fnd_digit;
    logic rx;
    logic tx;

    // 테스트벤치에서 스위치를 조작하기 위한 가상 레지스터
    logic [7:0] tb_gpi_sw;
    logic [7:0] tb_gpio_sw;

    // =========================================================
    // 3. 외부 환경(보드) 물리적 모사
    // =========================================================
    // 단방향 통신 (GPI는 밀어넣고, GPO는 구경만 함)
    assign GPI = tb_gpi_sw; 
    
    // 양방향 통신 (GPIO는 하위 8비트만 밀어넣고, 상위 8비트는 비워둠)
    assign GPIO[7:0]  = tb_gpio_sw; // CPU가 입력으로 읽을 스위치 값
    assign GPIO[15:8] = 8'bz;       // CPU가 출력할 LED 값이므로 High-Z 처리 

    // 4. Top 모듈 인스턴스화
    RV32I_TOP U_TOP (
        .clk(clk),
        .rst(rst),
        .GPI(GPI),
        .GPO(GPO),
        .GPIO(GPIO),
        .fnd_data(fnd_data),
        .fnd_digit(fnd_digit),
        .rx(rx),
        .tx(tx)
    );

    // 5. 100MHz 클럭 생성 (1주기 = 10ns)
    always #5 clk = ~clk;

    // =========================================================
    // 6. 시뮬레이션 시나리오
    // =========================================================
    initial begin
        // 초기화
        clk = 0;
        rst = 1;
        rx = 1;
        tb_gpi_sw = 8'h00;
        tb_gpio_sw = 8'h00;

        // [주의] C 코드를 변환한 Hex 파일을 메모리에 로드하는 코드가 
        // 하위 모듈(instruction_memory.sv 등)에 없다면 여기에 $readmemh 작성 필요

        // 리셋 해제 (CPU 부팅 시작)
        #100;
        rst = 0;

        // 시스템 초기화(sys_init) 완료 대기
        #5000; 

        // ---------------------------------------------------------
        // [데모 1] 단방향 GPO/GPI 즉각 반응 테스트
        // ---------------------------------------------------------
        $display("=== GPI to GPO Loopback Test ===");
        tb_gpi_sw = 8'hA5; // (10100101) 스위치 입력
        #2000;             // GPO 포트로 A5가 지연 없이 나오는지 파형 관찰
        
        tb_gpi_sw = 8'h3C; // (00111100) 스위치 값 변경
        #2000;             // GPO 포트가 즉시 3C로 바뀌는지 관찰

        // ---------------------------------------------------------
        // [데모 2] 양방향 GPIO 깜빡임 및 FND 관찰
        // ---------------------------------------------------------
        $display("=== GPIO Blink & FND Test ===");
        // CPU가 타이머를 돌리며 GPIO[15:8]을 깜빡이고 
        // FND 카운터를 올릴 때까지 시뮬레이션 시간 대기
        #100000; 

        $finish;
    end

endmodule