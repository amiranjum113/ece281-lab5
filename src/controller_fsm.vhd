----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is
    --states
    type state_type is (S0,S1,S2,S3);
    signal current_state, next_state :state_type;
    
begin
--synchronus reset
process (i_adv)
begin
    if rising_edge(i_adv) then
        if i_reset = '1' then
            current_state <= S0;
        else
            current_state <= next_state;
        end if;
    end if;
end process;

--next state logic
process (current_state)
begin
    case current_state is
        when S0 => next_state <= S1;
        when S1 => next_state <= S2;
        when S2 => next_state <= S3;
        when S3 => next_state <= S0;
    end case;
end process;

--output logic
process (current_state) --output only depends on curr in Moore
begin
    case current_state is 
        when S0 => o_cycle <= "0001";
        when S1 => o_cycle <= "0010";
        when S2 => o_cycle <= "0100";
        when S3 => o_cycle <= "1000";
    end case;
end process;
end FSM;
