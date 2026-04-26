//`timescale 1ns / 1ps
//
//module tb_Loopback_Top();
//
//    // 1. 입력 신호 선언
//    logic clk;
//    logic reset_n;
//    logic [7:0] switch;
//
//    // 2. 출력 신호 선언
//    logic [7:0] led;
//
//    // --- [핵심 수정 부분] 공통 버스 선언 ---
//    // tri1은 아무도 0으로 당기지 않을 때 자동으로 1(High)이 되는 풀업 라인입니다.
//    // tran 명령어 없이 이 두 가닥의 선을 마스터와 슬레이브에 동시에 물릴 겁니다.
//    tri1 i2c_sda_bus;
//    tri1 i2c_scl_bus;
//
//    // 4. 테스트할 Top 모듈 인스턴스화
//    // jb(마스터)와 jc(슬레이브)의 포트를 같은 버스에 직접 연결합니다.
//    Loopback_Top uut (
//        .clk(clk),
//        .reset_n(reset_n),
//        .switch(switch),
//        .led(led),
//        .jb_scl(i2c_scl_bus), // 마스터 출력 -> 공통 SCL 버스
//        .jb_sda(i2c_sda_bus), // 마스터 양방향 -> 공통 SDA 버스
//        .jc_scl(i2c_scl_bus), // 슬레이브 입력 <- 공통 SCL 버스에서 읽음
//        .jc_sda(i2c_sda_bus)  // 슬레이브 양방향 -> 공통 SDA 버스
//    );
//
//    // 5. 클럭 생성 (Basys3 기준 100MHz = 주기 10ns)
//    initial begin
//        clk = 0;
//        forever #5 clk = ~clk;
//    end
//
//    // 6. 테스트 시나리오
//    initial begin
//        // 초기화
//        reset_n = 0;
//        switch  = 8'h00;
//        
//        #100;
//        reset_n = 1; // 리셋 해제
//        #100;
//
//        $display("=== I2C Loopback Test Started ===");
//
//        // [TEST 1] 스위치 값을 0xA5 (1010_0101) 로 변경하여 전송 트리거
//        $display("[TIME: %0t ns] Switch changed to 0xA5", $time);
//        switch = 8'hA5;
//
//        // I2C 100kHz 전송은 매우 느립니다 (1비트당 10us).
//        // 넉넉하게 300us 대기
//        #300_000; 
//
//        if (led == 8'hA5)
//            $display("✅ SUCCESS: LED matches switch (0xA5)");
//        else
//            $display("❌ FAIL: LED is %h, expected 0xA5", led);
//
//        #50_000;
//
//        // [TEST 2] 스위치 값을 0x3C (0011_1100) 로 변경하여 연속 전송 테스트
//        $display("[TIME: %0t ns] Switch changed to 0x3C", $time);
//        switch = 8'h3C;
//
//        #300_000;
//
//        if (led == 8'h3C)
//            $display("✅ SUCCESS: LED matches switch (0x3C)");
//        else
//            $display("❌ FAIL: LED is %h, expected 0x3C", led);
//
//        $display("=== Testbench Finished ===");
//        $finish;
//    end
//
//endmodule


`timescale 1ns / 1ps

module tb_Loopback_Top();

    // 1. 입력 신호 선언
    logic clk;
    logic reset;          // (수정) Active-High 리셋
    logic [7:0] switch;
    logic btn_read;       // ★ 추가: Read 트리거 버튼

    // 2. 출력 신호 선언
    logic [7:0] led;        // 슬레이브가 수신한 데이터 표시
    logic [7:0] master_led; // ★ 추가: 마스터가 읽어온 데이터 표시

    // 3. 공통 I2C 버스 선언 (Pull-up 효과)
    tri1 i2c_sda_bus;
    tri1 i2c_scl_bus;

    // 4. 테스트할 Top 모듈 인스턴스화
    Loopback_Top uut (
        .clk(clk),
        .reset(reset),
        .switch(switch),
        .btn_read(btn_read),     // ★ 포트 매핑 추가
        .led(led),
        .master_led(master_led), // ★ 포트 매핑 추가
        .jb_scl(i2c_scl_bus), 
        .jb_sda(i2c_sda_bus), 
        .jc_scl(i2c_scl_bus), 
        .jc_sda(i2c_sda_bus)  
    );

    // 5. 클럭 생성 (100MHz = 주기 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 6. 테스트 시나리오
    initial begin
        // --- 초기화 ---
        reset    = 1; 
        switch   = 8'h00;
        btn_read = 0;
        
        #100;
        reset = 0; // 리셋 해제
        #100;

        $display("=== I2C Loopback Test Started ===");

        // ==========================================
        // [TEST 1] 마스터 Write 테스트 (0xA5 전송)
        // ==========================================
        $display("[TIME: %0t ns] Switch changed to 0xA5", $time);
        switch = 8'hA5;
        #300_000; // 전송 완료 대기

        if (led == 8'hA5)
            $display("✅ WRITE SUCCESS: Slave LED is 0xA5");
        else
            $display("❌ WRITE FAIL: Slave LED is %h, expected 0xA5", led);

        #50_000;

        // ==========================================
        // [TEST 2] 마스터 Write 테스트 (0x3C 연속 전송)
        // ==========================================
        $display("[TIME: %0t ns] Switch changed to 0x3C", $time);
        switch = 8'h3C;
        #300_000;

        if (led == 8'h3C)
            $display("✅ WRITE SUCCESS: Slave LED is 0x3C");
        else
            $display("❌ WRITE FAIL: Slave LED is %h, expected 0x3C", led);

        #50_000;

        // ==========================================
        // [TEST 3] 마스터 Read 테스트 (0x77 수신 확인)
        // ==========================================
        $display("[TIME: %0t ns] Read Button Pressed!", $time);
        btn_read = 1;
        #20;          // 버튼을 2클럭 동안 누름 (펄스 생성)
        btn_read = 0; // 버튼 뗌

        #300_000; // 읽기 완료 대기

        // 슬레이브가 0x77을 보내도록 하드코딩했으므로, 마스터 LED가 0x77이어야 함
        if (master_led == 8'h77)
            $display("✅ READ SUCCESS: Master LED received 0x77 from Slave!");
        else
            $display("❌ READ FAIL: Master LED is %h, expected 0x77", master_led);

        $display("=== Testbench Finished ===");
        $finish;
    end

endmodule