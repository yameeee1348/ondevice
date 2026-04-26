`timescale 1ns / 1ps



module tb_APB_master();

    logic         PCLK;
    logic         PRESETn;
    logic  [31:0] Addr;
    logic  [31:0] Wdata;
    logic         Wreq;
    logic         Rreq;
    
    logic [31:0] Rdata;
    logic        Ready;
    logic        PENABLE;
    logic        PWRITE;
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    
    // PSEL 및 응답 신호들
    logic  PSEL0; 
    logic [31:0] PRDATA0;
    logic        PREADY0;  
    
    logic PSEL1;
    logic PSEL2;
    logic PSEL3;
    logic PSEL4;
    logic PSEL5;
    
    logic  [31:0] PRDATA1;
    logic[31:0] PRDATA2;
    logic[31:0] PRDATA3;
    logic[31:0] PRDATA4;
    logic[31:0] PRDATA5;
    
    logic PREADY1;
    logic PREADY2;
    logic PREADY3;
    logic PREADY4;
    logic PREADY5;


APB_master dut(.*);

   
        
    always #5 PCLK = ~PCLK;
    


initial begin
    PCLK = 0;
    PRESETn =0;

    @(negedge PCLK);
    @(negedge PCLK);
    PRESETn =1;


    // RAM Write test
    @(posedge PCLK);
    #1;
    Addr = 32'h1000_0000;
    Wdata = 32'h0000_41;
    Wreq = 1'b1;

    // @(posedge PCLK);     
    // #1;
    @(PSEL0 && PENABLE);
        PREADY0 = 1'b1;
    @(posedge PCLK);
    #1;
    PREADY0 = 1'b0;
    Wreq = 1'b0;
    
    //UART Read test
    @(posedge PCLK);
    #1;
    Rreq = 1'b1;
    Addr = 32'h2000_4000;
    
    
    @(PSEL5 && PENABLE);
    @(posedge PCLK);
    @(posedge PCLK);
    #1;
        PREADY5 = 1'b1;
        PRDATA5 = 32'h0000_41;
    @(posedge PCLK);
    #1;
    PREADY5 = 1'b0;
    Rreq = 1'b0;
    @(posedge PCLK);
    @(posedge PCLK);
    
    
    $stop;

end

endmodule
