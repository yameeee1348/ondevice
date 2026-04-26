`timescale 1ns / 1ps



module tb_uart_tx();

    parameter BAUD_9600 = 104_160;

    reg clk, rst, btn_down; //need to for btn_down 100msec
    wire uart_tx;

top_uart dut(
    .clk(clk),
    .rst(rst),
    .btn_down(btn_down),    
    .uart_tx(uart_tx)

);

    always #5 clk =~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        btn_down = 0;

        #20;
        //reset
        rst = 0;

        // btn down, tx start
        btn_down =1'b1;
        #100_000; //100usec
        btn_down =1'b0;

        #(BAUD_9600*16);
        $stop;


    end



endmodule
