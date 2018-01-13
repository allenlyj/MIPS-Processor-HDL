#include <stdio.h>
#include "mips.h"

#define fir_size 32
#define coe_head 0
#define input_head 256
#define output_head_f 384
#define output_head_u 512
#define num_op 8

// Registers description
// R1(R17) Input traverser
// R2(R18) Input storage
// R3(R19) Coe traverser
// R4(R20) Coe storage (product storage)
// R5(R21) Sum storage
// R6(R22) Result traverser
// R7 Inner counter
// R8 Op counter


int main()
{
	FILE* mips_app;
	fopen_s(&mips_app,"FIR32_fused_normal.coe","w");
	fputs(ROM_HEAD,mips_app);
	
	__LUI(2,32);
	__ADDI(0,1,0);
	__ADDI(0,3,0);
	__ADDI(1,1,1);
	__BEQ(1,2,1);
	__J(3);
	__ADDI(0,1,0);
	__ADDI(3,3,1);
	__PROBE(3);
	__SLTI(3,4,256);
	__BEQ(0,4,1);
	__J(3);
	__ADDI(1,1,1);
	__BEQ(1,2,1);
	__J(12);
	__ADDI(0,1,0);
	__ADDI(3,3,-1);
	__PROBE(3);
	__BEQ(0,3,-16);
	__J(12);

	
	fclose(mips_app);
}

		