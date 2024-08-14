library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity validation is
    Port (
        clk                                   : in std_logic;
        reset                                 : in std_logic;

        i_start_validation_from_header        : in std_logic;
        i_start_validation_from_payload       : in std_logic;

        i_o_ready                             : in std_logic;
        i_ready                               : in std_logic;
        i_sum_payload                         : in unsigned(31 downto 0)         := x"00000000";
        i_checksum                            : in unsigned(31 downto 0)         := x"00000000";
        i_sum_without_checksum_without_payload: in unsigned(31 downto 0)         := x"00000000";
        o_waited_checksum                     : out std_logic_vector(15 downto 0):= x"0000";
        o_checksum_error                      : out std_logic                    := '0';

        i_packet_length                       : in std_logic_vector(15 downto 0) := x"0000"; 
        i_payload_length                      : in integer                       := 0;
        o_start_output                        : out std_logic                    := '0';
        o_payload_length_error                : out std_logic                    := '0';
        o_waited_packet_length                : out std_logic_vector(15 downto 0):= x"0000"
    );
end validation;

architecture arch_validation of validation is
    type t_CHECKSUM_STATE_TYPE is (IDLE,SUM_WITHOUT_CHECKSUM, SUM_ALL_FIELDS, SUM_WITH_CARRY, CHECKING_IF_RESULT_IS_FFFF, CALC_WAITED_CHECKSUM,
    VALUE_WAITED, END_OF_VALIDATION);
    type t_PAYLOAD_LENGTH_STATE_TYPE is (IDLE,GET_VALUES,TEST_CONDITION,END_OF_VALIDATION);
    signal checksum_state_reg, checksum_state_next                 : t_CHECKSUM_STATE_TYPE := IDLE;
    signal payload_length_state_reg, payload_length_state_next     : t_PAYLOAD_LENGTH_STATE_TYPE := IDLE;
    signal sum_32bits_reg, sum_32bits_next                         : unsigned(31 downto 0):= x"00000000";
    signal sum_16bits_reg, sum_16bits_next                         : unsigned(15 downto 0):= x"0000";
    signal sum_without_checksum_reg, sum_without_checksum_next     : unsigned(31 downto 0) := x"00000000";
    signal expected_checksum_reg, expected_checksum_next           : unsigned(15 downto 0):= x"0000";
    signal payload_length_error_reg, payload_length_error_next     : std_logic:= '0';
    signal checksum_error_reg, checksum_error_next                 : std_logic:= '0';
    signal start_output_reg, start_output_next                     : std_logic:= '0';
    signal sum_payload_reg, sum_payload_next                       : unsigned(31 downto 0) := x"00000000";
    signal packet_converted_int_reg, packet_converted_int_next     : integer := 0;
    signal payload_converted_int_reg, payload_converted_int_next   : integer := 0;
    signal expected_packet_length_next, expected_packet_length_reg : std_logic_vector(15 downto 0) := x"0000";

begin    

    State_atualization: process(clk, reset)
    begin
        if reset = '1' then
            checksum_state_reg        <= IDLE;
            payload_length_state_reg  <= IDLE;

            checksum_error_reg        <= '0';
            expected_checksum_reg     <= (others => '0');

            packet_converted_int_reg   <= 0;
            payload_converted_int_reg  <= 0;
            payload_length_error_reg   <= '0';
            expected_packet_length_reg <= (others => '0');

            start_output_reg           <= '0';
        
        end if;

        if rising_edge(clk) and reset = '0' then
            checksum_state_reg        <= checksum_state_next;
            sum_payload_reg           <= sum_payload_next;
            sum_without_checksum_reg  <= sum_without_checksum_next;
            sum_32bits_reg            <= sum_32bits_next;
            sum_16bits_reg            <= sum_16bits_next;
            checksum_error_reg        <= checksum_error_next;  
            expected_checksum_reg     <= expected_checksum_next;

            payload_length_error_reg   <= payload_length_error_next;
            packet_converted_int_reg   <= packet_converted_int_next;
            payload_converted_int_reg  <= payload_converted_int_next;
            payload_length_state_reg   <= payload_length_state_next;
            expected_packet_length_reg <= expected_packet_length_next;
            start_output_reg           <= start_output_next;
        end if;
    end process;
    

    Checksum_State_Attribution_Logic: process(i_ready, i_checksum,i_sum_without_checksum_without_payload,i_sum_payload,checksum_state_reg,
    sum_without_checksum_reg, sum_32bits_reg, sum_16bits_reg, expected_checksum_reg, payload_length_error_reg, checksum_error_reg)
    begin
        sum_payload_next          <= sum_payload_reg;
        sum_without_checksum_next <= sum_without_checksum_reg;
        sum_32bits_next           <= sum_32bits_reg;
        sum_16bits_next           <= sum_16bits_reg;
        expected_checksum_next    <= expected_checksum_reg;
        checksum_error_next       <= checksum_error_reg;

        
            case checksum_state_reg is
                when IDLE =>
                    if (i_start_validation_from_header = '1' or i_start_validation_from_payload = '1') and i_ready = '1' then
                        sum_payload_next <= i_sum_payload;
                    end if;

                when SUM_WITHOUT_CHECKSUM =>
                    sum_without_checksum_next <= i_sum_without_checksum_without_payload + i_sum_payload;
                
                when SUM_ALL_FIELDS =>
                    sum_32bits_next <= sum_without_checksum_reg + i_checksum;
                
                when SUM_WITH_CARRY =>
                    sum_16bits_next <= sum_32bits_reg(31 downto 16) + sum_32bits_reg(15 downto 0);

                when CHECKING_IF_RESULT_IS_FFFF =>     
                    if (sum_16bits_reg = x"FFFF") then
                        expected_checksum_next <= i_checksum(15 downto 0);
                    end if;

                when CALC_WAITED_CHECKSUM =>
                    sum_16bits_next <= sum_without_checksum_reg(31 downto 16) + sum_without_checksum_reg(15 downto 0);

                when VALUE_WAITED =>
                    expected_checksum_next <= not sum_16bits_reg;
                    checksum_error_next <= '1';

                when END_OF_VALIDATION =>

            end case;
    end process;

    Checksum_State_Transition_Logic: process(i_o_ready,i_ready, i_start_validation_from_header,i_start_validation_from_payload, sum_16bits_reg,
    checksum_state_reg,start_output_reg)
    begin
        checksum_state_next <= checksum_state_reg;
        start_output_next <= start_output_reg;

        case checksum_state_reg is
            when IDLE =>
                if i_o_ready = '1' then
                    start_output_next <= '0';
                end if;

                if (i_start_validation_from_header = '1' or i_start_validation_from_payload = '1') and i_ready = '1' then
                    checksum_state_next <= SUM_WITHOUT_CHECKSUM;
                end if;

            when SUM_WITHOUT_CHECKSUM =>
                checksum_state_next <= SUM_ALL_FIELDS;

            when SUM_ALL_FIELDS =>
                checksum_state_next <= SUM_WITH_CARRY;
            
            when SUM_WITH_CARRY =>
                checksum_state_next <= CHECKING_IF_RESULT_IS_FFFF;

            when CHECKING_IF_RESULT_IS_FFFF =>     
                if (sum_16bits_reg /= x"FFFF") then
                    checksum_state_next <= CALC_WAITED_CHECKSUM;
                end if;
                start_output_next <= '1';
                if (reset = '1') then
                    checksum_state_next <=  IDLE;
                end if;

            when CALC_WAITED_CHECKSUM =>
                checksum_state_next <= VALUE_WAITED;

            when VALUE_WAITED =>
                checksum_state_next <= END_OF_VALIDATION;

            when END_OF_VALIDATION =>
                start_output_next <= '1';

        end case;
    end process;

    Payload_Length_State_Attribution_Logic: process(i_packet_length,i_payload_length,expected_packet_length_reg,packet_converted_int_reg,
    payload_converted_int_reg,payload_length_error_reg,payload_length_state_reg)
    begin
        packet_converted_int_next           <= packet_converted_int_reg;
        payload_converted_int_next          <= payload_converted_int_reg;
        payload_length_error_next           <= payload_length_error_reg;
        expected_packet_length_next         <= expected_packet_length_reg;

        case payload_length_state_reg is
            when IDLE =>

            when GET_VALUES =>
                packet_converted_int_next  <= to_integer(unsigned(i_packet_length));
                payload_converted_int_next <= i_payload_length;

            when TEST_CONDITION =>
                if ((packet_converted_int_reg*4 < (payload_converted_int_reg + 16)) or ((payload_converted_int_reg + 16) <= (packet_converted_int_reg-1)*4)) then
                    payload_length_error_next <= '1';  
                end if;
                
                if payload_converted_int_reg mod 4 = 0 then
                    expected_packet_length_next <=  std_logic_vector(to_unsigned((payload_converted_int_reg + 16)/4,16));
                else 
                    expected_packet_length_next <=  std_logic_vector(to_unsigned((payload_converted_int_reg + 20 - (payload_converted_int_reg mod 4))/4,16)); 
                end if;
                
            when END_OF_VALIDATION =>

        end case;
    end process;

    Payload_Length_State_Transition_Logic: process(i_ready, i_start_validation_from_header,i_start_validation_from_payload,payload_length_state_reg)
    begin
        payload_length_state_next <= payload_length_state_reg;

        case payload_length_state_reg is
            when IDLE =>
                if (i_start_validation_from_header = '1' or i_start_validation_from_payload = '1') and i_ready = '1' then
                    payload_length_state_next <= GET_VALUES;
                end if;

            when GET_VALUES =>
                payload_length_state_next <= TEST_CONDITION;

            when TEST_CONDITION =>
                payload_length_state_next <= END_OF_VALIDATION;
            
            when END_OF_VALIDATION =>

        end case;
    end process;

    o_waited_checksum       <= std_logic_vector(expected_checksum_reg);
    o_checksum_error        <= checksum_error_reg;
    o_payload_length_error  <= payload_length_error_reg;
    o_start_output          <= start_output_reg;
    o_waited_packet_length  <= expected_packet_length_reg;

end arch_validation;



