`timescale 1ns / 1ps



module axi4_lite_slave_hw(

    input  logic        ACLK,
    input  logic        ARESETn,
    //AW
    input logic [31:0] AWADDR,
    input logic        AWVALID,
    output  logic        AWREADY,
    //W
    input logic [31:0] WDATA,
    input logic        WVALID,
    output  logic        WREADY,
    //B
    output  logic        BRESP,
    output  logic        BVALID,
    input logic        BREADY,
    //AR
    input logic [31:0] ARADDR,
    input logic        ARVALID,
    output  logic        ARREADY,
    //R
    output  logic [31:0] RDATA,
    output  logic        RVALID,
    input logic        RREADY,
    output  logic [ 1:0] RRESP
 
    );

    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

        //////////////AW TR
    typedef enum bit {
        AW_IDLE,
        AW_READY
    } aw_state_e;

    aw_state_e aw_state, aw_state_next;
    logic [3:0] aw_addr_reg, aw_addr_next;

    always_ff @( posedge ACLK ) begin 
        if (!ARESETn) begin
            aw_state <= AW_IDLE;
            aw_addr_reg <= 0;
        end else begin
            aw_state <= aw_state_next;
            aw_addr_reg <= aw_addr_next;
        end
    end

    always_comb begin 
        aw_state_next = aw_state;
        aw_addr_next = aw_addr_reg;
        AWREADY = 1'b0;
        case (aw_state)
            AW_IDLE: begin
                AWREADY = 1'b0;
                if (AWVALID) begin
                    aw_state_next = AW_READY;
                    aw_addr_next = AWADDR;
                end
            end 
            AW_READY:begin
                AWREADY = 1'b1;
                if (WVALID) aw_state_next = AW_IDLE;
            end
        endcase
        
    end


        ///////W tr
    typedef enum  bit{
        W_IDLE,
        W_READY
    } w_state_e;
  

    w_state_e w_state, w_state_next;

    always_ff @( posedge ACLK ) begin 
        if (!ARESETn) begin
            w_state <= W_IDLE;

        end else begin
            w_state <= w_state_next;
        end
    end

    always_comb begin 
        w_state_next = w_state;
        
        WREADY = 1'b0;
        case (w_state)
            W_IDLE: begin
                WREADY = 1'b0;
                if (AWVALID) begin
                    w_state_next = W_READY;
                end
            end
            W_READY : begin
                w_state_next = W_IDLE;
                WREADY = 1'b1;
                case (aw_addr_reg[3:2])
                    2'b00: slv_reg1 = WDATA; 
                    2'b01: slv_reg0 = WDATA; 
                    2'b10: slv_reg2 = WDATA; 
                    2'b11: slv_reg3 = WDATA; 
                endcase
            end 
        endcase
    end



    ////B Channel transfer

     typedef enum  {
        B_IDLE,
        B_VALID
    } b_state_e;
  

    b_state_e b_state, b_state_next;

    always_ff @( posedge ACLK ) begin 
        if (!ARESETn) begin
            b_state <= B_IDLE;

        end else begin
            b_state <= b_state_next;
        end
    end

    always_comb begin 
        b_state_next = b_state;
        BRESP = 2'b00;
        BVALID = 1'b0;
        
        case (b_state)
            B_IDLE: begin
                BVALID = 1'b0;
                if (WVALID && WREADY) begin
                    b_state_next = B_VALID;
                end
            end
            B_VALID : begin
                BRESP = 2'b00;
                BVALID = 1'b1;
                if (BVALID) begin
                    b_state_next = B_IDLE;
                   
                end
            end 
           
        endcase
        
    end


    /********************************************** READ TRANSACTION ********************************************/


    // AR
    typedef enum  {
        AR_IDLE,
        AR_READY
    } ar_state_e;
  

    ar_state_e ar_state, ar_state_next;
    logic [3:0] ar_addr_reg, ar_addr_next;

    always_ff @( posedge ACLK ) begin 
        if (!ARESETn) begin
            ar_state <= AR_IDLE;
            ar_addr_reg <= 0;

        end else begin
            ar_state <= ar_state_next;
            ar_addr_reg <= ar_addr_next;
        end
    end

    always_comb begin 
        ar_state_next = ar_state;
        ar_addr_next = ar_addr_reg;
        ARREADY = 1'b0;
        case (ar_state)
            AR_IDLE: begin
                ARREADY = 1'b0;
                if (ARVALID ) begin
                    ar_addr_next = ARADDR;
                    ar_state_next = AR_READY;
                end
            end
            AR_READY : begin
                
                ARREADY = 1'b1;
                    ar_state_next = AR_IDLE;
            end 
        endcase
        
    end



///R chanell

    typedef enum  {
        R_IDLE,
        R_VALID
    } r_state_e;
  

    r_state_e r_state, r_state_next;

    always_ff @( posedge ACLK ) begin 
        if (!ARESETn) begin
            r_state <= R_IDLE;

        end else begin
            r_state <= r_state_next;
        end
    end

    always_comb begin 
        RRESP = 2'b00;
        RVALID = 1'b0;
        case (r_state)
            R_IDLE: begin
                RVALID = 1'b0;
                RRESP = 2'b00;
                if (ARVALID && ARREADY) begin
                    r_state_next = R_VALID;
                end
            end
            R_VALID : begin
                if (RREADY) begin
                    r_state_next = R_IDLE;
                    RVALID = 1'b1;
                    RRESP = 2'b00;
                    case (ar_addr_reg[3:2])
                        2'd0: RDATA = slv_reg0; 
                        2'd1: RDATA = slv_reg1; 
                        2'd2: RDATA = slv_reg2; 
                        2'd3: RDATA = slv_reg3; 
                    endcase
                end
            end 
           
        endcase
        
    end



endmodule
