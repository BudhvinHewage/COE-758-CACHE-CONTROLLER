LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY tb_topLevel IS
END tb_topLevel;

ARCHITECTURE SIM OF tb_topLevel IS
    SIGNAL CLK     : STD_LOGIC := '0';
    SIGNAL MON_RDY : STD_LOGIC;
BEGIN
    CLK <= NOT CLK AFTER 10 ns;                       -- 50 MHz, 20 ns period

    UUT : ENTITY WORK.topLevel PORT MAP (CLK => CLK, MON_RDY => MON_RDY);
    -- run for 12 us in ISim; add internal signals from the Instance/Objects panel
END SIM;
