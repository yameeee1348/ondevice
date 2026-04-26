`timescale 1ns / 1ps

module tb_spi_system();

    // 시스템 클럭 및 리셋
    logic clk;
    logic reset;
    
    // SPI 모드 설정
    logic cpol;
    logic cpha;

    // ==========================================
    // 1번 보드 (Master) 측 신호
    // ==========================================
    logic [7:0] master_tx_data;
    logic       master_start;
    logic [7:0] master_rx_data;
    logic       master_done;
    logic       master_busy;
    logic [7:0] clk_div;

    // ==========================================
    // 2번 보드 (Slave) 측 신호
    // ==========================================
    logic [7:0] slave_tx_data; 
    logic [7:0] slave_rx_data;
    logic       slave_done;

    // ==========================================
    // 가상의 점퍼선 (SPI 4-Wire Bus)
    // ==========================================
    logic sclk;
    logic mosi;
    logic miso;
    logic cs_n;

    // 클럭 생성 (50MHz 기준)
    always #10 clk = ~clk;

    // 마스터 모듈 인스턴스화 (1번 보드)
    SPI_master dut_master (
        .clk(clk),
        .reset(reset),
        .cpol(cpol),
        .cpha(cpha),
        .clk_div(clk_div),
        .tx_data(master_tx_data),
        .start(master_start),
        .miso(miso),          // Slave가 보내는 선을 받음
        .rx_data(master_rx_data),
        .done(master_done),
        .busy(master_busy),
        .sclk(sclk),          // Slave로 보냄
        .mosi(mosi),          // Slave로 보냄
        .cs_n(cs_n)           // Slave로 보냄
    );

    // 슬레이브 모듈 인스턴스화 (2번 보드)
    SPI_slave dut_slave (
        .clk(clk),
        .reset(reset),
        .cpol(cpol),
        .cpha(cpha),
        .tx_data(slave_tx_data), // Slave가 Master로 보낼 데이터
        .sclk(sclk),          // Master가 보내는 선을 받음
        .mosi(mosi),          // Master가 보내는 선을 받음
        .cs_n(cs_n),          // Master가 보내는 선을 받음
        .miso(miso),          // Master로 보냄
        .rx_data(slave_rx_data),
        .done(slave_done)
    );

    // 통신 시나리오 생성을 위한 Task
    task spi_send_buttons(logic [3:0] btn_val);
        // 약속한 프로토콜: [0, 0, 0, 0, B3, B2, B1, B0]
        @(posedge clk);
        #1;

        master_tx_data = {4'b0000, btn_val}; 
        master_start = 1'b1;
        @(posedge clk);
        #1;
        master_start = 1'b0;
        
        // 슬레이브가 데이터를 온전히 다 받을 때까지 대기
        wait(slave_done);
        @(posedge clk);
        $display("Time: %0t | BTN Input: %b | Slave RX: %b", $time, btn_val, slave_rx_data);
    endtask

    // 테스트 시나리오 시작
    initial begin
        // 초기화
        clk = 0;
        reset = 1;
        cpol = 0;
        cpha = 0;     // 가장 기본인 Mode 0
        clk_div = 4;
        master_start = 0;
        
        // 슬레이브가 마스터로 돌려보낼 더미 데이터 (마스터의 수신 확인용)
        slave_tx_data = 8'hAA; // 이진수: 1010_1010
        
        repeat(5) @(posedge clk);
        reset = 0;
        repeat(5) @(posedge clk);

        // 테스트 1: 0번 버튼 하나만 눌렀을 때
        $display("--- Test 1: Button 0 ---");
        spi_send_buttons(4'b0001); 
        #1000;

        // 테스트 2: 2번 버튼 하나만 눌렀을 때
        $display("--- Test 2: Button 2 ---");
        spi_send_buttons(4'b0010); 
        #1000;

        // 테스트 3: 1번, 3번 버튼 동시 누름
        $display("--- Test 3: Button 1 & 3 ---");
        spi_send_buttons(4'b0100); 
        #1000;

        // 테스트 4: 모드를 바꿔서(Mode 3) 전체 버튼 다 누름
        $display("--- Test 4: Mode 3 (All Buttons) ---");
        cpol = 1; cpha = 1;
        #1000;
        spi_send_buttons(4'b1000); 
        
        #2000;
        $finish;
    end

endmodule