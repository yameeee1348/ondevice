// `timescale 1ns / 1ps




// module tb_uart_simulation();

//     // 1. 입출력 신호 선언
//     reg        clk;
//     reg        rst;
//     reg  [3:0] sw;
//     reg        btn_r, btn_c, btn_l, btn_u, btn_d;
//     reg        uart_rx;
//     reg        echo;
    
//     wire       trigger;
//     wire       uart_tx;
//     wire [3:0] fnd_digit;
//     wire [7:0] fnd_data;
//     wire       dhtio;
//     wire       dht11_valid;

//     // 2. DUT 연결
//     top_uart_wsw uut (
//         .clk        (clk),
//         .rst        (rst),
//         .sw         (sw),
//         .btn_r      (btn_r),
//         .btn_c      (btn_c),
//         .btn_l      (btn_l),
//         .btn_u      (btn_u),
//         .btn_d      (btn_d),
//         .uart_rx    (uart_rx),
//         .echo       (echo),
//         .trigger    (trigger),
//         .uart_tx    (uart_tx),
//         .fnd_digit  (fnd_digit),
//         .fnd_data   (fnd_data),
//         .dhtio      (dhtio),
//         .dht11_valid(dht11_valid)
//     );

//     // 3. 파라미터 및 클럭
//     parameter CLK_PERIOD = 10;
//     parameter BIT_PERIOD = 104166;

//     always #(CLK_PERIOD/2) clk = ~clk;

//     // 4. Verilog Task: UART 전송
//     task send_uart_byte;
//         input [7:0] data;
//         integer i;
//         begin
//             uart_rx = 0; 
//             #(BIT_PERIOD);
//             for (i = 0; i < 8; i = i + 1) begin
//                 uart_rx = data[i];
//                 #(BIT_PERIOD);
//             end
//             uart_rx = 1; 
//             #(BIT_PERIOD);
//             #(BIT_PERIOD);
//         end
//     endtask

//     // 5. Verilog Task: 시퀀스 실행
//     task run_rcrs_sequence;
//         begin
//             $display("--- Starting Sequence: r -> c -> r -> s ---");
//             send_uart_byte(8'h72); // 'r'
//             #500000;
//             send_uart_byte(8'h63); // 'c'
//             #500000;
//             send_uart_byte(8'h72); // 'r'
//             #500000;
//             send_uart_byte(8'h73); // 's'
//             #1000000;
//         end
//     endtask

//     // 6. 메인 시나리오
//     initial begin
//         clk = 0; rst = 1; sw = 4'b0000; 
//         {btn_r, btn_c, btn_l, btn_u, btn_d} = 5'b00000;
//         uart_rx = 1; echo = 0;

//         #(CLK_PERIOD * 10);
//         rst = 0;
//         #(CLK_PERIOD * 10);

//         // [Mode 1 & 2] Watch & Stopwatch
//         sw = 4'b0000; run_rcrs_sequence();
//         sw = 4'b0010; run_rcrs_sequence();
//         sw = 4'b0100; run_rcrs_sequence();
//         sw = 4'b1000; run_rcrs_sequence();
//         sw = 4'b1010; run_rcrs_sequence();
//         sw = 4'b1110; run_rcrs_sequence();

//         // [Mode 3] Ultrasonic (가장 오류가 잦은 부분 수정)
//         $display("[Mode] Ultrasonic Mode Start");
//         sw = 4'b1000;
        
//         // Verilog-2001 안전한 병렬 실행 구조
//         fork
//             run_rcrs_sequence(); // 이 Task가 끝나면 fork 블록을 빠져나가야 함
//             begin : echo_response
//                 // 무한 루프 대신 충분한 횟수만큼만 반복하도록 설정
//                 // 혹은 run_rcrs_sequence가 끝날 때까지 trigger에 응답
//                 repeat(20) begin 
//                     @(posedge trigger);
//                     #1000;
//                     echo = 1;
//                     #58000;
//                     echo = 0;
//                 end
//             end
//         join // join_any 대신 join 사용 (표준)
        
//         // [Mode 4] DHT11
//         sw = 4'b1010; run_rcrs_sequence();

//         $display("Simulation Finished Successfully.");
//         $finish;
//     end

// endmodule


// `timescale 1ns / 1ps

// module tb_uart_simulation();

//     // 1. 입출력 신호 선언
//     reg clk, rst, uart_rx, echo;
//     reg [3:0] sw;
//     reg btn_r, btn_c, btn_l, btn_u, btn_d;
//     wire trigger, uart_tx, dht11_valid;
//     wire [3:0] fnd_digit;
//     wire [7:0] fnd_data;
//     wire dhtio;

//     // 2. DUT 연결
//     top_uart_wsw uut (
//         .clk(clk), .rst(rst), .sw(sw),
//         .btn_r(btn_r), .btn_c(btn_c), .btn_l(btn_l), .btn_u(btn_u), .btn_d(btn_d),
//         .uart_rx(uart_rx), .echo(echo), .trigger(trigger), .uart_tx(uart_tx),
//         .fnd_digit(fnd_digit), .fnd_data(fnd_data), .dhtio(dhtio), .dht11_valid(dht11_valid)
//     );

//     // 3. 파라미터 및 클럭
//     parameter CLK_PERIOD = 10;
//     parameter BIT_PERIOD = 104166;
//     always #(CLK_PERIOD/2) clk = ~clk;

//     // DHT11 시뮬레이션용 신호
//     reg dht_drive;
//     reg dht_en;
//     assign dhtio = (dht_en) ? dht_drive : 1'bz;

//     // 4. Task: UART 전송
//     task send_uart_byte;
//         input [7:0] data;
//         integer i;
//         begin
//             uart_rx = 0; #(BIT_PERIOD);
//             for (i = 0; i < 8; i = i + 1) begin
//                 uart_rx = data[i]; #(BIT_PERIOD);
//             end
//             uart_rx = 1; #(BIT_PERIOD * 2);
//         end
//     endtask

//     // 5. Task: DHT11 데이터 주입 (습도 55.00%, 온도 32.02도)
//     // 40bit 구성: 8'h37(습도55) + 8'h00 + 8'h20(온도32) + 8'h02 + Checksum(8'h59)
//     task simulate_dht11_data;
//         reg [39:0] dht_packet;
//         integer j;
//         begin
//             dht_packet = {8'h37, 8'h00, 8'h20, 8'h02, 8'h59}; 
//             wait(dhtio == 0); // 모듈의 시작 신호 감지
//             dht_en = 1;
//             wait(dhtio == 1); #20000; // WAIT 단계 통과
            
//             // Response: 80us Low, 80us High
//             dht_drive = 0; #80000; dht_drive = 1; #80000;
            
//             // 40-bit Data 송신
//             for (j = 39; j >= 0; j = j - 1) begin
//                 dht_drive = 0; #50000; // Start bit Low
//                 dht_drive = 1;
//                 if (dht_packet[j]) #70000; // '1'은 70us High
//                 else #26000;               // '0'은 26us High
//             end
//             dht_drive = 0; #50000; dht_en = 0;
//         end
//     endtask

//     // 6. 메인 시나리오
//     initial begin
//         // 초기화
//         clk = 0; rst = 1; sw = 4'b0000; 
//         {btn_r, btn_c, btn_l, btn_u, btn_d} = 5'b00000;
//         uart_rx = 1; echo = 0; dht_en = 0; dht_drive = 1'bz;

//         #(CLK_PERIOD * 10) rst = 0; #(CLK_PERIOD * 10);

//         // [Mode 1] Watch & Stopwatch
//         $display(">> Mode: Watch & Stopwatch");
//         sw = 4'b0000; send_uart_byte("r"); #500000; send_uart_byte("s");
//         sw = 4'b0010; send_uart_byte("r"); #500000; send_uart_byte("s");

//         // [Mode 2] Ultrasonic (10cm 설정)
//         $display(">> Mode: Ultrasonic (10cm)");
//         sw = 4'b1000;
//         fork
//             begin
//                 send_uart_byte("r"); 
//                 #2000000; 
//                 send_uart_byte("s");
//             end
//             begin
//                 @(posedge trigger);
//                 #1000; // 지연시간
//                 echo = 1;
//                 #580000; // 10cm * 58us = 580,000ns (580us)
//                 echo = 0;
//             end
//         join

//         // [Mode 3] DHT11 (온도 32.02, 습도 55.00)
//         $display(">> Mode: DHT11 (Temp: 32.02, Humid: 55.00)");
//         sw = 4'b1010;
//         fork
//             begin
//                 send_uart_byte("r");
//                 #3000000;
//                 send_uart_byte("s");
//             end
//             begin
//                 simulate_dht11_data();
//             end
//         join

//         #5000000;
//         $display("Simulation Finished Successfully.");
//         $finish;
//     end

//     // 풀업 저항 모사
//     assign (pull1, pull0) dhtio = 1'b1;

// endmodule
`timescale 1ns / 1ps

module tb_uartr_simulation();

    // 1. 신호 선언
    reg clk, rst, uart_rx;
    reg [15:0] display_data, watch_data;
    reg [1:0] sw_3_1;
    
    wire uart_tx;
    wire [3:0] cmd_tick, cmd_switch;

    // 2. DUT 인스턴스화
    top_uart uut (
        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx),
        .display_data(display_data),
        .watch_data(watch_data),
        .sw_3_1(sw_3_1),
        .uart_tx(uart_tx),
        .cmd_tick(cmd_tick),
        .cmd_switch(cmd_switch)
    );

    // 3. 클럭 생성 (100MHz)
    parameter CLK_PERIOD = 10;
    parameter BIT_PERIOD = 104166; // 9600 bps
    always #(CLK_PERIOD/2) clk = ~clk;

    
    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            uart_rx = 0; #(BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i]; #(BIT_PERIOD);
            end
            uart_rx = 1; #(BIT_PERIOD * 2);
        end
    endtask

    // 5. 테스트 시나리오
    initial begin
        // 초기화
        clk = 0; rst = 1; uart_rx = 1;
        watch_data = 16'h1200; 
        sw_3_1 = 2'b00;

        #(CLK_PERIOD * 10) rst = 0;
        #(CLK_PERIOD * 10);

        // --- [모드 1] 초음파 모드: 0012cm ---
        
        sw_3_1 = 2'b10; // Ultrasonic mode
        display_data = 16'h0012; 
        #1000;
        send_uart_byte(8'h73); // s  TX 시작
        #(BIT_PERIOD * 150);   

       // DHT11 온습도 모드: 습도 55.00 ---
        
        sw_3_1 = 2'b11; // Sensor(DHT11) mode
        display_data = 16'h5500; 
        #1000;
        send_uart_byte(8'h73); // 's
        #(BIT_PERIOD * 150);

        //  온습도 모드: 온도 29.12 
        sw_3_1 = 2'b11;
        display_data = 16'h2912; 
        #1000;
        send_uart_byte(8'h73); 
        #(BIT_PERIOD * 150);

       
        $finish;
    end

endmodule