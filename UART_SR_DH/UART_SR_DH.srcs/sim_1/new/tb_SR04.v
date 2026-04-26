`timescale 1ns/1ps

module tb_SR04;

  // ------------------------------------------------------------
  // I/O
  // ------------------------------------------------------------
  reg         clk;
  reg         rst;
  reg  [4:0]  sw;
  reg         btn_r;
  reg         btn_min_up;
  reg         btn_hour_up;
  reg         btn_echo;
  reg         uart_rx;
  reg         echo;

  wire        uart_tx;
  wire [3:0]  fnd_digit;
  wire [7:0]  fnd_data;
  wire        trigger;

  // ------------------------------------------------------------
  // 100MHz clock
  // ------------------------------------------------------------
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // ------------------------------------------------------------
  // DUT (Top)
  // ------------------------------------------------------------
  UART_SR_DH dut (
    .clk        (clk),
    .rst        (rst),
    .sw         (sw),
    .btn_r      (btn_r),
    .btn_min_up (btn_min_up),
    .btn_hour_up(btn_hour_up),
    .btn_echo   (btn_echo),
    .uart_rx    (uart_rx),
    .echo       (echo),
    .uart_tx    (uart_tx),
    .fnd_digit  (fnd_digit),
    .fnd_data   (fnd_data),
    .trigger    (trigger)
  );

  // ------------------------------------------------------------
  // 버튼 "디바운스 통과"용 눌림 (>=80us 필요)
  // btn_debounce: 100kHz 샘플(10us) + 8연속 1 => 80us 이상
  // ------------------------------------------------------------
  task automatic press_btn_echo_us(input integer hold_us);
    begin
      btn_echo = 1'b1;
      #(hold_us * 1000);   // us -> ns
      btn_echo = 1'b0;
      // 디바운스/edge 로직이 clk에서 정리될 시간 조금 부여
      #(50_000); // 50us
    end
  endtask

  // ------------------------------------------------------------
  // Echo 모델: dist(cm) -> echo_high_us = dist * 58
  // trigger 끝나고 200us 후 echo rising
  // ------------------------------------------------------------
  task automatic send_echo_cm(input integer dist_cm);
    integer echo_high_us;
    begin
      echo_high_us = dist_cm * 58;

      @(posedge trigger);
      @(negedge trigger);

      #(200_000);           // 200us
      echo = 1'b1;
      #(echo_high_us * 1000);
      echo = 1'b0;

      $display("[%0t ns] ECHO sent: %0d cm (high %0d us)", $time, dist_cm, echo_high_us);
    end
  endtask

  // ------------------------------------------------------------
  // distance 체크: top 내부 w_distance를 직접 확인
  // (FND 표시값이 아니라 SR04 결과를 보는 게 목적이니까)
  // ------------------------------------------------------------
  task automatic check_distance_top(input integer exp_cm, input integer tol_cm);
    integer got;
    begin
      // SR04가 echo 끝난 뒤 distance를 갱신하는 시점까지 여유
      #(5_000_000); // 5ms

      got = dut.w_distance;   // <-- top 내부 wire 직접 참조
      if ((got < (exp_cm - tol_cm)) || (got > (exp_cm + tol_cm))) begin
        $display("[%0t ns] FAIL: expected %0d±%0d cm, got %0d",
                 $time, exp_cm, tol_cm, got);
      end else begin
        $display("[%0t ns] PASS: expected %0d±%0d cm, got %0d",
                 $time, exp_cm, tol_cm, got);
      end
    end
  endtask

  // ------------------------------------------------------------
  // Optional: trigger 폭 측정(10us인지 확인하고 싶을 때)
  // ------------------------------------------------------------
  task automatic check_trigger_width_us(input integer exp_us, input integer tol_us);
    time t_rise, t_fall;
    integer width_us;
    begin
      @(posedge trigger); t_rise = $time;
      @(negedge trigger); t_fall = $time;

      width_us = (t_fall - t_rise) / 1000; // ns->us
      if ((width_us < (exp_us - tol_us)) || (width_us > (exp_us + tol_us))) begin
        $display("[%0t ns] TRIG WIDTH FAIL: expected %0d±%0d us, got %0d us",
                 $time, exp_us, tol_us, width_us);
      end else begin
        $display("[%0t ns] TRIG WIDTH PASS: expected %0d±%0d us, got %0d us",
                 $time, exp_us, tol_us, width_us);
      end
    end
  endtask

  // ------------------------------------------------------------
  // Main
  // ------------------------------------------------------------
  initial begin
    // init
    rst         = 1'b1;
    sw          = 5'b0;
    btn_r       = 1'b0;
    btn_min_up  = 1'b0;
    btn_hour_up = 1'b0;
    btn_echo    = 1'b0;
    uart_rx     = 1'b1;   // UART idle
    echo        = 1'b0;

    repeat(20) @(posedge clk);
    rst = 1'b0;

    // Ultra mode ON (sw[4]=1) + FND ultra 표시도 같이 켜짐
    sw[4] = 1'b1;

    // 내부 신호 상태 보고 싶으면(있는 경우만)
    // $monitor("[%0t] trig=%b echo=%b w_ultra_start=%b dist=%0d",
    //          $time, trigger, echo, dut.w_ultra_start, dut.w_distance);

    // --------------------------
    // Case 1: 30cm
    // --------------------------
    fork
      begin
        // 버튼을 충분히 길게 눌러서 디바운스 통과
        press_btn_echo_us(120);  // 120us
      end
      begin
        // trigger 나오면 echo 생성
        send_echo_cm(30);
      end
    join

    // trigger 폭 확인(원하면 켜)
    // check_trigger_width_us(10, 2);

    check_distance_top(30, 1);

    // SR04 내부에 STOP 대기(예: 60ms)가 있을 수 있으니 넉넉히 대기
    #(100_000_000); // 100ms

    // --------------------------
    // Case 2: 300cm
    // --------------------------
    fork
      begin
        press_btn_echo_us(120);
      end
      begin
        send_echo_cm(300);
      end
    join

    check_distance_top(300, 2);

    #(100_000_000); // 100ms

    // --------------------------
    // Case 3: TIMEOUT (echo 안 줌)
    // --------------------------
    $display("[%0t ns] TIMEOUT test start (no echo)", $time);
    press_btn_echo_us(120);

    // 타임아웃 + stop까지 넉넉히
    #(150_000_000); // 150ms

    $display("[%0t ns] DONE. last w_distance=%0d", $time, dut.w_distance);
    $finish;
  end

endmodule
