`timescale 1ns / 1ps
`include "defines.sv"

module RV32I_Core (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    output logic        dWe,
    output logic [31:0] dAddr,
    output logic [31:0] wData,
    input  logic [31:0] rData,
    output logic        apb_req,
    input  logic        apb_ready
);

    logic       regFileWe;
    logic [3:0] aluControl;
    logic       aluSrcMuxSel;
    logic [2:0] RFWDSrcMuxSel;
    logic branch, jal, jalr;
    logic PCEn;

    ControlUnit U_ControlUnit (.*);
    DataPath U_DataPath (.*);
endmodule

module ControlUnit (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic        PCEn,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        dWe,
    output logic [ 2:0] RFWDSrcMuxSel,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    input  logic        apb_ready,
    output logic        apb_req
);
    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] func3 = instrCode[14:12];
    wire [6:0] func7 = instrCode[31:25];
    logic [10:0] controls;

    typedef enum {
        FETCH,
        DECODE,
        R_EXE,
        I_EXE,
        L_EXE,
        L_MEM,
        L_WB,
        S_EXE,
        S_MEM,
        B_EXE,
        LU_EXE,
        AU_EXE,
        J_EXE,
        JL_EXE
    } state_e;

    state_e state, state_next;

    assign {PCEn, regFileWe, aluSrcMuxSel, dWe, RFWDSrcMuxSel, branch,jal,jalr, apb_req} = controls;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) state <= FETCH;
        else state <= state_next;
    end

    always_comb begin
        state_next = state;
        case (state)
            FETCH:  state_next = DECODE;
            DECODE: begin
                case (opcode)
                    `OP_TYPE_R:  state_next = R_EXE;
                    `OP_TYPE_L:  state_next = L_EXE;
                    `OP_TYPE_I:  state_next = I_EXE;
                    `OP_TYPE_S:  state_next = S_EXE;
                    `OP_TYPE_B:  state_next = B_EXE;
                    `OP_TYPE_LU: state_next = LU_EXE;
                    `OP_TYPE_AU: state_next = AU_EXE;
                    `OP_TYPE_J:  state_next = J_EXE;
                    `OP_TYPE_JL: state_next = JL_EXE;
                endcase
            end
            R_EXE:  state_next = FETCH;
            L_EXE:  state_next = L_MEM;
            L_MEM:  if (apb_ready == 1'b1) state_next = L_WB;
            L_WB:   state_next = FETCH;
            I_EXE:  state_next = FETCH;
            S_EXE:  state_next = S_MEM;
            S_MEM:  if (apb_ready == 1'b1) state_next = FETCH;
            B_EXE:  state_next = FETCH;
            LU_EXE: state_next = FETCH;
            AU_EXE: state_next = FETCH;
            J_EXE:  state_next = FETCH;
            JL_EXE: state_next = FETCH;
        endcase
    end

    always_comb begin
        controls   = 11'b0_0_0_0_000_0_0_0_0;
        aluControl = `ADD;
        case (state)
            // {PCEn,regFileWe,aluSrcMuxSel,dWe,RFWDSrcMuxSel3,branch,jal,jalr, apb_req}
            FETCH:  controls = 11'b1_0_0_0_000_0_0_0_0;
            DECODE: controls = 11'b0_0_0_0_000_0_0_0_0;
            R_EXE: begin
                controls   = 11'b0_1_0_0_000_0_0_0_0;
                aluControl = {func7[5], func3};
            end
            L_EXE:  controls = 11'b0_0_1_0_000_0_0_0_0;
            L_MEM:  controls = 11'b0_0_1_0_000_0_0_0_1;
            L_WB:   controls = 11'b0_1_1_0_001_0_0_0_0;
            I_EXE: begin
                controls = 11'b0_1_1_0_000_0_0_0_0;
                if ({func7[5], func3} == 4'b1101) aluControl = {1'b1, func3};
                else aluControl = {1'b0, func3};
            end
            S_EXE:  controls = 11'b0_0_1_0_000_0_0_0_0;
            S_MEM:  controls = 11'b0_0_1_1_000_0_0_0_1;
            B_EXE: begin
                controls   = 11'b0_0_0_0_000_1_0_0_0;
                aluControl = {1'b0, func3};
            end
            LU_EXE: controls = 11'b0_1_0_0_010_0_0_0_0;
            AU_EXE: controls = 11'b0_1_0_0_011_0_0_0_0;
            J_EXE:  controls = 11'b0_1_0_0_100_0_1_0_0;
            JL_EXE: controls = 11'b0_1_0_0_100_0_1_1_0;
        endcase
    end

    /*
    always_comb begin
        controls = 4'bx;
        case (opcode)
            // {regFileWe,aluSrcMuxSel,dWe,RFWDSrcMuxSel3,branch,jal,jalr}
            `OP_TYPE_R:  controls = 9'b1_0_0_000_0_0_0;
            `OP_TYPE_L:  controls = 9'b1_1_0_001_0_0_0;
            `OP_TYPE_I:  controls = 9'b1_1_0_000_0_0_0;
            `OP_TYPE_S:  controls = 9'b0_1_1_000_0_0_0;
            `OP_TYPE_B:  controls = 9'b0_0_0_000_1_0_0;
            `OP_TYPE_LU: controls = 9'b1_0_0_010_0_0_0;
            `OP_TYPE_AU: controls = 9'b1_0_0_011_0_0_0;
            `OP_TYPE_J:  controls = 9'b1_0_0_100_0_1_0;
            `OP_TYPE_JL: controls = 9'b1_0_0_100_0_1_1;
            default:     controls = 5'bx;
        endcase
    end

    always_comb begin
        case (opcode)
            `OP_TYPE_R: aluControl = {func7[5], func3};
            `OP_TYPE_I: begin
                if ({func7[5], func3} == 4'b1101) aluControl = {1'b1, func3};
                else aluControl = {1'b0, func3};
            end
            `OP_TYPE_B: aluControl = {1'b0, func3};
            default:    aluControl = `ADD;
        endcase
    end
    */
endmodule

module DataPath (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    input  logic        PCEn,
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl,
    input  logic        aluSrcMuxSel,
    input  logic [ 2:0] RFWDSrcMuxSel,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    output logic [31:0] dAddr,
    output logic [31:0] wData,
    input  logic [31:0] rData
);

    logic [31:0] PC_Data, RegFileData1, RegFileData2, aluResult;
    logic [31:0] immOut, aluSrcMuxOut, RFWDSrcMuxOut;
    logic [31:0] branchMuxOut, adder4Out, adderImmOut, jalrMuxOut;
    logic branchMuxSel, btaken;
    logic [31:0] DecReg_immOut;
    logic [31:0] DecReg_RegFileData1, DecReg_RegFileData2;
    logic [31:0] ExeReg_aluResult, ExeReg_RegFileData2;
    logic [31:0] ExeReg_branchMuxOut;
    logic [31:0] MemReg_rData;

    assign dAddr = ExeReg_aluResult;
    assign wData = ExeReg_RegFileData2;
    assign branchMuxSel = jal | (btaken & branch);


    register U_ExeReg_WData (
        .clk  (clk),
        .reset(reset),
        .d    (DecReg_RegFileData2),
        .q    (ExeReg_RegFileData2)
    );

    mux_2x1 U_JalrMux (
        .sel(jalr),
        .x0 (instrMemAddr),
        .x1 (RegFileData1),
        .y  (jalrMuxOut)
    );

    adder U_Adder_PC_Imm (
        .a(DecReg_immOut),
        .b(jalrMuxOut),
        .y(adderImmOut)
    );

    adder U_Adder_PC4 (
        .a(instrMemAddr),
        .b(32'd4),
        .y(adder4Out)
    );

    mux_2x1 U_BranchMux (
        .sel(branchMuxSel),
        .x0 (adder4Out),
        .x1 (adderImmOut),
        .y  (branchMuxOut)
    );

    register U_ExeReg_BranchMux (
        .clk  (clk),
        .reset(reset),
        .d    (branchMuxOut),
        .q    (ExeReg_branchMuxOut)
    );

    register_en U_PC (
        .clk  (clk),
        .reset(reset),
        .en   (PCEn),
        .d    (ExeReg_branchMuxOut),
        .q    (instrMemAddr)
    );


    RegisterFile U_RegFile (
        .clk(clk),
        .we(regFileWe),
        .RAddr1(instrCode[19:15]),
        .RAddr2(instrCode[24:20]),
        .WAddr(instrCode[11:7]),
        .WData(RFWDSrcMuxOut),
        .RData1(RegFileData1),
        .RData2(RegFileData2)
    );


    register U_DecReg_RF1 (
        .clk  (clk),
        .reset(reset),
        .d    (RegFileData1),
        .q    (DecReg_RegFileData1)
    );

    register U_DecReg_RF2 (
        .clk  (clk),
        .reset(reset),
        .d    (RegFileData2),
        .q    (DecReg_RegFileData2)
    );

    mux_2x1 U_AluSrcMux (
        .sel(aluSrcMuxSel),
        .x0 (DecReg_RegFileData2),
        .x1 (DecReg_immOut),
        .y  (aluSrcMuxOut)
    );

    alu U_ALU (
        .aluControl(aluControl),
        .a(DecReg_RegFileData1),
        .b(aluSrcMuxOut),
        .btaken(btaken),
        .result(aluResult)
    );

    register U_ExeReg_ALU (
        .clk  (clk),
        .reset(reset),
        .d    (aluResult),
        .q    (ExeReg_aluResult)
    );

    register U_MemReg_rData (
        .clk  (clk),
        .reset(reset),
        .d    (rData),
        .q    (MemReg_rData)
    );

    mux_5x1 U_RFWDSrcMux (
        .sel(RFWDSrcMuxSel),
        .x0 (aluResult),
        .x1 (MemReg_rData),
        .x2 (DecReg_immOut),
        .x3 (adderImmOut),
        .x4 (adder4Out),
        .y  (RFWDSrcMuxOut)
    );


    extend U_Extend (
        .instrCode(instrCode),
        .immExt(immOut)
    );

    register U_DecReg_Ext (
        .clk  (clk),
        .reset(reset),
        .d    (immOut),
        .q    (DecReg_immOut)
    );

endmodule


module alu (
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic        btaken,
    output logic [31:0] result
);
    always_comb begin
        case (aluControl)
            `ADD:    result = a + b;
            `SUB:    result = a - b;
            `SLL:    result = a << b;
            `SRL:    result = a >> b;
            `SRA:    result = $signed(a) >>> b[4:0];
            `SLT:    result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLTU:   result = (a < b) ? 1 : 0;
            `XOR:    result = a ^ b;
            `OR:     result = a | b;
            `AND:    result = a & b;
            default: result = 32'bx;
        endcase
    end

    always_comb begin
        case (aluControl[2:0])
            `BEQ: btaken = (a == b);
            `BNE: btaken = (a != b);
            `BLT: btaken = ($signed(a) < $signed(b));
            `BGE: btaken = ($signed(a) >= $signed(b));
            `BLTU: btaken = (a < b);
            `BGEU: btaken = (a >= b);
            default btaken = 1'b0;
        endcase
    end
endmodule

module register_en (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) q <= 0;
        else if (en) q <= d;
    end
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) q <= 0;
        else q <= d;
    end
endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RAddr1,
    input  logic [ 4:0] RAddr2,
    input  logic [ 4:0] WAddr,
    input  logic [31:0] WData,
    output logic [31:0] RData1,
    output logic [31:0] RData2
);
    logic [31:0] RegFile[0:2**5-1];

    // initial begin  // for test
    //     for (int i = 0; i < 32; i++) begin
    //         RegFile[i] = i;
    //     end
    // end

    always_ff @(posedge clk) begin
        if (we) RegFile[WAddr] <= WData;
    end

    assign RData1 = (RAddr1 != 0) ? RegFile[RAddr1] : 0;
    assign RData2 = (RAddr2 != 0) ? RegFile[RAddr2] : 0;
endmodule

module extend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] func3 = instrCode[14:12];
    wire [6:0] func7 = instrCode[31:25];

    always_comb begin
        case (opcode)
            `OP_TYPE_R: immExt = 32'bx;
            `OP_TYPE_L: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_I: begin
                case ({
                    func7[5], func3
                })
                    4'b0001: immExt = {27'b0, instrCode[24:20]};
                    4'b0101: immExt = {27'b0, instrCode[24:20]};
                    4'b1101: immExt = {27'b0, instrCode[24:20]};
                    default: begin
                        if (func3 == 3'b011) immExt = {20'b0, instrCode[31:20]};
                        else immExt = {{20{instrCode[31]}}, instrCode[31:20]};
                    end
                endcase
            end
            `OP_TYPE_S:
            immExt = {{20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]};
            `OP_TYPE_B:
            immExt = {
                {20{instrCode[31]}},
                instrCode[7],
                instrCode[30:25],
                instrCode[11:8],
                1'b0
            };
            `OP_TYPE_LU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_AU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_J:
            immExt = {
                {12{instrCode[31]}},
                instrCode[19:12],
                instrCode[20],
                instrCode[30:21],
                1'b0
            };
            `OP_TYPE_JL: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            default: immExt = 32'bx;
        endcase
    end
endmodule

module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);
    always_comb begin
        case (sel)
            1'b0:    y = x0;
            1'b1:    y = x1;
            default: y = 32'bx;
        endcase
    end
endmodule

module mux_5x1 (
    input  logic [ 2:0] sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    input  logic [31:0] x2,
    input  logic [31:0] x3,
    input  logic [31:0] x4,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (sel)
            3'd0:    y = x0;
            3'd1:    y = x1;
            3'd2:    y = x2;
            3'd3:    y = x3;
            3'd4:    y = x4;
            default: y = 32'bx;
        endcase
    end
endmodule
