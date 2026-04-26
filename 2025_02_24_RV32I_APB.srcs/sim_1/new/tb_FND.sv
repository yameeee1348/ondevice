`timescale 1ns / 1ps

task display_fnd_font_table();
    $display("======== Font Table =======");
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
    $display("===========================");
endtask


class transaction;
    rand bit [31:0] PWDATA;
    rand bit PSEL;
    rand bit PENABLE;
    bit [3:0] fndCom;
    bit [7:0] fndFont;

    constraint PWDATA_range { PWDATA < 10000; } 

    task display(string name);
        $display("[%s] PWDATA: %0d (%0h), PSEL: %d, PENABLE: %d, fnd_com=%b, fnd_font=%h", 
                 name, PWDATA, PWDATA, PSEL, PENABLE, fndCom, fndFont);
    endtask 


endclass

interface periph_fnd_intf;
    bit          PCLK;
    bit          PRESET;
    logic        PSEL;
    logic        PENABLE;
    logic [31:0] PWDATA;
    logic [31:0] paddr_reg;
    logic        tick_1khz;
    logic [3:0]  fndCom;
    logic [7:0]  fndFont;
endinterface

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbx;
    event gen_next_event;
    virtual periph_fnd_intf periph_fnd_intf;
    int tick_counter = 0;

    function new(virtual periph_fnd_intf periph_fnd_intf, mailbox #(transaction) gen2drv_mbx, event gen_next_event);
        this.periph_fnd_intf = periph_fnd_intf;
        this.gen2drv_mbx = gen2drv_mbx;
        this.gen_next_event = gen_next_event;
    endfunction

    task run(int run_count);
        repeat(run_count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbx.put(tr);
            $display("\n[NEW DATA] PWDATA: %0d (%0h), PSEL: %d, PENABLE: %d", 
                        tr.PWDATA, tr.PWDATA, tr.PSEL, tr.PENABLE);
            tr.display("GEN");
            tick_counter = 0;
            @(gen_next_event);
        end
    endtask
endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbx;
    virtual periph_fnd_intf periph_fnd_intf;
    event mon_next_event;

    function new(virtual periph_fnd_intf periph_fnd_intf, mailbox #(transaction) gen2drv_mbx, event mon_next_event);
        this.periph_fnd_intf = periph_fnd_intf;
        this.gen2drv_mbx = gen2drv_mbx;
        this.mon_next_event = mon_next_event;
    endfunction

    task reset();
        periph_fnd_intf.PRESET <= 1;
        periph_fnd_intf.PSEL <= 0;
        periph_fnd_intf.PENABLE <= 0;
        periph_fnd_intf.fndCom <= 0;
        periph_fnd_intf.fndFont <= 0;
        periph_fnd_intf.tick_1khz <= 0;
        periph_fnd_intf.paddr_reg <= 32'h0;
        repeat(5) @(posedge periph_fnd_intf.PCLK);
        periph_fnd_intf.PRESET <= 0;

         // Write to START_ADDR to set control bit
        periph_fnd_intf.paddr_reg = 32'h0; // Set to START_ADDR
        periph_fnd_intf.PSEL <= 1;
        periph_fnd_intf.PENABLE <= 1;
        periph_fnd_intf.PWDATA <= 32'h1; // Set control bit to 1
        @(posedge periph_fnd_intf.PCLK);

        periph_fnd_intf.PSEL <= 0;
        periph_fnd_intf.PENABLE <= 0;
        @(posedge periph_fnd_intf.PCLK);

        // Set back to FND_DATA_ADDR for normal operation
        periph_fnd_intf.paddr_reg = 32'h4;

    endtask

    task run();
        forever begin
            gen2drv_mbx.get(tr);
            #1;
            periph_fnd_intf.PWDATA = tr.PWDATA;
            periph_fnd_intf.PENABLE = tr.PENABLE;
            periph_fnd_intf.PSEL = tr.PSEL;
            tr.display("DRV");
            ->mon_next_event;
        end
    endtask 
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbx;
    virtual periph_fnd_intf periph_fnd_intf;
    event mon_next_event;
    bit first_transaction = 1;

    function new(virtual periph_fnd_intf periph_fnd_intf, mailbox #(transaction) mon2scb_mbx, event mon_next_event);
        this.periph_fnd_intf = periph_fnd_intf;
        this.mon2scb_mbx = mon2scb_mbx;
        this.mon_next_event = mon_next_event;
    endfunction
        
    task run();
        forever begin
            @(mon_next_event);
            tr = new();
            
            if (first_transaction) begin
                repeat(3) @(posedge periph_fnd_intf.tick_1khz);  // 첫 트랜잭션은 3ms 대기
                first_transaction = 0;                          
            end


            if(periph_fnd_intf.PSEL && periph_fnd_intf.PENABLE) begin
                display_fnd_font_table();
            end else begin
                $display("Control signals not active: PSEL=%0d, PENABLE=%0d - Skipping output check", 
                periph_fnd_intf.PSEL, periph_fnd_intf.PENABLE);
            end


            repeat(4) begin 
                @(posedge periph_fnd_intf.tick_1khz);
                #1;
                tr.PWDATA = periph_fnd_intf.PWDATA;
                tr.PENABLE = periph_fnd_intf.PENABLE;
                tr.PSEL = periph_fnd_intf.PSEL;
                tr.fndCom = periph_fnd_intf.fndCom;
                tr.fndFont = periph_fnd_intf.fndFont;
                @(posedge periph_fnd_intf.PCLK);
                mon2scb_mbx.put(tr);
                tr.display("MON");
            end


        end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbx;
    event gen_next_event;
    int total_cnt, pass_cnt, fail_cnt, skipped_cnt;
    int expected_digit;
    int fnd_check_counter = 0;
    bit [7:0] expected_font;

    bit [7:0] font_map[10] = '{
        8'hc0, 8'hf9, 8'ha4, 8'hb0, 8'h99, 
        8'h92, 8'h82, 8'hf8, 8'h80, 8'h90
    };

    function new(mailbox #(transaction) mon2scb_mbx, event gen_next_event);
        this.mon2scb_mbx = mon2scb_mbx;
        this.gen_next_event = gen_next_event;
        total_cnt = 0;
        pass_cnt = 0;
        fail_cnt = 0;
        skipped_cnt = 0;
    endfunction
        
    task run();
        forever begin 
            mon2scb_mbx.get(tr);
            tr.display("SCB");

            if (tr.PSEL && tr.PENABLE) begin

                case (tr.fndCom)
                    4'b0111: expected_digit = (tr.PWDATA / 1000) % 10; 
                    4'b1011: expected_digit = (tr.PWDATA / 100) % 10;  
                    4'b1101: expected_digit = (tr.PWDATA / 10) % 10;   
                    4'b1110: expected_digit = tr.PWDATA % 10;          
                    default: expected_digit = -1;
                endcase

                if (expected_digit >= 0)
                    expected_font = font_map[expected_digit];
                else
                    expected_font = 8'h00;

                if (tr.fndFont == expected_font) begin
                    $display("\n\tPASS!!! num: %0d, fnd_font: %h == expected_font: %h\n", 
                             expected_digit, tr.fndFont, expected_font);
                    pass_cnt++;
                end else begin
                    $display("\n\tFAIL!!! num: %0d, fnd_font: %h != expected_font: %h\n", 
                             expected_digit, tr.fndFont, expected_font);
                    fail_cnt++;
                end
            end else begin
                skipped_cnt++;
            end
            
            total_cnt++;
            fnd_check_counter++;
            


            if(fnd_check_counter == 4) begin
                ->gen_next_event;
                fnd_check_counter = 0;
            end
        end 
    endtask
endclass


class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    mailbox #(transaction) mon2scb_mbx;
    mailbox #(transaction) gen2drv_mbx;

    event gen_next_event;
    event mon_next_event;

    virtual periph_fnd_intf periph_fnd_intf;

    function new(virtual periph_fnd_intf periph_fnd_intf);
        this.periph_fnd_intf = periph_fnd_intf;
        gen2drv_mbx = new();
        mon2scb_mbx = new();
        gen = new(periph_fnd_intf, gen2drv_mbx, gen_next_event);
        drv = new(periph_fnd_intf, gen2drv_mbx, mon_next_event);
        mon = new(periph_fnd_intf, mon2scb_mbx, mon_next_event);
        scb = new(mon2scb_mbx, gen_next_event);
    endfunction

    task report();
        $display("===============================");
        $display("======    Final Report    =====");
        $display("===============================");
        $display("|| ");
        $display("|| Pass Test: %0d ", scb.pass_cnt);
        $display("|| Fail Test: %0d ", scb.fail_cnt);
        $display("|| Skipped Test: %0d ", scb.skipped_cnt);
        $display("|| Total Test: %0d ", scb.total_cnt);
        $display("|| ");
        $display("===============================");
        $display("=== Test Bench is finished ====");
        $display("===============================");
    endtask 

    task run_test(int run_count);
        drv.reset();
        #1000;
        fork
            gen.run(run_count);
            drv.run();
            mon.run();
            scb.run();
        join_any
        report();
        #10 $finish;
    endtask
endclass

module tb_FND;
    periph_fnd_intf periph_fnd_intf();    
    environment env;

    periph_fnd DUT (
        .PCLK(periph_fnd_intf.PCLK),     
        .PRESET(periph_fnd_intf.PRESET),   
        .PADDR(periph_fnd_intf.paddr_reg), 
        .PWRITE(1'b1),
        .PSEL(periph_fnd_intf.PSEL),
        .PENABLE(periph_fnd_intf.PENABLE),
        .PWDATA(periph_fnd_intf.PWDATA),
        .PRDATA(),
        .PREADY(),
        .fndCom(periph_fnd_intf.fndCom),
        .fndFont(periph_fnd_intf.fndFont)
    );

    always #5 periph_fnd_intf.PCLK = ~periph_fnd_intf.PCLK;
    
    reg [16:0] tick_counter = 0;
    
    always @(posedge periph_fnd_intf.PCLK) begin
        tick_counter <= tick_counter + 1;
        if (tick_counter == 100000) begin
            periph_fnd_intf.tick_1khz <= 1;
            tick_counter <= 0;
        end else begin
            periph_fnd_intf.tick_1khz <= 0;
        end
    end

    initial begin
        periph_fnd_intf.PCLK = 0;
        env = new(periph_fnd_intf);
        env.run_test(50);
    end
endmodule