`timescale 1ns / 1ps

// 1. Top FIFO Module
module fifo(
    input  logic       clk,
    input  logic       rst,
    input  logic       push,      // we -> push
    input  logic       pop,       // re -> pop
    input  logic [7:0] push_data, // wdata -> push_data
    output logic [7:0] pop_data,  // rdata -> pop_data
    output logic       full,
    output logic       empty
);
    logic [3:0] waddr, raddr;

    // Register File 연결
    register_file U_REG_FILE (
        .clk      (clk),
        .wdata    (push_data),
        .waddr    (waddr),
        .raddr    (raddr),
        .we       (push & (~full)), // Overflow 방지
        .rdata    (pop_data)
    );

    // Control Unit 연결
    control_unit U_CONTROL_UNIT (
        .clk      (clk),
        .rst      (rst),
        .we       (push), // 내부 포트는 we/re 유지 가능 (이름 매핑만 처리)
        .re       (pop),
        .wptr     (waddr),
        .rptr     (raddr),
        .full     (full),
        .empty    (empty)
    );

endmodule

// 2. Register File
module register_file (
    input  logic        clk,
    input  logic [7:0]  wdata,
    input  logic [3:0]  waddr,
    input  logic [3:0]  raddr,
    input  logic        we,
    output logic [7:0]  rdata
);
    logic [7:0] ram [0:15];

    always_ff @(posedge clk) begin 
        if (we) begin
            ram[waddr] <= wdata;
        end
    end
    
    // FWFT(First-Word Fall-Through) 방식
    assign rdata = ram[raddr];

endmodule

// 3. Control Unit
module control_unit (
    input  logic       clk,
    input  logic       rst,
    input  logic       we,
    input  logic       re,
    output logic [3:0] wptr,
    output logic [3:0] rptr,
    output logic       full,
    output logic       empty
);

    logic [3:0] wptr_reg, wptr_next, rptr_reg, rptr_next;
    logic full_reg, full_next, empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk or posedge rst) begin 
        if (rst) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1'b1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always_comb begin 
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;

        case ({we, re})
            2'b01: begin // POP
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (rptr_next == wptr_reg)
                        empty_next = 1'b1;
                end
            end
            2'b10: begin // PUSH
                if (!full_reg) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg)
                        full_next = 1'b1;
                end
            end
            2'b11: begin // PUSH & POP 동시
                if (full_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else if (empty_reg) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    rptr_next = rptr_reg + 1;
                    wptr_next = wptr_reg + 1;
                end
            end
        endcase
    end
endmodule