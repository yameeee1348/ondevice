// `timescale 1ns / 1ps

// // ==========================================
// // 1. Interface
// // ==========================================
// interface fifo_interface (input logic clk);
//     logic       rst;
//     logic       we;
//     logic       re;
//     logic [7:0] wdata;
//     logic [7:0] rdata;
//     logic       full;
//     logic       empty;
// endinterface

// // ==========================================
// // 2. Transaction
// // ==========================================
// class transaction;
//     rand bit [7:0] wdata;
//     rand bit       we;
//     rand bit       re;
//     logic    [7:0] rdata;
//     logic          full;
//     logic          empty;

//     function void display(string name);
//         $display("[%0t] %s | WE:%b RE:%b | WDATA:%h RDATA:%h | F:%b E:%b", 
//                  $time, name, we, re, wdata, rdata, full, empty);
//     endfunction
// endclass

// // ==========================================
// // 3. Generator
// // ==========================================
// class generator;
//     transaction tr;
//     mailbox #(transaction) gen2drv_mbox;
//     event gen_next_ev;

//     function new(mailbox #(transaction) gen2drv_mbox, event gen_next_ev);
//         this.gen2drv_mbox = gen2drv_mbox;
//         this.gen_next_ev = gen_next_ev;
//     endfunction

//     task run(int run_count);
//         repeat(run_count) begin
//             tr = new();
//             if (!tr.randomize()) $error("Randomization failed!");
//             gen2drv_mbox.put(tr);
//             @(gen_next_ev); // Scoreboard가 끝낼 때까지 대기
//         end
//     endtask 
// endclass

// // ==========================================
// // 4. Driver (사용자님의 PASS 로직 적용)
// // ==========================================
// class driver;
//     transaction tr;
//     mailbox #(transaction) gen2drv_mbox;
//     virtual fifo_interface fifo_if;

//     function new(mailbox #(transaction) gen2drv_mbox, virtual fifo_interface fifo_if);
//         this.gen2drv_mbox = gen2drv_mbox;
//         this.fifo_if = fifo_if;
//     endfunction

//     // 초기화 태스크
//     task reset();
//         fifo_if.rst   <= 1;
//         fifo_if.we    <= 0;
//         fifo_if.re    <= 0;
//         fifo_if.wdata <= 0;
//         repeat(5) @(posedge fifo_if.clk);
//         fifo_if.rst   <= 0;
//         $display("[%0t] DRV: Reset Released", $time);
//     endtask

//     task run();
//         forever begin
//             gen2drv_mbox.get(tr);
//             // [사용자님 로직] posedge 후 #1 뒤에 신호 인가
//             @(posedge fifo_if.clk);
//             #1; 
//             fifo_if.we    <= tr.we;
//             fifo_if.re    <= tr.re;
//             fifo_if.wdata <= tr.wdata;
//         end
//     endtask
// endclass

// // ==========================================
// // 5. Monitor (사용자님의 negedge 샘플링 적용)
// // ==========================================
// class monitor;
//     transaction tr;
//     mailbox #(transaction) mon2scb_mbox;
//     virtual fifo_interface fifo_if;

//     function new(mailbox #(transaction) mon2scb_mbox, virtual fifo_interface fifo_if);
//         this.mon2scb_mbox = mon2scb_mbox;
//         this.fifo_if = fifo_if;
//     endfunction

//     task run();
//         forever begin
//             tr = new();
//             // [사용자님 로직] negedge에서 샘플링 (안전한 시점)
//             @(negedge fifo_if.clk);
//             tr.we    = fifo_if.we;
//             tr.re    = fifo_if.re;
//             tr.wdata = fifo_if.wdata;
//             tr.rdata = fifo_if.rdata;
//             tr.full  = fifo_if.full;
//             tr.empty = fifo_if.empty;
            
//             mon2scb_mbox.put(tr);
//         end 
//     endtask
// endclass

// // ==========================================
// // 6. Scoreboard
// // ==========================================
// class scoreboard;
//     transaction tr;
//     mailbox #(transaction) mon2scb_mbox;
//     event gen_next_ev;
//     bit [7:0] fifo_queue[$]; // 무한 큐

//     function new(mailbox #(transaction) mon2scb_mbox, event gen_next_ev);
//         this.mon2scb_mbox = mon2scb_mbox;
//         this.gen_next_ev = gen_next_ev;
//     endfunction

//     task run();
//         forever begin
//             mon2scb_mbox.get(tr);
            
//             // Push 동작 체크
//             if(tr.we && !tr.full) begin
//                 fifo_queue.push_back(tr.wdata); // [사용자님 로직] back으로 push
//                 $display("[%0t] SCB: PUSH! Data:%h | Queue Size:%0d", $time, tr.wdata, fifo_queue.size());
//             end

//             // Pop 동작 체크
//             if(tr.re && !tr.empty) begin
//                 if(fifo_queue.size() > 0) begin
//                     bit [7:0] expected = fifo_queue.pop_front(); // [사용자님 로직] front에서 pop
//                     if(tr.rdata === expected)
//                         $display("[%0t] SCB: PASS! Got:%h Exp:%h", $time, tr.rdata, expected);
//                     else
//                         $display("[%0t] SCB: FAIL! Got:%h Exp:%h (Mismatch!)", $time, tr.rdata, expected);
//                 end
//             end
            
//             -> gen_next_ev; // 작업 완료 후 Generator 깨우기
//         end
//     endtask
// endclass

// // ==========================================
// // 7. Environment & Top
// // ==========================================
// class environment;
//     generator  gen;
//     driver     drv;
//     monitor    mon;
//     scoreboard scb;
//     mailbox #(transaction) g2d, m2s;
//     event gen_next;
//     virtual fifo_interface vif;

//     function new(virtual fifo_interface vif);
//         this.vif = vif;
//         g2d = new(); m2s = new();
//         gen = new(g2d, gen_next);
//         drv = new(g2d, vif);
//         mon = new(m2s, vif);
//         scb = new(m2s, gen_next);
//     endfunction

//     task run();
//         drv.reset();
//         fork
//             gen.run(50); // 50번 테스트
//             drv.run();
//             mon.run();
//             scb.run();
//         join_any
//         #100;
//         $display("--- SIMULATION FINISHED ---");
//         $stop;
//     endtask
// endclass

// module tb_fifo_sv();
//     bit clk;
//     always #5 clk = ~clk;

//     fifo_interface fifo_if(clk);

//     // RTL Instance
//     fifo dut (
//         .clk  (clk),
//         .rst  (fifo_if.rst),
//         .we   (fifo_if.we),
//         .re   (fifo_if.re),
//         .wdata(fifo_if.wdata),
//         .rdata(fifo_if.rdata),
//         .full (fifo_if.full),
//         .empty(fifo_if.empty)
//     );

//     environment env;
//     initial begin
//         env = new(fifo_if);
//         env.run();
//     end
// endmodule

`timescale 1ns / 1ps

// ==========================================
// 1. Interface
// ==========================================
interface fifo_interface (input logic clk);
    logic       rst;
    logic       we;
    logic       re;
    logic [7:0] wdata;
    logic [7:0] rdata;
    logic       full;
    logic       empty;
endinterface

// ==========================================
// 2. Transaction (제약 조건 추가)
// ==========================================
class transaction;
    rand bit [7:0] wdata;
    rand bit       we;
    rand bit       re;
    logic    [7:0] rdata;
    logic          full;
    logic          empty;

    // 기본 제약: 쓰기 확률을 높여서 Full이 잘 발생하도록 설정
    constraint basic_cfg {
        we dist {1 := 60, 0 := 40};
        re dist {1 := 10, 0 := 90}; 
    }

    function void display(string name);
        $display("[%0t] %-10s | WE:%b RE:%b | WDATA:%h RDATA:%h | F:%b E:%b", 
                 $time, name, we, re, wdata, rdata, full, empty);
    endfunction
endclass

// ==========================================
// 3. Generator
// ==========================================
class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox #(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev = gen_next_ev;
    endfunction

    task run(int run_count);
        repeat(run_count) begin
            tr = new();
            if (!tr.randomize()) $error("Randomization failed!");
            gen2drv_mbox.put(tr);
            @(gen_next_ev); 
        end
    endtask 

    // 인위적으로 Full을 만들기 위한 전용 태스크
    task fill_up(int count);
        repeat(count) begin
            tr = new();
            // 인라인 제약조건: 무조건 쓰기만 수행
            if(!tr.randomize() with { we == 1; re == 0; }) $error("Randomization failed!");
            gen2drv_mbox.put(tr);
            @(gen_next_ev);
        end
    endtask
endclass

// ==========================================
// 4. Driver (사용자님 로직 유지)
// ==========================================
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual fifo_interface fifo_if;

    function new(mailbox #(transaction) gen2drv_mbox, virtual fifo_interface fifo_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.fifo_if = fifo_if;
    endfunction

    task reset();
        fifo_if.rst   <= 1;
        fifo_if.we    <= 0;
        fifo_if.re    <= 0;
        fifo_if.wdata <= 0;
        repeat(5) @(posedge fifo_if.clk);
        fifo_if.rst   <= 0;
        $display("[%0t] DRV: Reset Released", $time);
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(posedge fifo_if.clk);
            #1; 
            fifo_if.we    <= tr.we;
            fifo_if.re    <= tr.re;
            fifo_if.wdata <= tr.wdata;
        end
    endtask
endclass

// ==========================================
// 5. Monitor (사용자님 로직 유지)
// ==========================================
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual fifo_interface fifo_if;

    function new(mailbox #(transaction) mon2scb_mbox, virtual fifo_interface fifo_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fifo_if = fifo_if;
    endfunction

    task run();
        forever begin
            tr = new();
            @(negedge fifo_if.clk);
            tr.we    = fifo_if.we;
            tr.re    = fifo_if.re;
            tr.wdata = fifo_if.wdata;
            tr.rdata = fifo_if.rdata;
            tr.full  = fifo_if.full;
            tr.empty = fifo_if.empty;
            mon2scb_mbox.put(tr);
        end 
    endtask
endclass

// ==========================================
// 6. Scoreboard (Pass/Fail 카운트 추가)
// ==========================================
class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;
    bit [7:0] fifo_queue[$]; 
    int pass_cnt = 0, fail_cnt = 0;

    function new(mailbox #(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev = gen_next_ev;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            
            // Push 동작
            if(tr.we && !tr.full) begin
                fifo_queue.push_back(tr.wdata);
                $display("[%0t] SCB: PUSH! Data:%h | Q_Size:%0d", $time, tr.wdata, fifo_queue.size());
            end

            // Pop 동작
            if(tr.re && !tr.empty) begin
                if(fifo_queue.size() > 0) begin
                    bit [7:0] expected = fifo_queue.pop_front();
                    if(tr.rdata === expected) begin
                        $display("[%0t] SCB: PASS! Got:%h Exp:%h", $time, tr.rdata, expected);
                        pass_cnt++;
                    end else begin
                        $display("[%0t] SCB: FAIL! Got:%h Exp:%h", $time, tr.rdata, expected);
                        fail_cnt++;
                    end
                end
            end
            
            if(tr.full) $display("[%0t] SCB: <--- FIFO IS FULL! --->", $time);
            
            -> gen_next_ev;
        end
    endtask

    function void report();
        $display("\n====== FINAL REPORT ======");
        $display("  PASS: %0d, FAIL: %0d", pass_cnt, fail_cnt);
        $display("==========================\n");
    endfunction
endclass

// ==========================================
// 7. Environment & Top
// ==========================================
class environment;
    generator gen; driver drv; monitor mon; scoreboard scb;
    mailbox #(transaction) g2d, m2s;
    event gen_next;
    virtual fifo_interface vif;

    function new(virtual fifo_interface vif);
        this.vif = vif;
        g2d = new(); m2s = new();
        gen = new(g2d, gen_next);
        drv = new(g2d, vif);
        mon = new(m2s, vif);
        scb = new(m2s, gen_next);
    endfunction

    task run();
        drv.reset();
        fork
            begin
                // 1. FIFO를 가득 채움 (16칸 기준, 여유있게 20번 쓰기)
                gen.fill_up(20); 
                // 2. Full 신호를 관찰하며 5번 더 쓰기 시도 (Full 유지)
                gen.fill_up(5);
                // 3. 이후 일반 랜덤 동작
                gen.run(30);
            end
            drv.run();
            mon.run();
            scb.run();
        join_any
        #500;
        scb.report();
        $display("--- SIMULATION FINISHED ---");
        $finish;
    endtask
endclass

module tb_fifo_sv();
    bit clk;
    always #5 clk = ~clk;

    fifo_interface fifo_if(clk);

    fifo dut (
        .clk  (clk),
        .rst  (fifo_if.rst),
        .we   (fifo_if.we),
        .re   (fifo_if.re),
        .wdata(fifo_if.wdata),
        .rdata(fifo_if.rdata),
        .full (fifo_if.full),
        .empty(fifo_if.empty)
    );

    environment env;
    initial begin
        env = new(fifo_if);
        env.run();
    end
endmodule