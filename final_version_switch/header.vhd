library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header is
    Port (
        -- signal for condition states
        i_last                                  : in std_logic;
        i_valid                                 : in std_logic;
        
        clk                                     : in std_logic;
        reset                                   : in std_logic;
        
        i_byte                                  : in std_logic_vector(7 downto 0);
        
        o_packet_length                         : out std_logic_vector(15 downto 0) := x"0000";
        o_checksum                              : out std_logic_vector(15 downto 0) := x"0000";
        o_seqnum                                : out std_logic_vector(31 downto 0) := x"00000000";
        o_flag                                  : out std_logic_vector(7 downto 0) := x"00";
        o_protocol                              : out std_logic_vector(7 downto 0) := x"00";
        o_dummy                                 : out std_logic_vector(15 downto 0) := x"0000";
        o_source_address                        : out std_logic_vector(15 downto 0) := x"0000";
        o_destination_address                   : out std_logic_vector(15 downto 0) := x"0000";

        o_sum_without_checksum_without_payload  : out unsigned(31 downto 0) := x"00000000";
        o_checksum_32bits                       : out unsigned(31 downto 0) := x"00000000";
        o_start_payload                         : out std_logic := '0';
        o_start_validation                      : out std_logic := '0'
        );
end header;

architecture arch_header of header is
    constant c_WIDTH: integer := 1;
    -- possible states
    type t_HEADER_STATE_TYPE is (IDLE, PACKET_LENGTH, CHECKSUM, SEQNUM, flag, PROTOCOL, DUMMY, SOURCE_ADDRESS, DESTINATION_ADDRESS, END_HEADER);
    signal r_header_state_reg, r_header_state_next: t_HEADER_STATE_TYPE := IDLE;
    -- checksum and more
    signal w_extended_part                                                                       : unsigned(31 downto 0) := x"00000000";
    signal r_sum_without_checksum_without_payload_next,r_sum_without_checksum_without_payload_reg: unsigned(31 downto 0) := x"00000000";
    signal r_checksum_32bits_reg, r_checksum_32bits_next                                         : unsigned(31 downto 0) := x"00000000";
    -- counter to entering i_bytes and know the length of the payload
    signal r_internal_counter_reg, r_internal_counter_next                                       : integer := 0;
    -- entering fields
    signal r_packet_length_reg, r_packet_length_next                                             : std_logic_vector(15 downto 0) := x"0000";
    signal r_checksum_reg, r_checksum_next                                                       : std_logic_vector(15 downto 0) := x"0000";
    signal r_seqnum_reg, r_seqnum_next                                                           : std_logic_vector(31 downto 0) := x"00000000";
    signal r_flag_reg, r_flag_next                                                               : std_logic_vector(7 downto 0)  := x"00";
    signal r_protocol_reg, r_protocol_next                                                       : std_logic_vector(7 downto 0)  := x"00";
    signal r_dummy_reg, r_dummy_next                                                             : std_logic_vector(15 downto 0) := x"0000";
    signal r_source_address_reg, r_source_address_next                                           : std_logic_vector(15 downto 0) := x"0000";
    signal r_destination_address_reg, r_destination_address_next                                 : std_logic_vector(15 downto 0) := x"0000";
    signal r_start_payload_reg, r_start_payload_next                                             : std_logic := '0';
    signal r_start_validation_reg, r_start_validation_next                                       : std_logic := '0';

begin
    
    State_Atualization: process(clk, reset)
    begin
        if reset = '1' then
            r_header_state_reg        <= IDLE;
            r_internal_counter_reg    <= 0;
            r_packet_length_reg       <= (others => '0');
            r_checksum_reg            <= (others => '0');
            r_seqnum_reg              <= (others => '0');
            r_flag_reg                <= (others => '0');
            r_protocol_reg            <= (others => '0');
            r_dummy_reg               <= (others => '0');
            r_source_address_reg      <= (others => '0');
            r_destination_address_reg <= (others => '0');
            r_start_payload_reg       <= '0';
            r_start_validation_reg    <= '0';
        end if;

        if rising_edge(clk) and reset = '0' then

            r_header_state_reg                         <= r_header_state_next;
            r_packet_length_reg                        <= r_packet_length_next;
            r_checksum_reg                             <= r_checksum_next;
            r_seqnum_reg                               <= r_seqnum_next;
            r_flag_reg                                 <= r_flag_next;
            r_protocol_reg                             <= r_protocol_next;
            r_dummy_reg                                <= r_dummy_next;
            r_source_address_reg                       <= r_source_address_next;
            r_destination_address_reg                  <= r_destination_address_next;
            r_internal_counter_reg                     <= r_internal_counter_next;
            r_start_payload_reg                        <= r_start_payload_next;
            r_start_validation_reg                     <= r_start_validation_next;
            r_sum_without_checksum_without_payload_reg <= r_sum_without_checksum_without_payload_next;
            r_checksum_32bits_reg                      <= r_checksum_32bits_next;

        end if;
    end process;
    
    State_Transition_Logic: process(r_header_state_reg,r_internal_counter_reg, i_valid, i_last)
    begin

        -- Initialize values
        r_header_state_next     <= r_header_state_reg;
        r_internal_counter_next <= r_internal_counter_reg; 
        r_start_validation_next <= r_start_validation_reg;
        r_start_payload_next    <= r_start_payload_reg;

        case r_header_state_reg is
            when IDLE =>
                if (i_valid = '1' and i_last = '0') then
                    r_header_state_next <= PACKET_LENGTH;                   
                end if;

            when PACKET_LENGTH =>
                r_internal_counter_next <= r_internal_counter_reg + 1;

                if (r_internal_counter_reg = c_WIDTH) then
                    r_header_state_next     <= CHECKSUM;
                    r_internal_counter_next <= 0;
                end if;

            when CHECKSUM =>
                r_internal_counter_next <= r_internal_counter_reg + 1;

                if (r_internal_counter_reg = c_WIDTH) then
                    r_header_state_next     <= SEQNUM;
                    r_internal_counter_next <= 0;
                end if;

            when SEQNUM =>
                r_internal_counter_next <= r_internal_counter_reg + 1;

                if (r_internal_counter_reg = c_WIDTH+2) then
                    r_header_state_next     <= FLAG;
                    r_internal_counter_next <= 0;
                end if;

            when FLAG =>
                r_internal_counter_next <= r_internal_counter_reg + 1;

                if (r_internal_counter_reg = c_WIDTH-1) then
                    r_header_state_next     <= PROTOCOL;
                    r_internal_counter_next <= 0;
                end if;

            when PROTOCOL =>
                r_internal_counter_next <= r_internal_counter_reg + 1;

                if (r_internal_counter_reg = c_WIDTH-1) then 
                    r_header_state_next     <= DUMMY;  
                    r_internal_counter_next <= 0;
                end if;

            when DUMMY =>
                r_internal_counter_next <= r_internal_counter_reg + 1;

                if (r_internal_counter_reg = c_WIDTH) then
                    r_header_state_next     <= SOURCE_ADDRESS;
                    r_internal_counter_next <= 0;
                end if;

            when SOURCE_ADDRESS =>
                r_internal_counter_next <= r_internal_counter_reg + 1;

                if (r_internal_counter_reg = c_WIDTH) then
                    r_header_state_next     <= DESTINATION_ADDRESS;
                    r_internal_counter_next <= 0;
                end if;

            when DESTINATION_ADDRESS =>
                r_internal_counter_next <= r_internal_counter_reg + 1;

                if (r_internal_counter_reg = c_WIDTH and i_last = '0' and i_valid = '1') then
                    r_header_state_next     <= END_HEADER;
                    r_internal_counter_next <= 0;
                    r_start_payload_next    <= '1';
                elsif (r_internal_counter_reg = c_WIDTH and i_last = '1' and i_valid = '1') then
                    r_header_state_next     <= END_HEADER;
                    r_internal_counter_next <= 0;
                    r_start_validation_next <= '1';
                end if;

            when END_HEADER =>
                if (reset = '1') then
                    r_header_state_next <= IDLE;
                end if;

        end case;
    end process;

    State_Attribution_Logic: process(i_byte,r_header_state_reg, r_packet_length_reg,r_checksum_reg,r_seqnum_reg,r_flag_reg,
    r_protocol_reg,r_dummy_reg,r_source_address_reg,r_destination_address_reg)
    begin
        
        -- Initialize values
        r_packet_length_next                         <= r_packet_length_reg;
        r_checksum_next                              <= r_checksum_reg;
        r_seqnum_next                                <= r_seqnum_reg;
        r_flag_next                                  <= r_flag_reg;
        r_protocol_next                              <= r_protocol_reg;
        r_dummy_next                                 <= r_dummy_reg;
        r_source_address_next                        <= r_source_address_reg;
        r_destination_address_next                   <= r_destination_address_reg;
        r_sum_without_checksum_without_payload_next  <= r_sum_without_checksum_without_payload_reg;
        r_checksum_32bits_next                       <= r_checksum_32bits_reg;

        case r_header_state_reg is
            when IDLE =>

            when PACKET_LENGTH =>
                r_packet_length_next <= r_packet_length_reg(7 downto 0) & i_byte;

            when CHECKSUM =>
                r_checksum_next <= r_checksum_reg(7 downto 0) & i_byte;

            when SEQNUM =>
                r_seqnum_next <= r_seqnum_reg(23 downto 0) & i_byte;

            when FLAG =>
                r_flag_next <= i_byte;

            when PROTOCOL =>
                r_protocol_next <= i_byte;

            when DUMMY =>
                r_dummy_next <= r_dummy_reg(7 downto 0) & i_byte;

            when SOURCE_ADDRESS =>
                r_source_address_next <= r_source_address_reg(7 downto 0) & i_byte;

            when DESTINATION_ADDRESS =>
                r_destination_address_next <= r_destination_address_reg(7 downto 0) & i_byte;

            when END_HEADER =>
                r_sum_without_checksum_without_payload_next <= (w_extended_part(15 downto 0) & unsigned(r_packet_length_reg)) 
                                                            + (w_extended_part(15 downto 0) & unsigned(r_seqnum_reg(15 downto 0)))
                                                            + (w_extended_part(15 downto 0) & unsigned(r_seqnum_reg(31 downto 16))) 
                                                            + (w_extended_part(15 downto 0) & unsigned((r_flag_reg & r_protocol_reg))) 
                                                            + (w_extended_part(15 downto 0) & unsigned(r_dummy_reg))
                                                            + (w_extended_part(15 downto 0) & unsigned(r_source_address_reg)) 
                                                            + (w_extended_part(15 downto 0) & unsigned(r_destination_address_reg));
 
                r_checksum_32bits_next <= (w_extended_part(15 downto 0) & unsigned(r_checksum_reg));
        end case;  
    end process;

    o_packet_length                         <= r_packet_length_reg;
    o_checksum                              <= r_checksum_reg;
    o_seqnum                                <= r_seqnum_reg;
    o_flag                                  <= r_flag_reg;
    o_protocol                              <= r_protocol_reg;
    o_dummy                                 <= r_dummy_reg;
    o_source_address                        <= r_source_address_reg;
    o_destination_address                   <= r_destination_address_reg;
    o_sum_without_checksum_without_payload  <= r_sum_without_checksum_without_payload_reg;
    o_checksum_32bits                       <= r_checksum_32bits_reg;
    o_start_payload                         <= r_start_payload_reg;
    o_start_validation                      <= r_start_validation_reg;
    

end arch_header;
