`timescale 1ns / 1ps

interface ram_interface(input clk);

    logic        we;
    logic [3:0]  addr;
    logic [7:0]  wdata;
    logic [7:0] rdata;
endinterface //ram_interface


class transaction;

    rand bit [3:0] addr;
    rand bit [7:0] wdata;
    rand bit       we;
    logic [7:0]    rdata;

    function display(string name);
        $display("[%t : %s we = %d, addr = %2h, wdata = %2h, radata = %2h]",$time, name, we,addr, wdata,rdata);
        
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
        @(gen_next_ev);
        end

    endtask //
endclass //generator

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual ram_interface ram_if;



    function new(mailbox #(transaction) mon2scb_mbox, virtual ram_interface ram_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.ram_if = ram_if;
    endfunction //new()

    task  run();
        forever begin
            tr = new();
            @(posedge ram_if.clk);
            #1;
            tr.wdata = ram_if.wdata;
            tr.we = ram_if.we;
            tr.rdata = ram_if.rdata;
            mon2scb_mbox.put(tr);
            tr.display("mon"); 
            end
    endtask //
endclass //monitor



class scoreboard;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;
    int pass_cnt, fail_cnt, try_cnt;

    function new(mailbox #(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev = gen_next_ev;

    endfunction //new()

    task  run();
        pass_cnt = 0;
        fail_cnt = 0;
        try_cnt = 0;
        forever begin
            mon2scb_mbox.get(tr);
            try_cnt++;
            if(tr.we)
            if (tr.wdata == tr.rdata) begin
                $display("%t : pass : wdata = %h, rdata = %h",$time,tr.wdata, tr.rdata);
                pass_cnt ++;
            end else begin
                 $display("%t : fail : wdata = %h, rdata = %h",$time,tr.wdata, tr.rdata);
                fail_cnt++;
            end
            tr.display("scb");
            -> gen_next_ev;
        end
    endtask //
endclass //scoreboard

class driver;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual ram_interface ram_if;


    function new(mailbox #(transaction) gen2drv_mbox, 
                            virtual ram_interface ram_if);
        this.gen2drv_mbox =  gen2drv_mbox;
        this.ram_if = ram_if;
    endfunction //new()

    // task  preset();
    //     ram_if.clk = 0;
    //     ram_if.addr = 0;
    //     ram_if.wdata = 0;
    //     ram_if.we = 0;
    //     @(posedge ram_if.clk);
    //     @(negedge ram_if.clk);
    //     @(posedge ram_if.clk);

    // endtask //


    task  run();
        forever begin
            gen2drv_mbox.get(tr);
            @(posedge ram_if.clk);
            ram_if.we = tr.we;
            ram_if.addr = tr.addr;
            ram_if.wdata = tr.wdata;
            tr.display("drv");
        end
    endtask //

endclass //driver


class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event gen_next_ev;



    function new(virtual ram_interface ram_if);
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, ram_if);
        mon = new(mon2scb_mbox, ram_if);
        scb = new(mon2scb_mbox, gen_next_ev);

    endfunction //new()

    task  run();
        // drv.preset();
        ram_if.clk =0;
        ram_if.we = 0;
        ram_if.wdata = 0;
        ram_if.addr = 0;
        #1;
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();

        join
        #20;
        $stop;

    endtask //


endclass //environment


module tb_sram_pre();


    ram_interface ram_if(clk);
    environment env;

    sram dut(
        .clk(clk),
        .we(ram_if.we),
        .addr(ram_if.addr),
        .wdata(ram_if.wdata),
        .rdata(ram_if.rdata)
    );

    always #5 ram_if.clk = ~ram_if.clk;

    initial begin
        clk = 0;
        env = new(ram_if);
        env.run();
    end
endmodule
////가상메모리,,,,,,