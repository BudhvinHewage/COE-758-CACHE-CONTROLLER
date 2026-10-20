----------------------------------------------------------------------------------
-- Company:         Toronto Metropolitan University (Ryerson)
-- Engineer:        Budhvin Hewage
--
-- Design Name:     Cache Controller
-- Module Name:     cacheController - Behavioral
-- Target Devices:  XC3S500E (Spartan-3E)
--
-- Description:     Moore FSM controlling a direct-mapped, write-back cache
--                  (8 blocks x 32 bytes). Handles hit, clean miss (case 3) and
--                  dirty miss (case 4) by driving the SDRAM controller, the
--                  BlockRAM address/write-enable and the write mux / read demux.
--                  Address map: tag [15:8], index [7:5], offset [4:0].
--
-- Dependencies:    None.
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY cacheController IS
    PORT (
        CLK           : IN  STD_LOGIC;
        CS            : IN  STD_LOGIC;
        WR_RD         : IN  STD_LOGIC;
        ADD           : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        RDY           : OUT STD_LOGIC;
        SDRAM_ADD     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        SDRAM_WR_RD   : OUT STD_LOGIC;
        SDRAM_MEMSTRB : OUT STD_LOGIC;
        SRAM_ADD      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        SRAM_WEN      : OUT STD_LOGIC;
        MUX_SEL       : OUT STD_LOGIC;
        DEMUX_SEL     : OUT STD_LOGIC
    );
END cacheController;

ARCHITECTURE BEHAVIORAL OF cacheController IS

    ------------------------------------------------------------------ 
    TYPE STATE_TYPES IS (
        CC_INITIALIZATION,      -- reset all tags, valid bits, dirty bits; then go to by setting CPU_RDY=1
        CC_IDLE,                -- wait for CS=1 and read and latch ADD and WR_RD signals, then go to next state
        CC_IDENTIFY_REQUEST,    -- hit / clean miss / dirty miss and pick the entry point into the chain
        CC_WRITE_SDRAM_SET,     -- write-back, where cycle A is letting the SDRAM address (old tag) and the SRAM address settle
        CC_WRITE_SDRAM_STRB,    -- write-back, where cycle B is generating the MEMSTRB pulse, incrementing the counter or exitting after word 31
        CC_READ_SDRAM_SET,      -- fetch, where cycle A is letting the SDRAM address (new tag) and SRAM address settle
        CC_READ_SDRAM_STRB,     -- fetch, where cycle B is generating the MEMSTRB pulse and SRAM_WEN, incrementing the counter or exitting after word 31
        CC_WRITE_SRAM,          -- the CPU's single-word write into SRAM and sets the dirty bit to indicate that the row has been modified
        CC_READ_SRAM,           -- the CPU's single-word read from SRAM to the CPU_IN 
        CC_AFFIRM_REQUEST       -- hold until CS drops, then back to IDLE (RDY rises)
    );
    SIGNAL STATE, NEXT_STATE : STATE_TYPES := CC_INITIALIZATION;

    ------------------------------------------------------------------  
    TYPE TAG_ARRAY_TYPE IS ARRAY (0 TO 7) OF STD_LOGIC_VECTOR(7 DOWNTO 0);                  -- a type of an array of 8 tags, each being 8 bits wide

    SIGNAL TAG_ARRAY                : TAG_ARRAY_TYPE := (OTHERS => (OTHERS => '0'));        -- initalize the tag array to all zeros, by selecting all initial elements, then each bit in each element to zero
    SIGNAL VALID_ARRAY              : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');      -- initalize the valid array to all zeros, by selecting all initial elements, then each bit in each element to zero
    SIGNAL DIRTY_ARRAY              : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');      -- initalize the dirty array to all zeros, by selecting all initial elements, then each bit in each element to zero

    ------------------------------------------------------------------  
    SIGNAL ADDRESS_SIGNAL           : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');     -- the address from the CPU, latched when CS=1
    SIGNAL WRITE_ENABLE_SIGNAL      : STD_LOGIC := '0';                                     -- the write/read signal from the CPU, latched when CS=1
    SIGNAL COUNTER                  : UNSIGNED(4 DOWNTO 0) := (OTHERS => '0');              -- word counter from 0 to 31, incremented after every MEMSTRB pulse, and reset to 0 when the next phase begins

    ------------------------------------------------------------------
    SIGNAL TAG_VALUE                : STD_LOGIC_VECTOR(7 DOWNTO 0);                         -- the tag value of the current CPU request, extracted from the address
    SIGNAL INDEX_VALUE              : STD_LOGIC_VECTOR(2 DOWNTO 0);                         -- the index value of the current CPU request, extracted from the address
    SIGNAL CURRENT_INDEX            : INTEGER RANGE 0 TO 7;                                 -- the integer value of the current index, used to access the tag, valid and dirty arrays and is converted from the INDEX_VALUE signal
    SIGNAL HIT                      : STD_LOGIC;                                            -- a signal that indicates whether the current CPU request is a hit or a miss, based on the tag and valid bit of the current index
    SIGNAL COUNTER_VECTOR           : STD_LOGIC_VECTOR(4 DOWNTO 0);                         -- the counter value converted to a std_logic_vector, used to access the SRAM and SDRAM addresses
    SIGNAL LAST                     : STD_LOGIC;                                            -- counter = 31, so the next MEMSTRB pulse will be the last one in the current phase

BEGIN

    ------------------------------------------------------------------
    --         all permenent signals are assigned here              --

    TAG_VALUE                       <= ADDRESS_SIGNAL(15 DOWNTO 8);                         -- the tag value of the current CPU request, extracted from the address
    INDEX_VALUE                     <= ADDRESS_SIGNAL(7 DOWNTO 5);                          -- the index value of the current CPU request, extracted from the address
    CURRENT_INDEX                   <= TO_INTEGER(UNSIGNED(INDEX_VALUE));                   -- the integer value of the current index
    COUNTER_VECTOR                  <= STD_LOGIC_VECTOR(COUNTER);                           -- the counter value converted to a std_logic_vector, used to access the SRAM and SDRAM addresses
    LAST                            <= '1' WHEN COUNTER = TO_UNSIGNED(31, 5) ELSE '0';      -- convert the 31 value to unsigned and compare it with the counter value(current) and assign '1' if they are equal, else assign '0'

    -- determine if the current CPU request is a hit or a miss, by checking if the valid bit is set and if the tag value matches the tag stored in the tag array for the current index
    HIT <= '1' WHEN (VALID_ARRAY(CURRENT_INDEX) = '1' AND TAG_ARRAY(CURRENT_INDEX) = TAG_VALUE) ELSE '0';

    ------------------------------------------------------------------
    --ensure that states are updated on the rising edge of the clock--
    PROCESS (CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            STATE <= NEXT_STATE;
        END IF;
    END PROCESS;

    ------------------------------------------------------------------
    PROCESS (STATE, CS, HIT, DIRTY_ARRAY, CURRENT_INDEX, LAST, WRITE_ENABLE_SIGNAL)
    BEGIN
        NEXT_STATE <= STATE;
        CASE STATE IS
            WHEN CC_INITIALIZATION  => 
                NEXT_STATE <= CC_IDLE;

            WHEN CC_IDLE  => 
                IF CS = '1' THEN 
                    NEXT_STATE <= CC_IDENTIFY_REQUEST; 
                END IF;

            WHEN CC_IDENTIFY_REQUEST =>
                IF HIT = '1' THEN
                    IF WRITE_ENABLE_SIGNAL = '1' THEN
                        NEXT_STATE <= CC_WRITE_SRAM;  -- case 1: hit and write
                    ELSE
                        NEXT_STATE <= CC_READ_SRAM;   -- case 2: hit and read
                    END IF;

                ELSIF DIRTY_ARRAY(CURRENT_INDEX) = '1' THEN
                    NEXT_STATE <= CC_WRITE_SDRAM_SET;           -- case 4: dirty miss (write back, then fetch)
                
                ELSIF DIRTY_ARRAY(CURRENT_INDEX) = '0' THEN
                    NEXT_STATE <= CC_READ_SDRAM_SET;            -- case 3: clean miss (fetch only)
                END IF;
                

            WHEN CC_WRITE_SDRAM_SET =>
                NEXT_STATE <= CC_WRITE_SDRAM_STRB;
            
            WHEN CC_WRITE_SDRAM_STRB =>
                IF LAST = '1' THEN
                    NEXT_STATE <= CC_IDENTIFY_REQUEST;
                ELSE
                    NEXT_STATE <= CC_WRITE_SDRAM_SET;
                END IF;
            
            WHEN CC_READ_SDRAM_SET =>
                NEXT_STATE <= CC_READ_SDRAM_STRB;
            
            WHEN CC_READ_SDRAM_STRB =>
                IF LAST = '1' THEN
                    NEXT_STATE <= CC_IDENTIFY_REQUEST;
                ELSE
                    NEXT_STATE <= CC_READ_SDRAM_SET;
                END IF;

            WHEN CC_WRITE_SRAM =>
                NEXT_STATE <= CC_AFFIRM_REQUEST;
            
            WHEN CC_READ_SRAM =>
                NEXT_STATE <= CC_AFFIRM_REQUEST;

            WHEN CC_AFFIRM_REQUEST =>
                IF CS = '0' THEN
                    NEXT_STATE <= CC_IDLE;
                END IF;

        END CASE;
    END PROCESS;

    ------------------------------------------------------------------
    PROCESS (STATE, ADDRESS_SIGNAL, TAG_VALUE, INDEX_VALUE, CURRENT_INDEX, COUNTER_VECTOR, TAG_ARRAY)
    BEGIN
        RDY                         <= '0';
        SDRAM_ADD                   <= TAG_ARRAY(CURRENT_INDEX) & INDEX_VALUE & COUNTER_VECTOR;
        SDRAM_WR_RD                 <= '0';
        SDRAM_MEMSTRB               <= '0';
        SRAM_ADD                    <= ADDRESS_SIGNAL(7 DOWNTO 0);       
        SRAM_WEN                    <= '0';
        MUX_SEL                     <= '0';                        
        DEMUX_SEL                   <= '1';                        

        CASE STATE IS
            WHEN CC_IDLE =>
                RDY                 <= '1';

            WHEN CC_WRITE_SRAM =>
                SRAM_WEN            <= '1';
                MUX_SEL             <= '0';
                SRAM_ADD            <= ADDRESS_SIGNAL(7 DOWNTO 0);

            WHEN CC_READ_SRAM =>
                SRAM_ADD            <= ADDRESS_SIGNAL(7 DOWNTO 0);
                SRAM_WEN            <= '0';                        

            WHEN CC_WRITE_SDRAM_SET =>
                SDRAM_MEMSTRB       <= '0';
                SDRAM_WR_RD         <= '1';
                SRAM_ADD            <= INDEX_VALUE & COUNTER_VECTOR;
                SRAM_WEN            <= '0';
                SDRAM_ADD           <= TAG_ARRAY(CURRENT_INDEX) & INDEX_VALUE & COUNTER_VECTOR;
                DEMUX_SEL           <= '0';

            WHEN CC_WRITE_SDRAM_STRB =>
                SDRAM_MEMSTRB       <= '1';
                SDRAM_WR_RD         <= '1';
                SRAM_ADD            <= INDEX_VALUE & COUNTER_VECTOR;
                SRAM_WEN            <= '0';
                SDRAM_ADD           <= TAG_ARRAY(CURRENT_INDEX) & INDEX_VALUE & COUNTER_VECTOR;
                DEMUX_SEL           <= '0';

            WHEN CC_READ_SDRAM_SET =>
                SDRAM_MEMSTRB       <= '0';
                SDRAM_WR_RD         <= '0';
                SRAM_ADD            <= INDEX_VALUE & COUNTER_VECTOR;
                SDRAM_ADD           <= TAG_VALUE & INDEX_VALUE & COUNTER_VECTOR;
                MUX_SEL             <= '1';
                SRAM_WEN            <= '0';

            WHEN CC_READ_SDRAM_STRB =>
                SDRAM_MEMSTRB       <= '1';
                SDRAM_WR_RD         <= '0';
                SRAM_ADD            <= INDEX_VALUE & COUNTER_VECTOR;
                SDRAM_ADD           <= TAG_VALUE & INDEX_VALUE & COUNTER_VECTOR;
                MUX_SEL             <= '1';
                SRAM_WEN            <= '1';

            WHEN OTHERS => NULL;                     -- INIT, IDENTIFY_REQUEST: defaults
        END CASE;
    END PROCESS;

    ------------------------------------------------ 4. datapath registers (clocked)
    PROCESS (CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN

            IF STATE = CC_IDLE AND CS = '1' THEN
                COUNTER <= (OTHERS => '0');
                ADDRESS_SIGNAL <= ADD;
                WRITE_ENABLE_SIGNAL <= WR_RD;
            END IF;

            IF STATE = CC_WRITE_SDRAM_STRB OR STATE = CC_READ_SDRAM_STRB THEN
                COUNTER <= COUNTER + 1;
            END IF;

            IF STATE = CC_READ_SDRAM_STRB AND LAST = '1' THEN
                TAG_ARRAY(CURRENT_INDEX) <= TAG_VALUE;
                VALID_ARRAY(CURRENT_INDEX) <= '1';
                DIRTY_ARRAY(CURRENT_INDEX) <= '0';
            END IF;

            IF STATE = CC_WRITE_SDRAM_STRB AND LAST = '1' THEN
                VALID_ARRAY(CURRENT_INDEX) <= '1';
                DIRTY_ARRAY(CURRENT_INDEX) <= '0';
            END IF;

            IF STATE = CC_WRITE_SRAM THEN
                DIRTY_ARRAY(CURRENT_INDEX) <= '1';
            END IF;

        END IF;
    END PROCESS;

END BEHAVIORAL;