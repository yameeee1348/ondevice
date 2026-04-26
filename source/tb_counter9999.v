`timescale 1ns / 1ps



module tb_counter9999 ();
        reg clk,reset;
        reg  i_tick;
        reg [2:0] sw;
        wire [13:0] counter;
// sw0 : up_down_mode, sw1 : run_stop, sw2 : clear


 counter_9999 dut(

    .clk(clk),
    .reset(reset),
    .i_tick(i_tick),
    .mode(sw[0]),
    .clear(sw[2]),
    .run_stop(sw[1]),
    .counter(counter)   
 );

    always #5 clk = ~clk;
    always #10 i_tick = ~i_tick;
    initial begin
        
        #0;
        clk = 0;
        sw[1] = 1;
        sw[2] = 0;
        reset = 1;
        sw[0] = 0;
        i_tick =1;  //모든 값 초기화
        #20;
        reset = 0;
        #2000;     //다운카운트 모드 활성화
        sw[0] = 1;
        #500;
        sw[2] = 1;   //클리어 모드 활성화
        #2000;
        sw[2] = 0;   //업카운트 활성화 및 클리어 비활성화
        sw[0] = 0;
        #2000;     //stop 활성화
        sw[1] = 0;
        #1000;     // run 활성화
        sw[1] = 1;
        #2000;
    
        $stop;

    
        
         
    end
     
endmodule

      //  reg reset;
      //  reg sw0;
      //  wire [7:0] fnd_data;
      //  wire [3:0] fnd_digit;
//    top_adder1 dut(
//    
//    .clk(clk),
//    .reset(reset),
//    .sw0(sw0),
//    .fnd_digit(fnd_digit),
//    .fnd_data(fnd_data)
//    
//);