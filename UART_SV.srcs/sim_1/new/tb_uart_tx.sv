`timescale 1ns / 1ps

// --- Interface ---
interface tx_interface;
    logic       clk;
    logic       rst;
    logic       tx_start;
    logic       b_tick;
    logic [7:0] tx_data;
    logic       uart_tx;
    logic       tx_busy;
    logic       tx_done;
endinterface

// --- Transaction ---
class transaction;
    rand bit [7:0] tx_data;
    function void display(string name);
        $display ("[%t] %s: data = 8'h%h", $time, name, tx_data);
    endfunction
endclass

// --- Generator ---
class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox #(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev = gen_next_ev;
    endfunction

    task run(int run_count);
        repeat (run_count) begin
            tr = new();
            if(!tr.randomize()) $error("Randomization failed!");
            gen2drv_mbox.put(tr);
            tr.display("GEN");
            @(gen_next_ev); // Scoreboard에서 신호를 줄 때까지 대기
        end
    endtask
endclass

// --- Scoreboard ---
class scoreboard;
    transaction tr_mon;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;
    bit [7:0] expected_q[$]; 
    
    int pass_cnt, fail_cnt, error_cnt;

    function new(mailbox #(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev = gen_next_ev;
        pass_cnt = 0; fail_cnt = 0; error_cnt = 0;
    endfunction

    task run();
        bit [7:0] exp;
        forever begin
            mon2scb_mbox.get(tr_mon); 
            if (expected_q.size() > 0) begin
                exp = expected_q.pop_front();
                if (tr_mon.tx_data === exp) begin
                    $display("[%t] SCB: => [PASS] Exp: %h | Got: %h", $time, exp, tr_mon.tx_data);
                    pass_cnt++;
                end else begin
                    $display("[%t] SCB: => [FAIL] Exp: %h | Got: %h", $time, exp, tr_mon.tx_data);
                    fail_cnt++;
                end
            end else begin
                $display("[%t] SCB: => [ERROR] Unexpected data: %h", $time, tr_mon.tx_data);
                error_cnt++;
            end
            -> gen_next_ev; // Generator에게 다음 데이터 생성 요청
        end
    endtask

    function void report();
        $display("\n-----------------------------------------");
        $display("       FINAL TEST CASE REPORT          ");
        $display("-----------------------------------------");
        $display("  Total Passed : %0d", pass_cnt);
        $display("  Total Failed : %0d", fail_cnt);
        $display("-----------------------------------------");
        if(fail_cnt == 0 && pass_cnt > 0) $display("  RESULT: SUCCESS");
        else $display("  RESULT: FAIL");
        $display("-----------------------------------------\n");
    endfunction
endclass

// --- Driver ---
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual tx_interface tx_if;
    scoreboard scb_handle;

    function new(mailbox #(transaction) gen2drv_mbox, virtual tx_interface tx_if, scoreboard scb_handle);
        this.gen2drv_mbox = gen2drv_mbox;
        this.tx_if = tx_if;
        this.scb_handle = scb_handle;
    endfunction

    task run();
        tx_if.tx_start = 0;
        forever begin
            gen2drv_mbox.get(tr);
            scb_handle.expected_q.push_back(tr.tx_data);
            
            wait(tx_if.tx_busy == 0); 
            @(posedge tx_if.clk);
            tx_if.tx_data = tr.tx_data;
            tx_if.tx_start = 1'b1;
            @(posedge tx_if.clk);
            tx_if.tx_start = 1'b0;
            $display("[%t] DRV: Sent 8'h%h", $time, tr.tx_data);
        end
    endtask
endclass

// --- Monitor ---
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual tx_interface tx_if;

    function new(mailbox #(transaction) mon2scb_mbox, virtual tx_interface tx_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.tx_if = tx_if;
    endfunction

    task run();
        bit [7:0] captured_data;
        forever begin
            @(negedge tx_if.uart_tx); // Start bit
            repeat(8) @(posedge tx_if.clk) while(!tx_if.b_tick) @(posedge tx_if.clk);
            
            for (int i=0; i<8; i++) begin
                repeat(16) @(posedge tx_if.clk) while(!tx_if.b_tick) @(posedge tx_if.clk);
                captured_data[i] = tx_if.uart_tx;
            end
            
            repeat(16) @(posedge tx_if.clk) while(!tx_if.b_tick) @(posedge tx_if.clk); // Stop bit
            
            tr = new();
            tr.tx_data = captured_data;
            $display("[%t] MON: Captured 8'h%h", $time, tr.tx_data);
            mon2scb_mbox.put(tr);
        end
    endtask
endclass

// --- Environment ---
class environment;
    generator gen;
    driver drv;
    scoreboard scb;
    monitor mon;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;
    virtual tx_interface tx_if;

    function new(virtual tx_interface tx_if);
        this.tx_if = tx_if;
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        scb = new(mon2scb_mbox, gen_next_ev);
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, tx_if, scb);
        mon = new(mon2scb_mbox, tx_if);
    endfunction

    task run();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
        
        // 데이터가 Scoreboard까지 처리될 시간을 위해 큐가 빌 때까지 대기
        wait(scb.expected_q.size() == 0);
        #1000;
        scb.report();
        $finish;
    endtask
endclass

// --- Testbench Top ---
module tb_uart_tx();
    bit clk;
    bit b_tick;

    always #5 clk = ~clk;

    initial begin
        b_tick = 0;
        forever begin
            repeat(10) @(posedge clk);
            b_tick = 1;
            @(posedge clk);
            b_tick = 0;
        end
    end

    tx_interface tx_if();
    assign tx_if.clk = clk;
    assign tx_if.b_tick = b_tick;

    uart_tx dut (
        .clk(tx_if.clk), .rst(tx_if.rst), .tx_start(tx_if.tx_start),
        .b_tick(tx_if.b_tick), .tx_data(tx_if.tx_data),
        .uart_tx(tx_if.uart_tx), .tx_busy(tx_if.tx_busy), .tx_done(tx_if.tx_done)
    );

    environment env;

    initial begin
        // 초기화 필수
        tx_if.rst = 1;
        tx_if.tx_start = 0;
        tx_if.tx_data = 0;
        
        #20 tx_if.rst = 0;
        env = new(tx_if);
        env.run();
    end
endmodule