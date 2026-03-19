// `timescale 1ns / 1ps

// interface rx_interface;

//     logic       clk;
//     logic       rst;
//     logic       rx;
//     logic       b_tick;
//     logic [7:0] rx_data;
//     logic       rx_done;

// endinterface  //

// class transaction;

//     rand bit [7:0] rx_data;
//     // 디버깅을 위한 출력 함수
//     function void display(string name);
//         $display("[%t] %s: data = 8'h%h (binary: %b)", $time, name, rx_data, rx_data);
//     endfunction
// endclass  //transaction


// class generator;
//     transaction tr;
//     mailbox #(transaction) gen2drv_mbox;
//     event gen_next_ev;



//     function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
//         this.gen2drv_mbox = gen2drv_mbox;
//         this.gen_next_ev  = gen_next_ev;
//     endfunction  //new()


//     task run(int run_count);
//         repeat (run_count) begin
//             tr = new();
//             tr.randomize();
//             gen2drv_mbox.put(tr);
//             tr.display("gen");
//             @(gen_next_ev);
//         end
//     endtask  //
// endclass  //generator

// class driver;
//     transaction tr;
//     mailbox #(transaction) gen2drv_mbox;
//     virtual rx_interface rx_if;
//     scoreboard scb_handle; // Scoreboard에 기대값을 넣어주기 위해 추가


//     function new(mailbox#(transaction) gen2drv_mbox,
//                  virtual rx_interface rx_if);
//         this.gen2drv_mbox = gen2drv_mbox;
//         this.rx_if = rx_if;

//     endfunction  //new()


//     // b_tick을 N번 기다리는 보조 task
//     task wait_uart_ticks(int n);
//         repeat(n) begin
//             @(posedge rx_if.clk);
//             while(!rx_if.b_tick) @(posedge rx_if.clk);
//         end
//     endtask

//     task run();
//         // 초기 상태: UART Idle은 High(1)
//         rx_if.rx = 1'b1;

//         forever begin
//             gen2drv_mbox.get(tr);
//             // tr.display("drv"); // 로그 확인용
//             // 드라이버가 쏘기 전에 스코어보드 큐에 저장
//             scb_handle.add_expected(tr.rx_data);

//             // --- [Start Bit (0)] ---
//             // 이전 데이터의 Stop 비트가 끝나자마자 바로 0으로 떨어뜨림
//             rx_if.rx = 1'b0;
//             wait_uart_ticks(16); 

//             // --- [Data Bits (8 bits, LSB first)] ---
//             for (int i = 0; i < 8; i++) begin
//                 rx_if.rx = tr.rx_data[i];
//                 wait_uart_ticks(16);
//             end

//             // --- [Stop Bit (1)] ---
//             rx_if.rx = 1'b1;
//             wait_uart_ticks(16); 
            
//             // 여기서 대기(Idle Gap) 없이 바로 다음 루프(forever)의 get(tr)로 이동하여 
//             // 다음 Start Bit(0)를 즉시 시작합니다.
//         end
//     endtask
// endclass  //driver


// class monitor;

//     transaction tr;
//     mailbox #(transaction) mon2scb_mbox;
//     virtual rx_interface rx_if;


//     function new(mailbox#(transaction) mon2scb_mbox,
//                  virtual rx_interface rx_if);
//         this.mon2scb_mbox = mon2scb_mbox;
//         this.rx_if = rx_if;

//     endfunction  //new()

//     task run();
//         forever begin
//             @(posedge rx_if.clk);
//             #1;
//             if (rx_if.rx_done) begin
//             tr         = new();
//             tr.rx_data = rx_if.rx_data;
//             // tr.rx_done    = rx_if.rx_done;
//             $display("[%t] MON: 데이터 수신 포착! -> 8'h%h", $time, tr.rx_data);
//             mon2scb_mbox.put(tr);
//             end


//         end
//     endtask  //


// endclass  //monitor


// class scoreboard;
//     transaction tr;
//     mailbox #(transaction) mon2scb_mbox;
//     event gen_next_ev;
//     bit [7:0] exp_data;

//     logic [7:0] expected_q[$];
//     int total_cnt;
//     int pass_cnt;
//     int fail_cnt;


//     function new(mailbox #(transaction) mon2scb_mbox, event gen_next_ev);
//         this.mon2scb_mbox = mon2scb_mbox;
//         this.gen_next_ev = gen_next_ev;
        
//     endfunction //new()

//     task  add_expected(bit [7:0] data);
//         expected_q.push_back(data);
        
//     endtask //

//     task  run();
//         forever begin
//             mon2scb_mbox.get(tr);
//             total_cnt ++;
//             $display("[%t] SCB: 모니터로부터 데이터 획득 = 8'h%h", $time, tr.rx_data);

//             if (expected_q.size() >0) begin
//                 bit [7:0] exp_data = expected_q.pop_front();

//             if (tr.rx_data === exp_data) begin
//                 $display("  => [PASS] Expected: 8'h%h | Got: 8'h%h", exp_data, tr.rx_data);
//                     pass_cnt++;
//                 end else begin
//                     $display("  => [FAIL] Expected: 8'h%h | Got: 8'h%h", exp_data, tr.rx_data);
//                     fail_cnt++;
//                 end 
//                 end else begin
//                     $display("  => [ERROR] 기대값 큐가 비어있는데 데이터가 수신되었습니다!");
//                 fail_cnt++;
//             end
//             -> gen_next_ev;
//         end
//     endtask //

//     function void report();
//         $display("\n------- UART RX Verification Report -------");
//         $display("  Total Transactions : %0d", total_cnt);
//         $display("  Passed             : %0d", pass_cnt);
//         $display("  Failed             : %0d", fail_cnt);
//         $display("-------------------------------------------\n");
//     endfunction

// endclass //

// class environment;

//     generator gen;
//     driver drv;
//     monitor mon;
//     scoreboard scb;

//     mailbox #(transaction) gen2drv_mbox;
//     mailbox #(transaction) mon2scb_mbox;

//     event gen_next_ev;


//     function new(virtual rx_interface rx_if);
//         gen2drv_mbox = new();
//         mon2scb_mbox = new();
//         gen = new(gen2drv_mbox,gen_next_ev);
//         scb = new(mon2scb_mbox, gen_next_ev);
//         drv = new(gen2drv_mbox, rx_if, scb);
//         mon = new(mon2scb_mbox, rx_if);
        
//     endfunction //new()

//     task  run();
//         fork
//             gen.run(10);
//             drv.run();
//             mon.run();
//             scb.run();

//         join_any
//         #20;
//         $stop;
//     endtask //
// endclass //


// module tb_uart_rx ();

//     bit clk;

//     always #5 clk = ~clk;

//     initial begin
//         b_tick = 0;
//         forever begin
//             repeat(10) @(posedge clk); // 10클럭마다 틱 발생 (가정)
//             b_tick = 1;
//             @(posedge clk);
//             b_tick = 0;
//         end
//     end

//     rx_interface rx_if();
//     assign rx_if.clk = clk;
//     assign rx_if.b_tick = b_tick;


//     uart_rx dut (
//         .clk(clk),
//         .rst(rx_if.rst),
//         .rx(rx_if.rx),
//         .b_tick(rx_if.b_tick),
//         .rx_data(rx_if.rx_data),
//         .rx_done(rx_if.rx_done)
//     );

//     environment env;

//     initial begin
//         rx_if.rst = 1;
//         #20 rx_if.rst = 0;
//         env = new(rx_if);
//         env.run();
//     end
// endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//`timescale 1ns / 1ps
//
//interface rx_interface;
//    logic       clk;
//    logic       rst;
//    logic       rx;
//    logic       b_tick;
//    logic [7:0] rx_data;
//    logic       rx_done;
//endinterface
//
//class transaction;
//    rand bit [7:0] rx_data;
//    function void display(string name);
//        $display("[%t] %s: data = 8'h%h (binary: %b)", $time, name, rx_data, rx_data);
//    endfunction
//endclass
//
//
//class generator;
//    transaction tr;
//    mailbox #(transaction) gen2drv_mbox;
//    event gen_next_ev;
//
//    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
//        this.gen2drv_mbox = gen2drv_mbox;
//        this.gen_next_ev  = gen_next_ev;
//    endfunction
//
//    task run(int run_count);
//        repeat (run_count) begin
//            tr = new();
//            tr.randomize();
//            gen2drv_mbox.put(tr);
//            tr.display("gen");
//            @(gen_next_ev);
//        end
//    endtask
//endclass
//
//// --- Scoreboard 클래스 (순서 최적화) ---
//class scoreboard;
//    transaction tr;
//    mailbox #(transaction) mon2scb_mbox;
//    event gen_next_ev;
//    bit [7:0] expected_q[$];
//    int total_cnt = 0;
//    int pass_cnt = 0;
//    int fail_cnt = 0;
//
//    function new(mailbox #(transaction) mon2scb_mbox, event gen_next_ev);
//        this.mon2scb_mbox = mon2scb_mbox;
//        this.gen_next_ev = gen_next_ev;
//    endfunction
//
//    task add_expected(bit [7:0] data);
//        expected_q.push_back(data);
//    endtask
//
//    task run();
//        bit [7:0] exp_data; // 로컬 변수로 사용
//        forever begin
//            mon2scb_mbox.get(tr);
//            total_cnt++;
//            $display("[%t] SCB: data from monitor = 8'h%h", $time, tr.rx_data);
//
//            if (expected_q.size() > 0) begin
//                exp_data = expected_q.pop_front();
//                if (tr.rx_data === exp_data) begin
//                    $display("  => [PASS] Expected: 8'h%h | Got: 8'h%h", exp_data, tr.rx_data);
//                    pass_cnt++;
//                end else begin
//                    $display("  => [FAIL] Expected: 8'h%h | Got: 8'h%h", exp_data, tr.rx_data);
//                    fail_cnt++;
//                end 
//            end else begin
//                $display("  => [ERROR] ");///큐가 비어있는데 데이터가 수신된 경우
//                fail_cnt++;
//            end
//            -> gen_next_ev;
//        end
//    endtask
//
//    function void report();
//        $display("\n------- UART RX Verification Report -------");
//        $display("  Total Transactions : %0d", total_cnt);
//        $display("  Passed             : %0d", pass_cnt);
//        $display("  Failed             : %0d", fail_cnt);
//        $display("-------------------------------------------\n");
//    endfunction
//endclass
//
//class driver;
//    transaction tr;
//    mailbox #(transaction) gen2drv_mbox;
//    virtual rx_interface rx_if;
//    scoreboard scb_handle;
//
//    function new(mailbox#(transaction) gen2drv_mbox, virtual rx_interface rx_if, scoreboard scb_handle);
//        this.gen2drv_mbox = gen2drv_mbox;
//        this.rx_if = rx_if;
//        this.scb_handle = scb_handle;
//    endfunction
//
//    task wait_uart_ticks(int n);
//        repeat(n) begin
//            @(posedge rx_if.clk);
//            while(!rx_if.b_tick) @(posedge rx_if.clk);
//        end
//    endtask
//
//    task run();
//        rx_if.rx = 1'b1;
//        forever begin
//            gen2drv_mbox.get(tr);
//            scb_handle.add_expected(tr.rx_data);
//
//            rx_if.rx = 1'b0; // Start bit
//            wait_uart_ticks(16); 
//            for (int i = 0; i < 8; i++) begin
//                rx_if.rx = tr.rx_data[i];
//                wait_uart_ticks(16);
//            end
//            rx_if.rx = 1'b1; // Stop bit
//            wait_uart_ticks(16); 
//        end
//    endtask
//endclass
//
//class monitor;
//    transaction tr;
//    mailbox #(transaction) mon2scb_mbox;
//    virtual rx_interface rx_if;
//
//    function new(mailbox#(transaction) mon2scb_mbox, virtual rx_interface rx_if);
//        this.mon2scb_mbox = mon2scb_mbox;
//        this.rx_if = rx_if;
//    endfunction
//
//    task run();
//        forever begin
//            @(posedge rx_if.clk);
//            if (rx_if.rx_done) begin
//                tr = new();
//                tr.rx_data = rx_if.rx_data;
//                $display("[%t] MON capcuture data-> 8'h%h", $time, tr.rx_data);
//                mon2scb_mbox.put(tr);
//            end
//        end
//    endtask
//endclass
//
//
//
//class environment;
//    generator gen;
//    driver drv;
//    monitor mon;
//    scoreboard scb;
//    mailbox #(transaction) gen2drv_mbox;
//    mailbox #(transaction) mon2scb_mbox;
//    event gen_next_ev;
//
//    function new(virtual rx_interface rx_if);
//        gen2drv_mbox = new();
//        mon2scb_mbox = new();
//        
//        // 중요: 생성 순서! scb를 먼저 만들어야 drv에게 줄 수 있습니다.
//        scb = new(mon2scb_mbox, gen_next_ev);
//        gen = new(gen2drv_mbox, gen_next_ev);
//        drv = new(gen2drv_mbox, rx_if, scb); 
//        mon = new(mon2scb_mbox, rx_if);
//    endfunction
//
//    task run();
//        fork
//            gen.run(10);
//            drv.run();
//            mon.run();
//            scb.run();
//        join_any
//        #2000; // 결과가 SCB에 도달할 때까지 충분히 대기
//        scb.report();
//        $finish;
//    endtask
//endclass
//
//module tb_uart_rx ();
//    bit clk;
//    bit b_tick; // 선언 추가
//
//    always #5 clk = ~clk;
//
//    initial begin
//        b_tick = 0;
//        forever begin
//            repeat(10) @(posedge clk); 
//            b_tick = 1;
//            @(posedge clk);
//            b_tick = 0;
//        end
//    end
//
//    rx_interface rx_if();
//    assign rx_if.clk = clk;
//    assign rx_if.b_tick = b_tick;
//
//    uart_rx dut (
//        .clk(rx_if.clk),
//        .rst(rx_if.rst),
//        .rx(rx_if.rx),
//        .b_tick(rx_if.b_tick),
//        .rx_data(rx_if.rx_data),
//        .rx_done(rx_if.rx_done)
//    );
//
//    environment env;
//
//    initial begin
//        rx_if.rst = 1;
//        #20 rx_if.rst = 0;
//        env = new(rx_if);
//        env.run();
//    end
//endmodule
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

// ==========================================
// 1. Interface
// ==========================================
interface rx_interface;
    logic       clk, rst, rx, b_tick, rx_done;
    logic [7:0] rx_data;
endinterface

// ==========================================
// 2. Transaction & Generator
// ==========================================
class transaction;
    rand bit [7:0] rx_data;
    function void display(string name);
        $display("[%t] %s: data = 8'h%h", $time, name, rx_data);
    endfunction
endclass

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
            @(gen_next_ev);
        end
    endtask
endclass

// ==========================================
// 3. Scoreboard
// ==========================================
class scoreboard;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;
    bit [7:0] expected_q[$];
    int total_cnt, pass_cnt, fail_cnt;

    function new(mailbox #(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev = gen_next_ev;
    endfunction

    function void add_expected(bit [7:0] data);
        expected_q.push_back(data);
    endfunction

    task run();
        transaction tr;
        bit [7:0] exp_data;
        forever begin
            mon2scb_mbox.get(tr);
            total_cnt++;
            if (expected_q.size() > 0) begin
                exp_data = expected_q.pop_front();
                if (tr.rx_data === exp_data) begin
                    $display("[%t] SCB: [PASS] Exp: 8'h%h | Got: 8'h%h", $time, exp_data, tr.rx_data);
                    pass_cnt++;
                end else begin
                    $display("[%t] SCB: [FAIL] Exp: 8'h%h | Got: 8'h%h", $time, exp_data, tr.rx_data);
                    fail_cnt++;
                end 
            end else begin
                $display("[%t] SCB: [glich!!] ", $time);
                fail_cnt++;
            end
            -> gen_next_ev;
        end
    endtask

    function void report();
        $display("\n======= UART RX REPORT =======");
        $display(" Pass: %0d, Fail: %0d", pass_cnt, fail_cnt);
        $display("==============================\n");
    endfunction
endclass

// ==========================================
// 4. Driver (글리치 생성 로직 수정)
// ==========================================
class driver;
    mailbox #(transaction) gen2drv_mbox;
    virtual rx_interface rx_if;
    scoreboard scb_handle;

    function new(mailbox#(transaction) gen2drv_mbox, virtual rx_interface rx_if, scoreboard scb_handle);
        this.gen2drv_mbox = gen2drv_mbox;
        this.rx_if = rx_if;
        this.scb_handle = scb_handle;
    endfunction

    // b_tick을 n번 기다리는 테스크
    task wait_uart_ticks(int n);
        repeat(n) begin
            @(posedge rx_if.clk);
            while(!rx_if.b_tick) @(posedge rx_if.clk);
        end
    endtask

    // 수정된 글리치 테스크: b_tick 기반으로 확실히 0을 유지함
    task send_glitch(int ticks);
        $display("[%t] DRV: glich start ( for%0d ticks rx=0)", $time, ticks);
        rx_if.rx = 1'b0;      // rx를 0으로
        wait_uart_ticks(ticks); // 지정된 틱만큼 유지 (예: 4틱)
        rx_if.rx = 1'b1;      // 다시 1로 복구
        $display("[%t] DRV: glich stop", $time);
    endtask

    task run();
        transaction tr;
        rx_if.rx = 1'b1;
        forever begin
            gen2drv_mbox.get(tr);
            scb_handle.add_expected(tr.rx_data);
            
            rx_if.rx = 1'b0; wait_uart_ticks(16); // Start
            for (int i=0; i<8; i++) begin
                rx_if.rx = tr.rx_data[i]; wait_uart_ticks(16); // Data
            end
            rx_if.rx = 1'b1; wait_uart_ticks(16); // Stop
        end
    endtask
endclass

// ==========================================
// 5. Monitor & Environment
// ==========================================
class monitor;
    mailbox #(transaction) mon2scb_mbox;
    virtual rx_interface rx_if;

    function new(mailbox#(transaction) mon2scb_mbox, virtual rx_interface rx_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.rx_if = rx_if;
    endfunction

    task run();
        transaction tr;
        forever begin
            @(posedge rx_if.clk);
            if (rx_if.rx_done) begin
                tr = new();
                tr.rx_data = rx_if.rx_data;
                mon2scb_mbox.put(tr);
            end
        end
    endtask
endclass

class environment;
    generator gen; driver drv; monitor mon; scoreboard scb;
    mailbox #(transaction) g2d, m2s;
    event gen_next;
    virtual rx_interface rx_if;

    function new(virtual rx_interface rx_if);
        this.rx_if = rx_if;
        g2d = new(); m2s = new();
        scb = new(m2s, gen_next);
        gen = new(g2d, gen_next);
        drv = new(g2d, rx_if, scb);
        mon = new(m2s, rx_if);
    endfunction

    task run(int count);
        fork
            scb.run(); mon.run(); drv.run();
            begin
                #100; // 초기화 대기
                // 8틱 미만의 글리치(예: 4틱)를 발생시킴
                // DUT가 8틱 지점에서 rx를 재검사한다면 이 신호는 무시되어야 함
                drv.send_glitch(4); 
                
                // 글리치 무시 여부를 확인하기 위해 한 프레임 이상 충분히 대기
                drv.wait_uart_ticks(200); 
                
                // 그 다음 정상 데이터 전송
                gen.run(count);      
            end
        join_any
        #1000000; scb.report(); $finish;
    endtask
endclass

// ==========================================
// 6. Top
// ==========================================
module tb_uart_rx ();
    bit clk, b_tick;
    always #5 clk = ~clk;

    initial begin
        b_tick = 0;
        forever begin
            repeat(10) @(posedge clk);
            b_tick = 1; @(posedge clk); b_tick = 0;
        end
    end

    rx_interface rx_if();
    assign rx_if.clk = clk;
    assign rx_if.b_tick = b_tick;

    uart_rx dut (
        .clk(rx_if.clk), .rst(rx_if.rst), .rx(rx_if.rx),
        .b_tick(rx_if.b_tick), .rx_data(rx_if.rx_data), .rx_done(rx_if.rx_done)
    );

    environment env;
    initial begin
        rx_if.rst = 1; rx_if.rx = 1;
        #100 rx_if.rst = 0;
        env = new(rx_if);
        env.run(5); 
    end
endmodule