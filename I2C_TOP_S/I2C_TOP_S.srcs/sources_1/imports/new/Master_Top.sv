`timescale 1ns / 1ps



module Master_Top(
    input logic clk,
    input logic reset_n,
    input logic [7:0] switch,
    output logic scl,
    output logic sda,
    output logic busy_led
);
    logic reset;
    assign reset = !reset_n;

    logic cmd_start, cmd_write, cmd_stop, done, busy;
    logic [7:0] tx_data;

    logic [7:0] switch_reg;
    logic start_trigger;

    assign busy_led = busy;
    assign start_trigger = (switch != switch_reg) && !busy;

    typedef enum  logic [1:0] {ST_IDLE, ST_START_ADDR, ST_WRITE_DATA, ST_STOP  } m_flow_e;
    m_flow_e m_flow;

I2C_Master u_i2c_master_inst (
        .clk(clk), .reset(reset),
        .cmd_start(cmd_start), .cmd_write(cmd_write), .cmd_read(1'b0), .cmd_stop(cmd_stop),
        .tx_data(tx_data), .done(done), .busy(busy),
        .scl(scl), .sda(sda),
        .* // 나머지는 기본 연결
    );

    always_ff @(posedge clk) begin
        if (reset) switch_reg <= 8'h00;
        else switch_reg<=switch;
    end
  
  
    always_ff @(posedge clk) begin
        if (reset) begin
            m_flow <= ST_IDLE;
            cmd_start <= 0;
            cmd_write <= 0;
            cmd_stop <= 0;

        end else begin
            case (m_flow)
                ST_IDLE: if (start_trigger) begin
                    cmd_start <=1;
                    tx_data <= 8'hA0;
                    m_flow <= ST_START_ADDR;
                end 
                ST_START_ADDR: if (done) begin
                    cmd_start <= 0;
                    cmd_write <= 1;
                    tx_data <= switch;
                    m_flow <= ST_WRITE_DATA;
                end
                ST_WRITE_DATA: if (done) begin
                    cmd_write <= 0;
                    cmd_stop <= 1;
                    m_flow <= ST_STOP;

                end
                ST_STOP: if (done) begin
                    cmd_stop <= 0;
                    m_flow <= ST_IDLE;
                end
            endcase
        end
    end
endmodule
