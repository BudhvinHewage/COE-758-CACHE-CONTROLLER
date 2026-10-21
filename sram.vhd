-- sram.vhd : behavioural stand-in for the CoreGen BlockRAM (256 x 8, SIMULATION).
-- Same entity name/ports as a CoreGen "Single Port RAM" core (clka, wea(0:0),
-- addra, dina, douta), so in ISE you drop this file and add the .xco core instead.
-- Read: data appears on DOUT after the next rising edge (spec Fig 11).
-- Write: data stored on the next rising edge when WEA=1 (spec Fig 12).
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sram is
    Port ( clka  : IN  STD_LOGIC;
           wea   : IN  STD_LOGIC_VECTOR(0 downto 0);
           addra : IN  STD_LOGIC_VECTOR(7 downto 0);
           dina  : IN  STD_LOGIC_VECTOR(7 downto 0);
           douta : OUT STD_LOGIC_VECTOR(7 downto 0));
end sram;

architecture Behavioral of sram is
    type ram_t is array (0 to 255) of STD_LOGIC_VECTOR(7 downto 0);
    signal ram : ram_t := (others => (others => '0'));
begin
    process (clka)
    begin
        if rising_edge(clka) then
            if wea(0) = '1' then
                ram(to_integer(unsigned(addra))) <= dina;
            end if;
            douta <= ram(to_integer(unsigned(addra)));   -- read-first
        end if;
    end process;
end Behavioral;
