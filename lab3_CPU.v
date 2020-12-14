`timescale 1ns / 1ps

// Program Counter Register ////////////////////////////////////////////////////
module PC_reg
(
    input clk, 
    input reset,
    input start,
    input [31:0] NPC,
    output reg [31:0] PC
);

    always @ (posedge clk) begin
        if (reset) begin
            PC <= 32'h00000064;
        end else begin
            PC <= NPC;
        end
    end 
endmodule

// Program Counter Adder ///////////////////////////////////////////////////////
module PC_Add4
(
    input [31:0] PC_IN,
    output [31:0] PC_OUT
);
    assign PC_OUT = PC_IN + 32'h00000004;
endmodule

//Instruction Memory Fetch /////////////////////////////////////////////////////
module IM
(
    input [31:0] ADDR,
    input reset,
    output [31:0] INSTR
);
    reg [31:0] MEMORY [511:0];
    
    always @(posedge reset) // Reset Initializes 10 Preset Memory Values
    begin
        MEMORY[100] <= 32'b000000_00001_00010_00011_00000_100000; //add $3, $1, $2
        MEMORY[104] <= 32'b000000_01001_00011_00100_00000_100010; //sub $4, $9, $3
        MEMORY[108] <= 32'b000000_00011_01001_00101_00000_100101; //or $5, $3, $9
        MEMORY[112] <= 32'b000000_00011_01001_00110_00000_100110; //xor $6, $3, $9
        MEMORY[116] <= 32'b000000_00011_01001_00111_00000_100100; //and $7, $3, $9
    end
    assign INSTR = MEMORY[ADDR];
endmodule

// IF/ID Register //////////////////////////////////////////////////////////////
module IF_ID_Reg
(
    input [31:0] INSTR_IN,
    input reset,
    input clk,
    output reg [5:0] OPCODE_OUT,
    output reg [4:0] RS_OUT,
    output reg [4:0] RT_OUT,
    output reg [4:0] RD_OUT,
    output reg [4:0] SHAMT_OUT,
    output reg [5:0] FUNC_OUT,
    output reg [15:0] IMM_OUT
);
    always @(posedge clk) begin
        if (reset) begin
            OPCODE_OUT <= 0;
            RS_OUT <= 0;
            RT_OUT <= 0;
            RD_OUT <= 0;
            SHAMT_OUT <= 0;
            FUNC_OUT <= 0;
            IMM_OUT <= 0;
        end else begin
            OPCODE_OUT <= INSTR_IN[31:26];
            RS_OUT <= INSTR_IN[25:21];
            RT_OUT <= INSTR_IN[20:16];
            RD_OUT <= INSTR_IN[15:11];
            SHAMT_OUT <= INSTR_IN[10:6];
            FUNC_OUT <= INSTR_IN[5:0];
            IMM_OUT <= INSTR_IN[15:0];
        end
    end    
endmodule

// Sign/Bit Extender ///////////////////////////////////////////////////////////
module SignExt
(
input [15:0] Immediate,
output [31:0] SignExt_IMM
);
assign SignExt_IMM = {{16{Immediate[15]}},Immediate[15:0]};
endmodule

// Control Unit ////////////////////////////////////////////////////////////////
module Control_Unit
(
input clk,
input reset,
//
input [4:0] rs, //Added for Final
input [4:0] rt,
input [4:0] mrn,
input mm2reg,
input mwreg,
input [4:0] ern,
input em2reg,
input ewreg,
output reg [1:0] fwda,
output reg [1:0] fwdb,
//
input [5:0] opcode,
input [5:0] funct,
output reg RegDst_OUT, //Goes to Selector of RD/RT Mux
output reg WriteReg_OUT, //wreg
output reg Mem2Reg_OUT, //m2reg
output reg WriteMem_OUT, //wmem
output reg [3:0] ALU_Ctrl_OUT, //aluc 4bit control signal
output reg [1:0] ALU_Op_OUT, //aluop
output reg ALU_Src //aluimm selector bit
);

reg [3:0] Ctrl_Output [63:0]; //R-Type Function Memory
always @ (posedge reset) begin //Pre-Load Function -> ALU Control
    Ctrl_Output[0] <= 4'b1010; //sll
    Ctrl_Output[2] <= 4'b1100; //srl
    Ctrl_Output[3] <= 4'b1011; //sra
    Ctrl_Output[8] <= 4'bxxxx; //jr
    Ctrl_Output[32] <= 4'b0010; //add
    Ctrl_Output[34] <= 4'b0110; //sub
    Ctrl_Output[36] <= 4'b0000; //and
    Ctrl_Output[37] <= 4'b0001; //or
    Ctrl_Output[38] <= 4'b1001; //xor
end

reg [3:0] Ctrl_Output_I [15:0]; //I-Type Function Memory
always @ (posedge reset) begin //Pre-Load ALU Function -> ALU Control
    Ctrl_Output_I[8] <= 4'b0010; //addi
    Ctrl_Output_I[12] <= 4'b0000; //andi
    Ctrl_Output_I[13] <= 4'b0001; //ori
    Ctrl_Output_I[14] <= 4'b1001; //xori
    Ctrl_Output_I[15] <= 4'b0010; //lui
end

always @ (negedge clk) begin
    if (opcode == 6'b100011) begin //Checking for lw
        ALU_Op_OUT <= 00; //Not needed at present...
        ALU_Ctrl_OUT <= 0010; //Set to 'Add'
        ALU_Src <= 1; 
        RegDst_OUT <= 1; 
        WriteReg_OUT <= 1;
        Mem2Reg_OUT <= 1;
        WriteMem_OUT <= 0;
    end else if (opcode == 6'b101011) begin //Checking for sw
        ALU_Op_OUT <= 00;
        ALU_Ctrl_OUT <= 0010;
        ALU_Src <= 1;
        RegDst_OUT <= 0; //Don't Care...
        WriteReg_OUT <= 0;
        Mem2Reg_OUT <= 0; //Don't Care... May need changed later.
        WriteMem_OUT <= 1;
    end else if (opcode == 6'b000100 | opcode == 6'b000101) begin //Checking for branch conditions
        ALU_Op_OUT <= 01;
        ALU_Ctrl_OUT <= 0110; //Set to 'Subtract'
        ALU_Src <= 0;
        RegDst_OUT <= 0; //Don't Care...
        WriteReg_OUT <= 0;
        Mem2Reg_OUT <= 0; //Don't Care...
        WriteMem_OUT <= 0; 
    end else if (opcode == 6'b000000) begin //Checking for R-Type
        ALU_Op_OUT <= 10;
        ALU_Ctrl_OUT <= Ctrl_Output[funct]; //Setting ALU Control based upon Funct values
        ALU_Src <= 0;
        RegDst_OUT <= 0; //Set to rd
        WriteReg_OUT <= 1;
        Mem2Reg_OUT <= 0;
        WriteMem_OUT <= 0;
    end else if (opcode[5:3] == 3'b001) begin //Checking for I-Type (Not Including Branch)
        ALU_Op_OUT <= 00; //Not Needed at Present...
        ALU_Ctrl_OUT <= Ctrl_Output_I[opcode];
        ALU_Src <= 1; //Need Immediate for Operations
        RegDst_OUT <= 0; //Set to rd
        WriteReg_OUT <= 1;
        Mem2Reg_OUT <= 0;
        WriteMem_OUT <= 0;
    end else if (opcode == 6'b000010 | opcode == 6'b000011) begin //Checking for j or jal
        ALU_Op_OUT <= 01;
        ALU_Ctrl_OUT <= 0110; //Set to 'Subtract'
        ALU_Src <= 1;
        RegDst_OUT <= 0; //Don't Care...
        WriteReg_OUT <= 0;
        Mem2Reg_OUT <= 0; //Don't Care...
        WriteMem_OUT <= 0; 
    end
end

always @(negedge clk) begin
// data1 (A) input to ALU
		if ((ewreg == 1'b1) && (ern == rs)) begin //RegWrite Enabled for EXE stage, and Destination Reg is same as rs in ID stage.
			fwda <= 2'b01;  // stage 3 forwarding
		end else if ((mwreg == 1'b1) && (mrn == rs)) begin
			fwda <= 2'b10;  // stage 4 forwarding
	    end else if ((mm2reg == 1'b1) && (mrn == rs)) begin
	        fwda <= 2'b11;  // stage 4 (Data Mem Out) forwarding
		end else begin
			fwda <= 2'b00;  // no forwarding
        end

// data2 (B) input to ALU
		if ((ewreg == 1'b1) && (ern == rt)) begin
			fwdb <= 2'b01;  // stage 3 forwarding
		end else if ((mwreg == 1'b1) && (mrn == rt)) begin
			fwdb <= 2'b10;  // stage 4 forwarding
		end else if ((mm2reg == 1'b1) && (mrn == rt)) begin
		    fwdb <= 2'b11;  // stage 4 (Data Mem Out) forwarding
		end else begin
			fwdb <= 2'b00;  // no forwarding
        end
    end

endmodule

// RD_RT Multiplexer ///////////////////////////////////////////////////////////
module RD_RT_MUX
(
input [4:0] RD_A,
input [4:0] RT_B,
input select,
output [4:0] C
);
assign C = (select) ? RT_B : RD_A; //Format: C = selector bit "?" True Statement (if 1) ":" False Statement (if 0)
endmodule

// Register File //////////////////////////////////////////////////////////////
module RegisterFile
(
input reset,
input clk,
input [4:0] rs,
input [4:0] rt,
input [4:0] rd,
input [31:0] New_Data,
input Write_Enable,
output [31:0] qa,
output [31:0] qb
);

reg [31:0] Reg_File [31:0]; //32 by 32 bits
always @ (posedge reset) begin //Yes, using a For loop would have been better, but this allows for individual initial variable manipulation.
    Reg_File[0] <= 32'h0000_0000;
    Reg_File[1] <= 32'hA000_00AA;
    Reg_File[2] <= 32'h1000_0011;
    Reg_File[3] <= 32'h2000_0022;
    Reg_File[4] <= 32'h3000_0033;
    Reg_File[5] <= 32'h4000_0044;
    Reg_File[6] <= 32'h5000_0055;
    Reg_File[7] <= 32'h6000_0066;
    Reg_File[8] <= 32'h7000_0077;
    Reg_File[9] <= 32'h8000_0088;
    Reg_File[10] <= 32'h9000_0099;
    Reg_File[11] <= 0;
    Reg_File[12] <= 0;
    Reg_File[13] <= 0;
    Reg_File[14] <= 0;
    Reg_File[15] <= 0;
    Reg_File[16] <= 0;
    Reg_File[17] <= 0;
    Reg_File[18] <= 0;
    Reg_File[19] <= 0;
    Reg_File[20] <= 0;
    Reg_File[21] <= 0;
    Reg_File[22] <= 0;
    Reg_File[23] <= 0;
    Reg_File[24] <= 0;
    Reg_File[25] <= 0;
    Reg_File[26] <= 0;
    Reg_File[27] <= 0;
    Reg_File[28] <= 0;
    Reg_File[29] <= 0;
    Reg_File[30] <= 0;
    Reg_File[31] <= 0;
end

always @(negedge clk) begin //Using Negative to Pre-Load for next Positive clk edge
    if (Write_Enable)
        Reg_File[rd] = New_Data;
    end
assign qa = Reg_File[rs];
assign qb = Reg_File[rt];
endmodule

// ID/EXE Register ////////////////////////////////////////////////////////////
module ID_EXE_Reg
(
input clk,
input reset,
input wreg_IN,
output reg ewreg,
input m2reg_IN,
output reg em2reg,
input wmem_IN,
output reg ewmem,
input [3:0] aluc_IN,
output reg [3:0] ealuc,
input aluimm_IN,
output reg ealuimm,
input [4:0] RD_RT_SEL_IN,
output reg [4:0] RD_RT_SEL_OUT,
input [31:0] qa_IN,
output reg [31:0] qa_OUT,
input [31:0] qb_IN,
output reg [31:0] qb_OUT,
input [31:0] se_imm_IN,
output reg [31:0] se_imm_OUT
);
always @ (posedge reset) begin //(Re)set all output registers to 0.
    ewreg <= 0;
    em2reg <= 0;
    ewmem <= 0;
    ealuc <= 0;
    ealuimm <= 0;
    RD_RT_SEL_OUT <= 0;
    qa_OUT <= 0;
    qb_OUT <= 0;
    se_imm_OUT <= 0;     
end

always @ (posedge clk) begin //Set all Inputs to Outputs (Gate)
    ewreg <= wreg_IN;
    em2reg <= m2reg_IN;
    ewmem <= wmem_IN;
    ealuc <= aluc_IN;
    ealuimm <= aluimm_IN;
    RD_RT_SEL_OUT <= RD_RT_SEL_IN;
    qa_OUT <= qa_IN;
    qb_OUT <= qb_IN;
    se_imm_OUT <= se_imm_IN;
end
endmodule

// ALU MUX //////////////////////////////////////////////////////////////////////
module ALU_MUX
(
input [31:0] qb_in,
input [31:0] imm_in,
input selector,
output [31:0] B_out
);
assign B_out = (selector) ? imm_in : qb_in;
endmodule

// ALU //////////////////////////////////////////////////////////////////////////
module ALU
(
input clk,
input [3:0] ctrl,
input [31:0] A,
input [31:0] B,
output reg [31:0] result
);

always @ (negedge clk) begin
    if (ctrl == 4'b0000) begin // A AND B
    result <= A & B;
    end else if (ctrl == 4'b0001) begin // A OR B
    result <= A | B;
    end else if (ctrl == 4'b0010) begin // A + B
    result <= A + B;
    end else if (ctrl == 4'b0110) begin // A - B
    result <= A - B;
    end else if (ctrl == 4'b0111) begin // A < B
    result <= A < B;
    end else if (ctrl == 4'b1100) begin // A NOR B
    result <= ~(A | B);
    end else if (ctrl == 4'b1001) begin // A XOR B
    result <= A ^ B;
    end
end

endmodule

// EXE/MEM Register /////////////////////////////////////////////////////
module EXE_MEM_Reg
(
input clk,
input reset,
input ewreg,
output reg mwreg,
input em2reg,
output reg mm2reg,
input ewmem,
output reg mwmem,
input [4:0] RD_RT_SEL_IN_2,
output reg [4:0] RD_RT_SEL_OUT_2,
input [31:0] R,
output reg [31:0] R_OUT,
input [31:0] qb_IN,
output reg [31:0] qb_OUT
);
always @ (posedge reset) begin //(Re)set all output registers to 0.
    mwreg <= 0;
    mm2reg <= 0;
    mwmem <= 0;
    RD_RT_SEL_OUT_2 <= 0;
    R_OUT <= 0;
    qb_OUT <= 0; 
end

always @ (posedge clk) begin //Set all Inputs to Outputs (Gate)
    mwreg <= ewreg;
    mm2reg <= em2reg;
    mwmem <= ewmem;
    RD_RT_SEL_OUT_2 <= RD_RT_SEL_IN_2;
    R_OUT <= R;
    qb_OUT <= qb_IN;
end
endmodule

// Data Memory ////////////////////////////////////////////////////////////////
module DataMemory
(
input reset,
input clk,
input we,
input [31:0] a,
input [31:0] di,
output reg [31:0] do
);

reg [31:0] DATAMEM[0:255];
always @ (posedge reset) begin
//Given for Lab 4, preloading memory
        DATAMEM[0] <= 32'hA000_00AA;
        DATAMEM[1] <= 32'h1000_0011;
        DATAMEM[2] <= 32'h2000_0022;
        DATAMEM[3] <= 32'h3000_0033;
        DATAMEM[4] <= 32'h4000_0044;
        DATAMEM[5] <= 32'h5000_0055;
        DATAMEM[6] <= 32'h6000_0066;
        DATAMEM[7] <= 32'h7000_0077;
        DATAMEM[8] <= 32'h8000_0088;
        DATAMEM[9] <= 32'h9000_0099;
        DATAMEM[10] <= 0;
        DATAMEM[11] <= 0;
        DATAMEM[12] <= 0;
end

always @ (negedge clk) begin
    if (we == 1) begin
    DATAMEM[a] <= di; //Write Operation
    end else if (we == 0) begin
    do <= DATAMEM[a]; //Read Operation
    end
end

endmodule

// MEM/WB Register ///////////////////////////////////////////////////////////
module MEM_WB_Reg
(
input clk,
input reset,
input mwreg,
output reg wwreg,
input mm2reg,
output reg wm2reg,
input [4:0] rd_rt_sel_in,
output reg [4:0] rd_rt_sel_out,
input [31:0] alu_result,
output reg [31:0] alu_result_out,
input [31:0] do,
output reg [31:0] do_out
);

always @ (posedge reset) begin //(Re)set all output registers to 0.
    wwreg <= 0;
    wm2reg <= 0;
    rd_rt_sel_out <= 0;
    alu_result_out <= 0;
    do_out <= 0;
end

always @ (posedge clk) begin //Set all Inputs to Outputs (Gate)
    wwreg <= mwreg;
    wm2reg <= mm2reg;
    rd_rt_sel_out <= rd_rt_sel_in;
    alu_result_out <= alu_result;
    do_out <= do;
end

endmodule

// WB Mux /////////////////////////////////////////////////////////////////////////////////////
module WB_MUX
(
input [31:0] do,
input [31:0] alu_result,
input wm2reg,
output [31:0] d_sel
);
assign d_sel = (wm2reg) ? do : alu_result;
endmodule

// Forwarding Mux /////////////////////////////////////////////////////////////////////////////
module FWD_MUX
(
input [1:0] SEL,
input [31:0] a,
input [31:0] b,
input [31:0] c,
input [31:0] d,
output reg [31:0] out
);

always @ (a or b or c or d or SEL)
begin

case (SEL)
2'b00 : out <= a;
2'b01 : out <= b;
2'b10 : out <= c;
2'b11 : out <= d;
endcase

end

endmodule
