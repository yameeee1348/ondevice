`timescale 1ns / 1ps

module tb_stopwatch_simulation();

    // 1. 신호 선언
    reg clk, reset;
    reg [3:0] sw;
    reg btn_r, btn_c, btn_l, btn_u, btn_d;
    reg [3:0] cmd_tick, cmd_switch;
    reg echo;
    
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;
    wire [15:0] display_data, watch_data;
    wire trigger;
    wire dhtio;
    wire dht11_valid;

    // 2. DUT 인스턴스화
    top_stopwatch_watch uut (
        .clk(clk), .reset(reset), .sw(sw),
        .btn_r(btn_r), .btn_c(btn_c), .btn_l(btn_l), .btn_u(btn_u), .btn_d(btn_d),
        .cmd_tick(cmd_tick), .cmd_switch(cmd_switch), .echo(echo),
        .fnd_digit(fnd_digit), .fnd_data(fnd_data),
        .display_data(display_data), .watch_data(watch_data),
        .trigger(trigger), .dhtio(dhtio), .dht11_valid(dht11_valid)
    );

    // 100MHz 클럭 생성
    always #5 clk = ~clk;

    // --- Task 선언 ---
    
    // UART Run 명령
    task send_cmd_r; 
        begin
            cmd_tick[0] = 1; #100; cmd_tick[0] = 0; #100;
        end
    endtask

    // 물리 버튼 Clear (디바운싱 고려 100us)
    task press_btn_c; 
        begin
            $display(">> Action: Pressing Reset Button (Debounce Time Applied)");
            btn_c = 1; #100000; // 100us 유지
            btn_c = 0; #100000; // 안정화
        end
    endtask

    // 3. 메인 시뮬레이션 시나리오
    initial begin
        // 초기화
        clk = 0; reset = 1; sw = 4'b0000;
        {btn_r, btn_c, btn_l, btn_u, btn_d} = 5'b0;
        {cmd_tick, cmd_switch} = 8'b0;
        echo = 0;

        #100 reset = 0; #1000;

        // --- STEP 1: Stopwatch Mode (sw=0010) ---
        $display("===== Scenario: Stopwatch r-c-r-s Test =====");
        sw = 4'b0010; 
        
        // 1. 'r' (Run)
        send_cmd_r();
        #200000; 

        // 2. 'c' (Clear) - 문법 오류 수정됨
        press_btn_c(); 

        // 3. 'r' (Re-run) - 라벨 제거 및 정상 호출
        send_cmd_r();
        #500000; 

        // --- STEP 2: Sensor Data Verification (Force) ---
        // uut 내부의 실제 와이어 이름에 맞춰 force (sw_3_1 기준 2'b11 모드)
        $display(">> Scenario: Sensor Data Verification");
        
        // uut 내부의 정적 와이어나 레지스터에 값 강제 주입
        force uut.w_dist = 24'd10;          
        force uut.w_humidity = 16'h5500;    
        force uut.w_temperature = 16'h2002; 
        
        // DHT11 온도 모드 설정 (sw[3]=1, sw[1]=1, sw[2]=1)
        sw = 4'b1110; 
        #1000;
        $display(">> Final Check - Display Data: %h (Target: 2002)", display_data);

        // 시계 데이터 확인 (초기값 12:00 가정)
        $display(">> Final Check - Watch Data: %h", watch_data);

        #10000;
        release uut.w_dist;
        release uut.w_humidity;
        release uut.w_temperature;
        
        $display("Simulation Finished Successfully.");
        $finish;
    end

endmodule