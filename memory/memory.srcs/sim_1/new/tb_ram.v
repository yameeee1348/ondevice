`timescale 1ns / 1ps



module tb_ram();
    
    reg clk;
    reg we;
    reg [9:0] addr;
    reg [7:0] wdata;
    wire [7:0] rdata;



    ram  dut(
    .clk(clk),
    .we(we),
    .addr(addr),
    .wdata(wdata),
    .rdata(rdata)

);

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        addr = 0;
        wdata = 0;
        we=0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        we=1;
        @(posedge clk);
        #1;
        addr=10;
        wdata = 8'ha;
        @(posedge clk);
        #1;
        addr=11;
        wdata = 8'hb;
        @(posedge clk);
        #1;
        addr=31;
        wdata = 8'hc;
        @(posedge clk);
        #1;
        addr=32;
        wdata = 8'hd;
         @(posedge clk);
         #1;



        we =0;

        #1;
        addr =10;
        @(posedge clk);
        #1;
        addr =11;
        @(posedge clk);

        #1;
        addr =31;
        @(posedge clk);

        #1;
        addr =32;
        @(posedge clk);





    end

endmodule
