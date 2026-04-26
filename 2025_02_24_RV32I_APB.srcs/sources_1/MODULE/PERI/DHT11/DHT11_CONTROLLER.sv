`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: T.Y JANG
// 
// Create Date: 12/22/2024 05:39:26 PM
// Design Name: 
// Module Name: DHT11_controller
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

module periph_dht11 (
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
    inout  logic        data_io
);

    logic [$clog2(11600) - 1:0] humidity, temperature;
    logic start, clk_out;

    apb_slave_interface_dht11 U_APB_SLAVE_INTERFACE (
        .*,
        .start(start),
        .humidity(humidity),
        .temperature(temperature)
    );
    
    clock_gate U_CLOCK_GATE(
        .clk_in(PCLK),    
        .enable(start),    
        .clk_out(clk_out)
    );

    DHT11_CONTROLLER U_DHT11(
        .clk(clk_out),
        .reset(PRESET),
        .data_io(data_io),
        .humidity(humidity),
        .temperature(temperature),
        .led()
    );

endmodule
 

module apb_slave_interface_dht11 (
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
    input  logic [$clog2(11600) - 1:0] humidity,
    input  logic [$clog2(11600) - 1:0] temperature
);

    localparam START_ADDR = 4'h0;
    localparam HUMIDITY_ADDR = 4'h4;
    localparam TEMPERATURE_ADDR = 4'h8;

    logic [31:0] start_reg, humidity_reg, temperature_reg;

    assign start     = start_reg[0];
    assign humidity_reg = humidity;
    assign temperature_reg = temperature;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            start_reg <= 0;
        end else begin
            PREADY <= 1'b0;

            if (PSEL && PENABLE && PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0])
                    START_ADDR    : start_reg <= PWDATA;
                    default:        ;
                endcase
            end else if (PSEL && PENABLE && !PWRITE) begin
                PREADY <= 1'b1;
                case (PADDR[3:0])
                    START_ADDR:     PRDATA <= start_reg;
                    HUMIDITY_ADDR:  PRDATA <= humidity_reg; 
                    TEMPERATURE_ADDR: PRDATA <= temperature_reg;
                    default:        PRDATA = 'x;
                endcase
            end
        end
    end
endmodule

module DHT11_CONTROLLER(
    input clk,
    input reset,
    inout data_io,
    output reg [$clog2(11600) - 1:0] humidity,
    output reg [$clog2(11600) - 1:0] temperature,
    output reg [7:0] led
);

////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////  PARAMETERS   ////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

    localparam IDLE = 4'b0001;
    localparam SEND_REQUEST = 4'b0010;
    localparam WAIT_RESPONSE_LOW = 4'b0011;
    localparam WAIT_RESPONSE_HIGH = 4'b0100;
    localparam READ_DATA = 4'b0101;
    localparam VERIFY_CHECKSUM = 4'b0110;

    localparam TIMEOUT = 100_000;

////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////  WIRE & REG   ////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////


    reg [$clog2(TIMEOUT):0] timeout_counter;
    reg [5:0] bit_counter;  // For 40 bits (0 to 39)
    reg [39:0] data_buffer;
    reg read_state;

    /* Tri-state Control */
    reg data_tri;  // 0: Output, 1: Input
    reg data_tx;
    reg prev_data_io;
    assign data_io = (data_tri) ? 1'bZ : data_tx;

    /* Tick Counters*/
    reg [21:0] us_tick_counter;
    wire w_us_tick, w_ms_tick;

    reg [3:0] state, next_state;

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////  MODULE INSTANTIATIONS   ///////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////    

    tick_clock #(
        .CLOCK_FREQ (100_000_000),
        .TARGET_FREQ(1_000_000)
    ) us_tick_generator (
        .clk  (clk),
        .reset(reset),
        .tick (w_us_tick)
    );


////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////  MODULE Logic   ////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

    /* State Register */
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end



    /* State Transition */
    always @(*) begin

        next_state = state;

        if (w_us_tick) begin

            case (state)
                IDLE: begin
                    if (us_tick_counter > 3_000_000) begin
                        next_state = SEND_REQUEST;
                    end
                end
                
                SEND_REQUEST: begin
                    if (us_tick_counter > 18_000) begin
                        next_state = WAIT_RESPONSE_LOW;
                    end
                end
                
                WAIT_RESPONSE_LOW: begin
                    if (!data_io && prev_data_io) begin
                        next_state = WAIT_RESPONSE_HIGH;
                    end else if (us_tick_counter > TIMEOUT) begin
                        next_state = IDLE;
                    end
                end
                
                WAIT_RESPONSE_HIGH: begin
                    if (data_io && !prev_data_io) begin
                        next_state = READ_DATA;
                    end else if (us_tick_counter > TIMEOUT) begin
                        next_state = IDLE;
                    end
                end
                
                READ_DATA: begin
                    if (bit_counter >= 40) begin
                        next_state = VERIFY_CHECKSUM;
                    end else if (us_tick_counter > TIMEOUT) begin
                        next_state = IDLE;
                    end
                end
                
                VERIFY_CHECKSUM: begin
                    next_state = IDLE;
                end
                
                default: next_state = IDLE;
            endcase
        end 

    end


    /* State Logic */
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_tri <= 0;
            data_tx <= 1;
            bit_counter <= 0;
            led <= 8'b00000000;
            data_buffer <= 0;
            humidity <= 0;
            temperature <= 0;
            read_state <= 0;
            prev_data_io <= 1;
            us_tick_counter <= 0;
        end else if (w_us_tick) begin
            prev_data_io <= data_io;
            
            case (state)
                IDLE: begin
                    led <= 8'b00000001;
                    if (us_tick_counter > 3_000_000) begin
                        data_tri <= 0;
                        data_tx <= 0;
                        us_tick_counter <= 0;
                    end else begin
                        us_tick_counter <= us_tick_counter + 1;
                    end
                end
                
                SEND_REQUEST: begin
                    led <= 8'b00000011;
                    if (us_tick_counter > 18_000) begin
                        data_tri <= 1;
                        data_tx <= 1;
                        us_tick_counter <= 0;
                    end else begin
                        us_tick_counter <= us_tick_counter + 1;
                    end
                end
                
                WAIT_RESPONSE_LOW: begin
                    led <= 8'b00000111;
                    us_tick_counter <= us_tick_counter + 1;
                end
                
                WAIT_RESPONSE_HIGH: begin
                    led <= 8'b00001111;
                    if (data_io && !prev_data_io) begin
                        bit_counter <= 0;
                        us_tick_counter <= 0;
                        read_state <= 0;
                    end else begin
                        us_tick_counter <= us_tick_counter + 1;
                    end
                end
                
                READ_DATA: begin
                    led <= 8'b00011111;
                    case (read_state)
                        0: begin
                            if (data_io && !prev_data_io) begin
                                us_tick_counter <= 0;
                                read_state <= 1;
                            end else begin
                                us_tick_counter <= us_tick_counter + 1;
                            end
                        end
                        1: begin
                            if (!data_io && prev_data_io) begin
                                us_tick_counter <= 0;
                                data_buffer[39 - bit_counter] <= (us_tick_counter > 50) ? 1'b1 : 1'b0;
                                bit_counter <= bit_counter + 1;
                                read_state <= 0;
                            end else begin
                                us_tick_counter <= us_tick_counter + 1;
                            end
                        end
                    endcase
                end
                
                VERIFY_CHECKSUM: begin
                    led <= 8'b00111111;
                    if(data_buffer[7:0] == data_buffer[39:32] + data_buffer[31:24] + data_buffer[23:16] + data_buffer[15:8]) begin
                        humidity <= {data_buffer[39:32]};
                        temperature <= (data_buffer[23:16]) * 100 + (data_buffer[15:8]);
                    end
                end
            endcase
        end
    end

endmodule




