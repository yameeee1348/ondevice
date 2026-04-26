`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 09:23:06 AM
// Design Name: 
// Module Name: PWM_TOP
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
 
module periph_pwm (
    input  logic        PCLK,     // APB CLK
    input  logic        PRESET,   // APB asynchronous RESET
    // APB Interface Signals
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // Internal Signals
    output logic        pwm_clk
);

    logic [31:0] prescaler, duty_cycle;
    logic start, clk_out;

    apb_slave_interface_pwm U_APB_SLAVE_INTERFACE (
        .*,
        .start(start),
        .prescaler(prescaler),
        .duty_cycle(duty_cycle)
    );
    
    clock_gate U_CLOCK_GATE(
        .clk_in(PCLK),    
        .enable(start),    
        .clk_out(clk_out)
    );

    PWM_TOP U_PWM(
        .clk(clk_out),
        .reset(PRESET),
        .prescaler(prescaler),
        .duty_cycle(duty_cycle),
        .pwm_clk(pwm_clk)
    );

endmodule
 

module apb_slave_interface_pwm (
    input  logic        PCLK,       // APB CLK
    input  logic        PRESET,     // APB asynchronous RESET
    // APB Interface Signals
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // Internal Signals
    output logic        start,
    output logic [31:0] prescaler,
    output logic [31:0] duty_cycle
);

    localparam START_ADDR = 4'h0;
    localparam PRESCALER_ADDR = 4'h4;
    localparam DUTY_ADDR = 4'h8;

    logic [31:0] start_reg, pre_reg, duty_reg;

    assign start     = start_reg[0];
    assign prescaler = pre_reg;
    assign duty_cycle = duty_reg;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            start_reg <= 0;
            pre_reg   <= 0; 
            duty_reg  <= 0;
        end else begin
            PREADY <= 1'b0;

            if (PSEL && PENABLE && PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0])
                    START_ADDR    : start_reg <= PWDATA;
                    PRESCALER_ADDR: pre_reg <= PWDATA;
                    DUTY_ADDR:      duty_reg <= PWDATA;
                    default:        ;
                endcase
            end else if (PSEL && PENABLE && !PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0])
                    START_ADDR:     PRDATA <= start_reg;
                    PRESCALER_ADDR: PRDATA <= pre_reg;
                    DUTY_ADDR:      PRDATA <= duty_reg;
                    default:        PRDATA = 'x;
                endcase
            end
        end
    end
endmodule
 

module PWM_TOP (
    input logic clk,
    input logic reset,
    input logic [31:0] prescaler,
    input logic [31:0] duty_cycle,
    output logic pwm_clk
);


    logic [31:0] pwm_clk_counter;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            pwm_clk_counter <= 0;
            pwm_clk         <= 0;
        end else begin
            if (pwm_clk_counter == prescaler - 1) begin
                pwm_clk_counter <= 0;
            end else begin
                pwm_clk_counter <= pwm_clk_counter + 1;
            end
                
            if (pwm_clk_counter < duty_cycle) begin
                pwm_clk <= 1;
            end else begin
                pwm_clk <= 0;
            end 
         end
    end   

endmodule
