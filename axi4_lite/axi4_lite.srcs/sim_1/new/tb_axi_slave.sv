`timescale 1ns / 1ps



module tb_axi_slave ();

    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line
    localparam C_S_AXI_DATA_WIDTH = 32;
    localparam C_S_AXI_ADDR_WIDTH = 4;
    // Global Clock Signal
    logic S_AXI_ACLK;
    // Global Reset Signal. This Signal is Active LOW
    logic S_AXI_ARESETN;
    // Write address (issued by master, acceped by Slave)
    logic [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR;
    // Write channel Protection type. This signal indicates the
    // privilege and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    logic [2 : 0] S_AXI_AWPROT;
    // Write address valid. This signal indicates that the master signaling
    // valid write address and control information.
    logic S_AXI_AWVALID;
    // Write address ready. This signal indicates that the slave is ready
    // to accept an address and associated control signals.
    logic S_AXI_AWREADY;
    // Write data (issued by master, acceped by Slave) 
    logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA;
    // Write strobes. This signal indicates which byte lanes hold
    // valid data. There is one write strobe bit for each eight
    // bits of the write data bus.    
    logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB;
    // Write valid. This signal indicates that valid write
    // data and strobes are available.
    logic S_AXI_WVALID;
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    logic S_AXI_WREADY;
    // Write response. This signal indicates the status
    // of the write transaction.
    logic [1 : 0] S_AXI_BRESP;
    // Write response valid. This signal indicates that the channel
    // is signaling a valid write response.
    logic S_AXI_BVALID;
    // Response ready. This signal indicates that the master
    // can accept a write response.
    logic S_AXI_BREADY;
    // Read address (issued by master, acceped by Slave)
    logic [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR;
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether the
    // transaction is a data access or an instruction access.
    logic [2 : 0] S_AXI_ARPROT;
    // Read address valid. This signal indicates that the channel
    // is signaling valid read address and control information.
    logic S_AXI_ARVALID;
    // Read address ready. This signal indicates that the slave is
    // ready to accept an address and associated control signals.
    logic S_AXI_ARREADY;
    // Read data (issued by slave)
    logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA;
    // Read response. This signal indicates the status of the
    // read transfer.
    logic [1 : 0] S_AXI_RRESP;
    // Read valid. This signal indicates that the channel is
    // signaling the required read data.
    logic S_AXI_RVALID;
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
    logic S_AXI_RREADY;



    myip2_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) dut (
        .*
    );

    always #5 S_AXI_ACLK = ~S_AXI_ACLK;

    task axi_write(logic [31:0] addr, logic [31:0] data);
        @(posedge S_AXI_ACLK);
        S_AXI_AWADDR  <= addr;
        S_AXI_AWVALID <= 1'b1;
        S_AXI_WDATA   <= data;
        S_AXI_WVALID  <= 1'b1;
        S_AXI_WSTRB   <= 4'b1111;
        S_AXI_BREADY  <= 1'b1;

        wait (S_AXI_AWREADY & S_AXI_WREADY);
        @(posedge S_AXI_ACLK);
        S_AXI_AWVALID <= 1'b0;
        S_AXI_WVALID  <= 1'b0;

        wait (S_AXI_BVALID);
        @(posedge S_AXI_ACLK);
        S_AXI_BREADY <= 1'b0;
        $display("[%t] WRITE : Addr=0x%0h, Data = 0x%0h", $time, addr, data);


    endtask  //

    task axi_read(logic [31:0] addr);
        @(posedge S_AXI_ACLK);
        S_AXI_ARADDR  <= addr;
        S_AXI_ARVALID <= 1'b1;
        S_AXI_RREADY  <= 1'b1;

        wait (S_AXI_ARREADY);
        @(posedge S_AXI_ACLK);
        S_AXI_ARVALID <= 1'b0;

        wait (S_AXI_RVALID);
        @(posedge S_AXI_ACLK);
        S_AXI_RREADY <= 1'b0;
        $display("[%t] READ : Addr=0x%0h, Data = 0x%0h", $time, addr,
                 S_AXI_RDATA);

    endtask  //



    initial begin
        S_AXI_ACLK    = 0;
        S_AXI_ARESETN = 0;
        S_AXI_AWADDR  = 0;
        S_AXI_ARPROT  = 0;
        S_AXI_AWVALID = 0;
        S_AXI_WDATA   = 0;
        S_AXI_WSTRB   = 0;
        S_AXI_WVALID  = 0;
        S_AXI_BREADY  = 0;
        S_AXI_ARADDR  = 0;
        S_AXI_AWPROT  = 0;
        S_AXI_ARVALID = 0;
        S_AXI_RREADY  = 0;

        repeat (3) @(posedge S_AXI_ACLK);
        S_AXI_ARESETN = 1;
        repeat (3) @(posedge S_AXI_ACLK);
        axi_write(4'h0, 32'hDEADBEEF);
        axi_write(4'h4, 32'hCAFEBABE);
        axi_write(4'h8, 32'h12345678);
        axi_write(4'hc, 32'hAAAABBBB);

        repeat (3) @(posedge S_AXI_ACLK);
        axi_read(4'h0);
        axi_read(4'h4);
        axi_read(4'h8);
        axi_read(4'hc);
        repeat (3) @(posedge S_AXI_ACLK);
        $finish;
    end

endmodule
