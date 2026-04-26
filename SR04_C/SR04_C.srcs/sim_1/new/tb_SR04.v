// `timescale 1ns / 1ps



// module tb_SR04();

//     reg clk;
//     reg rst;
//     reg echo;
//     wire trigger;
//     wire [23:0] distance;

       
// initial clk = 1'b0;
//     always #5 clk = ~clk;


// SR04 dut (

//     .clk(clk),
//     .rst(rst),
//     .echo(echo),
//     .trigger(trigger),
//     .distance(distance)


// );

 
//   task automatic send_echo_cm(input integer dist_cm);
//     integer echo_high_us;
//     begin
//       echo_high_us = dist_cm * 58;

     
//       @(posedge trigger);
//       @(negedge trigger);

    
//       #(200_0000); 


//       echo = 1'b1;
//       #(echo_high_us * 1000); 

 
//       echo = 1'b0;

      
//       $display("[%0t ns] ECHO sent: %0d cm (high %0d us)", $time, dist_cm, echo_high_us);
//     end
//   endtask


//   initial begin
//     rst  = 1'b1;
//     echo = 1'b0;

//     repeat(10) @(posedge clk);
//     rst = 1'b0;
//       send_echo_cm(30);
    
//     #1_000_000; 
    
//   rst  = 1'b1;

//      repeat(10) @(posedge clk);
//  rst = 1'b0;

//     #1_000_00;


//     @(posedge trigger);
//     @(negedge trigger);
//     $display("[%0t ns] TIMEOUT test: no echo", $time);

  
//     #80_000_000; 

//     $finish;
//   end

// endmodule


`timescale 1ns / 1ps

module tb_SR04;

  reg clk;
  reg rst;
  reg echo;
  wire trigger;
  wire [23:0] distance;

  // 100MHz clock (10ns)
  initial clk = 1'b0;
  always #5 clk = ~clk;

  SR04 dut (
    .clk(clk),
    .rst(rst),
    .echo(echo),
    .trigger(trigger),
    .distance(distance)
  );

  // ------------------------------------------------------------
  // Echo task: dist(cm) -> echo_high_us = dist * 58
  // trigger 끝나고 200us 뒤 echo rising
  // ------------------------------------------------------------
  task automatic send_echo_cm(input integer dist_cm);
    integer echo_high_us;
    begin
      echo_high_us = dist_cm * 58;

      // DUT 트리거 한 사이클 기다림
      @(posedge trigger);
      @(negedge trigger);

      // 200us delay (주의: 200_000ns = 200us)
      #(200_000);

      echo = 1'b1;
      #(echo_high_us * 1000); // us -> ns
      echo = 1'b0;

      $display("[%0t ns] ECHO sent: %0d cm (high %0d us)", $time, dist_cm, echo_high_us);
    end
  endtask

  // distance 체크 helper
  task automatic check_distance(input integer exp_cm, input integer tol_cm);
    begin
      // distance는 echo_fall 이후 STOP 진입 시점에 갱신됨
      // 넉넉하게 조금 기다렸다가 확인
      #(2_000_000); // 2ms

      if ((distance < (exp_cm - tol_cm)) || (distance > (exp_cm + tol_cm))) begin
        $display("[%0t ns] FAIL: expected %0d±%0d cm, got %0d",
                 $time, exp_cm, tol_cm, distance);
      end else begin
        $display("[%0t ns] PASS: expected %0d±%0d cm, got %0d",
                 $time, exp_cm, tol_cm, distance);
      end
    end
  endtask

  // ------------------------------------------------------------
  // Test sequence
  // ------------------------------------------------------------
  initial begin
    rst  = 1'b1;
    echo = 1'b0;

    repeat(10) @(posedge clk);
    rst = 1'b0;

    // --------------------------
    // Case1: 30cm
    // --------------------------
    send_echo_cm(30);
    check_distance(30, 1);

    // 다음 측정까지 STOP이 60ms라서 충분히 기다려야 다음 TRIG를 안정적으로 잡음
    #(70_000_000); // 70ms

    // --------------------------
    // Case2: 300cm
    // --------------------------
    send_echo_cm(300);
    check_distance(300, 2);

    #(70_000_000); // 70ms

    // --------------------------
    // Case3: TIMEOUT (echo 안 줌)
    // --------------------------
    @(posedge trigger);
    @(negedge trigger);
    $display("[%0t ns] TIMEOUT test: no echo will be sent", $time);

    // TIMEOUT_US=30000us -> 30ms
    // STOP까지 가고 다음 사이클 준비까지 넉넉히 80ms 대기
    #(80_000_000);

    $display("[%0t ns] DONE. last distance=%0d", $time, distance);
    $finish;
  end

endmodule
