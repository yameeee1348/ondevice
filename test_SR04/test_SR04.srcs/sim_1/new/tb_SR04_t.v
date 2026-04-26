`timescale 1ns/1ps
module tb_SR04_t;

  reg clk, rst, echo;
  wire trigger;
  wire [23:0] distance;

  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz
  end

  SR04_t dut (
    .clk(clk), .rst(rst), .echo(echo),
    .trigger(trigger), .distance(distance)
  );

  initial begin
    rst = 1; echo = 0;
    #200; rst = 0;
    echo = 1'b1;
#5_000_000;   // 5ms
echo = 1'b0;
    // 20ms 후 echo 강제 주입 (30cm)
    #20_000_000;
    echo = 1;
    #(30*58*1000); // 1740us
    echo = 0;

    // 반영 대기
    #50_000_000;
    $display("distance=%0d", distance);

    $finish;
  end

endmodule
