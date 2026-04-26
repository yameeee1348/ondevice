`timescale 1ns / 1ps

interface register_interface;
    logic clk;
    logic rst;
    logic we;
    logic [7:0] wdata;
    logic [7:0] rdata;

    property Preset_check;
        @(posedge clk) rst |=> (rdata == 0);
    endproperty
    reg_reset_check: assert property(Preset_check) else $display("%t: Assert error: reset check",$time);
endinterface //register_interface


class transaction;
    
    rand bit [7:0] wdata;
    rand bit       we;
    logic [7:0] rdata;    

    task  display(string name);
        $display("%t: [%s]we = %d ,wdata = %h, rdata= %h",$time, name,we, wdata,rdata);
    endtask //
    
endclass 

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox #(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev = gen_next_ev;
    endfunction //new()

    task  run(int run_count);
        repeat(run_count) begin
            tr = new();
            // tr.randomize();
            assert (tr.randomize()) 
            else   $display ("[gen] tr.randomize() error");
            gen2drv_mbox.put(tr);
            tr.display("gen");
            @(gen_next_ev);
        end
    endtask //
endclass //generator


class monitor;
transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual register_interface register_if; 

    function new(mailbox #(transaction) mon2scb_mbox, 
                 virtual register_interface register_if);
        this.mon2scb_mbox = mon2scb_mbox;

        this.register_if = register_if;
    endfunction //new()


     task  run();
        
        
        forever begin
            tr = new();    
            @(posedge register_if.clk);
            #1;
            tr.wdata = register_if.wdata;
            tr.we    = register_if.we;

            tr.rdata = register_if.rdata;
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
    virtual register_interface register_if; 


    function new(mailbox #(transaction) gen2drv_mbox, 
                 virtual register_interface register_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.register_if = register_if;
    endfunction //new()

    task  preset();
    ///register f/f reset
        register_if.clk = 0;
        register_if.rst = 1;
        register_if.we = 0;
        register_if.wdata = 0;
        @(posedge register_if.clk);
        @(negedge register_if.clk);
        register_if.rst = 0;
        @(posedge register_if.clk);

    endtask //


    task  run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge register_if.clk);
            register_if.we = tr.we;
            register_if.wdata = tr.wdata;
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


    function new(virtual register_interface register_if);
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, register_if);
        mon = new(mon2scb_mbox, register_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction //new()

    task  run();
        drv.preset();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #20;

        $display("________________________");
        $display("** 8bit register verifi **");
        $display("**************************");
        $display("**try count = %3d       **",scb.try_cnt);
        $display("**pass count = %3d      **",scb.pass_cnt);
        $display("**fail count = %3d      **",scb.fail_cnt);
        $display("**************************");
        $stop;
    endtask //
endclass //environment






module tb_register( );

    register_interface register_if();
    environment env;
register dut(
    .clk(register_if.clk),
    .rst(register_if.rst),
    .we (register_if.we),
    .wdata(register_if.wdata),
    .rdata(register_if.rdata)
);

    always #5 register_if.clk = ~register_if.clk;

    initial begin
      //  register_if.clk = 0;
     //   register_if.rst = 1;
        env = new(register_if);
        env.run();
    end

endmodule


