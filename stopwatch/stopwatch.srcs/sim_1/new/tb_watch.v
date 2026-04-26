// `timescale 1ns/1ps

// module tb_watch;

//   reg clk, rst;
//   reg rx;
//   reg b_tick;

//   wire [7:0] rx_data;
//   wire rx_done;

//   wire cnt_r, cnt_l, cnt_u, cnt_d;

//   // UART RX만 따로
//   uart_rx U_RX (
//     .clk(clk),
//     .rst(rst),
//     .rx(rx),
//     .b_tick(b_tick),
//     .rx_data(rx_data),
//     .rx_done(rx_done)
//   );

//   // ASCII DECODER
//   ascii_decoder U_DEC (
//     .clk(clk),
//     .rst(rst),
//     .rx_done(rx_done),
//     .rx_data(rx_data),
//     .cnt_r(cnt_r),
//     .cnt_l(cnt_l),
//     .cnt_u(cnt_u),
//     .cnt_d(cnt_d)
//   );

//   // clk 100MHz 느낌 (10ns)
//   always #5 clk = ~clk;

//   // b_tick: 매 클럭마다 1펄스(1-cycle)
//   always @(posedge clk or posedge rst) begin
//     if (rst) b_tick <= 1'b0;
//     else     b_tick <= 1'b1; // 매 posedge마다 b_tick을 1로 만들어도 uart_rx는 "b_tick==1일 때만" 카운트하므로 동작
//   end

//   // -------- UART 보내기 task (16x 오버샘플 가정, LSB-first) --------
//   task send_uart_byte(input [7:0] data);
//     integer k;
//     begin
//       // IDLE 상태 유지
//       rx <= 1'b1;
//       repeat(20) @(posedge clk);

//       // START bit (0) : 16 b_tick 동안 유지
//       rx <= 1'b0;
//       repeat(16) @(posedge clk);

//       // DATA bits (LSB-first) : 각 비트 16클럭 유지
//       for (k=0; k<8; k=k+1) begin
//         rx <= data[k];
//         repeat(16) @(posedge clk);
//       end

//       // STOP bit (1) : 16클럭 유지
//       rx <= 1'b1;
//         repeat(17) @(posedge clk);
//     end
//   endtask

//   // 기대값 체크 task
//   task expect_decode(input [7:0] sent);
//     begin
//       // rx_done 뜰 때까지 대기
//       wait(rx_done == 1'b1);

//       // 1) rx_data 검증
//       if (rx_data !== sent) begin
//         $display("[%0t] FAIL rx_data: got=%h exp=%h", $time, rx_data, sent);
//         $stop;
//       end

//       // 2) decoder 펄스 검증(해당 클럭에 cnt_* 중 하나만 1)
//       if (sent == 8'h72) begin // 'r'
//         if (!(cnt_r && !cnt_l && !cnt_u && !cnt_d)) begin
//           $display("[%0t] FAIL decode 'r': cnt_r/l/u/d=%b%b%b%b", $time, cnt_r,cnt_l,cnt_u,cnt_d);
//           $stop;
//         end
//       end else if (sent == 8'h6C) begin // 'l'
//         if (!(!cnt_r && cnt_l && !cnt_u && !cnt_d)) begin
//           $display("[%0t] FAIL decode 'l': cnt_r/l/u/d=%b%b%b%b", $time, cnt_r,cnt_l,cnt_u,cnt_d);
//           $stop;
//         end
//       end else if (sent == 8'h75) begin // 'u'
//         if (!(!cnt_r && !cnt_l && cnt_u && !cnt_d)) begin
//           $display("[%0t] FAIL decode 'u': cnt_r/l/u/d=%b%b%b%b", $time, cnt_r,cnt_l,cnt_u,cnt_d);
//           $stop;
//         end
//       end else if (sent == 8'h64) begin // 'd'
//         if (!(!cnt_r && !cnt_l && !cnt_u && cnt_d)) begin
//           $display("[%0t] FAIL decode 'd': cnt_r/l/u/d=%b%b%b%b", $time, cnt_r,cnt_l,cnt_u,cnt_d);
//           $stop;
//         end
//       end else begin
//         // 디코더 맵에 없는 문자는 다 0이어야 함
//         if (cnt_r || cnt_l || cnt_u || cnt_d) begin
//           $display("[%0t] FAIL decode other: sent=%h cnt=%b%b%b%b", $time, sent, cnt_r,cnt_l,cnt_u,cnt_d);
//           $stop;
//         end
//       end

//       // rx_done이 1클럭 펄스인지 체크(다음 클럭에 0이어야 정상)
//       @(posedge clk);
//       if (rx_done !== 1'b0) begin
//         $display("[%0t] WARN rx_done not 1-cycle pulse (rx_done=%b)", $time, rx_done);
//       end

//       $display("[%0t] PASS sent=%h rx_data=%h cnt=%b%b%b%b",
//                $time, sent, rx_data, cnt_r,cnt_l,cnt_u,cnt_d);

//       // 다음 프레임 대비
//       repeat(10) @(posedge clk);
//     end
//   endtask

//   initial begin
//     clk = 0;
//     rst = 1;
//     rx  = 1;

//     repeat(10) @(posedge clk);
//     rst = 0;

//     // 'r','l','u','d' 테스트
//     send_uart_byte(8'h72); expect_decode(8'h72);
//     send_uart_byte(8'h6C); expect_decode(8'h6C);
//     send_uart_byte(8'h75); expect_decode(8'h75);
//     send_uart_byte(8'h64); expect_decode(8'h64);

//     // 맵에 없는 문자도 테스트(예: 'x')
//     send_uart_byte(8'h78); expect_decode(8'h78);

//     $display("ALL TEST PASSED");
//     $stop;
//   end

// endmodule
