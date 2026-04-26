`timescale 1ns / 1ps

module MCU ( 
    input  logic       clk,
    input  logic       reset,
    output logic [7:0] GPOA,
    input  logic [7:0] GPIB,
    inout  logic [7:0] GPIOC,
    output logic [7:0] fndFont,
    output logic [3:0] fndCom,
    input  logic       uart_transmit_button,
    input  logic       rx,
    output logic       tx,
    output logic       pwm_clk,
    inout  logic       dht_11_inout,
    input  logic       echo,
    output logic       trigger
);  

    logic w_uart_transmit_button;

    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;
    logic        dWe;
    logic [31:0] dAddr;
    logic [31:0] wData, rData;
    logic apb_req, apb_ready;

    logic [31:0] PADDR;
    logic        PWRITE;
    logic        PSEL_RAM;
    logic        PSEL_GPO;
    logic        PSEL_GPI;
    logic        PSEL_GPIO;
    logic        PSEL_FND;
    logic        PSEL_UART;
    logic        PSEL_PWM;
    logic        PSEL_DHT11;
    logic        PSEL_HC_SR04;
    logic        PENABLE;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA_RAM;
    logic [31:0] PRDATA_GPO;
    logic [31:0] PRDATA_GPI;
    logic [31:0] PRDATA_GPIO;
    logic [31:0] PRDATA_FND;
    logic [31:0] PRDATA_UART;
    logic [31:0] PRDATA_PWM;
    logic [31:0] PRDATA_DHT11;
    logic [31:0] PRDATA_HC_SR04;
    logic        PREADY_RAM;
    logic        PREADY_GPO;
    logic        PREADY_GPI;
    logic        PREADY_GPIO;
    logic        PREADY_FND;
    logic        PREADY_UART;
    logic        PREADY_PWM;
    logic        PREADY_DHT11;
    logic        PREADY_HC_SR04;
 
    button_detector U_DEBOUNCE(
    .clk(clk), .reset(reset), .button(uart_transmit_button),
    .rising_edge(w_uart_transmit_button), .falling_edge(), .both_edge()
    );


    ROM U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    RV32I_Core U_RV32I (
        .clk(clk),
        .reset(reset),
        .instrCode(instrCode),
        .instrMemAddr(instrMemAddr),
        .dWe(dWe),
        .dAddr(dAddr),
        .wData(wData),
        .rData(rData),
        .apb_req(apb_req),
        .apb_ready(apb_ready)
    );

    APB_Master_Interface U_APB_Master_Interface (
        .PCLK(clk),
        .PRESET(reset),
        // APB Interface Signals // SLAVE
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PSEL_RAM(PSEL_RAM),
        .PSEL_GPO(PSEL_GPO),
        .PSEL_GPI(PSEL_GPI),
        .PSEL_GPIO(PSEL_GPIO),
        .PSEL_FND(PSEL_FND),
        .PSEL_UART(PSEL_UART),
        .PSEL_PWM(PSEL_PWM),
        .PSEL_DHT11(PSEL_DHT11),
        .PSEL_HC_SR04(PSEL_HC_SR04),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PRDATA_RAM(PRDATA_RAM),
        .PRDATA_GPO(PRDATA_GPO),
        .PRDATA_GPI(PRDATA_GPI),
        .PRDATA_GPIO(PRDATA_GPIO),
        .PRDATA_FND(PRDATA_FND),
        .PRDATA_UART(PRDATA_UART),
        .PRDATA_PWM(PRDATA_PWM),
        .PRDATA_DHT11(PRDATA_DHT11),
        .PRDATA_HC_SR04(PRDATA_HC_SR04),
        .PREADY_RAM(PREADY_RAM),
        .PREADY_GPO(PREADY_GPO),
        .PREADY_GPI(PREADY_GPI),
        .PREADY_GPIO(PREADY_GPIO),
        .PREADY_FND(PREADY_FND),
        .PREADY_UART(PREADY_UART),
        .PREADY_PWM(PREADY_PWM),
        .PREADY_DHT11(PREADY_DHT11),
        .PREADY_HC_SR04(PREADY_HC_SR04),
        // Internal Interface Signals // CPU
        .write(dWe),
        .addr(dAddr),
        .wdata(wData),
        .rdata(rData),
        .req(apb_req),
        .ready(apb_ready)
    );


    periph_ram U_RAM (
        .PCLK(clk),
        .PRESET(reset),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PSEL(PSEL_RAM),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA_RAM),
        .PREADY(PREADY_RAM)
    );

    periph_gpo U_GPOA (
        .*,
        .PCLK(clk),
        .PRESET(reset),
        .PSEL   (PSEL_GPO),
        .PRDATA (PRDATA_GPO),
        .PREADY (PREADY_GPO),
        .outport(GPOA)
    );

    periph_gpi U_GPIB(
        .*,
        .PCLK(clk),
        .PRESET(reset), 
        .PSEL(PSEL_GPI),
        .PRDATA(PRDATA_GPI),
        .PREADY(PREADY_GPI),
        .inport(GPIB)
    );

    periph_gpio U_GPIOC(
        .*,
        .PCLK(clk),
        .PRESET(reset),
        .PSEL(PSEL_GPIO),
        .PRDATA(PRDATA_GPIO),
        .PREADY(PREADY_GPIO),
        .io_data(GPIOC)
    );

    periph_fnd U_FND(
        .*,
        .PCLK(clk),
        .PRESET(reset),
        .PSEL(PSEL_FND),
        .PRDATA(PRDATA_FND),
        .PREADY(PREADY_FND),
        .fndFont(fndFont),
        .fndCom(fndCom)
    );

    periph_uart U_UART(
        .*,
        .PCLK(clk),    
        .PRESET(reset),
        .PSEL(PSEL_UART),
        .PRDATA(PRDATA_UART),
        .PREADY(PREADY_UART),
        .start_button(w_uart_transmit_button),
        .rx(rx),
        .tx(tx)
    );
    
    periph_pwm U_PWM(
        .*,
        .PCLK(clk),
        .PRESET(reset),
        .PSEL(PSEL_PWM),
        .PRDATA(PRDATA_PWM),
        .PREADY(PREADY_PWM),
        .pwm_clk(pwm_clk)
    );

    periph_dht11 U_DHT11(
    .*,
    .PCLK(clk),
    .PRESET(reset),
    .PSEL(PSEL_DHT11),
    .PRDATA(PRDATA_DHT11),
    .PREADY(PREADY_DHT11),
    .data_io(dht_11_inout)
    );

    periph_hc_sr04 U_HC_SR04(
    .*,
    .PCLK(clk),     // APB CLK
    .PRESET(reset),   // APB asynchronous RESET
    .PSEL(PSEL_HC_SR04),
    .PRDATA(PRDATA_HC_SR04),
    .PREADY(PREADY_HC_SR04),
    .echo(echo),
    .trigger(trigger)
    );
    
endmodule






