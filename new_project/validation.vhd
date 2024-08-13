library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity validation is
    Port (
        -- input data
        clk: in std_logic;
        i_o_ready: in std_logic;
        i_valid: in std_logic; 
        i_last: in std_logic;

        i_ready: in std_logic;
        i_o_valid: in std_logic;
        i_o_last: in std_logic; 

        -- checksum error
        i_sum_payload: in unsigned(31 downto 0);
        i_checksum: in unsigned(31 downto 0);
        i_sum_without_checksum_without_payload: in unsigned(31 downto 0);
        o_waited_checksum: out unsigned(15 downto 0) := x"0000";
        o_checksum_error: out std_logic := '0';
        
        -- payload length error
        i_packet_length: in std_logic_vector(15 downto 0); 
        i_payload_length : in integer :=0;
        o_payload_length_error: out std_logic := '0'

        );
end validation;

architecture arch_validation of validation is
    type t_CHECKSUM_STATE_TYPE is (IDLE, SUM_ALL_FIELDS, SUM_WITH_CARRY, CHECKING_IF_RESULT_IS_FFFF, CALC_WAITED_CHECKSUM, VALUE_WAITED, END_OF_VALIDATION);
    signal r_checksum_state_reg, r_checksum_state_next: t_CHECKSUM_STATE_TYPE := IDLE;
    signal r_sum_32_reg, r_sum_32_next: unsigned(31 downto 0):= x"00000000";
    signal r_sum_16_reg, r_sum_16_next: unsigned(15 downto 0):= x"0000";
    signal r_sum_without_checksum_reg, r_sum_without_checksum_next: unsigned(31 downto 0) := x"00000000";
    signal w_o_last: std_logic:= '0';

    -- component o_switch is
    -- Port (
    --     -- input data
    --     clk: in std_logic;
        
    --     i_o_ready: out std_logic;
    --     i_valid: in std_logic; 
    --     i_last: in std_logic;

    --     i_ready: in std_logic;
    --     i_o_valid: out std_logic;
    --     i_o_last: out std_logic;   

    --     i_sync: in std_logic:= '0';
    --     i_close: in std_logic:= '0';
    --     i_checksum_validation: in std_logic:= '0';
    --     i_payload_legth_validation: in std_logic:= '0';
    --     i_destination_not_found_validation: in std_logic:= '0';
    --     i_seqnum_validation: in std_logic:= '0';
    --     i_destination_address: in std_logic_vector(15 downto 0) := (others =>'0') ;
    --     i_source_address: in std_logic_vector(15 downto 0) := (others =>'0') ;
    --     i_ports: in std_logic_vector(4 downto 0):= (others =>'0') ;

    --     -- ports
    --     o_data: out std_logic_vector(7 downto 0):= (others =>'0');
    --     o_ports: out std_logic_vector(4 downto 0):= (others =>'0');
    --     o_flag_error: out std_logic_vector(5 downto 0):= (others =>'0');
    --     o_source_address: out std_logic_vector(15 downto 0):= (others =>'0');
    --     o_destination_address: out std_logic_vector(15 downto 0):= (others =>'0')
    --     );
    -- end component;

begin    

    -- output_process: o_switch
    -- port map (
    --     clk => clk,
    --     i_o_ready => open,
    --     i_valid => i_valid, 
    --     i_last => i_last,

    --     i_ready => i_ready,
    --     i_o_valid => open,
    --     i_o_last => open,    

    --     i_sync => end_t,
    --     i_close => '0',
    --     i_checksum_validation => '0',
    --     i_payload_legth_validation => '0',
    --     i_destination_not_found_validation => '0',
    --     i_seqnum_validation => '0',
    --     i_destination_address => (others =>'0') ,
    --     i_source_address => (others =>'0') ,
    --     i_ports => (others =>'0') ,

    --     -- ports
    --     o_data => open,
    --     o_ports => open,
    --     o_flag_error => open,
    --     o_source_address => open, 
    --     o_destination_address => open

    -- );
    w_o_last <= i_o_last;
-- VALIDATION TEM QUE FUNCIONAR DEPOIS DO IVALID = 0, ILAST = 0 , OREADY = 0
    State_atualization: process(clk)
    begin
        if i_o_last = '1' then
            r_checksum_state_reg <= IDLE;
            o_payload_length_error <= '0';

        elsif rising_edge(clk) then
            r_sum_without_checksum_reg <= r_sum_without_checksum_next;
            r_sum_32_reg <= r_sum_32_next;
            r_sum_16_reg <= r_sum_16_next;
            r_checksum_state_reg <= r_checksum_state_next;
        end if;
    end process;
    

    Checksum_Validation: process(clk,r_sum_without_checksum_reg, r_sum_32_reg,r_sum_16_reg,r_checksum_state_reg)
    begin
        r_sum_without_checksum_next <= r_sum_without_checksum_reg;
        r_sum_32_next <= r_sum_32_reg;
        r_sum_16_next <= r_sum_16_reg;
        r_checksum_state_next <= r_checksum_state_reg;

        case r_checksum_state_reg is
            when IDLE =>
                if (i_ready = '1') then
                    r_sum_without_checksum_next <= i_sum_without_checksum_without_payload + i_sum_payload;
                    r_checksum_state_next <= SUM_ALL_FIELDS;
                end if;

            when SUM_ALL_FIELDS =>
                r_sum_32_next <= r_sum_without_checksum_reg + i_checksum;
                r_checksum_state_next <= SUM_WITH_CARRY;
            
            when SUM_WITH_CARRY =>
                r_sum_16_next <= r_sum_32_reg(31 downto 16) + r_sum_32_reg(15 downto 0);
                r_checksum_state_next <= CHECKING_IF_RESULT_IS_FFFF;

            when CHECKING_IF_RESULT_IS_FFFF =>     
                if (r_sum_16_reg /= x"FFFF") then
                    r_checksum_state_next <= CALC_WAITED_CHECKSUM;
                else
                    o_waited_checksum <= i_checksum(15 downto 0);
                end if;

            when CALC_WAITED_CHECKSUM =>
                r_sum_16_next <= r_sum_without_checksum_reg(31 downto 16) + r_sum_without_checksum_reg(15 downto 0);
                r_checksum_state_next <= VALUE_WAITED;

            when VALUE_WAITED =>
                o_waited_checksum <= not r_sum_16_reg;
                o_checksum_error <= '1';
                r_checksum_state_next <= END_OF_VALIDATION;

            when END_OF_VALIDATION =>
                if (i_valid = '0') then
                    r_checksum_state_next <=  IDLE;
                end if;
        end case;
    end process;

    Packet_Length_Validation: process(i_payload_length)
    begin
        if (to_integer(unsigned(i_packet_length)) /= ((i_payload_length / 4) + 4)) and (i_ready = '1') then
            o_payload_length_error <= '1';  
        else
            o_payload_length_error <= '0';  
        end if;
        w_o_last <= '1';
    end process;





end arch_validation;



