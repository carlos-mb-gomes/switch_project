library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header is
    Port (
        -- signal for condition states
        clk                                     : in std_logic;
        reset                                   : in std_logic;
        
        i_last                                  : in std_logic;
        i_valid                                 : in std_logic;
        
        i_byte                                  : in std_logic_vector(7 downto 0);
        
        o_packet_length                         : out std_logic_vector(15 downto 0) := x"0000";
        o_checksum                              : out std_logic_vector(15 downto 0) := x"0000";
        o_seqnum                                : out std_logic_vector(31 downto 0) := x"00000000";
        o_flag                                  : out std_logic_vector(7 downto 0) := x"00";
        o_protocol                              : out std_logic_vector(7 downto 0) := x"00";
        o_dummy                                 : out std_logic_vector(15 downto 0) := x"0000";
        o_source_address                        : out std_logic_vector(15 downto 0) := x"0000";
        o_destination_address                   : out std_logic_vector(15 downto 0) := x"0000";

        o_start_payload                         : out std_logic := '0';

        o_sum_without_checksum_without_payload  : out unsigned(31 downto 0) := x"00000000";
        o_checksum_32bits                       : out unsigned(31 downto 0) := x"00000000";
        o_start_validation                      : out std_logic := '0'
        );
end header;

architecture arch_header of header is
    constant c_WIDTH: integer := 1;
    -- possible states
    type t_HEADER_STATE_TYPE is (IDLE, PACKET_LENGTH, CHECKSUM, SEQNUM, flag, PROTOCOL, DUMMY, SOURCE_ADDRESS, DESTINATION_ADDRESS, END_HEADER);
    signal header_state_reg, header_state_next: t_HEADER_STATE_TYPE := IDLE;
    -- aux validation
    signal w_extended_part                                                                   : unsigned(31 downto 0) := x"00000000";
    signal sum_without_checksum_without_payload_next,sum_without_checksum_without_payload_reg: unsigned(31 downto 0) := x"00000000";
    signal checksum_converted_32bits_reg, checksum_converted_32bits_next                     : unsigned(31 downto 0) := x"00000000";
    -- counter to entering i_bytes
    signal internal_counter_reg, internal_counter_next                                       : integer := 0;
    -- entering fields
    signal packet_length_reg, packet_length_next                                             : std_logic_vector(15 downto 0) := x"0000";
    signal checksum_reg, checksum_next                                                       : std_logic_vector(15 downto 0) := x"0000";
    signal seqnum_reg, seqnum_next                                                           : std_logic_vector(31 downto 0) := x"00000000";
    signal flag_reg, flag_next                                                               : std_logic_vector(7 downto 0)  := x"00";
    signal protocol_reg, protocol_next                                                       : std_logic_vector(7 downto 0)  := x"00";
    signal dummy_reg, dummy_next                                                             : std_logic_vector(15 downto 0) := x"0000";
    signal source_address_reg, source_address_next                                           : std_logic_vector(15 downto 0) := x"0000";
    signal destination_address_reg, destination_address_next                                 : std_logic_vector(15 downto 0) := x"0000";
    signal start_payload_reg, start_payload_next                                             : std_logic := '0';
    signal start_validation_reg, start_validation_next                                       : std_logic := '0';

begin
    
    State_Atualization: process(clk, reset)
    begin
        if reset = '1' then
            header_state_reg        <= IDLE;
            -- não é necessário resetá-los
            packet_length_reg       <= (others => '0');
            checksum_reg            <= (others => '0');
            seqnum_reg              <= (others => '0');
            flag_reg                <= (others => '0');
            protocol_reg            <= (others => '0');
            dummy_reg               <= (others => '0');
            source_address_reg      <= (others => '0');
            destination_address_reg <= (others => '0');

            internal_counter_reg    <= 0;
            
            start_payload_reg       <= '0';
            start_validation_reg    <= '0';
        end if;

        if rising_edge(clk) and reset = '0' then

            header_state_reg                         <= header_state_next;

            packet_length_reg                        <= packet_length_next;
            checksum_reg                             <= checksum_next;
            seqnum_reg                               <= seqnum_next;
            flag_reg                                 <= flag_next;
            protocol_reg                             <= protocol_next;
            dummy_reg                                <= dummy_next;
            source_address_reg                       <= source_address_next;
            destination_address_reg                  <= destination_address_next;

            internal_counter_reg                     <= internal_counter_next;

            start_payload_reg                        <= start_payload_next;

            start_validation_reg                     <= start_validation_next;
            sum_without_checksum_without_payload_reg <= sum_without_checksum_without_payload_next;
            checksum_converted_32bits_reg            <= checksum_converted_32bits_next;

        end if;
    end process;
    
    State_Transition_Logic: process(header_state_reg,internal_counter_reg, i_valid, i_last)
    begin

        -- Initialize values
        header_state_next     <= header_state_reg;
        internal_counter_next <= internal_counter_reg; 
        start_validation_next <= start_validation_reg;
        start_payload_next    <= start_payload_reg;

        case header_state_reg is
            when IDLE =>
                if (i_valid = '1' and i_last = '0') then
                    header_state_next <= PACKET_LENGTH;                   
                end if;

            when PACKET_LENGTH =>
                internal_counter_next <= internal_counter_reg + 1;

                if (internal_counter_reg = c_WIDTH) then
                    header_state_next     <= CHECKSUM;
                    internal_counter_next <= 0;
                end if;

            when CHECKSUM =>
                internal_counter_next <= internal_counter_reg + 1;

                if (internal_counter_reg = c_WIDTH) then
                    header_state_next     <= SEQNUM;
                    internal_counter_next <= 0;
                end if;

            when SEQNUM =>
                internal_counter_next <= internal_counter_reg + 1;

                if (internal_counter_reg = c_WIDTH+2) then
                    header_state_next     <= FLAG;
                    internal_counter_next <= 0;
                end if;

            when FLAG =>
                internal_counter_next <= internal_counter_reg + 1;

                if (internal_counter_reg = c_WIDTH-1) then
                    header_state_next     <= PROTOCOL;
                    internal_counter_next <= 0;
                end if;

            when PROTOCOL =>
                internal_counter_next <= internal_counter_reg + 1;

                if (internal_counter_reg = c_WIDTH-1) then 
                    header_state_next     <= DUMMY;  
                    internal_counter_next <= 0;
                end if;

            when DUMMY =>
                internal_counter_next <= internal_counter_reg + 1;

                if (internal_counter_reg = c_WIDTH) then
                    header_state_next     <= SOURCE_ADDRESS;
                    internal_counter_next <= 0;
                end if;

            when SOURCE_ADDRESS =>
                internal_counter_next <= internal_counter_reg + 1;

                if (internal_counter_reg = c_WIDTH) then
                    header_state_next     <= DESTINATION_ADDRESS;
                    internal_counter_next <= 0;
                end if;

            when DESTINATION_ADDRESS =>
                internal_counter_next <= internal_counter_reg + 1;

                if (internal_counter_reg = c_WIDTH and i_last = '0' and i_valid = '1') then
                    header_state_next     <= END_HEADER;
                    internal_counter_next <= 0;
                    start_payload_next    <= '1';
                elsif (internal_counter_reg = c_WIDTH and i_last = '1' and i_valid = '1') then
                    header_state_next     <= END_HEADER;
                    internal_counter_next <= 0;
                    start_validation_next <= '1';
                end if;

            when END_HEADER =>
                if (reset = '1') then
                    header_state_next <= IDLE;
                end if;

            when others =>
        end case;
    end process;

    State_Attribution_Logic: process(i_byte,header_state_reg, packet_length_reg,checksum_reg,seqnum_reg,flag_reg,protocol_reg,dummy_reg,source_address_reg,
    destination_address_reg)
    begin
        
        -- Initialize values
        packet_length_next                         <= packet_length_reg;
        checksum_next                              <= checksum_reg;
        seqnum_next                                <= seqnum_reg;
        flag_next                                  <= flag_reg;
        protocol_next                              <= protocol_reg;
        dummy_next                                 <= dummy_reg;
        source_address_next                        <= source_address_reg;
        destination_address_next                   <= destination_address_reg;
        sum_without_checksum_without_payload_next  <= sum_without_checksum_without_payload_reg;
        checksum_converted_32bits_next             <= checksum_converted_32bits_reg;

        case header_state_reg is
            when IDLE =>

            when PACKET_LENGTH =>
                packet_length_next <= packet_length_reg(7 downto 0) & i_byte;

            when CHECKSUM =>
                checksum_next <= checksum_reg(7 downto 0) & i_byte;

            when SEQNUM =>
                seqnum_next <= seqnum_reg(23 downto 0) & i_byte;

            when FLAG =>
                flag_next <= i_byte;

            when PROTOCOL =>
                protocol_next <= i_byte;

            when DUMMY =>
                dummy_next <= dummy_reg(7 downto 0) & i_byte;

            when SOURCE_ADDRESS =>
                source_address_next <= source_address_reg(7 downto 0) & i_byte;

            when DESTINATION_ADDRESS =>
                destination_address_next <= destination_address_reg(7 downto 0) & i_byte;

            when END_HEADER =>
                sum_without_checksum_without_payload_next <= (w_extended_part(15 downto 0) & unsigned(packet_length_reg)) 
                                                            + (w_extended_part(15 downto 0) & unsigned(seqnum_reg(15 downto 0)))
                                                            + (w_extended_part(15 downto 0) & unsigned(seqnum_reg(31 downto 16))) 
                                                            + (w_extended_part(15 downto 0) & unsigned((flag_reg & protocol_reg))) 
                                                            + (w_extended_part(15 downto 0) & unsigned(dummy_reg))
                                                            + (w_extended_part(15 downto 0) & unsigned(source_address_reg)) 
                                                            + (w_extended_part(15 downto 0) & unsigned(destination_address_reg));
 
                checksum_converted_32bits_next <= (w_extended_part(15 downto 0) & unsigned(checksum_reg));
            
            when others =>
        end case;  
    end process;

    -- Output Atualization
    -- header fields
    o_packet_length                         <= packet_length_reg;
    o_checksum                              <= checksum_reg;
    o_seqnum                                <= seqnum_reg;
    o_flag                                  <= flag_reg;
    o_protocol                              <= protocol_reg;
    o_dummy                                 <= dummy_reg;
    o_source_address                        <= source_address_reg;
    o_destination_address                   <= destination_address_reg;

    -- aux validation
    o_sum_without_checksum_without_payload  <= sum_without_checksum_without_payload_reg;
    o_checksum_32bits                       <= checksum_converted_32bits_reg;
    o_start_validation                      <= start_validation_reg;
    
    -- aux payload
    o_start_payload                         <= start_payload_reg;
    

end arch_header;
