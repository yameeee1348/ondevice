`timescale 1ns / 1ps

interface fnd_interface;
    logic        clk;
    logic        reset;
    logic        tick_1khz;
    logic [15:0] PWDATA;
    logic        PSEL;
    logic [3:0]  fnd_com;
    logic [7:0]  fnd_font;
endinterface

class transaction;
    rand bit [15:0] PWDATA;
    rand bit PSEL;
    bit [3:0] fnd_com;
    bit [7:0] fnd_font;

    constraint PWDATA_range { PWDATA < 10000; }

    task display(string name);
        $display("[%s] PWDATA: %0d (%0h) PSEL: %b fnd_com=%b fnd_font=%h", 
                 name, PWDATA, PWDATA, PSEL, fnd_com, fnd_font);
    endtask
endclass

class generator;
    transaction fnd_trans;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_event;
    virtual fnd_interface fnd_intf;
    int tick_counter = 0;

    function new(mailbox #(transaction) gen2drv_mbox, event gen_next_event, virtual fnd_interface fnd_intf);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_event = gen_next_event;
        this.fnd_intf = fnd_intf;
    endfunction

    task run(int count);
        repeat (count * 5) begin
            @(posedge fnd_intf.tick_1khz);
            tick_counter++;

            if (tick_counter == 5) begin
                fnd_trans = new();
                fnd_trans.randomize();
                gen2drv_mbox.put(fnd_trans);
                $display("\n[NEW DATA] PWDATA: %0d (%0h) PSEL: %b\n", 
                          fnd_trans.PWDATA, fnd_trans.PWDATA, fnd_trans.PSEL);
                fnd_trans.display("GEN");
                tick_counter = 0;
                @(gen_next_event);
            end
        end
    endtask
endclass

class driver;
    transaction fnd_trans;
    mailbox #(transaction) gen2drv_mbox;
    virtual fnd_interface fnd_intf;
    event mon_next_event;

    function new(mailbox #(transaction) gen2drv_mbox, virtual fnd_interface fnd_intf, event mon_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.fnd_intf = fnd_intf;
        this.mon_next_event = mon_next_event;
    endfunction

    task reset();
        fnd_intf.reset <= 1;
        fnd_intf.PWDATA <= 0;
        fnd_intf.PSEL <= 0;
        fnd_intf.fnd_com <= 0;
        fnd_intf.fnd_font <= 0;
        fnd_intf.tick_1khz <= 0; 
        repeat(5) @(posedge fnd_intf.clk);
        fnd_intf.reset <= 0;
    endtask

    task run(int count);
        repeat(count) begin
            gen2drv_mbox.get(fnd_trans);
            #1;
            fnd_intf.PWDATA <= fnd_trans.PWDATA;
            fnd_intf.PSEL <= fnd_trans.PSEL;
            fnd_trans.display("DRV");
            ->mon_next_event;
        end
    endtask
endclass

class monitor;
    transaction fnd_trans;
    mailbox #(transaction) mon2scb_mbox;
    virtual fnd_interface fnd_intf;
    event mon_next_event;

    function new(mailbox #(transaction) mon2scb_mbox, virtual fnd_interface fnd_intf, event mon_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fnd_intf = fnd_intf;
        this.mon_next_event = mon_next_event;
    endfunction

    task run(int count);
        repeat (count) begin
            @(mon_next_event);
            fnd_trans = new();
            
            repeat (4) begin
                @(posedge fnd_intf.tick_1khz);
                #1;
                fnd_trans.PWDATA = fnd_intf.PWDATA;
                fnd_trans.PSEL = fnd_intf.PSEL;
                fnd_trans.fnd_com = fnd_intf.fnd_com;
                fnd_trans.fnd_font = fnd_intf.fnd_font;
                @(posedge fnd_intf.clk);
                mon2scb_mbox.put(fnd_trans);
                fnd_trans.display("MON");
            end
        end
    endtask
endclass

class scoreboard;
    transaction scb_trans;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_event;
    int total_cnt, pass_cnt, fail_cnt, psel_low_cnt;
    int expected_digit;
    bit [7:0] expected_font;

    bit [7:0] font_map[10] = '{
        8'hc0, 8'hf9, 8'ha4, 8'hb0, 8'h99, 
        8'h92, 8'h82, 8'hf8, 8'h80, 8'h90
    };

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_event);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.gen_next_event = gen_next_event;
        total_cnt           = 0;
        pass_cnt            = 0;
        fail_cnt            = 0;
        psel_low_cnt        = 0;
    endfunction

    task run(int count);
        repeat(count * 4) begin
            mon2scb_mbox.get(scb_trans);
            scb_trans.display("SCB");

            if (scb_trans.PSEL) begin
                case (scb_trans.fnd_com)
                    4'b0111: expected_digit = (scb_trans.PWDATA / 1000) % 10; 
                    4'b1011: expected_digit = (scb_trans.PWDATA / 100) % 10;  
                    4'b1101: expected_digit = (scb_trans.PWDATA / 10) % 10;   
                    4'b1110: expected_digit = scb_trans.PWDATA % 10;          
                    default: expected_digit = -1;
                endcase

                if (expected_digit >= 0)
                    expected_font = font_map[expected_digit];
                else
                    expected_font = 8'h00;

            if (scb_trans.fnd_font == expected_font) begin
                $display("\n\tPASS!!! num: %0d   fnd_font: %h == expected_font: %h\n", 
                         expected_digit, scb_trans.fnd_font, expected_font);
                pass_cnt++;
            end else begin
                $display("\n\tFAIL!!! num: %0d   fnd_font: %h != expected_font: %h\n", 
                         expected_digit, scb_trans.fnd_font, expected_font);
                fail_cnt++;
            end
            
            end else begin
                $display("PSEL LOW, NO OUTPUT CHECK");
                psel_low_cnt++;
            end

            total_cnt++;
            -> gen_next_event;
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

    event gen_next_event;
    event mon_next_event;

    virtual fnd_interface fnd_intf;

    function new(virtual fnd_interface fnd_intf);
        this.fnd_intf = fnd_intf;
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen_next_event, fnd_intf);
        drv = new(gen2drv_mbox, fnd_intf, mon_next_event);
        mon = new(mon2scb_mbox, fnd_intf, mon_next_event);
        scb = new(mon2scb_mbox, gen_next_event);
    endfunction

    task display_fnd_font_table();
        $display("========Font Table=======");
        $display("===========================");
        $display("         0 -> c0         ");
        $display("         1 -> f9         ");
        $display("         2 -> a4         ");
        $display("         3 -> b0         ");
        $display("         4 -> 99         ");
        $display("         5 -> 92         ");
        $display("         6 -> 82         ");
        $display("         7 -> f8         ");
        $display("         8 -> 80         ");
        $display("         9 -> 90         ");
        $display("===========================");
    endtask

    task  report();
        $display("===========================");
        $display("========Final Report=======");
        $display("===========================");
        $display("========Pass Test:%0d =======", scb.pass_cnt);
        $display("========Fail Test:%0d =======", scb.fail_cnt);
        $display("========PSEL LOW :%0d =======", scb.psel_low_cnt);
        $display("========Total Test:%0d =======", scb.total_cnt);
        $display("===========================");
        $display("===Test Bench is finished ===");
        $display("===========================");
    endtask 

    task run_test();
        drv.reset();
        display_fnd_font_table();
        fork
            gen.run(5);
            drv.run(5);
            mon.run(5);
            scb.run(5);
        join
        report();
        #10 $finish;
    endtask
endclass

module tb_fnd_periph();
    fnd_interface fnd_intf();
    environment env;

    fnd_periph DUT(
        .PCLK(fnd_intf.clk),
        .PRESET(fnd_intf.reset),
        .PENABLE(1'b1),
        .PWRITE(1'b1),
        .PADDR(4'h0),
        .PWDATA(fnd_intf.PWDATA),
        .PSEL(fnd_intf.PSEL),
        .PRDATA(),
        .PREADY(),
        .fnd_font(fnd_intf.fnd_font),
        .fnd_com(fnd_intf.fnd_com)
    );

    always #5 fnd_intf.clk = ~fnd_intf.clk;
    reg [16:0] tick_counter = 0;
    
    always @(posedge fnd_intf.clk) begin
        tick_counter <= tick_counter + 1;
        if (tick_counter == 100000) begin
            fnd_intf.tick_1khz <= 1;
            tick_counter <= 0;
        end else begin
            fnd_intf.tick_1khz <= 0;
        end
    end

    initial begin
        fnd_intf.clk = 0;
        env = new(fnd_intf);
        env.run_test();
    end
endmodule
