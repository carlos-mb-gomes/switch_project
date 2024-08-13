library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity payload_entity is
    Port (
        -- signal for condition states
        i_byte: in std_logic_vector(7 downto 0);
        clk: in std_logic;
        o_Ready: out std_logic;
        i_last: in std_logic;
        i_valid: in std_logic;

        i_ready:in std_logic;
        o_valid: out std_logic;
        o_last: out std_logic;    
        
        -- fields
        i_start_payload: in std_logic:= '0' ;
        o_payload: out std_logic_vector(3839 downto 0);
        o_sum_payload: out unsigned(31 downto 0);
        -- validation information
        o_payload_length: out integer
        );
end payload_entity;

architecture arch_payload of payload_entity is
    type t_PAYLOAD_STATE_TYPE is (PAYLOAD, PAYLOAD_LENGTH, SUM_PAYLOAD);
    signal r_payload_state_reg, r_payload_state_next: t_PAYLOAD_STATE_TYPE:= PAYLOAD; 
    signal r_payload_reg, r_payload_next: std_logic_vector(3839 downto 0) := (others => '0');
    signal r_sum_even_payload_reg, r_sum_even_payload_next: unsigned(31 downto 0):= (others => '0');
    signal r_sum_odd_payload_reg, r_sum_odd_payload_next: unsigned(31 downto 0):= (others => '0');
    signal r_sum_payload_reg, r_sum_payload_next: unsigned(31 downto 0):= (others => '0');
    signal r_internal_counter_reg, r_internal_counter_next: integer := 0;
    signal w_payload_length: integer := 0;

    -- component validation is 
    -- port (
    --     -- input data
    --     clk: in std_logic;
    --     i_Valid, i_Last: in std_logic;
    --     o_Ready: in std_logic;
        
    --     i_ready: in std_logic;
    --     o_valid: in std_logic;
    --     o_last: in std_logic;    
    --     --checksum
    --     i_payload: in std_logic_vector(3839 downto 0);
    --     i_sum_even_payload: in unsigned(31 downto 0);
    --     i_sum_odd_payload: in unsigned(31 downto 0);
    --     i_checksum: in unsigned(31 downto 0);
    --     i_sum_without_checksum_without_payload: in unsigned(31 downto 0);
    --     o_waited_checksum: out unsigned(15 downto 0) := x"0000";
    --     o_checksum_error: out std_logic := '0';
    --     -- payload length
    --     i_packet_length: in std_logic_vector(15 downto 0);
    --     i_payload_length : in integer :=0;
    --     -- output data
    --     o_payload_length_error: out std_logic
    -- );
    -- end component;

begin

    -- -- modulo da validação
    -- validation_module: validation
    -- port map(
    --     clk => clk,
    --     i_Valid => i_Valid,
    --     o_Ready => o_Ready,
    --     i_Last => i_Last,
    --     i_ready => i_ready,
    --     o_valid => o_valid,
    --     o_last => o_last,
    --     -- checksum 

    --     i_payload => r_payload_reg,
    --     i_sum_even_payload => r_sum_even_payload_reg,
    --     i_sum_odd_payload => r_sum_odd_payload_reg,
    --     i_checksum => r_converted_checksum_32bits,
    --     i_sum_without_checksum_without_payload => r_sum_without_checksum_without_payload,
    --     o_checksum_error => open,
    --     o_waited_checksum => open,
    --     -- payload length
    --     i_packet_length => r_packet_length_reg,
    --     i_payload_length => r_internal_counter_reg,
    --     --others
    --     o_payload_length_error => open

    -- );
    
    State_Atualization: process(clk)
    begin
        if i_valid = '0' then
            r_payload_state_reg <= PAYLOAD;
            -- fields
            -- r_payload_reg <= (others =>'0');
            -- w_payload_length_reg <= 0;
            -- -- counter
            -- r_internal_counter_reg <= 0;
            -- -- checksum aux
            -- r_sum_even_payload_reg <= (others =>'0');
            -- r_sum_odd_payload_reg <= (others =>'0');
            -- r_sum_payload_reg <= (others =>'0');

        elsif rising_edge(clk) then
        -- state
            r_payload_state_reg <= r_payload_state_next;
        -- fields
            r_payload_reg <= r_payload_next;
        -- counter
            r_internal_counter_reg <= r_internal_counter_next;
        -- checksum aux
            r_sum_even_payload_reg <= r_sum_even_payload_next;
            r_sum_odd_payload_reg <= r_sum_odd_payload_next;
            r_sum_payload_reg <= r_sum_payload_next;

        end if;
    end process;
    
    Payload_consolidation: process(i_start_payload,r_internal_counter_reg,r_payload_state_reg)
    begin
        r_sum_payload_next <= r_sum_payload_reg;
        w_payload_length <= 0;
        r_internal_counter_next <= r_internal_counter_reg;
        r_sum_odd_payload_next <= r_sum_odd_payload_reg;
        r_sum_even_payload_next <= r_sum_even_payload_reg;

        case r_payload_state_reg is
            when PAYLOAD =>
                if i_start_payload = '1' then
                    r_payload_next <= r_payload_reg(3831 downto 0) & i_byte;
                    r_internal_counter_next <= r_internal_counter_reg + 1;

                    if (r_internal_counter_reg mod 2 = 1) and (i_valid = '1') then
                        r_sum_odd_payload_next <= r_sum_odd_payload_reg + unsigned(i_byte);
                    elsif (r_internal_counter_reg mod 2 = 0) and (i_valid = '1') then
                        r_sum_even_payload_next <= r_sum_even_payload_reg + unsigned(i_byte); 
                    else
                        r_sum_even_payload_next <= (others =>'0');
                        r_sum_odd_payload_next <= (others =>'0');
                    end if;
                end if;

            when PAYLOAD_LENGTH =>
                if i_valid = '0' then
                    w_payload_length <= r_internal_counter_reg;
                end if;

            when SUM_PAYLOAD => 
                if w_payload_length mod 2 = 0 then
                    r_sum_payload_next <= r_sum_odd_payload_reg + unsigned(r_sum_even_payload_reg(23 downto 0) & x"00");
                else
                    r_sum_payload_next <= unsigned(r_sum_odd_payload_reg(23 downto 0) & x"00") + r_sum_even_payload_reg;
                end if;
        end case;
    end process; 

    Payload_Transition_State: process(i_start_payload,r_internal_counter_reg,r_payload_state_reg)
    begin

    r_payload_state_next <= r_payload_state_reg;
        case r_payload_state_reg is
            when PAYLOAD =>
                if i_last = '1' then
                    r_payload_state_next <= PAYLOAD_LENGTH;
                end if;

            when PAYLOAD_LENGTH =>
                if i_valid = '0' then
                    r_payload_state_next <= SUM_PAYLOAD;
                end if;

            when SUM_PAYLOAD => 
        end case;
    end process;   

        -- Output atualization 

    o_payload <= r_payload_reg;
    o_payload_length <= w_payload_length;
    o_sum_payload <= r_sum_payload_reg;

end arch_payload;
