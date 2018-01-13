----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:21:18 10/30/2015 
-- Design Name: 
-- Module Name:    register_bank - Behavioral 
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

entity register_bank is
    Port ( read_address1 : in  STD_LOGIC_VECTOR (4 downto 0);
           read_address2 : in  STD_LOGIC_VECTOR (4 downto 0);
           write_address : in  STD_LOGIC_VECTOR (4 downto 0);
           data_out1 : out  STD_LOGIC_VECTOR (31 downto 0);
           data_out2 : out  STD_LOGIC_VECTOR (31 downto 0);
           data_in : in  STD_LOGIC_VECTOR (31 downto 0);
           write_en : in  STD_LOGIC;
           clock : in  STD_LOGIC);
end register_bank;

architecture Behavioral of register_bank is

signal bank: bank_type := (others => (others => '0'));

begin

-- Reading data
data_out1 <= 	(others => '0') when read_address1 = "00000" else
					bank(to_integer(unsigned(read_address1)));
data_out2 <= 	(others => '0') when read_address2 = "00000" else
					bank(to_integer(unsigned(read_address2)));
					
-- Writing data
process(clock)
begin
	if clock'event and clock = '1' then
		if write_en = '1' then
			bank(to_integer(unsigned(write_address))) <= data_in;
		end if;
	end if;
end process;			


end Behavioral;

