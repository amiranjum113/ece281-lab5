--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_basys3 is
    port(
        clk     : in std_logic; 
        sw      : in std_logic_vector(7 downto 0); 
        btnU    : in std_logic; -- Reset
        btnC    : in std_logic; -- FSM Advance (to be debounced)
        
        led     : out std_logic_vector(15 downto 0);
        seg     : out std_logic_vector(6 downto 0);
        an      : out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 

    -- Component Declarations
    component button_debounce is
        Port( clk     : in  STD_LOGIC;
              reset   : in  STD_LOGIC;
              button  : in  STD_LOGIC;
              action  : out STD_LOGIC);
    end component;

    component clock_divider is
        generic (constant k_DIV : natural := 25000000);
        port ( i_clk   : in std_logic;
               i_reset : in std_logic;
               o_clk   : out std_logic);
    end component;

    component controller_fsm is
        Port ( i_reset : in STD_LOGIC;
               i_adv   : in STD_LOGIC; -- Driven by debounced signal
               o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component;
    
    component ALU is
        Port ( i_A      : in STD_LOGIC_VECTOR (7 downto 0);
               i_B      : in STD_LOGIC_VECTOR (7 downto 0);
               i_op     : in STD_LOGIC_VECTOR (2 downto 0);
               o_result : out STD_LOGIC_VECTOR (7 downto 0);
               o_flags  : out STD_LOGIC_VECTOR (3 downto 0));
    end component;
    
    component sevenseg_decoder is
        Port ( i_Hex   : in STD_LOGIC_VECTOR (3 downto 0);
               o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
    end component;

    component TDM4 is
        generic ( constant k_WIDTH : natural  := 4);
        Port ( i_clk   : in  STD_LOGIC;
               i_reset : in  STD_LOGIC;
               i_D3    : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2    : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1    : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0    : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data  : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel   : out STD_LOGIC_VECTOR (3 downto 0));
    end component;
    
    component twos_comp is
        port ( i_bin  : in std_logic_vector(7 downto 0);
               o_sign : out std_logic;
               o_hund : out std_logic_vector(3 downto 0);
               o_tens : out std_logic_vector(3 downto 0);
               o_ones : out std_logic_vector(3 downto 0));
    end component;

    -- Internal Signals
    signal w_btnC_debounced : std_logic; -- Signal between debouncer and FSM
    signal cycle            : std_logic_vector (3 downto 0);
    signal regA, regB       : std_logic_vector(7 downto 0) := (others => '0');
    signal alu_result       : std_logic_vector(7 downto 0);
    signal alu_flags        : std_logic_vector(3 downto 0);
    signal display_val      : std_logic_vector(7 downto 0);
    signal tdm_data         : std_logic_vector(3 downto 0);
    signal tdm_sel          : std_logic_vector(3 downto 0);
    signal o_clk_tdm        : std_logic;
    
    signal o_sign_sig       : std_logic;
    signal o_hund_sig, o_tens_sig, o_ones_sig : std_logic_vector(3 downto 0);
    signal decoded_seg      : std_logic_vector(6 downto 0);

begin

    -- 1. Button Debouncer
    debounce_inst : button_debounce
        port map(
            clk    => clk,
            reset  => btnU,
            button => btnC,
            action => w_btnC_debounced 
        );

    -- 2. FSM
    FSM_inst : controller_fsm
        port map(            
            i_reset => btnU,
            i_adv   => w_btnC_debounced,
            o_cycle => cycle
        );

-- 3. Register Storage: Triggered by the SAME signal as the FSM
    process(w_btnC_debounced, btnU)
    begin
        if btnU = '1' then
            regA <= (others => '0');
            regB <= (others => '0');
        elsif rising_edge(w_btnC_debounced) then
            -- We capture based on the state we are CURRENTLY in
            -- as we are being triggered to leave it.
            if cycle = "0001" then     -- Leaving S0
                regA <= sw;
            elsif cycle = "0010" then  -- Leaving S1
                regB <= sw;
            end if;
        end if;
    end process;
    
    -- 4. ALU & Display Path Logic
    ALU_inst : ALU
        port map(i_A => regA, i_B => regB, i_op => sw(2 downto 0), 
                 o_result => alu_result, o_flags => alu_flags);

    display_val <= (others => '0') when cycle = "0001" else -- S0: Blank
                   regA           when cycle = "0010" else -- S1: Show locked A
                   regB           when cycle = "0100" else -- S2: Show locked B
                   alu_result     when cycle = "1000" else -- S3: Show Result
                   (others => '0');

    twoscomp_inst : twos_comp
        port map(i_bin => display_val, o_sign => o_sign_sig, 
                 o_hund => o_hund_sig, o_tens => o_tens_sig, o_ones => o_ones_sig);

    -- 5. Seven Segment Display & TDM
    clock_divider_inst: clock_divider
        generic map (k_DIV => 100000) 
        port map(i_clk => clk, i_reset => btnU, o_clk => o_clk_tdm);

    TDM_inst : TDM4
        port map(i_clk => o_clk_tdm, 
                 i_reset => btnU,
                 i_D3 => ("000" & o_sign_sig), 
                 i_D2 => o_hund_sig,
                 i_D1 => o_tens_sig, i_D0 => o_ones_sig,
                 o_data => tdm_data, o_sel => tdm_sel);

    sevenseg_inst : sevenseg_decoder
        port map(i_Hex => tdm_data, o_seg_n => decoded_seg);

    -- Special handling for minus sign and blanking
    seg <= "0111111" when (tdm_sel = "0111" and o_sign_sig = '1') else -- Dash
           "1111111" when (tdm_sel = "0111" and o_sign_sig = '0') else -- Blank sign
           decoded_seg;

    an <= "1111" when cycle(0) = '1' else tdm_sel; -- Blank all digits in Idle state

    -- 6. LED Outputs
    led(3 downto 0)   <= cycle; 
    led(15 downto 12) <= alu_flags; 
    led(11 downto 4)  <= (others => '0');    
    
end top_basys3_arch;
