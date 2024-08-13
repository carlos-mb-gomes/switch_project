library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity payload_field is
    Port (
        reset               : in std_logic:= '0';
        i_start_payload     : in std_logic:= '0';
        i_byte              : in std_logic_vector(7 downto 0);
        clk                 : in std_logic;
        
        i_last              : in std_logic;
        i_valid             : in std_logic;

        o_payload           : out std_logic_vector(3839 downto 0);

        o_sum_payload       : out unsigned(31 downto 0);
        o_payload_length    : out integer;
        o_start_validation  : out std_logic:= '0'
        );
end payload_field;

architecture arch_payload of payload_field is
    type t_PAYLOAD_STATE_TYPE is (PAYLOAD, PAYLOAD_LENGTH, SUM_PAYLOAD);
    signal r_payload_state_reg, r_payload_state_next        : t_PAYLOAD_STATE_TYPE:= PAYLOAD; 
    signal r_payload_reg, r_payload_next                    : std_logic_vector(3839 downto 0) := (others => '0');
    signal r_sum_even_payload_reg, r_sum_even_payload_next  : unsigned(31 downto 0):= (others => '0');
    signal r_sum_odd_payload_reg, r_sum_odd_payload_next    : unsigned(31 downto 0):= (others => '0');
    signal r_sum_payload_reg, r_sum_payload_next            : unsigned(31 downto 0):= (others => '0');
    signal r_internal_counter_reg, r_internal_counter_next  : integer := 0;
    signal r_payload_length_reg, r_payload_length_next      : integer := 0;
    signal r_start_validation_reg, r_start_validation_next  : std_logic := '0';

begin
    
    State_Atualization: process(clk, reset)
    begin
        if reset = '1' then
            r_payload_state_reg     <= PAYLOAD;
            r_payload_reg           <= (others => '0');
            r_sum_payload_reg       <= (others => '0');
            r_payload_length_reg    <= 0;
            r_internal_counter_reg  <= 0;
            r_sum_odd_payload_reg   <= (others => '0');
            r_sum_even_payload_reg <= (others => '0');
        end if;

        if rising_edge(clk) and reset = '0' then

            r_payload_state_reg     <= r_payload_state_next;
            r_payload_reg           <= r_payload_next;
            r_internal_counter_reg  <= r_internal_counter_next;
            r_sum_even_payload_reg  <= r_sum_even_payload_next;
            r_sum_odd_payload_reg   <= r_sum_odd_payload_next;
            r_sum_payload_reg       <= r_sum_payload_next;
            r_payload_length_reg    <= r_payload_length_next;
            r_start_validation_reg  <= r_start_validation_next;

        end if;
    end process;

    State_Transition_Logic: process(i_start_payload, i_last, i_valid, r_payload_state_reg)
    begin

    r_payload_state_next <= r_payload_state_reg;

        case r_payload_state_reg is
            
            when PAYLOAD =>
                if i_last = '1' and i_start_payload = '1' then
                    r_payload_state_next <= PAYLOAD_LENGTH;
                end if;

            when PAYLOAD_LENGTH =>
                if i_valid = '0' then
                    r_payload_state_next <= SUM_PAYLOAD;
                end if;

            when SUM_PAYLOAD => 

        end case;
    end process;   
    
    State_Attribution_Logic: process(i_start_payload, i_valid, r_internal_counter_reg, r_payload_state_reg,
     r_payload_reg, r_sum_odd_payload_reg, r_sum_even_payload_reg, r_payload_length_reg, r_sum_payload_reg)
    begin
        r_sum_payload_next          <= r_sum_payload_reg;
        r_payload_length_next       <= r_payload_length_reg;
        r_internal_counter_next     <= r_internal_counter_reg;
        r_sum_odd_payload_next      <= r_sum_odd_payload_reg;
        r_sum_even_payload_next     <= r_sum_even_payload_reg;
        r_start_validation_next     <= r_start_validation_reg;

        case r_payload_state_reg is

            when PAYLOAD =>
                if i_start_payload = '1' then
                    r_payload_next          <= r_payload_reg(3831 downto 0) & i_byte;
                    r_internal_counter_next <= r_internal_counter_reg + 1;

                    if (r_internal_counter_reg mod 2 = 1) and (i_valid = '1') then
                        r_sum_odd_payload_next <= r_sum_odd_payload_reg + unsigned(i_byte);
                    elsif (r_internal_counter_reg mod 2 = 0) and (i_valid = '1') then
                        r_sum_even_payload_next <= r_sum_even_payload_reg + unsigned(i_byte); 
                    else
                        r_sum_even_payload_next <= (others =>'0');
                        r_sum_odd_payload_next  <= (others =>'0');
                    end if;
                end if;
                
            when PAYLOAD_LENGTH =>
                if i_valid = '0' then
                    r_payload_length_next <= r_internal_counter_reg;
                end if;

            when SUM_PAYLOAD => 
                if r_payload_length_reg mod 2 = 0 then
                    r_sum_payload_next <= r_sum_odd_payload_reg + unsigned(r_sum_even_payload_reg(23 downto 0) & x"00");
                else
                    r_sum_payload_next <= unsigned(r_sum_odd_payload_reg(23 downto 0) & x"00") + r_sum_even_payload_reg;
                end if;
                r_start_validation_next <= '1';

        end case;
    end process; 

    -- Output atualization 
    o_payload           <= r_payload_reg;
    o_payload_length    <= r_payload_length_reg;
    o_sum_payload       <= r_sum_payload_reg;
    o_start_validation  <= r_start_validation_reg;

end arch_payload;
