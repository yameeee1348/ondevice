//`timescale 1ns / 1ps
//
//
//
//module tb_axi4_lite ();
//
//    logic        ACLK;
//    logic        ARESETn;
//    logic [31:0] AWADDR;
//    logic        AWVALID;
//    logic        AWREADY;
//    logic [31:0] WDATA;
//    logic        WVALID;
//    logic        WREADY;
//    logic        BRESP;
//    logic        BVALID;
//    logic        BREADY;
//    logic [31:0] ARADDR;
//    logic        ARVALID;
//    logic        ARREADY;
//    logic [31:0] RDATA;
//    logic        RVALID;
//    logic        RREADY;
//    logic [ 1:0] RRESP;
//    logic        transfer;
//    logic        ready;
//    logic [31:0] addr;
//    logic [31:0] wdata;
//    logic        write;
//    logic [31:0] rdata;
//
//    //SLAVE AXI-LITE Simulator
//    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;  
//
//
//    axi4_lite_master dut (.*);
//
//
//    always #5 ACLK = ~ACLK;
//    bit [31:0] slave_addr;
//    bit slv_addr_flag;
//
//    task automatic axi_slave_write_aw();
//        // AW channel
//        forever begin
//            @(posedge ACLK);
//            
//            if (AWVALID & !AWREADY) begin
//                slave_addr = AWADDR;
//                AWREADY = 1'b1;
//                slv_addr_flag = 1;
//            end else if (AWVALID & !AWREADY) begin
//                AWREADY = 1'b0;
//            end else begin
//                AWREADY = 1'b0;
//                slv_addr_flag = 0;
//            end
//        end
//    endtask //automatic
//
//    task automatic axi_slave_write_w();
//        // W channel
//        forever begin
//            @(posedge ACLK);
//            
//        if (WVALID & !WREADY) begin
//                wait(slv_addr_flag);
//                case (slave_addr[3:2])
//                    2'h0: slv_reg0 = WDATA;
//                    2'h1: slv_reg1 = WDATA;
//                    2'h2: slv_reg2 = WDATA;
//                    2'h3: slv_reg3 = WDATA; 
//                endcase
//                    WREADY = 1'b1;
//                    $display("[%0t]  SLAVE WRITE ADDR @%0h, WDATA = %0h", $time, addr, WDATA);
//                end else if (WVALID & !WREADY)begin
//                    WREADY = 1'b0;
//                end else begin
//                    WREADY = 1'b0;
//                end
//        end
//    endtask //automatic
//    
//
//    task automatic axi_slave_write_b();
//        // B channel
//        forever begin
//            @(posedge ACLK);
//        if (WVALID) begin
//            
//                    BRESP = 2'b00;
//                    BVALID = 1'b1;
//                    $display("[%0t]  SLAVE WRITE BRESP @%0h, WDATA = %0h", $time, addr, BRESP);
//                end else if (BVALID & BREADY) begin
//                    BVALID = 1'b0;
//                end else begin
//                    BVALID = 1'b0;
//                end
//        end
//    endtask //automatic
//
//    task automatic axi_slave_read_ar();
//        // A channel
//        forever begin
//            @(posedge ACLK);
//            
//            if (ARVALID & !ARREADY) begin
//                slave_addr = ARADDR;
//                ARREADY = 1'b1;
//                slv_addr_flag = 1;
//                $display("[%0t] SLAVE READ ADDR = %0h", $time, slave_addr);
//
//            end else if (ARVALID & ARREADY) begin
//                ARREADY = 1'b0;
//                slv_addr_flag = 1;
//            end else begin
//                ARREADY = 1'b0;
//                slv_addr_flag = 0;
//            end
//        end
//    endtask //automatic
//
//
//     task automatic axi_slave_read_r();
//        // R channel
//        forever begin
//            @(posedge ACLK);
//            
//        if (!RVALID & ARVALID) begin
//                wait(slv_addr_flag);
//                case (slave_addr[3:2])
//                    2'h0: RDATA = slv_reg0;
//                    2'h1: RDATA = slv_reg1;
//                    2'h2: RDATA = slv_reg2;
//                    2'h3: RDATA = slv_reg3; 
//                endcase
//                    RVALID = 1'b1;
//                    RRESP = 2'b00;
//                    $display("[%0t]  SLAVE READ ADDR @%0h, RDATA = %0h", $time, addr, RDATA);
//                end else if (RVALID & RREADY)begin
//                    RVALID = 1'b0;
//                end else begin
//                    RVALID = 1'b0;
//                    RRESP = 2'b00;
//                end
//        end
//    endtask //automatic
//
//
//    task automatic axi_write(logic [31:0] address, logic [31:0] data);
//        addr     <= address;
//        wdata    <= data;
//        write    <= 1'b1;
//        transfer <= 1'b1;
//        @(posedge ACLK);
//        transfer <= 1'b0;
//        do @(posedge ACLK); while (!ready);
//        $display("[%0t]  cpu WRITE ADDR @%0h, WDATA = %0h", $time, addr, wdata);
//    endtask  //automatic
//
//
//    task automatic axi_read(logic [31:0] address);
//        addr <= address;
//        write <= 1'b0;
//        transfer <= 1'b1;
//        @(posedge ACLK);
//        transfer <= 1'b0;
//        do @(posedge ACLK); while (!ready);
//          $display("[%0t] cpu  READ ADDR @%0h, RDATA = %0h", $time, addr, rdata);
//    endtask  //automatic
//
//
//    initial begin
//        
//         ACLK    = 0;
//        ARESETn = 0;
//        repeat (3) @(posedge ACLK);
//        ARESETn = 1;
//        repeat (3) @(posedge ACLK);
//
//        fork
//            axi_slave_write_aw();
//            axi_slave_write_w();
//            axi_slave_write_b();
//            axi_slave_read_ar();
//            axi_slave_read_r();
//        join_none
//
//        repeat (3) @(posedge ACLK);
//
//        axi_write(32'h00000000, 32'h11111111);
//        repeat (3) @(posedge ACLK);
//        axi_write(32'h00000004, 32'h22222222);
//        repeat (3) @(posedge ACLK);
//        axi_write(32'h00000008, 32'h33333333);
//        repeat (3) @(posedge ACLK);
//        axi_write(32'h0000000c, 32'h44444444);
//
//@(posedge ACLK);
//
//        axi_read(32'h00000000);
//        repeat (3) @(posedge ACLK);
//        axi_read(32'h00000004);
//        repeat (3) @(posedge ACLK);
//        axi_read(32'h00000008);
//        repeat (3) @(posedge ACLK);
//        axi_read(32'h0000000c);
//
//        repeat(10) @(posedge ACLK);
//        $finish;
//    end
//
//
//
//endmodule




`timescale 1ns / 1ps

module tb_axi4_lite ();

    // 1. 전역 신호 및 CPU 인터페이스 신호
    logic        ACLK;
    logic        ARESETn;
    logic        transfer;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic        write;
    logic [31:0] rdata;
    logic        ready;

    // 2. 통합 Top 모듈 인스턴스화 (Master + Slave)
    axi4_lite_top dut (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),
        .transfer(transfer),
        .addr    (addr),
        .wdata   (wdata),
        .write   (write),
        .rdata   (rdata),
        .ready   (ready)
    );

    // 3. 클럭 생성
    initial ACLK = 0;
    always #5 ACLK = ~ACLK;

    // 4. CPU 쓰기 명령 태스크
    task automatic axi_write(logic [31:0] address, logic [31:0] data);
        @(posedge ACLK);
        addr     <= address;
        wdata    <= data;
        write    <= 1'b1;
        transfer <= 1'b1;
        
        @(posedge ACLK);
        transfer <= 1'b0; // 한 클럭만 transfer 발생
        
        // 마스터-슬레이브 통신이 끝나서 ready가 올 때까지 대기
        wait(ready);
        @(posedge ACLK);
        $display("[%0t] [CPU WRITE] ADDR: 0x%0h, DATA: 0x%0h", $time, address, data);
    endtask

    // 5. CPU 읽기 명령 태스크
    task automatic axi_read(logic [31:0] address);
        @(posedge ACLK);
        addr     <= address;
        write    <= 1'b0;
        transfer <= 1'b1;
        
        @(posedge ACLK);
        transfer <= 1'b0;
        
        wait(ready);
        @(posedge ACLK);
        $display("[%0t] [CPU READ ] ADDR: 0x%0h, DATA: 0x%0h", $time, address, rdata);
    endtask

    // 6. 메인 테스트 시나리오
    initial begin
        // 초기화
        ARESETn = 0;
        transfer = 0;
        write = 0;
        addr = 0;
        wdata = 0;

        repeat (5) @(posedge ACLK);
        ARESETn = 1;
        repeat (5) @(posedge ACLK);

        // --- 쓰기 테스트 ---
        $display("--- Starting Write Transactions ---");
        axi_write(32'h00000000, 32'h11111111);
        axi_write(32'h00000004, 32'h22222222);
        axi_write(32'h00000008, 32'h33333333);
        axi_write(32'h0000000c, 32'h44444444);

        repeat (5) @(posedge ACLK);

        // --- 읽기 테스트 ---
        $display("--- Starting Read Transactions ---");
        axi_read(32'h00000000);
        axi_read(32'h00000004);
        axi_read(32'h00000008);
        axi_read(32'h0000000c);

        repeat (10) @(posedge ACLK);
        $display("--- Test Completed ---");
        $finish;
    end

endmodule