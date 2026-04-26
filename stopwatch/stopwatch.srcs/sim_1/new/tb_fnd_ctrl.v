`timescale 1ns / 1ps



module tb_fnd_ctrl ();


    reg         clk;
    reg         reset;
    reg         sel_display;
    reg      [23:0]   fnd_in_data;
    wire    [ 3:0]    fnd_digit;
    wire    [ 7:0]    fnd_data;




fnd_controller dut(

    .clk(clk),
    .reset(reset),
    .sel_display(sel_display),
    .fnd_in_data(fnd_in_data),
    .fnd_digit(fnd_digit),
    .fnd_data(fnd_data)
);

    always #5 clk = ~clk;
    initial begin
        
    #0;
    clk = 0;
    reset = 1;
    sel_display = 0;
    fnd_in_data = 24'h000001;
    #100;
    reset = 0;
    sel_display = 0;   //스탑워치 부분
    #1000000000;
   
    sel_display = 1;  //워치 부분
    
    #1000000000;
    
    $stop;

    end
    






endmodule