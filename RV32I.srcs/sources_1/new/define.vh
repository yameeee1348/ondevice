
`define simulation 1



//op code
`define R_type 7'b0110011
`define S_type 7'b0100011
`define I_type 7'b0010011
`define IL_type 7'b0000011
`define B_type 7'b1100011
`define LUI_type 7'b0110111
`define AUIPC_type 7'b0010111
`define JAL_type 7'b1101111
`define JALR_type 7'b1100111

//R-type instruction
// `define ADD 4'b0000
// `define SUB 4'b1000
// `define SLL 4'b0001// SLL
// `define SLT 4'b0010  // SLT
// `define SLTU 4'b0011 //: 32'b0;  // SLTU
// `define XOR 4'b0100
// `define SRL 4'b0101// SRL
// `define SRA 4'b1101  // SRA
// `define OR 4'b0110            
// `define AND 4'b0111


// `define BEQ 4'b0000
// `define BNE 4'b1001
// `define BLT 4'b1100
// `define BGE 4'b1101
// `define BLTU 4'b1110
// `define BGEU 4'b1111


`define ADD    4'b0000
`define SUB    4'b1000
`define SLL    4'b0001
`define SRL    4'b0101
`define SRA    4'b1101
`define SLT    4'b0010
`define SLTU   4'b0011
`define XOR    4'b0100
`define OR     4'b0110
`define AND    4'b0111
`define LUI    4'b1111
`define AUIPC  4'b0000
`define JUMP   4'b1110


`define BEQ   3'b000
`define BNE   3'b001
`define BLT   3'b100
`define BGE   3'b101
`define BLTU  3'b110
`define BGEU  3'b111
//--------------------R_type & I_type----------------------------
// //funct3
// `define FNC3_ADD_SUB 3'h0 
// `define FNC3_SLL 3'h1 
// `define FNC3_SLT 3'h2 
// `define FNC3_SLTU 3'h3 
// `define FNC3_XOR 3'h4 
// `define FNC3_SRL_SRA 3'h5 
// `define FNC3_OR 3'h6 
// `define FNC3_AND 3'h7

// //funct7
// `define FNC7_0 7'b0
// `define FNC7_SUB 7'b010_0000 
// `define FNC7_SRA 7'b010_0000

// //--------------------S_type----------------------------
// `define FNC3_SB 3'b0
// `define FNC3_SH 3'h1
// `define FNC3_SW 3'h2

// //--------------------IL_type----------------------------
// `define FNC3_LB 3'h0
// `define FNC3_LH 3'h1
// `define FNC3_LW 3'h2
// `define FNC3_LBU 3'h3
// `define FNC3_LHU 3'h4
