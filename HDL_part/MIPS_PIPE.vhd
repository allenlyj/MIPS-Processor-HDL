----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:02:19 10/27/2015 
-- Design Name: 
-- Module Name:    MIPS_PIPE - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

library work;
use work.MIPS_package.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MIPS_PIPE is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  pause : in std_logic;
			  probe : out STD_LOGIC_vector(7 downto 0));
end MIPS_PIPE;

architecture Behavioral of MIPS_PIPE is

-- Probe register
signal probe_internal: std_logic_vector(7 downto 0):= "00000000";

-- Global control
signal branch_taken: bus1; -- Fed from ALU stage
signal jump: bus1;         -- Fed from ID stage 
signal stall: bus1;			-- Fed from hazard detection

-- Signals within the IF stage
signal pc_current: bus32 := bus32(to_signed(-4,32));
signal pc_target: bus32;   	-- Fed from ALU stage
signal pc_jump: bus32;			-- Fed from ID stage 
signal pc_increment: bus32;	-- locally computed
signal instr_address: bus32;  -- input to instruction mem
signal instruction_out: bus32; -- output of instruction mem

-- Signal within the ID stage
-- come from previous stage ---------------------------------------------------------
signal instruction_in: bus32 := (others =>'0');  
signal pc_id: bus32 := (others => '0');  -- will be passed on 
-------------------------------------------------------------------------------------
-- locally generated ----------------------------------------------------------------
signal decode_address: bus7;
signal decoded_instr: micro_code;
signal opcode: bus6;
signal funct: bus6;
signal reg_s: bus5 := "00000";  -- initialized for simulation	
signal reg_t: bus5 := "00000";  -- initialized for simulation 
signal reg_d: bus5;
signal reg_dest_ID: bus5;  -- will be passed on 
signal imm: bus16;  
signal reg_out1: bus32;  -- might be selected to become reg_op1
signal reg_out2: bus32;  -- might be selected to become reg_op1
signal imm_ext: bus32;  -- will be passed on
signal reg_op1: bus32;  -- will be passed on
signal reg_op2: bus32;  -- will be passed on    
--------------------------------------------------------------------------------------

-- Decoded signal lookup:
---------------------------------------------------------------------------------------------------------------------------
--type micro_code is 
--	record
--	branch: bus1;  -- '1' If it's branch instruction                               -- will be passed on 
--	jump:   bus1;  -- '1' If it's jump instruction                                 -- consumed in this stage, to global control 
--	reg_op1: bus1; -- '1' If register1 needs to be readed                          -- consumed in this stage for hazard detection 
--	reg_op2: bus1; -- '1' If register2 needs to be readed                          -- consumed in this stage for hazard detection
--	imm_sign: bus1;  -- '1' If immediate operand is sign extended                  -- consumed in this stage for immediate prep
--	reg_dest_select: bus2; -- what type of destiny register, rt"00" or rd"01", or ra"11"  -- consume in this stage for register destiny prep
--	reg_write: bus1; -- '1' If the operation involves a register write             -- will be passed on 
--	R_or_I: bus1;   -- whether ALU operates on two regs '0' or reg and imm '1'     -- will be passed on 
--	mem_op: bus1;  -- '1' If the operation involves memory access                  -- will be passed on 
--	mem_write: bus1;  -- '1' If the memory operation is a write                    -- will be passed on 
--	ALU_op: bus4;  -- ALU control signal                                           -- will be passed on 
--	reg_result_select: bus2;  -- what to be written in to register.                -- will be passed on
--end record;	

-- Hazard unit signals
signal op1_dep_ALU: bus1; -- '1' if reg_op1 depend on ALU result
signal op1_dep_MEM: bus1; -- '1' if reg_op1 depend on MEM result
signal op2_dep_ALU: bus1; -- '1' if reg_op2 depend on ALU result
signal op2_dep_MEM: bus1; -- '1' if reg_op2 depend on MEM result
---------------------------------------------------------------------------------------------------------------------------

-- Signal within the ALU stage
-- come from previous stage ------------------------------------------------------------------
signal imm_ext_ALU: bus32 := (others =>'0');  -- consumed
signal reg_op1_ALU: bus32 := (others =>'0');  -- consumed
signal reg_op2_ALU: bus32 := (others =>'0');  -- consumed 
signal pc_ALU: bus32  := (others =>'0');      -- used but will be passed on
signal branch_ALU: bus1 := '0';               -- consumed
signal R_or_I_ALU: bus1 := '0';               -- consumed 
signal mem_op_ALU: bus1 := '0';               -- consumed
signal mem_write_ALU: bus1 := '0';            -- consumed 
signal ALU_op_ALU: bus4 := "0000";            -- consumed
signal reg_dest_ALU: bus5 := "00000";         -- bypassed
signal reg_write_ALU: bus1 := '0';            -- bypassed 
signal reg_result_select_ALU: bus2 := "00";   -- bypassed   
-----------------------------------------------------------------------------------------------
-- locally generated -----------------------------------------------------------------------------
signal ALU_in2: bus32;  -- ALU_in1 not needed since it's directly reg_op1_ALU
signal ALU_out: bus32;  -- connected to ALU ouput, will be passed on, also connected to hazard unit
signal ALU_zero: bus1;  -- connected to ALU zero flag
signal branch_offset: bus32;  -- rewire the imm to get the branch offset
signal mem_write: bus4;
---------------------------------------------------------------------------------------------------


-- Signal within the MEM stage
-- come from previous stage --------------------------------------------------------------------------
signal pc_MEM: bus32 := (others => '0');       -- might be written into reg 
signal ALU_out_MEM: bus32 := (others => '0');  -- might be written into reg 
signal reg_dest_MEM: bus5 := "00000";          -- connected to reg bank 
signal reg_write_MEM: bus1 := '0';             -- connected to reg bank
signal reg_result_select_MEM: bus2 := "00";    -- Used to select data to reg
-------------------------------------------------------------------------------------------------------
-- locally generated ----------------------------------------------------------------------------------
signal mem_data_out: bus32; -- data memory output, might be written into reg, also connected to hazard unit
signal data_to_reg: bus32;  -- the selected data to be written into register bank

begin

-- IF STAGE CODE ------------------------------------------------------------------------------------------------------------------------
-- IF stage behavior within clock cycle 
pc_increment <= bus32(unsigned(pc_current)+4);  --  pc increments in normal situation

-- Next pc select logic
pc_select:
process (branch_taken, jump, stall, pc_target, pc_jump, pc_increment)
begin
	if branch_taken = '1' then
		instr_address <= pc_target;
	elsif jump = '1' then
		instr_address <= pc_jump;
	elsif stall = '1' then  -- Very tricky here! see (1)
		instr_address <= pc_current;
	else
		instr_address <= pc_increment;
	end if;
end process;	

-- (1): When pipeline stalls, ID stage keeps its instruction and does not accept new one, which means the one read in the IF
-- (which has the address of pc_current in the stage) is wasted, and needs to be read again when the stall is cleared. 

-- The instruction memory
instr_mem : instruction_memory
  PORT MAP (
    clka => clock,
    addra => instr_address,
    douta => instruction_out
  );
  
-- IF stage behavior on clock edge
IF_clock:
process (clock)
begin
	if clock'event and clock = '1' then 
		if reset = '1' then                 -- Reset in the beginning, everything set to '0'
			pc_current <= bus32(to_signed(-4,32));
			instruction_in <= (others => '0');
			pc_id <= (others => '0');
		elsif branch_taken = '1' or jump = '1' then		   -- If branch taken, pc changes to target, decode stage flushed
			pc_current <= instr_address;
			instruction_in <= (others => '0');
			pc_id <= pc_increment;
		elsif stall = '1' then  				-- If stall due to hazard, pc doesn't increment, and instruction in decode stage stays
		else											-- Normal case
			pc_current <= instr_address;
			instruction_in <= instruction_out;
			pc_id <= pc_increment;
		end if;
	end if;
end process;
-- END OF IF STAGE -------------------------------------------------------------------------------------------------------------------------


-- ID STAGE CODE --------------------------------------------------------------------------------------------------------------------------
-- Fields assignment
opcode <= instruction_in (31 downto 26);
funct <= instruction_in (5 downto 0);
reg_s <= instruction_in (25 downto 21);
reg_t <= instruction_in (20 downto 16);
reg_d <= instruction_in (15 downto 11);
imm <= instruction_in (15 downto 0);
pc_jump <= "0000" & instruction_in(25 downto 0) & "00";

-- Register bank
Inst_register_bank: register_bank PORT MAP(
	read_address1 => reg_s,
	read_address2 => reg_t,
	write_address => reg_dest_MEM,  -- belongs to MEM stage 
	data_out1 => reg_out1,
	data_out2 => reg_out2,
	data_in => data_to_reg,       -- belongs to MEM stage 
	write_en => reg_write_MEM,      -- belongs to MEM stage 
	clock => clock
);

-- Instruction Decode
decode_address <= '1'&funct when opcode = "000000" else
						'0'&opcode;
						
decoded_instr <= my_mips_code(to_integer(unsigned(decode_address)));

-- Decide dependency
op1_dep_ALU <= '1' when (reg_s = reg_dest_ALU and reg_write_ALU = '1' and decoded_instr.reg_op1 = '1') else
					'0';
					
op1_dep_MEM <= '1' when (reg_s = reg_dest_MEM and reg_write_MEM = '1' and decoded_instr.reg_op1 = '1') else
					'0';
					
op2_dep_ALU <= '1' when (reg_t = reg_dest_ALU and reg_write_ALU = '1' and decoded_instr.reg_op2 = '1') else
					'0';
					
op2_dep_MEM <= '1' when (reg_t = reg_dest_MEM and reg_write_MEM = '1' and decoded_instr.reg_op2 = '1') else
					'0';

-- Stall decision
stall <= (mem_op_ALU and (op1_dep_ALU or op2_dep_ALU)) or pause; -- If any reg depend on an instr in ALU stage and that instr is load, stall

-- Operand bypass
reg_op1 <= ALU_out when op1_dep_ALU = '1' else  -- If dependent on both ALU and MEM, take the later one
			  data_to_reg when op1_dep_MEM = '1' else
			  reg_out1;
			  
reg_op2 <= ALU_out when op2_dep_ALU = '1' else
			  data_to_reg when op2_dep_MEM = '1' else
			  reg_out2;
			  
-- Immediate generation
imm_ext <= x"0000"&imm when decoded_instr.imm_sign = '0' or imm(15) = '0' else
			  x"FFFF"&imm;
			  
-- Destiny register selection
with decoded_instr.reg_dest_select select reg_dest_ID <=	reg_d when "01",
																			"11111" when "11",
																			reg_t when others;
																			
--*********************Special probe functionality***************------
process(clock)
begin
	if clock'event and clock = '1' then
		if decoded_instr.reg_dest_select = "10" then
			probe_internal <= reg_out1(7 downto 0);
		end if;
	end if;
end process;

probe <= probe_internal;

-- Jump control signal available in this stage 
jump <= decoded_instr.jump;

-- ID stage behavior on clock edge
ID_clock:
process (clock)
begin
	if clock'event and clock = '1' then
		if reset = '1' or branch_taken = '1' or stall = '1' then
			imm_ext_ALU <= (others =>'0');  -- consumed
			reg_op1_ALU <= (others =>'0');  -- consumed
			reg_op2_ALU <= (others =>'0');  -- consumed 
			pc_ALU <= (others =>'0');       -- used but will be passed on
			branch_ALU <= '0';              -- consumed
			R_or_I_ALU <= '0';               -- consumed 
			mem_op_ALU <= '0';               -- consumed
			mem_write_ALU <= '0';            -- consumed 
			ALU_op_ALU <= "0000";            -- consumed
			reg_dest_ALU <= "00000";         -- bypassed
			reg_write_ALU <= '0';            -- bypassed 
			reg_result_select_ALU <= "00";   -- bypassed   
		else
			imm_ext_ALU <= imm_ext;  
			reg_op1_ALU <= reg_op1;  
			reg_op2_ALU <= reg_op2;   
			pc_ALU <= pc_id;       
			branch_ALU <= decoded_instr.branch;              
			R_or_I_ALU <= decoded_instr.R_or_I;            
			mem_op_ALU <= decoded_instr.mem_op;               
			mem_write_ALU <= decoded_instr.mem_write;           
			ALU_op_ALU <= decoded_instr.ALU_op;           
			reg_dest_ALU <= reg_dest_id;       
			reg_write_ALU <= decoded_instr.reg_write;            
			reg_result_select_ALU <= decoded_instr.reg_result_select;     
		end if;
	end if;
end process;
-- END of ID stage -------------------------------------------------------------------------------------------------------------------
			

-- ALU stage code --------------------------------------------------------------------------------------------------------------------
-- branch target calculation, feed to pc_target in IF stage 
branch_offset <= imm_ext_ALU(29 downto 0)&"00";
pc_target <= bus32(signed(pc_ALU)+signed(branch_offset)); 

-- Generate the branch_taken global control
branch_taken <= ALU_zero and branch_ALU; 

-- Select between IMM and reg_op2_ALU
ALU_in2 <= reg_op2_ALU when R_or_I_ALU = '0' else
			  imm_ext_ALU;
-- The ALU
Inst_ALU: ALU PORT MAP
(
		ALU_op => ALU_op_ALU,
		input1 => reg_op1_ALU,
		input2 => ALU_in2,
		output => ALU_out,
		zero => ALU_zero
);

-- Extend the write enable signal
mem_write <= "1111" when mem_write_ALU = '1' else
				 "0000";
-- The data memory
data_memory : data_mem
  PORT MAP (
    clka => clock,
    ena => mem_op_ALU,         
    wea => mem_write,          
    addra => ALU_out,
    dina => reg_op2_ALU,
    douta => mem_data_out      -- belongs to the MEM stage 
); 

-- ALU stage behavior on clock edge
ALU_clock:
process (clock)
begin 
	if clock'event and clock = '1' then
		if reset = '1' then
			pc_MEM <=(others => '0');       	 -- might be written into reg 
			ALU_out_MEM <=(others => '0');  	 -- might be written into reg 
			reg_dest_MEM <= "00000";          -- connected to reg bank 
			reg_write_MEM <= '0';            -- connected to reg bank
			reg_result_select_MEM <= "00";    -- Used to select data to reg
		else                                 -- instruction in ALU will not be affected by stall or flush
			pc_MEM <= pc_ALU;
			ALU_out_MEM <= ALU_out;
			reg_dest_MEM <= reg_dest_ALU;
			reg_write_MEM <= reg_write_ALU;
			reg_result_select_MEM <= reg_result_select_ALU;
		end if;
	end if;
end process;
-- END of ALU stage ------------------------------------------------------------------------------------------------------------------
			
			

-- MEM stage code -------------------------------------------------------------------------------------------------------------------
-- most of MEM stage signals are already connected to the memory and register bank
-- select data to reg bank
data_to_reg <= pc_MEM when reg_result_select_MEM = "11" else
					mem_data_out when reg_result_select_MEM = "01" else
					ALU_out_MEM;
-- END of MEM stage -----------------------------------------------------------------------------------------------------------------

end Behavioral;

