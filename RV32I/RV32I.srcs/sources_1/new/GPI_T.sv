`timescale 1ns / 1ps



module GPI_T(
    input  logic PCLK,
    input  logic PRESET,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic PWRITE,
    input  logic PENABLE,
    input  logic PSEL,
    output  logic [31:0] PRDATA,
    output logic  PREADY,
    input logic [15:0] GPI_IN
   
    );


    localparam [11:0] GPI_CTL_ADDR = 12'h000;
    localparam [11:0] GPI_IDATA_ADDR = 12'h004;

    logic [15:0] GPI_IDATA_REG;
    logic [15:0] GPI_CTL_REG;

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    assign PRDATA = (PADDR[11:0] == GPI_CTL_ADDR) ? {16'h0000,GPI_CTL_REG} : 
                    (PADDR[11:0] == GPI_IDATA_ADDR) ? {16'h0000,GPI_IDATA_REG}:32'hxxxx_xxxx;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
           // GPI_IDATA_REG <= 16'h0000;
            GPI_CTL_REG <= 16'h0000;
        end else begin
            if (PREADY & PWRITE) begin
                case (PADDR[11:0])        
                    GPI_CTL_ADDR   :GPI_CTL_REG    <= PWDATA[15:0];
                    //GPI_IDATA_ADDR :GPI_IDATA_REG  <= PWDATA[15:0];
                
                endcase
            end
        end
    end

    genvar i;
    
    generate
    for (i = 0; i< 16; i++) begin 
    // assign GPO_OUT[i] = (GPO_CTL_REG[i]) ? GPO_ODATA_REG[i] : 1'bz;
        assign GPI_IDATA_REG[i] = (GPI_CTL_REG[i]) ? GPI_IN[i] : 1'bz;
      
    end
    
    endgenerate


endmodule
