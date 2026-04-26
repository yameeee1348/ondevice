`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/25/2025 03:07:21 PM
// Design Name: 
// Module Name: APB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module APB_Master_Interface (
    input logic PCLK,   // APB CLK
    input logic PRESET, // APB asynchronous RESET

    // APB Interface Signals
    output logic [31:0] PADDR,
    output logic        PWRITE,
    output logic        PSEL_RAM,
    output logic        PSEL_GPO,
    output logic        PSEL_GPI,
    output logic        PSEL_GPIO,
    output logic        PSEL_FND,
    output logic        PSEL_UART,
    output logic        PSEL_PWM,
    output logic        PSEL_DHT11,
    output logic        PSEL_HC_SR04,
    output logic        PENABLE,
    output logic [31:0] PWDATA,
    input  logic [31:0] PRDATA_RAM,
    input  logic [31:0] PRDATA_GPO,
    input  logic [31:0] PRDATA_GPI,
    input  logic [31:0] PRDATA_GPIO,
    input  logic [31:0] PRDATA_FND,
    input  logic [31:0] PRDATA_UART,
    input  logic [31:0] PRDATA_PWM,
    input  logic [31:0] PRDATA_DHT11,
    input  logic [31:0] PRDATA_HC_SR04,
    input  logic        PREADY_RAM,
    input  logic        PREADY_GPO,
    input  logic        PREADY_GPI,
    input  logic        PREADY_GPIO,
    input  logic        PREADY_FND,
    input  logic        PREADY_UART,
    input  logic        PREADY_PWM,
    input  logic        PREADY_DHT11,
    input  logic        PREADY_HC_SR04,
    // Internal Interface Signals
    input  logic        write,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    input  logic        req,
    output logic        ready
);
    logic [8:0] selx;
    logic decoder_en;
    logic [31:0] temp_addr, temp_wdata, temp_addr_next, temp_wdata_next;
    logic temp_write, temp_write_next;

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_e;

    apb_state_e state, state_next;

    assign PSEL_RAM     = selx[0];
    assign PSEL_GPO     = selx[1];
    assign PSEL_GPI     = selx[2];
    assign PSEL_GPIO    = selx[3];
    assign PSEL_FND     = selx[4];
    assign PSEL_UART    = selx[5];
    assign PSEL_PWM     = selx[6];
    assign PSEL_DHT11   = selx[7];
    assign PSEL_HC_SR04 = selx[8];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            state      <= IDLE;
            temp_addr  <= 0;
            temp_wdata <= 0;
            temp_write <= 0;
        end else begin
            state      <= state_next;
            temp_addr  <= temp_addr_next;
            temp_wdata <= temp_wdata_next;
            temp_write <= temp_write_next;
        end
    end

    always_comb begin
        state_next      = state;
        PADDR           = 0;
        PWDATA          = 0;
        PWRITE          = 0;
        PENABLE         = 0;
        decoder_en      = 0;
        temp_addr_next  = temp_addr;
        temp_wdata_next = temp_wdata;
        temp_write_next = temp_write;

        case (state)
            IDLE: begin
                decoder_en = 1'b0;  // PSELx
                if (req) begin
                    state_next = SETUP;
                    temp_addr_next = addr;  // latching
                    temp_wdata_next = wdata;
                    temp_write_next = write;
                end
            end
            SETUP: begin
                decoder_en = 1'b1;
                PENABLE = 1'b0;

                PADDR = temp_addr;
                if (temp_write == 1'b1) begin  // for write
                    PWDATA = temp_wdata;
                    PWRITE = 1'b1;
                end else begin  // for read
                    PWRITE = 0;
                end
                state_next = ACCESS;
            end
            ACCESS: begin
                decoder_en = 1'b1;
                PENABLE = 1'b1;

                PADDR = temp_addr;
                if (temp_write == 1'b1) begin  // for write
                    PWDATA = temp_wdata;
                    PWRITE = 1'b1;
                end else begin  // for read
                    PWRITE = 0;
                end

                if ((ready == 1'b1) && (req == 1'b0)) begin
                    state_next = IDLE;
                end
                //else if((PREADY == 1'b1) && (req == 1'b1)) state_next = SETUP;
            end
        endcase
    end

    APB_Decoder U_APB_Decoder (
        .enable(decoder_en),
        .sel(addr),
        .y(selx)
    );

    APB_Mux U_APB_Mux (
        .sel(addr),
        .x0 (PRDATA_RAM),
        .x1 (PRDATA_GPO),
        .x2 (PRDATA_GPI),
        .x3 (PRDATA_GPIO),
        .x4 (PRDATA_FND),
        .x5 (PRDATA_UART),
        .x6 (PRDATA_PWM),
        .x7 (PRDATA_DHT11),
        .x8 (PRDATA_HC_SR04),
        .y  (rdata),
        .r0 (PREADY_RAM),
        .r1 (PREADY_GPO),
        .r2 (PREADY_GPI),
        .r3 (PREADY_GPIO),
        .r4 (PREADY_FND),
        .r5 (PREADY_UART),
        .r6 (PREADY_PWM),
        .r7 (PREADY_DHT11),
        .r8 (PREADY_HC_SR04),
        .r  (ready)
    );

endmodule

module APB_Decoder (
    input  logic        enable,
    input  logic [31:0] sel,
    output logic [ 8:0] y
);
    always_comb begin
        y = 4'b0000;
        if (enable) begin
            casex (sel)
                32'h1000_0xxx: y = 9'b000000001;  // RAM
                32'h1000_1xxx: y = 9'b000000010;  // GP0
                32'h1000_2xxx: y = 9'b000000100;  // GPI
                32'h1000_3xxx: y = 9'b000001000;  // GPIO
                32'h1000_4xxx: y = 9'b000010000;  // FND
                32'h1000_5xxx: y = 9'b000100000;  // UART
                32'h1000_6xxx: y = 9'b001000000;  // PWM
                32'h1000_7xxx: y = 9'b010000000;  // DHT-11
                32'h1000_8xxx: y = 9'b100000000;  // HC-SR04
            endcase
        end
    end
endmodule

module APB_Mux (
    input  logic [31:0] sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    input  logic [31:0] x2,
    input  logic [31:0] x3,
    input  logic [31:0] x4,
    input  logic [31:0] x5,
    input  logic [31:0] x6,
    input  logic [31:0] x7,
    input  logic [31:0] x8,
    output logic [31:0] y,
    input  logic        r0,
    input  logic        r1,
    input  logic        r2,
    input  logic        r3,
    input  logic        r4,
    input  logic        r5,
    input  logic        r6,
    input  logic        r7,
    input  logic        r8,
    output logic        r
);

    always_comb begin
        y = 32'bx;
        casex (sel)
            32'h1000_0xxx: y = x0;  // RAM
            32'h1000_1xxx: y = x1;  // GP0
            32'h1000_2xxx: y = x2;  // GPI
            32'h1000_3xxx: y = x3;  // GPIO
            32'h1000_4xxx: y = x4;  // FND
            32'h1000_5xxx: y = x5;  // FND
            32'h1000_6xxx: y = x6;  // PWM
            32'h1000_7xxx: y = x7;  // DHT-11
            32'h1000_8xxx: y = x8;  // HC-SR04
        endcase
    end

    always_comb begin
        r = 1'b0;
        casex (sel)
            32'h1000_0xxx: r = r0;  // RAM
            32'h1000_1xxx: r = r1;  // GP0
            32'h1000_2xxx: r = r2;  // GPI
            32'h1000_3xxx: r = r3;  // GPIO
            32'h1000_4xxx: r = r4;  // FND
            32'h1000_5xxx: r = r5;  // FND
            32'h1000_6xxx: r = r6;  // PWM
            32'h1000_7xxx: r = r7;  // DHT-11
            32'h1000_8xxx: r = r8;  // HC-SR04
        endcase
    end
endmodule
