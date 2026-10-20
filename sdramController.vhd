----------------------------------------------------------------------------------
-- Company:         Toronto Metropolitan University (Ryerson)
-- Engineer:        Budhvin Hewage
--
-- Design Name:     Cache Controller
-- Module Name:     sdramController - Behavioral
-- Target Devices:  XC3S500E (Spartan-3E)
--
-- Description:     Behavioural model of the main memory. 256 x 8 array indexed
--                  by ADD(7 downto 0) (the tag is ignored). Writes on the rising
--                  clock edge when MEMSTRB = '1' and WR_RD = '1'. Read data is
--                  combinational, so it is valid while MEMSTRB is high.
--
-- Dependencies:    None.
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY sdramController IS
    PORT ( CLK     : IN  STD_LOGIC;
           ADD     : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
           WR_RD   : IN  STD_LOGIC;
           MEMSTRB : IN  STD_LOGIC;
           DIN     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
           DOUT    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END sdramController;

ARCHITECTURE BEHAVIORAL OF sdramController IS
    TYPE STORAGE_ARRAY_TYPE IS ARRAY (0 TO 255) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL MEM : STORAGE_ARRAY_TYPE := (OTHERS => (OTHERS => '0'));
BEGIN
    PROCESS (CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF MEMSTRB = '1' AND WR_RD = '1' THEN
                MEM(TO_INTEGER(UNSIGNED(ADD(7 DOWNTO 0)))) <= DIN;
            END IF;
        END IF;
    END PROCESS;

    DOUT <= MEM(TO_INTEGER(UNSIGNED(ADD(7 DOWNTO 0))));
END BEHAVIORAL;
