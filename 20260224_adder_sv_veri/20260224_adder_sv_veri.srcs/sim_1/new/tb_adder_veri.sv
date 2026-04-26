`timescale 1ns / 1ps

interface adder_interface;
    logic [31:0] a;
    logic [31:0] b;
    logic           mode;
    logic [31:0] s;
    logic           c;


endinterface //adder_interface


//stimulus(vector)
class transaction;

    randc bit [31:0] a;
    randc bit [31:0] b;
    randc bit        mode;
    logic [31:0]    s;
    logic           c;

    task display(string name);
        $display("%t: [%s] a = %h, b = %h, mode = %h, sum= %h, carry = %h, " ,$time, name,a,b,mode,s,c);

    endtask //display

    //constraint range{
    //    a> 10;
    //    b > 32'hffff_0000;
    //}

    //constraint dist_pattern {
    //    a dist {
    //        0 := 8,
    //        32'hffff_ffff:/10,
    //        [1:32'hffff_fffe]:=1
    //        };
    //}

    constraint list_pattern {
        a inside {[ 0:16]};
    }


endclass //transaction

// generator for randomize stimulus
class generator;
        
    //tr : transaction handler
    transaction tr;

    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox #(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev = gen_next_ev;
    endfunction

    task run(int count);
        repeat (count) begin
        tr = new();
        tr.randomize();

        gen2drv_mbox.put(tr);
        tr.display("gen");

        @(gen_next_ev);  //////////////wait
        end
    endtask //


endclass //generator


class driver;
        transaction tr;
        virtual adder_interface adder_if;
        mailbox #(transaction) gen2drv_mbox;
        event mon_next_ev;

    function new(mailbox #(transaction)gen2drv_mbox,
                event mon_next_ev, 
                virtual adder_interface adder_if);
        this.adder_if = adder_if;
        this.mon_next_ev = mon_next_ev;
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction //new()

    task run ();
        forever begin
            
            gen2drv_mbox.get(tr);

            adder_if.a =tr.a;
            adder_if.b =tr.b;
            adder_if.mode =tr.mode;
            tr.display("drv");
            #10;
            -> mon_next_ev;
            //event
        end
    endtask //run

endclass //driver


class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    int pass_cnt ;
    int fail_cnt ;
    bit [31:0] expected_sum;
    bit         expected_carry;

    function new(mailbox #(transaction) mon2scb_mbox, 
                    event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev = gen_next_ev;

    endfunction //new()

    task run();

        logic [31:0] exp_s;
        logic        exp_c;

        forever begin
            mon2scb_mbox.get(tr);
            tr.display("scb");
            // compare, pass, fail
            if (tr.mode == 0) 
            {expected_carry,expected_sum} = tr.a + tr.b;
             else {expected_carry,expected_sum} = tr.a - tr.b;


            if ((expected_sum == tr.s) && (expected_carry == tr.c)) begin
                 $display("[PASS]: a=%d,b=%d, mode=%d,s=%d,c=%d",tr.a, tr.b, tr.mode, tr.s, tr.c);
                pass_cnt++;
            end else begin
                $display("[FAIL]: a=%d,b=%d, mode=%d,s=%d,c=%d",tr.a, tr.b, tr.mode, tr.s, tr.c);
                fail_cnt++;
                $display("expected sum = %d", expected_sum);
                $display("expected sum = %d", expected_carry);
            end
            

            // $display("%t;a= %d, b=%d, mode = %d, s= %d, c= %d",$time,tr.a, tr.b, tr.mode, tr.s, tr.c);

            -> gen_next_ev;        
        end
    endtask
endclass //scoreboard

class monitor;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event mon_next_ev;
    virtual adder_interface adder_if;


    function new(mailbox #(transaction) mon2scb_mbox,
                    event mon_next_ev,
                 virtual adder_interface adder_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.mon_next_ev = mon_next_ev;
        this.adder_if = adder_if;


    endfunction //new()


    task run();
        forever begin
            @(mon_next_ev);
            tr = new();
            tr.a = adder_if.a;
            tr.b = adder_if.b;
            tr.mode = adder_if.mode;
            tr.s = adder_if.s;
            tr.c = adder_if.c;
            mon2scb_mbox.put(tr);
            tr.display("mon");


        end
    endtask //
endclass //monitor




class environment;

    generator gen;
    driver drv;
    // virtual adder_interface adder_if
    monitor mon;
    scoreboard scb;
    int i ;

    mailbox #(transaction) gen2drv_mbox;    //gen > drv
    mailbox #(transaction) mon2scb_mbox;       //mon > scb
    event gen_next_ev;       //scb to gen
    event mon_next_ev;      //drv to mon

    function new(virtual adder_interface adder_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, mon_next_ev,adder_if);
        mon = new(mon2scb_mbox, mon_next_ev, adder_if);
        scb = new(mon2scb_mbox, gen_next_ev);

    endfunction //new()


    task  run();
   ///peat (10) begin
        i = 100;
        fork
            gen.run(i);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #20;

        $display("____________________________");
        $display("**32bit adder verification**");
        $display("---------------------------=");
        $display("**total test cnt = %3d    **",i);
        $display("**total pass cnt = %3d    **",scb.pass_cnt);
        $display("**total fail cnt = %3d    **",scb.fail_cnt);
        $display("---------------------------=");
    ///nd
        $stop;
    endtask //

endclass //className


module tb_adder_veri();

    adder_interface adder_if();
    environment env;


    adder dut(

    .a(adder_if.a),
    .b(adder_if.b),
    .mode(adder_if.mode),
    .s(adder_if.s),
    .c(adder_if.c)
);

initial begin
    env = new(adder_if);


    //exe
    env.run();
end

endmodule
