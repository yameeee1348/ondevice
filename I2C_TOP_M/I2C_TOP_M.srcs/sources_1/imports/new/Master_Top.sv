`timescale 1ns / 1ps

module Master_Top(
    input  logic clk,
    input  logic reset,         // 가운데 버튼 (U18)
    input  logic [7:0] switch,  // 데이터 쓰기용 스위치 (SW0 ~ SW7)
    input  logic sw_read,       // ★ 데이터 읽기용 스위치 (SW15)
    
    output logic [7:0] rx_led,  // ★ 슬레이브에서 읽어온 데이터를 띄울 LED
    output logic jb_scl,        // 마스터 SCL 출력
    inout  wire  jb_sda         // 마스터 SDA 양방향
);

    logic cmd_start, cmd_write, cmd_read_cmd, cmd_stop, done, busy;
    logic [7:0] tx_data;
    logic [7:0] master_rx_data;

    // --- I2C 마스터 인스턴스 ---
    I2C_Master u_master (
        .clk(clk), 
        .reset(reset),
        .cmd_master(1'b1),
        .cmd_start(cmd_start), 
        .cmd_write(cmd_write), 
        .cmd_read(cmd_read_cmd),    // ★ FSM에서 제어하도록 변경
        .cmd_stop(cmd_stop),
        .tx_data(tx_data), 
        .ack_in(1'b1),              // ★ 1바이트만 읽을 것이므로 NACK(1) 설정
        .rx_data(master_rx_data),   // ★ 수신 데이터 포트 연결
        .ack_out(), 
        .done(done), 
        .busy(busy),
        .scl(jb_scl), 
        .sda(jb_sda) 
    );

    // --- 스위치 변화 감지 및 트리거 생성 ---
    logic [7:0] switch_reg;
    logic sw_read_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            switch_reg  <= 8'h00;
            sw_read_reg <= 1'b0;
        end else begin
            switch_reg  <= switch; 
            sw_read_reg <= sw_read; 
        end
    end

    // 쓰기: SW0~7 값이 변하면 동작
    wire write_trigger = (switch != switch_reg) && !busy;
    
    // 읽기: SW15 스위치를 위로 올리는 순간(Rising Edge) 1번만 동작
    wire read_trigger = sw_read && !sw_read_reg && !busy;

    // --- 안전한 순차 전송 FSM (Write & Read 통합) ---
    enum logic [3:0] {
        IDLE, 
        START_CMD, WAIT_START,
        ADDR_CMD,  WAIT_ADDR,
        DATA_CMD,  WAIT_DATA,
        STOP_CMD,  WAIT_STOP
    } state;

    logic is_read_op; // Read인지 Write인지 구분하는 플래그

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            {cmd_start, cmd_write, cmd_read_cmd, cmd_stop} <= 4'b0000;
            is_read_op <= 1'b0;
            rx_led <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    if (write_trigger) begin
                        is_read_op <= 1'b0; // Write 모드
                        cmd_start  <= 1; 
                        state      <= WAIT_START;
                    end else if (read_trigger) begin
                        is_read_op <= 1'b1; // Read 모드
                        cmd_start  <= 1; 
                        state      <= WAIT_START;
                    end
                end

                WAIT_START: begin
                    cmd_start <= 0; 
                    if (done) state <= ADDR_CMD;
                end

                ADDR_CMD: begin
                    tx_data   <= is_read_op ? 8'hA1 : 8'hA0; // Read면 A1, Write면 A0
                    cmd_write <= 1;   
                    state     <= WAIT_ADDR;
                end

                WAIT_ADDR: begin
                    cmd_write <= 0; 
                    if (done) state <= DATA_CMD;
                end

                DATA_CMD: begin
                    if (is_read_op) begin
                        cmd_read_cmd <= 1;  // Read 명령
                    end else begin
                        tx_data      <= switch;
                        cmd_write    <= 1;  // Write 명령
                    end
                    state <= WAIT_DATA;
                end

                WAIT_DATA: begin
                    cmd_write    <= 0;
                    cmd_read_cmd <= 0;
                    if (done) begin
                        // Read가 완료되면 수신된 데이터를 LED에 업데이트
                        if (is_read_op) rx_led <= master_rx_data;
                        state <= STOP_CMD;
                    end
                end

                STOP_CMD: begin
                    cmd_stop <= 1; 
                    state    <= WAIT_STOP;
                end

                WAIT_STOP: begin
                    cmd_stop <= 0;
                    if (done) state <= IDLE; 
                end
            endcase
        end
    end
endmodule