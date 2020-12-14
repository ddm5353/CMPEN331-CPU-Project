`timescale 1ns / 1ps

module lab3_CPU_testbench();
    reg clk; 
    reg start;
    reg reset;
    // Wiring for Program Counter:
    wire [31:0] PrgmCount; //Current Program Count
    wire [31:0] PC_NEXT; //Next Program Count
    // Wiring for IM:
    wire [31:0] INSTR; //Instruction
    // Wiring for IF/ID Register
    wire [5:0] OPCODE;
    wire [4:0] RS;
    wire [4:0] RT;
    wire [4:0] RD;
    wire [4:0] SHAMT;
    wire [5:0] FUNC;
    wire [15:0] IMM;
    // Wiring for Sign/Bit Extender
    wire [31:0] SE_IMM;
    // Wiring for Control Unit
    wire REGRT; //Selector bit for Mux
    wire WREG; //wreg
    wire M2REG; //m2reg
    wire WMEM; //wmem
    wire [3:0] ALU_CTRL; //aluc
    wire [1:0] ALU_OP; //ALU Op
    wire ALU_IMM;
    // Wiring for RD_RT Mux
    wire [4:0] C_SEL; //Output of Mux
    // Wiring for RegFile
    wire [31:0] QA;
    wire [31:0] QB;
    // Wiring for ID/EXE Register
    wire EWREG; //wreg out
    wire EM2REG; //m2reg out
    wire EWMEM; //wmem out
    wire [3:0] EALUC; //alu control out
    wire EALUIMM; //alu immediate selector
    wire [4:0] RD_RT_SEL; //selected target or dest.
    wire [31:0] QA_OUT; //reg qa
    wire [31:0] QB_OUT; //reg qb
    wire [31:0] SE_IMM_OUT; //Sign-Extended Immediate/Address
    // Wiring for ALU MUX and ALU
    wire [31:0] B_IN; //Selected data for B input to ALU
    wire [31:0] R; //ALU Output
    // Wiring for EXE/MEM Register ///////////////////////////////////////////////////
    wire MWREG; //Output of ewreg from reg
    wire MM2REG; //Output of em2reg from reg
    wire MWMEM; //Output of ewmem from reg
    wire [4:0] RD_RT_SEL_2; //Output of RD_RT_SEL from reg
    wire [31:0] ALU_RESULT; //R out from reg, Result of ALU
    wire [31:0] QB_Reg; //QB_Out from reg, from reg file
    // Wiring for Data Memory
    wire [31:0] DO; //Output from DataMemory
    // Wiring for MEM/WB Register ////////////////////////////////////////////////////
    wire WWREG; //Output of mwreg 
    wire WM2REG; //Output of mm2reg
    wire [4:0] RD_RT_SEL_3; //Output of selector bit
    wire [31:0] ALU_RESULT_2_MUX; //Output of alu result to mux
    wire [31:0] DO_OUT;
    // Wiring for WB Mux /////////////////////////////////////////////////////////////
    wire [31:0] D; //Output of WB Mux
    // Wiring for FWD Muxes //////////////////////////////////////////////////////////
    wire [1:0] FWDB; //Output of FWDB from CU
    wire [1:0] FWDA; //Output of FWDA from CU
    wire [31:0] FWDB_OUT; //Output of FWDB Mux
    wire [31:0] FWDA_OUT; //Output of FWDA Mux
    
// Call PC_Reg ///////////////////////////////////////////////////////////////////////
PC_reg PC_reg_uut
(
.clk(clk),
.reset(reset),
.PC(PrgmCount),
.NPC(PC_NEXT),
.start(start)
);

// Call Add 4 ////////////////////////////////////////////////////////////////////////
PC_Add4 PC_Add4_uut
(
.PC_IN(PrgmCount),
.PC_OUT(PC_NEXT)
);

// Call Instruction Memory ///////////////////////////////////////////////////////////
IM IM_uut
(
.ADDR(PrgmCount),
.reset(reset),
.INSTR(INSTR)
);

// Call IF/ID Register ///////////////////////////////////////////////////////////////
IF_ID_Reg IF_ID_uut
(
.clk(clk),
.reset(reset),
.INSTR_IN(INSTR),
.OPCODE_OUT(OPCODE),
.RS_OUT(RS),
.RT_OUT(RT),
.RD_OUT(RD),
.SHAMT_OUT(SHAMT),
.FUNC_OUT(FUNC),
.IMM_OUT(IMM)
);

// Call Sign Extender ////////////////////////////////////////////////////////////////
SignExt SignExt_uut
(
.Immediate(IMM),
.SignExt_IMM(SE_IMM)
);

// Call Control Unit /////////////////////////////////////////////////////////////////
Control_Unit CU_uut
(
.clk(clk),
.reset(reset),
//
.rs(RS), //Added for Final
.rt(RT),
.mrn(RD_RT_SEL_2),
.mm2reg(MM2REG),
.mwreg(MWREG),
.ern(RD_RT_SEL),
.em2reg(EM2REG),
.ewreg(EWREG),
.fwda(FWDA),
.fwdb(FWDB),
//
.opcode(OPCODE),
.funct(FUNC),
.RegDst_OUT(REGRT),
.WriteReg_OUT(WREG),
.Mem2Reg_OUT(M2REG),
.WriteMem_OUT(WMEM),
.ALU_Ctrl_OUT(ALU_CTRL),
.ALU_Op_OUT(ALU_OP),
.ALU_Src(ALU_IMM)
);

// Call RD_RT MUX ////////////////////////////////////////////////////////////////////
RD_RT_MUX RD_RT_MUX_uut
(
.RD_A(RD),
.RT_B(RT),
.select(REGRT),
.C(C_SEL)
);

// Call Register File ////////////////////////////////////////////////////////////////
RegisterFile RegFile_uut
(
.reset(reset),
.clk(clk),
.rs(RS),
.rt(RT),
.rd(RD_RT_SEL_3),
.New_Data(D),
.Write_Enable(WWREG),
.qa(QA),
.qb(QB)
);

// Call ID/EXE Register //////////////////////////////////////////////////////////////
ID_EXE_Reg ID_EXE_uut
(
.clk(clk),
.reset(reset),
.wreg_IN(WREG),
.ewreg(EWREG),
.m2reg_IN(M2REG),
.em2reg(EM2REG),
.wmem_IN(WMEM),
.ewmem(EWMEM),
.aluc_IN(ALU_CTRL),
.ealuc(EALUC),
.aluimm_IN(ALU_IMM),
.ealuimm(EALUIMM),
.RD_RT_SEL_IN(C_SEL),
.RD_RT_SEL_OUT(RD_RT_SEL),
.qa_IN(FWDA_OUT),
.qa_OUT(QA_OUT),
.qb_IN(FWDB_OUT),
.qb_OUT(QB_OUT),
.se_imm_IN(SE_IMM),
.se_imm_OUT(SE_IMM_OUT)
);

// Call ALU Multiplexer ///////////////////////////////////////////////////
ALU_MUX ALU_MUX_uut
(
.qb_in(QB_OUT),
.imm_in(SE_IMM_OUT),
.selector(EALUIMM),
.B_out(B_IN)
);

// Call ALU ////////////////////////////////////////////////////////////////
ALU ALU_uut
(
.clk(clk),
.ctrl(EALUC),
.A(QA_OUT),
.B(B_IN),
.result(R)
);

// Call EXE/MEM Register ////////////////////////////////////////////////////
EXE_MEM_Reg EXE_MEM_uut
(
.clk(clk),
.reset(reset),
.ewreg(EWREG), //Input
.mwreg(MWREG), //Output
.em2reg(EM2REG),
.mm2reg(MM2REG),
.ewmem(EWMEM),
.mwmem(MWMEM),
.RD_RT_SEL_IN_2(RD_RT_SEL),
.RD_RT_SEL_OUT_2(RD_RT_SEL_2),
.R(R),
.R_OUT(ALU_RESULT),
.qb_IN(QB_OUT),
.qb_OUT(QB_Reg)
);

// Call Data Memory //////////////////////////////////////////////////////////////////
DataMemory DataMemory_uut
(
.clk(clk),
.reset(reset),
.we(MWMEM),
.a(ALU_RESULT),
.di(QB_Reg),
.do(DO)
);

// Call MEM/WB Register //////////////////////////////////////////////////////////////
MEM_WB_Reg MEM_WB_uut
(
.clk(clk),
.reset(reset),
.mwreg(MWREG),
.wwreg(WWREG),
.mm2reg(MM2REG),
.wm2reg(WM2REG),
.rd_rt_sel_in(RD_RT_SEL_2),
.rd_rt_sel_out(RD_RT_SEL_3),
.alu_result(ALU_RESULT),
.alu_result_out(ALU_RESULT_2_MUX),
.do(DO),
.do_out(DO_OUT)
);

// Call WB Mux ///////////////////////////////////////////////////////////////////////
WB_MUX WB_MUX_uut
(
.do(DO_OUT),
.alu_result(ALU_RESULT_2_MUX),
.wm2reg(WM2REG),
.d_sel(D)
);

// Call FWDA Mux /////////////////////////////////////////////////////////////////////
FWD_MUX FWDA_Mux
(
.SEL(FWDA),     //Selector Bits
.a(QA),         //Opt 0
.b(R),          //Opt 1
.c(ALU_RESULT), //Opt 2
.d(DO),         //Opt 3
.out(FWDA_OUT)  //Out
);

// Call FWDB Mux /////////////////////////////////////////////////////////////////////
FWD_MUX FWDB_Mux
(
.SEL(FWDB),
.a(QB),
.b(R),
.c(ALU_RESULT),
.d(DO),
.out(FWDB_OUT)
);

// Set Initial Conditions ////////////////////////////////////////////////////////////
initial begin
    clk = 1;
    reset = 0;
    start = 0;
    #5 start = 1;
    reset = 1;
    #10 start = 0;
    reset = 0;
end

always #5 clk = ~clk;
endmodule