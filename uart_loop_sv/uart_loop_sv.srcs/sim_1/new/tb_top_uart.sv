`timescale 1ns / 1ps

// --- Interface (기존 형식 유지) ---
interface top_uart_interface;
    logic clk;
    logic rst;
    logic uart_rx; // DUT 입력
    logic uart_tx; // DUT 출력
    // 내부 관찰용 (선택 사항)
    logic b_tick;
endinterface

// --- Transaction (기존 형식 유지) ---
class transaction;
    rand bit [7:0] rx_data; // 송신/수신 데이터 공용
    function void display(string name);
        $display("[%t] %s: data = 8'h%h (binary: %b)", $time, name, rx_data, rx_data);
    endfunction
endclass

// --- Generator (기존 형식 유지) ---
class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction

    task run(int run_count);
        repeat (run_count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.display("gen");
            @(gen_next_ev);
        end
    endtask
endclass

// --- Scoreboard (통합 검증용 report 포함) ---
class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;
    
    bit [7:0] expected_q[$]; // Driver가 채워주는 큐
    
    // 발표용 통계 변수
    int total_cnt = 0;
    int pass_cnt  = 0;
    int fail_cnt  = 0;

    function new(mailbox #(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev = gen_next_ev;
    endfunction

    // Driver에서 호출하여 예상 데이터 적립
    task add_expected(bit [7:0] data);
        expected_q.push_back(data);
    endtask

    task run();
        bit [7:0] exp_data;
        forever begin
            mon2scb_mbox.get(tr); // Monitor로부터 데이터 수신
            total_cnt++;
            
            if (expected_q.size() > 0) begin
                exp_data = expected_q.pop_front();
                
                // --- Pass / Fail 판정 로직 ---
                if (tr.rx_data === exp_data) begin
                    $display("[%t] SCB: [PASS] Expected: 8'h%h | Got: 8'h%h", $time, exp_data, tr.rx_data);
                    pass_cnt++;
                end else begin
                    $display("[%t] SCB: [FAIL] Expected: 8'h%h | Got: 8'h%h", $time, exp_data, tr.rx_data);
                    fail_cnt++;
                end
            end else begin
                $display("[%t] SCB: [ERROR] No expected data but captured: 8'h%h", $time, tr.rx_data);
                fail_cnt++;
            end
            
            // 다음 데이터 생성을 위한 트리거
            -> gen_next_ev;
        end
    endtask

    // 발표 시 마지막에 호출할 리포트 함수
    function void report();
        $display("\n===========================================");
        $display("       UART LOOPBACK VERIFICATION REPORT      ");
        $display("===========================================");
        $display("  Total Transactions : %0d", total_cnt);
        $display("  PASSED             : %0d", pass_cnt);
        $display("  FAILED             : %0d", fail_cnt);
        $display("  Success Rate       : %0.2f%%", (total_cnt > 0) ? (real'(pass_cnt)/total_cnt)*100 : 0);
        $display("===========================================\n");
    endfunction
endclass

// --- Driver (Serial 인가 로직) ---
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual top_uart_interface top_if;
    scoreboard scb_handle;

    function new(mailbox#(transaction) gen2drv_mbox, virtual top_uart_interface top_if, scoreboard scb_handle);
        this.gen2drv_mbox = gen2drv_mbox;
        this.top_if = top_if;
        this.scb_handle = scb_handle;
    endfunction

    // Baudrate 타이밍 동기화 (16 ticks per bit)
    task wait_uart_ticks(int n);
        repeat(n) begin
            @(posedge top_if.clk);
            while(!top_if.b_tick) @(posedge top_if.clk);
        end
    endtask

    task run();
        top_if.uart_rx = 1'b1; // Idle
        forever begin
            gen2drv_mbox.get(tr);
            scb_handle.add_expected(tr.rx_data);

            // Serial 전송 시퀀스
            top_if.uart_rx = 1'b0; // Start bit
            wait_uart_ticks(16); 
            for (int i = 0; i < 8; i++) begin
                top_if.uart_rx = tr.rx_data[i];
                wait_uart_ticks(16);
            end
            top_if.uart_rx = 1'b1; // Stop bit
            wait_uart_ticks(16); 
        end
    endtask
endclass

// --- Monitor (Loopback Serial 캡처) ---
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual top_uart_interface top_if;

    function new(mailbox#(transaction) mon2scb_mbox, virtual top_uart_interface top_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.top_if = top_if;
    endfunction

    task wait_uart_ticks(int n);
        repeat(n) begin
            @(posedge top_if.clk);
            while(!top_if.b_tick) @(posedge top_if.clk);
        end
    endtask

    task run();
        bit [7:0] captured_data;
        forever begin
            @(negedge top_if.uart_tx); // Start bit 감지
            wait_uart_ticks(8);        // 중앙으로 이동
            
            for (int i = 0; i < 8; i++) begin
                wait_uart_ticks(16);   // 다음 비트 중앙
                captured_data[i] = top_if.uart_tx;
            end
            
            wait_uart_ticks(16);       // Stop bit 구간 대기
            
            tr = new();
            tr.rx_data = captured_data;
            $display("[%t] MON capture data from TX line -> 8'h%h", $time, tr.rx_data);
            mon2scb_mbox.put(tr);
        end
    endtask
endclass

// --- Environment ---
class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    function new(virtual top_uart_interface top_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        scb = new(mon2scb_mbox, gen_next_ev);
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, top_if, scb); 
        mon = new(mon2scb_mbox, top_if);
    endfunction

    task run();
        fork
            gen.run(100); // 20개 테스트
            drv.run();
            mon.run();
            scb.run();
        join_any
        #3000000; // UART는 느리므로 충분히 대기 (Baudrate 9600 기준)
        scb.report();
        $finish;
    endtask
endclass

// --- Testbench Top ---
module tb_top_uart ();
    bit clk;
    bit b_tick;

    always #5 clk = ~clk; // 100MHz

    // DUT의 Baudrate와 동기화된 b_tick 생성 (또는 DUT 내부 신호 assign 가능)
    // 여기서는 검증의 편의를 위해 DUT와 동일한 조건으로 생성합니다.
    initial begin
        b_tick = 0;
        forever begin
            repeat(651) @(posedge clk); // 100MHz / (9600*16) = 약 651
            b_tick = 1;
            @(posedge clk);
            b_tick = 0;
        end
    end

    top_uart_interface top_if();
    assign top_if.clk = clk;
    assign top_if.b_tick = b_tick;

    top_uart dut (
        .clk(top_if.clk),
        .rst(top_if.rst),
        .uart_rx(top_if.uart_rx),
        .uart_tx(top_if.uart_tx)
    );

    environment env;

    initial begin
        top_if.rst = 1;
        #20 top_if.rst = 0;
        env = new(top_if);
        env.run();
    end
endmodule