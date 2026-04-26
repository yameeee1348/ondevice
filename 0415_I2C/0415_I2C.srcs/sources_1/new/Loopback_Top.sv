`timescale 1ns / 1ps

module Loopback_Top(
    input  logic clk,
    input  logic reset,
    input  logic [7:0] switch,     // SW7 ~ SW0: Write 데이터용
    input  logic btn_read,         // ★ 수정: sw_read -> btn_read (테스트벤치와 이름 통일)
    
    output logic [7:0] led,        // Slave 수신 데이터 표시
    output logic [7:0] master_led, // Master 수신 데이터 표시

    output logic jb_scl,
    inout  wire  jb_sda,
    input  logic jc_scl,
    inout  wire  jc_sda
);

    logic cmd_start, cmd_write, cmd_read, cmd_stop, done, busy;
    logic [7:0] tx_data;
    logic [7:0] master_rx_data;

    logic [7:0] rx_data;
    logic rx_valid;

    // --- I2C 마스터 인스턴스 ---
    I2C_Master u_master1 (
        .clk(clk), .reset(reset),
        .cmd_master(1'b1),
        .cmd_start(cmd_start), .cmd_write(cmd_write), .cmd_read(cmd_read), .cmd_stop(cmd_stop),
        .tx_data(tx_data), .done(done), .rx_data(master_rx_data),
        .busy(busy), .scl(jb_scl), .sda(jb_sda), 
        .ack_in(1'b1), .ack_out()
    );

    // --- I2C 슬레이브 인스턴스 ---
    I2C_Slave u_slave (
        .clk(clk), .reset(reset), .slave_addr(7'h50),
        .rx_data(rx_data), .rx_valid(rx_valid),
        .scl(jc_scl), .sda(jc_sda), .tx_data(8'h77) 
    );

    // --- 트리거 생성 로직 ---
    logic [7:0] switch_reg;
    logic btn_read_reg; // ★ 수정: sw_read_reg -> btn_read_reg

    always_ff @(posedge clk) begin
        if (reset) begin
            switch_reg   <= 8'h00;
            btn_read_reg <= 1'b0;
        end else begin
            switch_reg   <= switch; 
            btn_read_reg <= btn_read; // ★ 수정: 버튼 상태 저장
        end
    end

    // Write: SW7~0 데이터가 바뀌면 트리거
    wire write_trigger = (switch != switch_reg) && !busy;
    
    // Read: btn_read를 누르는 순간(Rising Edge)에만 트리거
    wire read_trigger = btn_read && !btn_read_reg && !busy; // ★ 수정

    // --- 통합 FSM ---
    enum logic [3:0] {
        IDLE, START_CMD, WAIT_START, ADDR_CMD, WAIT_ADDR,
        DATA_CMD, WAIT_DATA, STOP_CMD, WAIT_STOP
    } state;

    logic is_read_op;

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            {cmd_start, cmd_write, cmd_read, cmd_stop} <= 4'b0000;
            is_read_op <= 1'b0;
            master_led <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    if (write_trigger) begin
                        is_read_op <= 1'b0; cmd_start <= 1; state <= WAIT_START;
                    end else if (read_trigger) begin
                        is_read_op <= 1'b1; cmd_start <= 1; state <= WAIT_START;
                    end
                end
                WAIT_START: begin
                    cmd_start <= 0; if (done) state <= ADDR_CMD;
                end
                ADDR_CMD: begin
                    tx_data <= is_read_op ? 8'hA1 : 8'hA0; 
                    cmd_write <= 1; state <= WAIT_ADDR;
                end
                WAIT_ADDR: begin
                    cmd_write <= 0; if (done) state <= DATA_CMD;
                end
                DATA_CMD: begin
                    if (is_read_op) cmd_read <= 1;
                    else begin tx_data <= switch; cmd_write <= 1; end
                    state <= WAIT_DATA;
                end
                WAIT_DATA: begin
                    cmd_write <= 0; cmd_read <= 0;
                    if (done) begin
                        if (is_read_op) master_led <= master_rx_data;
                        state <= STOP_CMD;
                    end
                end
                STOP_CMD: begin
                    cmd_stop <= 1; state <= WAIT_STOP;
                end
                WAIT_STOP: begin
                    cmd_stop <= 0; if (done) state <= IDLE; 
                end
            endcase
        end
    end

    // 슬레이브 수신 LED 업데이트
    always_ff @(posedge clk) begin
        if (reset) led <= 8'h00;
        else if (rx_valid) led <= rx_data;
    end

endmodule


`timescale 1ns / 1ps

module Loopback_Top(
    input  logic clk,
    input  logic reset_n,
    input  logic [7:0] switch,
    output logic [7:0] led,

    output logic jb_scl,
    inout  wire  jb_sda, // Master용 inout (wire 권장)

    input  logic jc_scl,
    inout  wire  jc_sda  // Slave용 inout
);
    logic reset;
    assign reset = !reset_n;

    // 내부 제어 신호
    logic cmd_start, cmd_write, cmd_stop, done, busy;
    logic [7:0] tx_data;
    logic [7:0] switch_reg;
    logic [7:0] rx_data;
    logic rx_valid;

    // 1. Master 인스턴스
    // 이미지 경고(Synth 8-7023)에 따라 포트 매핑을 더 엄격하게 맞춤
    I2C_master u_master (
        .clk(clk), 
        .reset(reset),
        .cmd_start(cmd_start), 
        .cmd_write(cmd_write), 
        .cmd_read(1'b0),     // Read 동작 확인 시 필요
        .cmd_stop(cmd_stop),
        .cmd_master(1'b1),    // 이미지에서 누락되었다고 나온 포트
        .tx_data(tx_data), 
        .ack_in(1'b0),
        .done(done), 
        .busy(busy),
        .scl(jb_scl), 
        .sda(jb_sda)          // inout 포트 직결
    );

    // 2. Slave 인스턴스
    I2C_Slave u_slave (
        .clk(clk), 
        .reset(reset),
        .slave_addr(7'h50),
        .rx_data(rx_data), 
        .rx_valid(rx_valid),
        .scl(jc_scl), 
        .sda(jc_sda),         // inout 포트 직결
        .tx_data(8'h00)
    );

    // --- 스위치 변화 감지 로직 ---
    always_ff @(posedge clk) begin
        if (reset) switch_reg <= 8'h00;
        else       switch_reg <= switch; 
    end

    wire start_trigger = (switch != switch_reg) && !busy;

   
    enum {IDLE, ADDR, DATA, STOP} state;
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            {cmd_start, cmd_write, cmd_stop} <= 3'b000;
        end else begin
            case (state)
                IDLE: if (start_trigger) begin
                    tx_data <= 8'hA0; 
                    cmd_start <= 1;
                    state <= ADDR;
                end 
                ADDR: if (done) begin
                    cmd_start <= 0;
                    cmd_write <= 1;
                    tx_data <= switch;
                    state <= DATA;
                end
                DATA: if (done) begin
                    cmd_write<= 0;
                    cmd_stop <= 1;
                    state <= STOP;
                end
                STOP: if (done) begin
                    cmd_stop <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

    // Slave 수신 결과 LED 출력
    always_ff @(posedge clk) begin
        if (reset) led <= 8'h00;
        else if (rx_valid) led <= rx_data;
    end

endmodule