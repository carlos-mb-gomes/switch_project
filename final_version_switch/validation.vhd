library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity validation is
    Port (
        i_start_validation_from_header        : in std_logic;
        i_start_validation_from_payload       : in std_logic;
        clk                                   : in std_logic;
        reset                                 : in std_logic;

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
    signal r_checksum_state_reg, r_checksum_state_next              : t_CHECKSUM_STATE_TYPE := IDLE;
    signal r_payload_length_state_reg, r_payload_length_state_next  : t_PAYLOAD_LENGTH_STATE_TYPE := IDLE;
    signal r_sum_32_reg, r_sum_32_next                              : unsigned(31 downto 0):= x"00000000";
    signal r_sum_16_reg, r_sum_16_next                              : unsigned(15 downto 0):= x"0000";
    signal r_sum_without_checksum_reg, r_sum_without_checksum_next  : unsigned(31 downto 0) := x"00000000";
    signal r_waited_checksum_reg, r_waited_checksum_next            : unsigned(15 downto 0):= x"0000";
    signal r_payload_length_error_reg, r_payload_length_error_next  : std_logic:= '0';
    signal r_checksum_error_reg, r_checksum_error_next              : std_logic:= '0';
    signal r_start_output_reg, r_start_output_next                  : std_logic:= '0';
    signal r_sum_payload_reg, r_sum_payload_next                    : unsigned(31 downto 0)        := x"00000000";
    signal r_packet_int_reg, r_packet_int_next                      : integer := 0;
    signal r_payload_int_reg, r_payload_int_next                    : integer := 0;
    signal r_waited_packet_length_next, r_waited_packet_length_reg : std_logic_vector(15 downto 0) := x"0000";

begin    

    State_atualization: process(clk, reset)
    begin
        if reset = '1' then
            r_checksum_state_reg        <= IDLE;
            r_payload_length_state_reg  <= IDLE;
            r_payload_length_error_reg  <= '0';
            r_checksum_error_reg        <= '0';
            r_waited_checksum_reg       <= (others => '0');
            r_packet_int_reg            <= 0;
            r_payload_int_reg           <= 0;
            r_waited_packet_length_reg  <= (others => '0');
            r_start_output_reg          <= '0';
        
        end if;

        if rising_edge(clk) and reset = '0' then
            r_sum_without_checksum_reg  <= r_sum_without_checksum_next;
            r_sum_32_reg                <= r_sum_32_next;
            r_sum_16_reg                <= r_sum_16_next;
            r_checksum_state_reg        <= r_checksum_state_next;
            r_waited_checksum_reg       <= r_waited_checksum_next;
            r_payload_length_error_reg  <= r_payload_length_error_next;
            r_checksum_error_reg        <= r_checksum_error_next;  
            r_start_output_reg          <= r_start_output_next;
            r_sum_payload_reg           <= r_sum_payload_next;
            r_packet_int_reg            <= r_packet_int_next;
            r_payload_int_reg           <= r_payload_int_next;
            r_payload_length_state_reg  <= r_payload_length_state_next;
            r_waited_packet_length_reg  <= r_waited_packet_length_next;
        end if;
    end process;
    

    Checksum_State_Attribution_Logic: process(i_ready, i_checksum,i_sum_without_checksum_without_payload,i_sum_payload,r_checksum_state_reg,
    r_sum_without_checksum_reg, r_sum_32_reg, r_sum_16_reg, r_waited_checksum_reg, r_payload_length_error_reg, r_checksum_error_reg)
    begin
        r_sum_without_checksum_next <= r_sum_without_checksum_reg;
        r_sum_32_next               <= r_sum_32_reg;
        r_sum_16_next               <= r_sum_16_reg;
        r_waited_checksum_next      <= r_waited_checksum_reg;
        r_checksum_error_next       <= r_checksum_error_reg;
        r_sum_payload_next          <= r_sum_payload_reg;

        
            case r_checksum_state_reg is
                when IDLE =>
                    if (i_start_validation_from_header = '1' or i_start_validation_from_payload = '1') and i_ready = '1' then
                        r_sum_payload_next <= i_sum_payload;
                    end if;

                when SUM_WITHOUT_CHECKSUM =>
                    r_sum_without_checksum_next <= i_sum_without_checksum_without_payload + i_sum_payload;
                
                when SUM_ALL_FIELDS =>
                    r_sum_32_next <= r_sum_without_checksum_reg + i_checksum;
                
                when SUM_WITH_CARRY =>
                    r_sum_16_next <= r_sum_32_reg(31 downto 16) + r_sum_32_reg(15 downto 0);

                when CHECKING_IF_RESULT_IS_FFFF =>     
                    if (r_sum_16_reg = x"FFFF") then
                        r_waited_checksum_next <= i_checksum(15 downto 0);
                    end if;

                when CALC_WAITED_CHECKSUM =>
                    r_sum_16_next <= r_sum_without_checksum_reg(31 downto 16) + r_sum_without_checksum_reg(15 downto 0);

                when VALUE_WAITED =>
                    r_waited_checksum_next <= not r_sum_16_reg;
                    r_checksum_error_next <= '1';

                when END_OF_VALIDATION =>

            end case;
    end process;

    Checksum_State_Transition_Logic: process(i_o_ready,i_ready, i_start_validation_from_header,i_start_validation_from_payload,
    r_sum_16_reg,r_checksum_state_reg,r_start_output_reg)
    begin
        r_checksum_state_next <= r_checksum_state_reg;
        r_start_output_next <= r_start_output_reg;

        case r_checksum_state_reg is
            when IDLE =>
                if i_o_ready = '1' then
                    r_start_output_next <= '0';
                end if;

                if (i_start_validation_from_header = '1' or i_start_validation_from_payload = '1') and i_ready = '1' then
                    r_checksum_state_next <= SUM_WITHOUT_CHECKSUM;
                end if;

            when SUM_WITHOUT_CHECKSUM =>
                r_checksum_state_next <= SUM_ALL_FIELDS;

            when SUM_ALL_FIELDS =>
                r_checksum_state_next <= SUM_WITH_CARRY;
            
            when SUM_WITH_CARRY =>
                r_checksum_state_next <= CHECKING_IF_RESULT_IS_FFFF;

            when CHECKING_IF_RESULT_IS_FFFF =>     
                if (r_sum_16_reg /= x"FFFF") then
                    r_checksum_state_next <= CALC_WAITED_CHECKSUM;
                end if;
                r_start_output_next <= '1';
                if (reset = '1') then
                    r_checksum_state_next <=  IDLE;
                end if;

            when CALC_WAITED_CHECKSUM =>
                r_checksum_state_next <= VALUE_WAITED;

            when VALUE_WAITED =>
                r_checksum_state_next <= END_OF_VALIDATION;

            when END_OF_VALIDATION =>
                r_start_output_next <= '1';

        end case;
    end process;

    Payload_Length_State_Attribution_Logic: process(i_packet_length,i_payload_length,r_waited_packet_length_reg,r_packet_int_reg,
    r_payload_int_reg,r_payload_length_error_reg,r_payload_length_state_reg)
    begin
        r_packet_int_next           <= r_packet_int_reg;
        r_payload_int_next          <= r_payload_int_reg;
        r_payload_length_error_next <= r_payload_length_error_reg;
        r_waited_packet_length_next <= r_waited_packet_length_reg;

        case r_payload_length_state_reg is
            when IDLE =>

            when GET_VALUES =>
                r_packet_int_next <= to_integer(unsigned(i_packet_length));
                r_payload_int_next <= i_payload_length;

            when TEST_CONDITION =>
                if ((r_packet_int_reg*4 < (r_payload_int_reg + 16)) or ((r_payload_int_reg + 16) <= (r_packet_int_reg-1)*4)) then
                    r_payload_length_error_next <= '1';  
                end if;
                
                if r_payload_int_reg mod 4 = 0 then
                    r_waited_packet_length_next <=  std_logic_vector(to_unsigned((r_payload_int_reg + 16)/4,16));
                else 
                    r_waited_packet_length_next <=  std_logic_vector(to_unsigned((r_payload_int_reg + 20 - (r_payload_int_reg mod 4))/4,16)); 
                end if;
                
            when END_OF_VALIDATION =>

        end case;
    end process;

    Payload_Length_State_Transition_Logic: process(i_ready, i_start_validation_from_header,i_start_validation_from_payload,r_payload_length_state_reg)
    begin
        r_payload_length_state_next <= r_payload_length_state_reg;

        case r_payload_length_state_reg is
            when IDLE =>
                if (i_start_validation_from_header = '1' or i_start_validation_from_payload = '1') and i_ready = '1' then
                    r_payload_length_state_next <= GET_VALUES;
                end if;

            when GET_VALUES =>
                r_payload_length_state_next <= TEST_CONDITION;

            when TEST_CONDITION =>
                r_payload_length_state_next <= END_OF_VALIDATION;
            
            when END_OF_VALIDATION =>

        end case;
    end process;

    o_waited_checksum       <= std_logic_vector(r_waited_checksum_reg);
    o_checksum_error        <= r_checksum_error_reg;
    o_payload_length_error  <= r_payload_length_error_reg;
    o_start_output          <= r_start_output_reg;
    o_waited_packet_length  <= r_waited_packet_length_reg;

end arch_validation;



