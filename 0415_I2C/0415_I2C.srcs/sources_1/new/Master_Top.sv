`timescale 1ns / 1ps

module Master_Top(
    input  logic clk,
    input  logic reset,       // 가운데 버튼 (U18)
    input  logic [7:0] switch,  // 데이터 전송용 스위치
    input  logic btn_read,      // Read 요청 버튼 (추가)
    
    output logic jb_scl,        // 마스터 SCL 출력
    inout  wire  jb_sda,        // 마스터 SDA 양방향
    
    output logic [7:0] rx_led,  // Read로 받아온 데이터를 표시할 LED (추가)
    output logic busy_led       // Busy 상태 표시 LED
);
    //logic reset;
    //assign reset = reset_n; // 버튼이 Active-High라면 reset_n을 그대로 사용

    // 제어 신호들
    logic cmd_start, cmd_write, cmd_read_cmd, cmd_stop; 
    logic done, busy;
    logic [7:0] tx_data;
    logic [7:0] rx_data_out;

    assign busy_led = busy;

    // --- I2C 마스터 인스턴스 ---
    I2C_Master u_master (
        .clk(clk), 
        .reset(reset),
        .cmd_master(1'b1),
        .cmd_start(cmd_start), 
        .cmd_write(cmd_write), 
        .cmd_read(cmd_read_cmd), // FSM에서 제어하도록 변경
        .cmd_stop(cmd_stop),
        .tx_data(tx_data), 
        .ack_in(1'b1),           // ★ 중요: 1바이트만 읽을 거라 NACK(1)로 설정
        .rx_data(rx_data_out),   // 슬레이브에서 읽어온 데이터
        .ack_out(),
        .done(done), 
        .busy(busy),
        .scl(jb_scl), 
        .sda(jb_sda) 
    );

    // --- 트리거 신호 생성 ---
    logic [7:0] switch_reg;
    logic btn_read_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            switch_reg <= 8'h00;
            btn_read_reg <= 1'b0;
        end else begin
            switch_reg <= switch;
            btn_read_reg <= btn_read;
        end
    end

    // 스위치 값이 변하면 Write 시작, 버튼을 누르면(Edge) Read 시작
    wire write_trigger = (switch != switch_reg) && !busy;
    wire read_trigger  = btn_read && !btn_read_reg && !busy;

    // --- 통합 FSM (Write & Read) ---
    enum logic [3:0] {
        IDLE, 
        START_CMD, WAIT_START,
        ADDR_CMD,  WAIT_ADDR,
        DATA_CMD,  WAIT_DATA,
        STOP_CMD,  WAIT_STOP
    } state;

    logic is_read_op; // 현재 동작이 Read인지 구분하는 플래그

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
                        is_read_op <= 1'b0; // Write 모드 진입
                        cmd_start  <= 1; 
                        state      <= WAIT_START;
                    end else if (read_trigger) begin
                        is_read_op <= 1'b1; // Read 모드 진입
                        cmd_start  <= 1; 
                        state      <= WAIT_START;
                    end
                end

                WAIT_START: begin
                    cmd_start <= 0; 
                    if (done) state <= ADDR_CMD;
                end

                ADDR_CMD: begin
                    // Write면 0xA0, Read면 0xA1 전송
                    tx_data   <= is_read_op ? 8'hA1 : 8'hA0; 
                    cmd_write <= 1;   
                    state     <= WAIT_ADDR;
                end

                WAIT_ADDR: begin
                    cmd_write <= 0; 
                    if (done) state <= DATA_CMD;
                end

                DATA_CMD: begin
                    if (is_read_op) begin
                        cmd_read_cmd <= 1;   // Read 모드: 읽어라!
                    end else begin
                        tx_data      <= switch;
                        cmd_write    <= 1;   // Write 모드: 써라!
                    end
                    state <= WAIT_DATA;
                end

                WAIT_DATA: begin
                    cmd_write    <= 0;
                    cmd_read_cmd <= 0;
                    if (done) begin
                        // Read가 끝났다면 읽어온 값을 LED에 저장
                        if (is_read_op) begin
                            rx_led <= rx_data_out;
                        end
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