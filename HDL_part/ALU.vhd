----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:27:46 10/31/2015 
-- Design Name: 
-- Module Name:    ALU - Behavioral 
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

entity ALU is
    Port ( ALU_op : in  STD_LOGIC_VECTOR (3 downto 0);
           input1 : in  STD_LOGIC_VECTOR (31 downto 0);
           input2 : in  STD_LOGIC_VECTOR (31 downto 0);
           output : out  STD_LOGIC_VECTOR (31 downto 0);
           zero : out  STD_LOGIC);
end ALU;

architecture Behavioral of ALU is
signal output_buffer: bus32;
begin

zero <= '1' when output_buffer = x"00000000" else
		  '0';

process(ALU_op,input1,input2)
begin
case ALU_op is
	when "0000" => output_buffer <= input1 and input2;
	when "0001" => output_buffer <= input1 or input2; 
	when "0011" => output_buffer <= input1 nor input2; 
	when "0010" => output_buffer <= bus32(signed(input1)+signed(input2));
	when "0110" => output_buffer <= bus32(signed(input1)-signed(input2));
	when "0100" => output_buffer <= input1 xor input2;
	when "0111" => output_buffer <= bus32(signed(input1)-signed(input2)) and x"80000000"; -- Set to "100..." when less than, to simplify things
	when others => output_buffer <= input2(15 downto 0) & x"0000";
end case;
end process;

output <= output_buffer;

end Behavioral;

