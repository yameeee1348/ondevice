`timescale 1ns / 1ps



module RV32I_TOP (
    input         clk,
    input         rst,
    input [7:0] GPI,
    output[7:0] GPO,
    inout [15:0] GPIO,
    output [7:0] fnd_data,
    output [3:0] fnd_digit,
    input rx,
    output tx
);

    logic [31:0] instr_addr, instr_data;
    logic dwe, dre;
    logic [2:0] o_funct3;
    logic [31:0] bus_addr, bus_wdata, bus_rdata, ready;
    logic bus_wreq, bus_rreq, bus_ready;

    logic [31:0] PADDR, PWDATA;
    logic PENABLE, PWRITE;

    logic PSEL0, PSEL1, PSEL2, PSEL3, PSEL4, PSEL5;
    logic [31:0] PRDATA0, PRDATA1, PRDATA2, PRDATA3, PRDATA4, PRDATA5;
    logic PREADY0, PREADY1, PREADY2, PREADY3, PREADY4, PREADY5;

   

    instruction_memory U_INSTRUCTION_MEM (.*);


    RV32_CPU U_RV32I (
        .*,
        .o_funct3(o_funct3)


    );


    APB_master U_APB_MASTER_INTERFACE (

        //Soc internal sig
        .PCLK(clk),
        .PRESET(rst),
        .i_funct3(o_funct3),
        .Addr(bus_addr),
        .Wdata(bus_wdata),
        .Wreq(bus_wreq),  //dwe
        .Rreq(bus_rreq),  //dre
        .Rdata(bus_rdata),
        .Ready(bus_ready),

        //to APB SLAVE
        .PADDR  (PADDR),
        .PWDATA (PWDATA),
        .PENABLE(PENABLE),
        .PWRITE (PWRITE),
        //from slave
        .PSEL0  (PSEL0),    //RAM
        .PSEL1  (PSEL1),    //GPO
        .PSEL2  (PSEL2),    //GPI
        .PSEL3  (PSEL3),    //GPIO
        .PSEL4  (PSEL4),    //FND
        .PSEL5  (PSEL5),    //UART

        .PRDATA0(PRDATA0),  //RAM
        .PRDATA1(PRDATA1),  //GPO
        .PRDATA2(PRDATA2),  //GPI
        .PRDATA3(PRDATA3),  //GPIO
        .PRDATA4(PRDATA4),  //FND
        .PRDATA5(PRDATA5),  //UART

        .PREADY0(PREADY0),  //RAM
        .PREADY1(PREADY1),  //GPO
        .PREADY2(PREADY2),  //GPI
        .PREADY3(PREADY3),  //GPIO
        .PREADY4(PREADY4),  //FND
        .PREADY5(PREADY5)   //UART



    );

    BRAM U_BRAM (
        .*,
        .PCLK  (clk),
        .PSEL  (PSEL0),    //RAM
        .PRDATA(PRDATA0),  //RAM
        .PREADY(PREADY0)   //RAM

    );

    GPI_T U_APB_GPI(

    .PCLK(clk),
    .PRESET(rst),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PSEL(PSEL2),
    .PRDATA(PRDATA2),
    .PREADY(PREADY2),
    .GPI_IN(GPI)
   
    );

    APB_GPO U_APB_GPO (
        .PCLK(clk),
        .PRESET(rst),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSEL(PSEL1),
        .PREADY(PREADY1),
        .PRDATA(PRDATA1),
        .GPO_OUT(GPO)

    );

    APB_GPIO U_APB_GPIO(
    .PCLK(clk),
    .PRESET(rst),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PSEL(PSEL3),
    .PRDATA(PRDATA3),
    .PREADY(PREADY3),
    .GPIO(GPIO)
);

    //     GPO_t U_GPO(
    //    .*,
    //    .PCLK(clk),
    //    .PRESET(rst),
    //    .PSEL(PSEL1),
    //    .PREADY(PREADY1)



    //    );

FND_T U_APB_FND(
    .PCLK(clk),
    .PRESET(rst),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PSEL(PSEL4),
    .PRDATA(PRDATA4),
    .PREADY(PREADY4),
    .fnd_digit(fnd_digit),
    .fnd_data(fnd_data)

);

UART_T U_APB_UART(
    .PCLK(clk),
    .PRESET(rst),
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PSEL(PSEL5),
    .PENABLE(PENABLE),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA5),
    .PREADY(PREADY5),
    .uart_rx(rx),
    .uart_tx(tx)
   

);

endmodule
