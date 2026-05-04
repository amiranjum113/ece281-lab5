----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
begin
    process (i_A, i_B, i_op)
        variable a_uns, b_uns : unsigned(8 downto 0);
        variable res_uns : unsigned (8 downto 0);
        variable res_8: std_logic_vector(7 downto 0);
        variable N, Z, C, V: std_logic;
    begin
        -- Initialize variables
        res_uns := (others => '0');
        res_8 := (others => '0'); -- Ensure res_8 is cleared
        V := '0';
        a_uns := unsigned ('0' & i_A);
        b_uns := unsigned ('0' & i_B);
    
        case i_op is
            when "000" => -- ADD
                res_uns := a_uns + b_uns;
                res_8 := std_logic_vector(res_uns(7 downto 0)); -- Assign here
                V := (i_A(7) and i_B(7) and not res_8(7)) or (not(i_A(7)) and not(i_B(7)) and res_8(7));
             
            when "001" => -- SUB
                res_uns := a_uns - b_uns;
                res_8 := std_logic_vector(res_uns(7 downto 0)); -- Assign here
                V := (i_A(7) and not(i_B(7)) and not res_8(7)) or (not(i_A(7)) and (i_B(7)) and res_8(7));

            when "010" => -- AND
                res_8 := i_A and i_B;
                res_uns := unsigned('0' & res_8);

            when "011" => -- OR
                res_8 := i_A or i_B;
                res_uns := unsigned('0' & res_8);                           

            when others =>
                res_8 := (others => '0');
                res_uns := (others => '0');
        end case;

        -- FLAG EXTRACTION
        -- This is the only logic change needed for the testbench
        if i_op = "001" then 
            C := not res_uns(8); -- Not-Borrow for SUB
        else
            C := res_uns(8);     -- Normal Carry for others
        end if;

        N := res_8(7);
        
        if res_8 = x"00" then 
            Z := '1';
        else
            Z := '0';
        end if;

        -- FINAL ASSIGNMENTS
        o_result <= res_8;
        o_flags <= N & Z & C & V;
    end process; 
end Behavioral;