// fifo.v (통합용 수정 버전)
module fifo #(
    parameter DEPTH = 16,
    parameter BIT_WIDTH = 8
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic                 we,    // push (RX_DONE 등과 연결)
    input  logic                 re,    // pop  (TX_READY 등과 연결)
    input  logic [BIT_WIDTH-1:0] wdata,
    output logic [BIT_WIDTH-1:0] rdata,
    output logic                 full,
    output logic                 empty
);
    // 주소 비트 계산: $clog2(16) = 4
    localparam ADDR_WIDTH = $clog2(DEPTH);
    logic [ADDR_WIDTH-1:0] waddr, raddr;

    register_file #(.DEPTH(DEPTH), .BIT_WIDTH(BIT_WIDTH)) U_REG_FILE (
        .clk   (clk),
        .wdata (wdata),
        .waddr (waddr),
        .raddr (raddr),
        .we    (we & (~full)), // overflow 방지
        .rdata (rdata)
    );

    control_unit #(.DEPTH(DEPTH)) U_CONTROL_UNIT (
        .clk   (clk),
        .rst   (rst),
        .we    (we),
        .re    (re),
        .wptr  (waddr),
        .rptr  (raddr),
        .full  (full),
        .empty (empty)
    );
endmodule

// control_unit.v (파라미터 적용)
module control_unit #(
    parameter DEPTH = 16
) (
    input  logic clk, rst, we, re,
    output logic [$clog2(DEPTH)-1:0] wptr, rptr,
    output logic full, empty
);
    localparam ADDR_WIDTH = $clog2(DEPTH);
    logic [ADDR_WIDTH-1:0] wptr_reg, wptr_next, rptr_reg, rptr_next;
    logic full_reg, full_next, empty_reg, empty_next;

    assign wptr = wptr_reg;
    assign rptr = rptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            wptr_reg <= 0; rptr_reg <= 0;
            full_reg <= 0; empty_reg <= 1'b1;
        end else begin
            wptr_reg <= wptr_next; rptr_reg <= rptr_next;
            full_reg <= full_next; empty_reg <= empty_next;
        end
    end

    // 사용자님의 정교한 조합 논리 로직 유지
    always_comb begin
        wptr_next = wptr_reg; rptr_next = rptr_reg;
        full_next = full_reg; empty_next = empty_reg;
        case ({we, re})
            2'b01: begin // POP
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (rptr_next == wptr_reg) empty_next = 1'b1;
                end
            end
            2'b10: begin // PUSH
                if (!full_reg) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) full_next = 1'b1;
                end
            end
            2'b11: begin // PUSH & POP 동시 발생
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

module register_file (
    input  logic        clk,
    input  logic [7:0] wdata,
    input  logic [3:0] waddr,
    input  logic [3:0] raddr,
    input  logic      we,
    output logic [7:0] rdata

);

    logic [7:0] ram [0:15];

    always_ff @( posedge clk ) begin 
        if (we) begin
            ram[waddr] <= wdata;
        end
    end
    
    assign rdata = ram[raddr];

    
endmodule