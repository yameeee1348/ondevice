`timescale 1ns / 1ps
`include "define.vh"


module rv32i_datapath (
    input         clk,
    input         rst,
    input         rf_we,
    input         alu_src,
    input  [ 3:0] alu_control,
    input  [31:0] instr_data,
    input  [31:0] drdata,
    input  [2:0]  rfwd_src,
    input         branch,
    input         jalr_sel,
    input         jal_sel,
    output [31:0] instr_addr,
    output [31:0] daddr,
    output [31:0] dwdata


);
    logic [31:0] rd1, rd2, alu_result, imm_data, alurs2_data;
    logic [31:0] rfwb_data;
    logic        btaken;
    logic [31:0] auipc_out;
    logic [31:0] pc_plus_4;
    logic [31:0] jal_out;
    assign daddr  = alu_result;
    assign dwdata = rd2;
  

    pc_counter U_PC (
        .clk(clk),
        .rst(rst),
        .btaken(btaken),
        .branch(branch),
        .jalr_sel(jalr_sel),
        .jal_sel(jal_sel),
        .rd1(rd1),
        .imm_data(imm_data),
        .program_counter(instr_addr),
        .auipc_out(auipc_out),
        .jal_out(jal_out)

    );

    register_file U_REG_FILE (
        .clk(clk),
        .rst(rst),
        .RA1(instr_data[19:15]),
        .RA2(instr_data[24:20]),
        .WA(instr_data[11:7]),
        .Wdata(rfwb_data),
        .rf_we(rf_we),
        .RD1(rd1),
        .RD2(rd2)
    );

    mux2x1 U_MUX_ALUSRC_RS2 (
        .in0(rd2),
        .in1(imm_data),
        .mux_sel(alu_src),
        .out_mux(alurs2_data)
    );
    imm_extender U_IMM_EXTENDER (
        .instr_data(instr_data),
        .imm_data  (imm_data)
    );

    alu U_ALU (
        .rd1(rd1),
        .rd2(alurs2_data),
        .alu_control(alu_control),
        .alu_result(alu_result),
        .btaken(btaken)
    );

    always_comb begin 
    
        case (rfwd_src)
            3'b000: rfwb_data = alu_result;
            3'b001: rfwb_data = drdata;//loaded_data;
            3'b010: rfwb_data = imm_data; //lui
            3'b011: rfwb_data = auipc_out;
            3'b100: rfwb_data = jal_out; //jal
             
            default: rfwb_data = 32'b0;
        endcase
    end


endmodule



module register_file (
    input         clk,
    input         rst,
    input  [ 4:0] RA1,
    input  [ 4:0] RA2,
    input  [ 4:0] WA,
    input  [31:0] Wdata,
    input         rf_we,
    output [31:0] RD1,
    output [31:0] RD2
);

    logic [31:0] register_file[1:31];

`ifdef simulation
    initial begin
        for (int i = 1; i < 32; i++) begin
            register_file[i] = i;
        end
    end
`endif

    // always_ff @(posedge clk) begin

    //     if (!rst & rf_we) begin
    //         register_file[WA] <= Wdata;
    //     end

    // end
    always_ff @(posedge clk) begin
        if (!rst && rf_we && (WA != 5'd0)) begin // x0(WA=0)일 때는 쓰기 금지
            register_file[WA] <= Wdata;
        end
    end


    assign RD1 = (RA1 != 0) ? register_file[RA1] : 0;
    assign RD2 = (RA2 != 0) ? register_file[RA2] : 0;




endmodule
module alu (
    input        [31:0] rd1,          // 이전 a
    input        [31:0] rd2,          // 이전 b
    input        [ 3:0] alu_control,  // 이전 alu_ctrl
    // input        [31:0] instr_addr,   // AUIPC용 PC값 (기존 데이터패스의 instr_addr)
    output logic [31:0] alu_result,   // 이전 result
    output logic        btaken         // 이전 branch_flag / btaken
);

    // 1. 산술/논리 연산 블록 (alu_result 결정)
    always_comb begin
        alu_result = 32'b0;
        case (alu_control)
            `ADD    : alu_result = rd1 + rd2;
            `SUB    : alu_result = rd1 - rd2;
            `SLL    : alu_result = rd1 << rd2[4:0];
            `SRL    : alu_result = rd1 >> rd2[4:0];
            `SRA    : alu_result = $signed(rd1) >>> rd2[4:0];
            `SLT    : alu_result = ($signed(rd1) < $signed(rd2)) ? 32'd1 : 32'd0;
            `SLTU   : alu_result = (rd1 < rd2) ? 32'd1 : 32'd0;
            `XOR    : alu_result = rd1 ^ rd2;
            `OR     : alu_result = rd1 | rd2;
            `AND    : alu_result = rd1 & rd2;
            `LUI    : alu_result = rd2;           // Immediate 통과            
            //`AUIPC  : alu_result = instr_addr + rd2; // PC + Imm
            default : alu_result = 32'b0;
        endcase
    end
    always_comb begin
        btaken = 1'b0; 
        
        //if (alu_control == `JUMP) begin // JAL, JALR 강제 점프 (4'b1110)
        //    btaken = 1'b1;
        //end 
        //else 
        if (alu_control[3]) begin // B-type (1xxx)
            case (alu_control[2:0])
                `BEQ  : btaken = (rd1 == rd2);
                `BNE  : btaken = (rd1 != rd2);
                `BLT  : btaken = ($signed(rd1) < $signed(rd2));
                `BGE  : btaken = ($signed(rd1) >= $signed(rd2));
                `BLTU : btaken = (rd1 < rd2);
                `BGEU : btaken = (rd1 >= rd2);
                default: btaken = 1'b0;
            endcase
        end
    end


endmodule



module pc_counter (
    input               clk,
    input               rst,
    input               btaken,
    input               branch,
    input               jalr_sel,
    input               jal_sel,
    input        [31:0] imm_data,
    input        [31:0] rd1,
    output logic [31:0] program_counter,
    output logic [31:0] auipc_out,
    output logic [31:0] jal_out
);
   logic [31:0] pc_4_out;
   logic [31:0] pc_imm_out;
   logic [31:0] pc_next;
   logic [31:0] pc_branch_target;
   logic [31:0] pc_last;


  
   assign pc_branch_target = jal_sel ? pc_4_out : pc_imm_out;
   assign auipc_out = pc_imm_out;
   assign jal_out = pc_4_out;
   wire pc_sel = (branch & btaken) | jal_sel;

mux2x1 U_JAL_MUX(
   .in0(pc_4_out),
   .in1(pc_imm_out),
   .mux_sel(pc_sel),
   .out_mux(pc_last)
);

   mux2x1 U_PC_MUX(
   .in0(program_counter),
   .in1(rd1),
   .mux_sel(jalr_sel),
   .out_mux(pc_next)
);

   pc_alu U_pc_IMM (
        .a(imm_data),
        .b(pc_next),
        .pc_alu_out(pc_imm_out)

    );

    pc_alu U_pc_ALU4 (
        .a(32'd4),
        .b(program_counter),
        .pc_alu_out(pc_4_out)

    );

   register U_REG (
       .clk(clk),
       .rst(rst),
       .data_in(pc_last),
       .data_out(program_counter)
   );
endmodule


// module pc_counter (
//      input               clk,
//      input               rst,
//      input               btaken,
//      input               branch,
//      input               jalr_sel,
//      input               jal_sel,
//      input        [31:0] imm_data,
//      input        [31:0] rd1,
//      output logic [31:0] program_counter,
//      output logic [31:0] auipc_out,
//      output logic [31:0] jal_out
//  );
//     logic [31:0] pc_4_out;
//     logic [31:0] pc_imm_out;
//     logic [31:0] pc_next;
//     logic [31:0] pc_last;

//     // 1. 점프 조건 통합 (JALR 추가!)
//     // btaken은 ALU에서 (JAL, 분기성공) 시 1로 올라옵니다. 
//     // JALR은 컨트롤 유닛에서 jalr_sel=1을 주므로 명시적으로 포함해야 합니다.
//     wire pc_sel = (branch & btaken) | jal_sel | jalr_sel;

//     // 2. Base 주소 선택: JALR만 rd1을 사용, 나머지는 PC 사용
//     mux2x1 U_PC_MUX(
//         .in0(program_counter),
//         .in1(rd1),
//         .mux_sel(jalr_sel),
//         .out_mux(pc_next)
//     );

//     // 3. Target 주소 계산 (Base + Offset)
//     logic [31:0] raw_imm_out;
//     pc_alu U_pc_IMM (
//          .a(imm_data),
//          .b(pc_next),
//          .pc_alu_out(raw_imm_out)
//      );
     
//     // JALR을 위한 LSB 마스킹 (RISC-V 스펙)
//     assign pc_imm_out = jalr_sel ? (raw_imm_out & 32'hFFFFFFFE) : raw_imm_out;

//     // 4. 순차 주소 계산 (PC + 4)
//     pc_alu U_pc_ALU4 (
//          .a(32'd4),
//          .b(program_counter),
//          .pc_alu_out(pc_4_out)
//      );

//     // 5. 다음 PC 결정 (점프 타겟 vs PC+4)
//     mux2x1 U_JAL_MUX(
//         .in0(pc_4_out),
//         .in1(pc_imm_out),
//         .mux_sel(pc_sel),
//         .out_mux(pc_last)
//     );

//     // 6. 특수 명령어용 출력 데이터 패스
//     assign auipc_out = pc_imm_out; // AUIPC는 jalr_sel=0이므로 PC+Imm 값이 나감
//     assign jal_out   = pc_4_out;   // JAL/JALR 리턴 주소는 무조건 PC+4

//     // 7. PC 레지스터 업데이트
//     register U_REG (
//         .clk(clk),
//         .rst(rst),
//         .data_in(pc_last),
//         .data_out(program_counter)
//     );
//  endmodule

module pc_alu (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] pc_alu_out

);
    assign pc_alu_out = a + b;
endmodule

module register (
    input clk,
    input rst,
    input [31:0] data_in,
    output [31:0] data_out
);
    logic [31:0] register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;

        end else begin
            register <= data_in;
        end

    end
    assign data_out = register;

endmodule


module mux2x1 (
    input        [31:0] in0,
    input        [31:0] in1,
    input               mux_sel,
    output logic [31:0] out_mux
);
    assign out_mux = {mux_sel} ? in1 : in0;
endmodule

module imm_extender (
    input [31:0] instr_data,
    output logic [31:0] imm_data

);

    always_comb begin
        imm_data = 32'd0;
        case (instr_data[6:0])
            `S_type: begin
                imm_data = {
                    {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]
                };
            end

            `I_type, `IL_type,`JALR_type: begin
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end
            `B_type: begin
                imm_data = {
                    {20{instr_data[31]}},
                    instr_data[7],
                    instr_data[30:25],
                    instr_data[11:8],
                    1'b0
                };
            end
            `LUI_type,`AUIPC_type: begin
                imm_data = {instr_data [31:12], 12'b0};
            end
            
            `JAL_type: begin
                imm_data = {{12{instr_data[31]}}, instr_data[19:12], instr_data[20],instr_data[30:21], 1'b0 };
            end

        endcase

    end
endmodule
