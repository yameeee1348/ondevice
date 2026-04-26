// `timescale 1ns / 1ps


// module tb_stopwatch ();

//     reg       clk;
//     reg       rst;
//     reg  [3:0]   sw;   //up/down   sw=011: 
//     reg       btn_r;     //i_run_stop
//     reg       btn_l;     //i_clear
//     reg       btn_min_up;   //
//     reg       btn_hour_up; //
//     reg         uart_rx;
//     wire        uart_tx;
//     wire [3:0] fnd_digit;
//     wire [7:0] fnd_data;

//     top_stopwatch dut (

//     .clk(clk),
//     .rst(rst),
//     .sw(sw),    //up/down   s
//     .btn_r(btn_r),      //i_run_stop
//     .btn_l(btn_l),      //i_clear
//     .btn_min_up(btn_min_up),   //
//     .btn_hour_up(btn_hour_up), /
//     .fnd_digit(fnd_digit),
//     .uart_rx(uart_rx), 
//     .uart_tx(uart_tx),
//     .fnd_data(fnd_data)
// );

//     always #5 clk = ~clk;

//     initial begin
//         #0;
//         clk = 0;
//         rst =1;
//         sw = 4'b0000;
//         btn_r = 0;
//         btn_l = 1;
//         btn_min_up = 0;
//         btn_hour_up = 0;
//         uart_rx = 0;
//         #100;
//         uart_rx = 1;
//         rst =0;
//         btn_l = 0;
//         btn_r = 1;
//         #1000;
        
        
        
//         #10000000;
//         btn_l = 1;
//         #1000;
        
        
        

//     end
    
// endmodule


// `timescale 1ns / 1ps

// module tb_stopwatch;

//     reg         clk;
//     reg         rst;
//     reg  [3:0]  sw;
//     reg         btn_r;
//     reg         btn_l;
//     reg         btn_min_up;
//     reg         btn_hour_up;
//     reg         uart_rx;

//     wire        uart_tx;
//     wire [3:0]  fnd_digit;
//     wire [7:0]  fnd_data;

//     // DUT
//     top_stopwatch dut (
//         .clk        (clk),
//         .rst        (rst),
//         .sw         (sw),
//         .btn_r      (btn_r),
//         .btn_l      (btn_l),
//         .btn_min_up (btn_min_up),
//         .btn_hour_up(btn_hour_up),
//         .uart_rx    (uart_rx),
//         .uart_tx    (uart_tx),
//         .fnd_digit  (fnd_digit),
//         .fnd_data   (fnd_data)
//     );

//     // 100MHz
//     always #5 clk = ~clk;

//     // 버튼 디바운서가 100kHz 샘플링 + 8탭 AND라서
//     // 최소 80us 이상 HIGH 유지 필요(여유로 200us 사용)
//     task press_r;
//     begin
//         btn_r = 1'b1;
//         #(200_000);          // 200us
//         btn_r = 1'b0;
//         #(200_000);          // release
//     end
//     endtask

//     task press_l;
//     begin
//         btn_l = 1'b1;
//         #(200_000);          // 200us
//         btn_l = 1'b0;
//         #(200_000);          // release
//     end
//     endtask

//     initial begin
//         // init
//         clk         = 1'b0;
//         rst         = 1'b1;
//         sw          = 4'b0000;
//         btn_r       = 1'b0;
//         btn_l       = 1'b0;
//         btn_min_up  = 1'b0;
//         btn_hour_up = 1'b0;
//         uart_rx     = 1'b1;  // UART idle는 1이 정상

//         // reset
//         #100;
//         rst = 1'b0;

//         // 약간 안정화 시간
//         #1_000_000; // 1ms

//         // ===== 테스트 시나리오 =====
//         // RUN 1번 (STOP->RUN)
//         press_r();

//         // 조금 동작 시간
//         #5_000_000; // 5ms

//         // RUN 2번 (RUN->STOP)
//         press_r();

//         // 조금 대기
//         #5_000_000;  // 5ms

//         // L 1번 (CLEAR)
//         press_l();

//         #5_000_000;
//         $stop;
//     end

// endmodule


`timescale 1ns / 1ps

module tb_stopwatch;

    reg         clk;
    reg         rst;
    reg  [3:0]  sw;
    reg         btn_r;
    reg         btn_l;
    reg         btn_min_up;
    reg         btn_hour_up;
    reg         uart_rx;

    wire        uart_tx;
    wire [3:0]  fnd_digit;
    wire [7:0]  fnd_data;


    top_stopwatch dut (
        .clk        (clk),
        .rst        (rst),
        .sw         (sw),
        .btn_r      (btn_r),
        .btn_l      (btn_l),
        .btn_min_up (btn_min_up),
        .btn_hour_up(btn_hour_up),
        .uart_rx    (uart_rx),
        .uart_tx    (uart_tx),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );
  
    always #5 clk = ~clk; 
   
    // 9600 bps 기준 1bit = 104166 ns
    localparam integer BAUD_RATE  = 9600;
    localparam integer BIT_PERIOD = 1000000000 / BAUD_RATE; // ns

    task uart_send(input [7:0] data);
        integer i;
        begin
            // idle
            uart_rx = 1'b1;
            #(BIT_PERIOD);

            // start bit (0)
            uart_rx = 1'b0;
            #(BIT_PERIOD);

            
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i];
                #(BIT_PERIOD);
            end

            // stop bit (1)
            uart_rx = 1'b1;
            #(BIT_PERIOD);

            //  gap 
            #(BIT_PERIOD*2);
        end
    endtask

    
    // Test: r 2번, l 1번

    initial begin
        // init
        clk         = 1'b0;
        rst         = 1'b1;
        btn_r       = 1'b0;
        btn_l       = 1'b0;
        btn_min_up  = 1'b0;
        btn_hour_up = 1'b0;
        uart_rx     = 1'b1;     

        // reset hold
        sw          = 4'b0000;  
        #200;
        rst = 1'b0;
        
        // RUN/STOP 토글 1회
        uart_send(8'h72);
        #(BIT_PERIOD*2);
        //  RUN/STOP 토글 2회
        uart_send(8'h72);
        #(BIT_PERIOD*2);
        //  CLEAR 1회
        uart_send(8'h6C);
        // 
        #(BIT_PERIOD*2);
        #(BIT_PERIOD*20);
         sw          = 4'b1010;
        
         
         //  RUN/STOP 토글 1회
        uart_send(8'h75);
        
        #(BIT_PERIOD*2);
        //  RUN/STOP 토글 2회
        uart_send(8'h75);
        
        #(BIT_PERIOD*2);
        // CLEAR 1회
        uart_send(8'h64);
        #(BIT_PERIOD*20);
        

        sw          = 4'b0000;
        //  RUN/STOP 토글 1회
        uart_send(8'h72);
        #(BIT_PERIOD*40);
        
        uart_send(8'h72);
        

        $stop;
    end

endmodule

        // #(BIT_PERIOD*20);
        // #(BIT_PERIOD*20);
        // #(BIT_PERIOD*20);
        // #(BIT_PERIOD*20);
        // #(BIT_PERIOD*200);
        // #(BIT_PERIOD*200);