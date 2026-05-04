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


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

begin
    process (i_A,i_B,i_op)
        variable a_uns, b_uns : unsigned(8 downto 0);
        variable res_uns : unsigned (8 downto 0);
        variable res_8: std_logic_vector(7 downto 0);
        variable N, Z, C, V: std_logic;
    
    begin
        res_uns := (others => '0');
        V := '0';
        Z := '0';
        a_uns := unsigned ('0' & i_A);--adding 0 to start to make i_A 9 bit, 9th bit tracks carry
        b_uns := unsigned ('0' & i_B);
    
        case i_op is
            when "000" => --ADD
                res_uns := a_uns + b_uns;
                --checking overflow(pos+pos=neg)or(neg+neg=pos)
                V := (i_A(7) and i_B(7) and not res_uns(7)) or (not(i_A(7)) and not(i_B(7)) and res_uns(7));
             
            when "001" => --SUB
                res_uns := a_uns - b_uns;
                --checking overflow (pos-neg=neg)or(neg-pos=pos)
                V := (i_A(7) xor i_B(7)) and (i_A(7) xor res_8(7));
            when "010" => --AND
                res_8 := i_A and i_B;
                res_uns := unsigned('0' & res_8);
            when "011" => --OR
                res_8 := i_A or i_B;
                res_uns := unsigned('0' & res_8);                             
            when others =>
                res_uns := (others => '0');
        end case;
        res_8 := std_logic_vector(res_uns(7 downto 0));
        --extractong flags:
        C := res_uns (8);
        N := res_8(7);
        
        if res_8 = x"00" then --all 8 bits of result are zero
            Z:='1';
        else
            Z:='0';
        end if;
        --finally
        o_result <= res_8;
        o_flags <= N & Z & C & V;
    end process; 
end Behavioral;

