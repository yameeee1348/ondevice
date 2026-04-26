`timescale 1ns / 1ps

module FIFO (
    input        clk,
    input        reset,
    // write side
    input  [7:0] wData,
    input        wr_en,
    output       full,
    // read side
    output [7:0] rData,
    input        rd_en,
    output       empty
);
    wire [1:0] wr_ptr, rd_ptr;

    fifo_ram U_FIFO_RAM (
        .clk  (clk),
        .wAddr(wr_ptr),
        .wData(wData),
        .wr_en(wr_en & ~full),
        .rAddr(rd_ptr),
        .rData(rData)
    );

    fifo_control_unit U_FIFO_ControlUnit (
        .clk(clk),
        .reset(reset),
        .wr_ptr(wr_ptr),
        .wr_en(wr_en),
        .full(full),
        .rd_ptr(rd_ptr),
        .rd_en(rd_en),
        .empty(empty)
    );
endmodule

module fifo_ram (
    input        clk,
    input  [1:0] wAddr,
    input  [7:0] wData,
    input        wr_en,
    input  [1:0] rAddr,
    output [7:0] rData
);
    reg [7:0] mem[0:2**2-1];

    assign rData = mem[rAddr];

    always @(posedge clk) begin
        if (wr_en) mem[wAddr] <= wData;
    end
endmodule

module fifo_control_unit (
    input        clk,
    input        reset,
    // write side
    output [1:0] wr_ptr,
    input        wr_en,
    output       full,
    // read side
    output [1:0] rd_ptr,
    input        rd_en,
    output       empty
);
    reg [1:0] wr_ptr_reg, wr_ptr_next, rd_ptr_reg, rd_ptr_next;
    reg full_reg, full_next, empty_reg, empty_next;
    wire [1:0] fifo_state;

    assign wr_ptr = wr_ptr_reg;
    assign rd_ptr = rd_ptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;
    assign fifo_state = {wr_en, rd_en};

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            full_reg   <= 1'b0;
            empty_reg  <= 1'b1;
            rd_ptr_reg <= 0;
            wr_ptr_reg <= 0;
        end else begin
            full_reg   <= full_next;
            empty_reg  <= empty_next;
            rd_ptr_reg <= rd_ptr_next;
            wr_ptr_reg <= wr_ptr_next;
        end
    end

    always @(*) begin
        full_next   = full_reg;
        empty_next  = empty_reg;
        rd_ptr_next = rd_ptr_reg;
        wr_ptr_next = wr_ptr_reg;
        case (fifo_state)
            2'b01: begin  // read, pop
                if (empty_reg == 1'b0) begin
                    full_next   = 1'b0;
                    rd_ptr_next = rd_ptr_reg + 1;
                    if (rd_ptr_next == wr_ptr_reg) begin
                        empty_next = 1'b1;
                    end
                end
            end
            2'b10: begin  // write, push
                if (full_reg == 1'b0) begin
                    empty_next  = 1'b0;
                    wr_ptr_next = wr_ptr_reg + 1;
                    if (wr_ptr_next == rd_ptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            2'b11: begin  // write, read, push, pop
                if (empty_reg == 1'b1) begin
                    wr_ptr_next = wr_ptr_reg + 1;
                    empty_next  = 1'b0;
                end else if (full_reg == 1'b1) begin
                    rd_ptr_next = rd_ptr_reg + 1;
                    full_next   = 1'b0;
                end else begin
                    wr_ptr_next = wr_ptr_reg + 1;
                    rd_ptr_next = rd_ptr_reg + 1;
                end
            end
        endcase
    end
endmodule


/*

module FIFO(
    input clk, reset,
    //  WRITE SIGNAL
    input   [7:0] wr_data,
    input   wr_en,
    output  full,
    
    //  READ SIGNAL
    output  [7:0] r_data,
    input   r_en,
    output  empty
    );


    wire [1:0] w_wr_ptr, w_r_ptr;


    RAM U_RAM(
    .clk(clk),
    .wr_addr(w_wr_ptr),
    .wr_data(wr_data),
    .wr_en(wr_en & ~full),
    .r_addr(w_r_ptr),
    .r_data(r_data)
    );

    FIFO_controller U_FIFO_CONTROLLER(
    .clk(clk), .reset(reset),
    .wr_en(wr_en),
    .wr_ptr(w_wr_ptr),
    .full(full),
    .r_en(r_en),
    .r_ptr(w_r_ptr),
    .empty(empty)
    );

endmodule



module RAM(
    input   clk,

    // WRITE SIGNAL
    input   [1:0] wr_addr,
    input   [7:0] wr_data,
    input   wr_en,

    // READ SIGNAL
    input   [1:0] r_addr,
    output  [7:0] r_data
    );

    reg [7:0] mem[0 : 2 ** 2-1];


    always @(posedge clk) begin
        if(wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    assign r_data = mem[r_addr];

endmodule



module FIFO_controller (
    input   clk, reset,

    //  WRITE SIGNAL
    input   wr_en,
    output  [1:0] wr_ptr,
    output  full,
    
    //  READ SIGNAL
    input   r_en,
    output  [1:0] r_ptr,
    output  empty
);


    reg [1:0] r_wr_ptr, next_wr_ptr, r_r_ptr, next_r_ptr;
    reg r_full, next_full, r_empty, next_empty;

    assign wr_ptr   = r_wr_ptr;
    assign r_ptr    = r_r_ptr;
    assign full     = r_full;
    assign empty    = r_empty;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_wr_ptr    <= 0;
            r_r_ptr     <= 0;
            r_full      <= 0;
            r_empty     <= 0;
        end else begin
            r_wr_ptr    <= next_wr_ptr;
            r_r_ptr     <= next_r_ptr;
            r_full      <= next_full;
            r_empty     <= next_empty;
        end
    end



    always @(*) begin
    
        next_wr_ptr = r_wr_ptr;
        next_r_ptr  = r_r_ptr;
        next_full   = r_full;
        next_empty  = r_empty;

        case ({wr_en, r_en})
            2'b01:  begin           // READ, POP
                if(r_empty == 0) begin
                    next_full = 0;
                    next_r_ptr = r_r_ptr + 1;

                    if(next_r_ptr == r_wr_ptr) begin
                        next_empty = 1;
                    end


                end
            end


            2'b10: begin            // WRITE, PUSH
                if(r_full == 0) begin
                    next_empty = 0;
                    next_wr_ptr = r_wr_ptr + 1;

                    if(next_wr_ptr == r_r_ptr) begin
                        next_full = 1;
                    end
                end
            end


            2'b11: begin          // READ, POP, WRITE, PUSH
                if (r_empty == 1'b1) begin
                    next_wr_ptr = r_wr_ptr + 1;
                    next_empty  = 1'b0;
                end else if (r_full == 1'b1) begin
                    next_r_ptr = r_r_ptr + 1;
                    next_full   = 1'b0;
                end else begin
                    next_wr_ptr = r_wr_ptr + 1;
                    next_r_ptr = r_r_ptr + 1;
                end

            end
        endcase 

    end


endmodule

*/