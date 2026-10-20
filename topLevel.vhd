----------------------------------------------------------------------------------
-- Company:         Toronto Metropolitan University (Ryerson)
-- Engineer:        Budhvin Hewage
--
-- Design Name:     Cache Controller
-- Module Name:     topLevel - Behavioral
-- Target Devices:  XC3S500E (Spartan-3E)
--
-- Description:     Structural top level: CPU_gen -> cacheController, with the
--                  BlockRAM, SDRAM model, write mux and read demux. MON_RDY drives
--                  an LED. ChipScope ICON/ILA are added to this file.
--
-- Dependencies:    CPU_gen, cacheController, sdramController, sram (BlockRAM core)
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY topLevel IS
    PORT ( CLK     : IN  STD_LOGIC;
           MON_RDY : OUT STD_LOGIC );
END topLevel;

ARCHITECTURE BEHAVIORAL OF topLevel IS
    ----------------------------------------------------------------------
    -- Signals for CPU_gen
    COMPONENT CPU_gen
        PORT ( CLK, RST, TRIG : IN  STD_LOGIC;
               ADDRESS        : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
               WR_RD, CS      : OUT STD_LOGIC;
               DOUT           : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) );
    END COMPONENT;

    -- Signals for cacheController
    COMPONENT cacheController
        PORT ( CLK, CS, WR_RD : IN  STD_LOGIC;
               ADD            : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
               RDY            : OUT STD_LOGIC;
               SDRAM_ADD      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
               SDRAM_WR_RD, SDRAM_MEMSTRB : OUT STD_LOGIC;
               SRAM_ADD       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
               SRAM_WEN, MUX_SEL, DEMUX_SEL : OUT STD_LOGIC );
    END COMPONENT;

    -- Signals for sdramController
    COMPONENT sdramController
        PORT ( CLK, WR_RD, MEMSTRB : IN STD_LOGIC;
               ADD  : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
               DIN  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
               DOUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) );
    END COMPONENT;

    -- Signals for sram
    COMPONENT sram
        PORT ( CLKA  : IN  STD_LOGIC;
               WEA   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
               ADDRA : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
               DINA  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
               DOUTA : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) );
    END COMPONENT;
    ----------------------------------------------------------------------
    SIGNAL CS, WR_RD, RDY        : STD_LOGIC;
    SIGNAL ADD                   : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL CPU_DOUT              : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL SDRAM_ADD             : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL SDRAM_WR_RD, SDRAM_MEMSTRB : STD_LOGIC;
    SIGNAL SDRAM_DOUT, SDRAM_DIN : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL SRAM_ADD              : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL SRAM_WEN              : STD_LOGIC;
    SIGNAL SRAM_WEN_V            : STD_LOGIC_VECTOR(0 DOWNTO 0);  
    SIGNAL SRAM_DIN, SRAM_DOUT   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL MUX_SEL, DEMUX_SEL    : STD_LOGIC;

BEGIN

    U_CTRL : cacheController
        PORT MAP (CLK => CLK, CS => CS, WR_RD => WR_RD, ADD => ADD, RDY => RDY,
                SDRAM_ADD => SDRAM_ADD, SDRAM_WR_RD => SDRAM_WR_RD,
                SDRAM_MEMSTRB => SDRAM_MEMSTRB, SRAM_ADD => SRAM_ADD,
                SRAM_WEN => SRAM_WEN, MUX_SEL => MUX_SEL, DEMUX_SEL => DEMUX_SEL);
    
    SRAM_DIN  <= CPU_DOUT   WHEN MUX_SEL = '0'   ELSE SDRAM_DOUT;       
    SDRAM_DIN <= SRAM_DOUT  WHEN DEMUX_SEL = '0' ELSE (OTHERS => '0');  
    
    U_CPU  : CPU_gen
        PORT MAP (CLK => CLK, RST => '0', TRIG => RDY, ADDRESS => ADD,
                WR_RD => WR_RD, CS => CS, DOUT => CPU_DOUT);

    U_SDRAM : sdramController
    PORT MAP (CLK => CLK, ADD => SDRAM_ADD, WR_RD => SDRAM_WR_RD,
              MEMSTRB => SDRAM_MEMSTRB, DIN => SDRAM_DIN, DOUT => SDRAM_DOUT);

    SRAM_WEN_V(0) <= SRAM_WEN;

    U_SRAM : sram
        PORT MAP (CLKA => CLK, WEA => SRAM_WEN_V, ADDRA => SRAM_ADD,
                DINA => SRAM_DIN, DOUTA => SRAM_DOUT);
    
    MON_RDY <= RDY;

END BEHAVIORAL;
