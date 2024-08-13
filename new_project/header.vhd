library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header is
    Port (
        -- signal for condition states
        i_ports: in std_logic_vector(4 downto 0);
        i_byte: in std_logic_vector(7 downto 0);
        clk: in std_logic;

        i_last: in std_logic;
        i_o_ready: in std_logic;
        i_valid: in std_logic;


        i_ready:in std_logic;
        i_o_valid: in std_logic;
        i_o_last: in std_logic;    

        -- fields
        o_packet_length: out std_logic_vector(15 downto 0);
        o_checksum: out std_logic_vector(15 downto 0);
        o_seqnum: out std_logic_vector(31 downto 0); 
        o_flag: out std_logic_vector(7 downto 0);
        o_protocol: out std_logic_vector(7 downto 0);
        o_dummy: out std_logic_vector(15 downto 0);
        o_source_address: out std_logic_vector(15 downto 0);   
        o_destination_address: out std_logic_vector(15 downto 0)
        
        -- payload component
        );
end header;

architecture arch_header of header is
    constant c_WIDTH: integer := 1;
    -- possible states
    type t_HEADER_STATE_TYPE is (IDLE, PACKET_LENGTH, CHECKSUM, SEQNUM, flag, PROTOCOL, DUMMY, SOURCE_ADDRESS, DESTINATION_ADDRESS, END_HEADER);
    signal r_header_state_reg, r_header_state_next: t_HEADER_STATE_TYPE := IDLE;
    -- checksum and more
    signal w_extended_part : unsigned(31 downto 0) := x"00000000";
    signal w_sum_without_checksum_without_payload: unsigned(31 downto 0) := x"00000000";
    -- counter to entering i_bytes and know the length of the payload
    signal r_internal_counter_reg, r_internal_counter_next: integer := 0;
    -- entering fields
    signal r_packet_length_reg, r_packet_length_next : std_logic_vector(15 downto 0) := x"0000";
    signal r_checksum_reg, r_checksum_next : std_logic_vector(15 downto 0) := x"0000";
    signal r_seqnum_reg, r_seqnum_next : std_logic_vector(31 downto 0) := x"00000000";
    signal r_flag_reg, r_flag_next : std_logic_vector(7 downto 0) := x"00";
    signal r_protocol_reg, r_protocol_next : std_logic_vector(7 downto 0) := x"00";
    signal r_dummy_reg, r_dummy_next : std_logic_vector(15 downto 0) := x"0000";
    signal r_source_address_reg, r_source_address_next : std_logic_vector(15 downto 0) := x"0000";
    signal r_destination_address_reg, r_destination_address_next : std_logic_vector(15 downto 0) := x"0000";
    signal r_start_payload_reg, r_start_payload_next: std_logic := '0';
    signal w_checksum_32bits: unsigned(31 downto 0) := x"00000000";
    signal w_sum_payload: unsigned(31 downto 0) := x"00000000";
    signal w_payload_length: integer :=0;
    --

    component payload_entity is 
    port (
        -- input data
        clk: in std_logic;
        i_Valid: in std_logic;
        i_o_ready: in std_logic;
        i_last: in std_logic;
        i_byte: in std_logic_vector(7 downto 0);

        i_ready: in std_logic;
        i_o_valid: in std_logic;
        i_o_last: in std_logic; 

        --payload
        i_start_payload: in std_logic:= '0' ;
        o_payload: out std_logic_vector(3839 downto 0);
        o_sum_payload: out unsigned(31 downto 0);
        -- payload length
        o_payload_length : out integer :=0
    );
    end component;

    component validation is
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
    end component;

    -- component route_table is
    --     Port (
    --         -- input data
    --         clk: in std_logic;
    --         i_valid, i_last: in std_logic;
    --         i_o_ready: in std_logic;
            
    --         i_ready: in std_logic;
    --         i_o_valid: in std_logic;
    --         i_o_last: in std_logic;
    --         -- o_dest_port: in std_logic_vector(4 downto 0) := "00000";
    
    --         -- ports
    --         i_flag: in std_logic_vector(7 downto 0) := x"00";
    --         i_ports: in std_logic_vector(4 downto 0) := "00000";
    --         i_seqnum: in std_logic_vector(31 downto 0) := x"00000000";
    --         i_source_address: in std_logic_vector(15 downto 0) := x"0000";
    --         i_destination_address: in std_logic_vector(15 downto 0) := x"0000"
    --         );
    -- end component;

begin

    -- route_table_module: route_table
    --     port map(
    --         clk => clk,
    --         i_valid => i_valid,
    --         i_last => i_last,
    --         i_o_ready => i_o_ready,
    --         i_ready => i_ready,
    --         i_o_valid => i_o_valid,
    --         i_o_last => i_o_last,
    --         i_flag => r_flag_reg,
    --         i_ports => i_ports,
    --         i_seqnum => r_seqnum_reg,
    --         i_source_address => r_source_address_reg,
    --         i_destination_address => r_destination_address_reg
    --         );


    payload_module: payload_entity
    port map(
        clk => clk,
        i_byte => i_byte,
        i_Valid => i_Valid,
        i_o_ready => i_o_ready,
        i_Last => i_Last,

        i_ready => i_ready,
        i_o_valid => i_o_valid,
        i_o_last => i_o_last,
        -- payload 
        i_start_payload => r_start_payload_reg,
        o_payload => open,
        o_sum_payload => w_sum_payload,
        -- payload length
        o_payload_length => w_payload_length
    );

        -- modulo da validação
    validation_module: validation
    port map(
    -- input data
        clk => clk,
        i_o_ready => i_o_ready,
        i_valid => i_valid, 
        i_last => i_last,

        i_ready => i_ready,
        i_o_valid => i_o_valid,
        i_o_last => i_o_last, 

        -- checksum error
        i_sum_payload => w_sum_payload,
        i_checksum => w_checksum_32bits,
        i_sum_without_checksum_without_payload => w_sum_without_checksum_without_payload,
        o_waited_checksum => open,
        o_checksum_error => open,
        
        -- payload length error
        i_packet_length => r_packet_length_reg, 
        i_payload_length => w_payload_length,
        o_payload_length_error => open

    );
    
    State_Atualization: process(clk)
    begin
        if i_o_last = '1' then
            r_header_state_reg <= IDLE;
            -- fields
            r_internal_counter_reg <= 0;
            r_start_payload_reg <= '0';
            -- checksum aux

        elsif rising_edge(clk) then
        -- state
            r_header_state_reg <= r_header_state_next;
        -- fields
            r_packet_length_reg <= r_packet_length_next;
            r_checksum_reg <= r_checksum_next;
            r_seqnum_reg <= r_seqnum_next;
            r_flag_reg <= r_flag_next;
            r_protocol_reg <= r_protocol_next;
            r_dummy_reg <= r_dummy_next;
            r_source_address_reg <= r_source_address_next;
            r_destination_address_reg <= r_destination_address_next;
            r_start_payload_reg <= r_start_payload_next;
        -- counter
            r_internal_counter_reg <= r_internal_counter_next;

        end if;
    end process;
    
    State_Transition_Logic: process(r_header_state_reg,r_internal_counter_reg, i_valid, i_last)
    begin

        -- Initialize default values
        r_header_state_next <= r_header_state_reg;
        r_internal_counter_next <= r_internal_counter_reg; 
        r_start_payload_next <= r_start_payload_reg;   
        w_sum_without_checksum_without_payload <= (others => '0');
        w_checksum_32bits <= (others => '0');

        case r_header_state_reg is
            when IDLE =>
                if (i_valid = '1' and i_last = '0') then
                    r_header_state_next <= PACKET_LENGTH;                   
                end if;

            when PACKET_LENGTH =>
                r_internal_counter_next <= r_internal_counter_reg + 1;
                if (r_internal_counter_reg = c_WIDTH) then
                    r_header_state_next <= CHECKSUM;
                    r_internal_counter_next <= 0;
                end if;

            when CHECKSUM =>
                r_internal_counter_next <= r_internal_counter_reg + 1;
                if (r_internal_counter_reg = c_WIDTH) then
                    r_header_state_next <= SEQNUM;
                    r_internal_counter_next <= 0;
                end if;

            when SEQNUM =>
                r_internal_counter_next <= r_internal_counter_reg + 1;
                if (r_internal_counter_reg = c_WIDTH+2) then
                    r_header_state_next <= flag;
                    r_internal_counter_next <= 0;
                end if;

            when FLAG =>
                r_internal_counter_next <= r_internal_counter_reg + 1;
                if (r_internal_counter_reg = c_WIDTH-1) then
                    r_header_state_next <= PROTOCOL;
                    r_internal_counter_next <= 0;
                end if;

            when PROTOCOL =>
                r_internal_counter_next <= r_internal_counter_reg + 1;
                if (r_internal_counter_reg = c_WIDTH-1) then 
                    r_header_state_next <= DUMMY;  
                    r_internal_counter_next <= 0;
                end if;

            when DUMMY =>
                r_internal_counter_next <= r_internal_counter_reg + 1;
                if (r_internal_counter_reg = c_WIDTH) then
                    r_header_state_next <= SOURCE_ADDRESS;
                    r_internal_counter_next <= 0;
                end if;

            when SOURCE_ADDRESS =>
                r_internal_counter_next <= r_internal_counter_reg + 1;
                if (r_internal_counter_reg = c_WIDTH) then
                    r_header_state_next <= DESTINATION_ADDRESS;
                    r_internal_counter_next <= 0;
                end if;

            when DESTINATION_ADDRESS =>
                r_internal_counter_next <= r_internal_counter_reg + 1;
                if (r_internal_counter_reg = c_WIDTH and i_last = '1') then
                    r_header_state_next <= END_HEADER;
                    r_internal_counter_next <= 0;
                elsif (r_internal_counter_reg = c_WIDTH and i_last = '0') then
                    r_header_state_next <= END_HEADER;
                    r_internal_counter_next <= 0;
                    r_start_payload_next <= '1';
                end if;

            when END_HEADER =>
                
        end case;
    end process;

    State_Attribution_Logic: process(i_byte,r_header_state_reg, r_packet_length_reg,r_checksum_reg,r_seqnum_reg,r_flag_reg,r_protocol_reg,r_dummy_reg,r_source_address_reg,r_destination_address_reg)
    begin
        
        -- Initialize default values
        r_packet_length_next <= r_packet_length_reg;
        r_checksum_next <= r_checksum_reg;
        r_seqnum_next <= r_seqnum_reg;
        r_flag_next <= r_flag_reg;
        r_protocol_next <= r_protocol_reg;
        r_dummy_next <= r_dummy_reg;
        r_source_address_next <= r_source_address_reg;
        r_destination_address_next <= r_destination_address_reg;

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
                w_sum_without_checksum_without_payload <= (w_extended_part(15 downto 0) & unsigned(r_packet_length_reg)) 
                                                            + (w_extended_part(15 downto 0) & unsigned(r_seqnum_reg(15 downto 0)))
                                                            + (w_extended_part(15 downto 0) & unsigned(r_seqnum_reg(31 downto 16))) 
                                                            + (w_extended_part(15 downto 0) & unsigned((r_flag_reg & r_protocol_reg))) 
                                                            + (w_extended_part(15 downto 0) & unsigned(r_dummy_reg))
                                                            + (w_extended_part(15 downto 0) & unsigned(r_source_address_reg)) 
                                                            + (w_extended_part(15 downto 0) & unsigned(r_destination_address_reg));
 
                w_checksum_32bits <= (w_extended_part(15 downto 0) & unsigned(r_checksum_reg));
        end case;  
    end process;

        -- Output atualization 
    o_packet_length <=  r_packet_length_reg;
    o_checksum <= r_checksum_reg;
    o_seqnum <= r_seqnum_reg;
    o_flag <= r_flag_reg;
    o_protocol <= r_protocol_reg;
    o_dummy <= r_dummy_reg;
    o_source_address <= r_source_address_reg;
    o_destination_address <= r_destination_address_reg;
    

end arch_header;
