library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity payload_field is
    Port (
        clk                 : in std_logic;
        reset               : in std_logic:= '0';

        i_valid             : in std_logic;
        i_last              : in std_logic;

        i_start_payload     : in std_logic:= '0';

        i_byte              : in std_logic_vector(7 downto 0);

        o_payload           : out std_logic_vector(3839 downto 0);
        o_payload_length    : out integer;

        o_sum_payload       : out unsigned(31 downto 0);
        o_start_validation  : out std_logic:= '0'
        );
end payload_field;

architecture arch_payload of payload_field is
    type t_PAYLOAD_STATE_TYPE is (PAYLOAD, PAYLOAD_LENGTH, SUM_PAYLOAD);
    signal payload_state_reg, payload_state_next        : t_PAYLOAD_STATE_TYPE:= PAYLOAD; 
    signal payload_reg, payload_next                    : std_logic_vector(3839 downto 0) := (others => '0');
    signal sum_even_payload_reg, sum_even_payload_next  : unsigned(31 downto 0):= (others => '0');
    signal sum_odd_payload_reg, sum_odd_payload_next    : unsigned(31 downto 0):= (others => '0');
    signal sum_payload_reg, sum_payload_next            : unsigned(31 downto 0):= (others => '0');
    signal internal_counter_reg, internal_counter_next  : integer := 0;
    signal payload_length_reg, payload_length_next      : integer := 0;
    signal start_validation_reg, start_validation_next  : std_logic := '0';

begin
    
    State_Atualization: process(clk, reset)
    begin
        if reset = '1' then
            payload_state_reg     <= PAYLOAD;

            payload_reg           <= (others => '0');
            sum_odd_payload_reg   <= (others => '0');
            sum_even_payload_reg  <= (others => '0');
            
            payload_length_reg    <= 0;
            
            sum_payload_reg       <= (others => '0');

            internal_counter_reg  <= 0;
        end if;

        if rising_edge(clk) and reset = '0' then
            
            payload_state_reg     <= payload_state_next;
            
            payload_reg           <= payload_next;
            sum_even_payload_reg  <= sum_even_payload_next;
            sum_odd_payload_reg   <= sum_odd_payload_next;
            
            payload_length_reg    <= payload_length_next;
            
            sum_payload_reg       <= sum_payload_next;

            internal_counter_reg  <= internal_counter_next;

            start_validation_reg  <= start_validation_next;

        end if;
    end process;

    State_Transition_Logic: process(i_start_payload, i_last, i_valid, payload_state_reg)
    begin

    payload_state_next <= payload_state_reg;

        case payload_state_reg is
            
            when PAYLOAD =>
                if i_last = '1' and i_start_payload = '1' then
                    payload_state_next <= PAYLOAD_LENGTH;
                end if;

            when PAYLOAD_LENGTH =>
                if i_valid = '0' then
                    payload_state_next <= SUM_PAYLOAD;
                end if;

            when SUM_PAYLOAD => 

            when others =>
        end case;
    end process;   
    
    State_Attribution_Logic: process(i_start_payload, i_valid, internal_counter_reg, payload_state_reg, payload_reg, sum_odd_payload_reg,
     sum_even_payload_reg, payload_length_reg, sum_payload_reg)
    begin
        sum_payload_next          <= sum_payload_reg;
        payload_length_next       <= payload_length_reg;
        internal_counter_next     <= internal_counter_reg;
        sum_odd_payload_next      <= sum_odd_payload_reg;
        sum_even_payload_next     <= sum_even_payload_reg;
        start_validation_next     <= start_validation_reg;

        case payload_state_reg is

            when PAYLOAD =>
                if i_start_payload = '1' then
                    payload_next          <= payload_reg(3831 downto 0) & i_byte;
                    internal_counter_next <= internal_counter_reg + 1;

                    if (internal_counter_reg mod 2 = 1) and (i_valid = '1') then
                        sum_odd_payload_next <= sum_odd_payload_reg + unsigned(i_byte);
                    elsif (internal_counter_reg mod 2 = 0) and (i_valid = '1') then
                        sum_even_payload_next <= sum_even_payload_reg + unsigned(i_byte); 
                    else
                        sum_even_payload_next <= (others =>'0');
                        sum_odd_payload_next  <= (others =>'0');
                    end if;
                end if;
                
            when PAYLOAD_LENGTH =>
                if i_valid = '0' then
                    payload_length_next <= internal_counter_reg;
                end if;

            when SUM_PAYLOAD => 
                if payload_length_reg mod 2 = 0 then
                    sum_payload_next <= sum_odd_payload_reg + unsigned(sum_even_payload_reg(23 downto 0) & x"00");
                else
                    sum_payload_next <= unsigned(sum_odd_payload_reg(23 downto 0) & x"00") + sum_even_payload_reg;
                end if;
                start_validation_next <= '1';

            when others =>
        end case;
    end process; 

    -- Output atualization 
    o_payload           <= payload_reg;
    o_payload_length    <= payload_length_reg;
    -- aux validation
    o_sum_payload       <= sum_payload_reg;
    o_start_validation  <= start_validation_reg;

end arch_payload;
