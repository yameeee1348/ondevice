`timescale 1ns / 1ps
interface  ram_if(input logic clk);
    
    logic       we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;

endinterface // ram_if


class test;
    virtual ram_if r_if;

    function new(virtual ram_if r_if);
    this.r_if = r_if;

    endfunction //new()

    virtual task write(logic [7:0] waddr, logic [7:0] data);
       
        r_if.we    = 1;
        r_if.addr  = waddr;
        r_if.wdata = data;
        @(posedge r_if.clk);

    endtask  //

    virtual task read(logic [7:0] raddr);
        
        r_if.we    = 0;
        r_if.addr  = raddr;
        @(posedge r_if.clk);

    endtask  //
endclass //test


class test_burst extends test;
    function new(virtual ram_if r_if);
        super.new(r_if);
    endfunction //new()
    task  write_burst(logic [7:0] waddr, logic [7:0] data, int len );
        for (int i = 0; i<len; i++) begin
            super.write(waddr, data);
            waddr++;
        end
    endtask //


        task  write(logic [7:0] waddr, logic [7:0] data);
                r_if.we = 1;
                r_if.addr = waddr+1;
                r_if.wdata = data;
                @(posedge r_if.clk);        
        endtask //
endclass //test_burst


class transaction;
    logic we;
    rand logic [7:0] addr;
    rand logic [7:0] wdata;
    logic [7:0] rdata;

    constraint c_addr {
        addr inside {[8'h00:8'h10]};
    }
    constraint c_wdata {
        wdata inside {[8'h10:8'h20]};
    }


    function print(string name);
        $display("[name] we:%0d, addr:0x%0x, wdata: 0x%0x, rdata:0x%0x", name, we, addr, wdata,rdata);
    endfunction //new()
endclass //transaction


class test_rand extends test;
    transaction tr;

       // logic we;
       // rand logic [7:0] addr;
       // rand logic [7:0] wdata;
       // logic [7:0] rdata;



    function new(virtual ram_if r_if);


        super.new(r_if);
    endfunction //new()

    task write_rand(int loop);
        repeat (loop) begin
            tr = new();
            tr.randomize();
            r_if.we = 1;
            r_if.addr =tr.addr;
            r_if.wdata = tr.wdata;
            @(posedge r_if.clk);
        end
    endtask
endclass //test_rand




module tb_ram ();
    logic clk;
    test BTS;
    test_rand BlackPink;

    

    ram_if r_if(clk);


     ram dut(

    .clk(r_if.clk),
    .we(r_if.we),
    .addr(r_if.addr),
    .wdata(r_if.wdata),
    .rdata(r_if.rdata)

    );
    initial clk = 0;
    always #5 clk = ~clk;

    // task ram_write(logic [7:0] waddr, logic [7:0] data);
    //     ram_write(8'h00,8'h01);
    //     we    = 1;
    //     addr  = waddr;
    //     wdata = data;
    //     @(posedge clk);

    // endtask  //

    // task ram_read(logic [7:0] raddr);
        
    //     we    = 0;
    //     addr  = raddr;
    //     @(posedge clk);

   // endtask  //

    initial begin
        repeat (5) @(posedge clk);
        BTS = new(r_if);
        BlackPink = new(r_if);
        $display("addr = 0x%0h", BTS);
        $display("addr = 0x%0h", BlackPink);
        
        BTS.write(8'h00, 8'h01);
        BTS.write(8'h01, 8'h02);
        BTS.write(8'h02, 8'h03);
        BTS.write(8'h03, 8'h04);
         BlackPink.write_rand(10);
       // BlackPink.write_burst(8'h00, 8'h01, 4);
        
        BTS.read( 8'h00);
        BTS.read( 8'h01);
        BTS.read( 8'h02);
        BTS.read( 8'h03);
        // ram_read(8'h00);
        // ram_read(8'h01);
        // ram_read(8'h02);
        // ram_read(8'h03);
        
        // we    = 1;
        // addr  = 8'h00;
        // wdata = 8'h01;
        // @(posedge clk);

        // we    = 1;
        // addr  = 8'h01;
        // wdata = 8'h02;
        // @(posedge clk);

        // we    = 1;
        // addr  = 8'h02;
        // wdata = 8'h03;
        // @(posedge clk);

        // we   = 0;
        // addr = 8'h00;
        // @(posedge clk);

        // we   = 0;
        // addr = 8'h01;
        // @(posedge clk);

        // we   = 0;
        // addr = 8'h02;
        // @(posedge clk);
        #20;
        $finish;
    end


endmodule
