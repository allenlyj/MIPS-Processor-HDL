#include "mips.h"
#include <stdio.h>

void write_instr (unsigned instr, FILE* code)
{
	char inst[33];
	unsigned int i, remain;
	remain = instr;
	for(i = 0; i<32; i++)
	{
		if (remain%2==1)
			inst[31-i] = '1';
		else
			inst[31-i] = '0';
		remain = remain>>1;
	}
	inst[32]=0;
	fputs(inst,code);
	fputs(",\n",code);
	printf("%s\n",inst);
}

// Three registers instructions
void special_instr(int op, int rs, int rt, int rd, int shamt, int funct, FILE* code)
{
	unsigned instruction = (op<<OPCODE_SHIFT)|(rs<<RS_SHIFT)| \
		    		  (rt<<RT_SHIFT)|(rd<<RD_SHIFT)| \
					  (shamt<<SHAMT_SHIFT)|funct;
	write_instr(instruction,code);
}

// Immediate instructions
void immediate_instr(int op, int rs, int rt, int imm, FILE* code)
{
	unsigned instruction = (op<<OPCODE_SHIFT)|(rs<<RS_SHIFT)| \
					  (rt<<RT_SHIFT)|(imm&IMM_MASK);
	write_instr(instruction,code);
}

// Jump instructions
void jump_instr(int op, int address, FILE* code)
{
	unsigned instruction = (op<<OPCODE_SHIFT)|(address&ADDR_MASK);
	write_instr(instruction,code);
}
