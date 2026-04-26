`timescale 1ns / 1ps

module periph_ram (
    input  logic        PCLK,     // APB CLK
    input  logic        PRESET,   // APB asynchronous RESET
    // APB Interface Signals
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY
);

    logic we;

    always_comb begin
        if (PSEL && PENABLE) begin
            we = PWRITE;
            PREADY = 1'b1;
        end else begin
            we = 1'b0;
            PREADY = 0;
        end
    end

    RAM U_RAM (
        .clk(PCLK),
        .we(we),
        .addr(PADDR[11:0]),
        .wData(PWDATA),
        .rData(PRDATA)
    );

endmodule


module RAM (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wData,
    output logic [31:0] rData
);
    logic [31:0] mem[0:2**12-1]; // 2**12-1

    always_ff @(posedge clk) begin
        if (we) mem[addr[11:2]] <= wData;
    end

    assign rData = mem[addr[11:2]];
endmodule
