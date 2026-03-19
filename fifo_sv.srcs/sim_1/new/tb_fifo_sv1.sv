`timescale 1ns / 1ps
interface fifo_interface;
    logic       clk;
    logic       rst;
    logic       we;
    logic       re;
    logic [7:0] w_data;
    logic [7:0] r_data;
    logic       full;
    logic       empty;
    endinterface



class transaction;

    rand bit [7:0] w_data;
    rand bit we;
    rand bit re;
    rand bit full;
    rand bit empty;
    logic [7:0] r_data;

    function  void display(string name);
        $display("[%t : %s we = %d,re = %d, wdata = %2h, rdata= %2h ]",$time, name, we,re,w_data,r_data);
        
    endfunction

    function new();
        
    endfunction //new()
endclass //transaction

class generator;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;


    function new(mailbox #(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev = gen_next_ev;
    endfunction //new()


    task run(int run_count);
        repeat(run_count) begin
        tr = new();
        tr.randomize();
        gen2drv_mbox.put(tr);
        tr.display("gen");
        @(gen_next_ev);
        end

    endtask 
endclass //generator


class driver;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual fifo_interface fifo_if;


    function new(mailbox #(transaction) gen2drv_mbox,
                virtual fifo_interface fifo_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.fifo_if = fifo_if;
    endfunction //new()

    task  run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge fifo_if.clk);
            fifo_if.w_data = tr.w_data;
            // fifo_if.r_data = tr.r_data;
            // fifo_if.full = tr.full;
            // fifo_if.empty = tr.empty;
            
            fifo_if.we = tr.we;
            fifo_if.re = tr.re;
            tr.display("drv");
        end
    endtask //
endclass //driver


class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual fifo_interface fifo_if;


    function new(mailbox #(transaction) mon2scb_mbox, virtual fifo_interface fifo_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fifo_if = fifo_if;
        
    endfunction //new()

    task  run();
        forever begin
            @(posedge fifo_if.clk);
            #1;
            tr              = new();
            tr.w_data     = fifo_if.w_data;
            tr.r_data     = fifo_if.r_data;
            tr.we         = fifo_if.we;
            tr.re         = fifo_if.re;
            tr.full       = fifo_if.full;
            tr.empty      = fifo_if.empty;
            tr.display("mon");
            mon2scb_mbox.put(tr);
        end 
    endtask //
endclass //monitor

// class scoreboard;

//     transaction tr;
//     mailbox #(transaction) mon2scb_mbox;
//     event gen_next_ev;


//     function new(mailbox #(transaction) mon2scb_mbox, event gen_next_ev);
//         this.mon2scb_mbox = mon2scb_mbox;
//         this.gen_next_ev = gen_next_ev;

        
//     endfunction //new()

//     task  run();
//     logci [7:0] expected_ram[0:15];
//         forever begin
//             mon2scb_mbox.get(tr);
//             tr.display("scb");
//             if(tr.we) begin
//                 expected_ram[]
//             end
//         end
//     endtask //
// endclass //scoreboard
class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    // 1. 데이터를 임시로 저장할 큐 (FIFO 모델)
    bit [7:0] expected_q[$]; 

    function new(mailbox #(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev = gen_next_ev;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            
            // 2. 쓰기(we/push) 동작 시 큐에 저장
            if(tr.we && !tr.full) begin
                expected_q.push_back(tr.w_data);
                $display("[SCB]stock: %h", tr.w_data);
            end

            // 3. 읽기(re/pop) 동작 시 큐에서 꺼내어 비교
            if(tr.re && !tr.empty) begin
                bit [7:0] exp_data;
                if(expected_q.size() != 0) begin
                    exp_data = expected_q.pop_front(); // 가장 먼저 들어온 데이터 꺼내기
                    if(tr.r_data === exp_data) begin
                        $display("[SCB] PASS: exp=%h, got=%h", exp_data, tr.r_data);
                    end else begin
                        $display("[SCB] FAIL: exp=%h, got=%h", exp_data, tr.r_data);
                    end
                end
            end
            
            -> gen_next_ev;
        end
    endtask
endclass


class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
  

    event gen_next_ev;



    function new(virtual fifo_interface fifo_if);
         gen2drv_mbox = new;
         mon2scb_mbox = new;
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, fifo_if);
        mon = new(mon2scb_mbox, fifo_if);
        scb = new(mon2scb_mbox, gen_next_ev);
      
    endfunction //new()

    task  run();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();

        join_any
        #20;
        
        $stop;

    endtask //
endclass


module tb_fifo_sv1();
    bit clk;

    always #5 clk = ~clk;

    fifo_interface fifo_if();
    assign fifo_if.clk = clk;

    fifo_sv dut(

    .clk(clk),
    .rst(fifo_if.rst),
    .push(fifo_if.we),
    .pop(fifo_if.re),
    .push_data(fifo_if.w_data),
    .pop_data(fifo_if.r_data),
    .full(fifo_if.full),
    .empty(fifo_if.empty)
);

environment env;
initial begin
    fifo_if.rst = 1'b1;
    #1;
    fifo_if.rst = 1'b0;

    env = new(fifo_if);
    env.run();
end

endmodule
