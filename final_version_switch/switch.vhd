library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity switch is
    Port (
        clk                     : in std_logic;
        i_ports                 : in std_logic_vector(4 downto 0);

        o_ready                 : out std_logic; 
        i_valid                 : in  std_logic;
        i_last                  : in  std_logic;

        i_ready                 : in  std_logic;
        o_last                  : out std_logic;
        o_valid                 : out std_logic;

        i_data                  : in std_logic_vector(7 downto 0); 

        o_flag_error            : out std_logic_vector(5 downto 0);
        o_destination_address   : out std_logic_vector(15 downto 0);
        o_source_address        : out std_logic_vector(15 downto 0);
        o_data                  : out std_logic_vector(7 downto 0)

        );
end switch;

architecture arch_switch of switch is
    signal reset                                    : std_logic:= '0';
    signal output_ready_reg, output_ready_next      : std_logic:= '1';

    signal w_packet_length                          : std_logic_vector(15 downto 0) := x"0000";
    signal w_checksum                               : std_logic_vector(15 downto 0) := x"0000";
    signal w_seqnum                                 : std_logic_vector(31 downto 0) := x"00000000";
    signal w_flag                                   : std_logic_vector(7 downto 0) := x"00";
    signal w_protocol                               : std_logic_vector(7 downto 0) := x"00";
    signal w_dummy                                  : std_logic_vector(15 downto 0) := x"0000";
    signal w_source_address                         : std_logic_vector(15 downto 0) := x"0000";
    signal w_destination_address                    : std_logic_vector(15 downto 0) := x"0000";
    signal w_payload                                : std_logic_vector(3839 downto 0) := (others => '0');

    signal w_sum_without_checksum_without_payload   : unsigned(31 downto 0) := x"00000000";
    signal w_checksum_32bits                        : unsigned(31 downto 0) := x"00000000";
    signal w_start_payload                          : std_logic := '0';
    signal w_sum_payload                            : unsigned(31 downto 0) := x"00000000";
    signal w_payload_length                         : integer;

    signal w_payload_length_error                   : std_logic:= '0';
    signal w_checksum_error                         : std_logic:= '0';
    signal w_seqnum_error                           : std_logic:= '0';
    signal w_destination_address_error              : std_logic:='0';
    signal w_expected_checksum                      : std_logic_vector(15 downto 0):= (others => '0');
    signal w_start_validation_from_payload          : std_logic:= '0';
    signal w_start_validation_from_header           : std_logic:= '0';
    signal w_start_output                           : std_logic:= '0';

    signal w_output_last                            : std_logic := '0';
    signal w_output_valid                           : std_logic := '0';
    signal w_expected_seqnum                        : std_logic_vector(31 downto 0) := (others => '0');
    signal w_expected_packet_length                 : std_logic_vector(15 downto 0) := (others => '0');
    signal start_output_reg, start_output_next      : std_logic := '0';


    component header is
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

            o_start_payload                         : out std_logic := '0';

            o_sum_without_checksum_without_payload  : out unsigned(31 downto 0) := x"00000000";
            o_checksum_32bits                       : out unsigned(31 downto 0) := x"00000000";
            o_start_validation                      : out std_logic := '0'
            );
    end component;

    component payload_field is
        Port (
            i_last              : in std_logic;
            i_valid             : in std_logic;

            clk                 : in std_logic;
            reset               : in std_logic:= '0';

            i_start_payload     : in std_logic:= '0';

            i_byte              : in std_logic_vector(7 downto 0);

            o_payload           : out std_logic_vector(3839 downto 0);
            o_payload_length    : out integer;

            o_sum_payload       : out unsigned(31 downto 0);
            o_start_validation  : out std_logic:= '0'
            );
    end component;

    component validation is
    Port (
        clk                                   : in std_logic;
        reset                                 : in std_logic;

        i_start_validation_from_header        : in std_logic;
        i_start_validation_from_payload       : in std_logic;

        i_valid                               : in std_logic;
        i_ready                               : in std_logic;
        i_sum_payload                         : in unsigned(31 downto 0)         := x"00000000";
        i_checksum                            : in unsigned(31 downto 0)         := x"00000000";
        i_sum_without_checksum_without_payload: in unsigned(31 downto 0)         := x"00000000";
        o_expect_checksum                     : out std_logic_vector(15 downto 0):= x"0000";
        o_checksum_error                      : out std_logic                    := '0';

        i_packet_length                       : in std_logic_vector(15 downto 0) := x"0000"; 
        i_payload_length                      : in integer                       := 0;
        o_start_output                        : out std_logic                    := '0';
        o_payload_length_error                : out std_logic                    := '0';
        o_waited_packet_length                : out std_logic_vector(15 downto 0):= x"0000"
    );
end component;

component route_table is
    Port (
        -- input data
        clk                                     : in std_logic;
        reset                                   : in std_logic;
        i_ready                                 : in std_logic; 
        -- ports
        i_flag                                  : in std_logic_vector(7 downto 0) := x"00";
        i_ports                                 : in std_logic_vector(4 downto 0) := "00000";
        i_seqnum                                : in std_logic_vector(31 downto 0) := x"00000000";
        i_source_address                        : in std_logic_vector(15 downto 0) := x"0000";
        -- validation destination address not found
        i_destination_address                   : in std_logic_vector(15 downto 0) := x"0000";
        o_seqnum_error                          : out std_logic := '0';
        o_expected_seqnum                       : out std_logic_vector(31 downto 0) := (others => '0');
        o_destination_address_not_found_error   : out std_logic := '0'
        );
end component;

component output_switch is
    Port (
        -- signal for condition states
        clk                                     : in std_logic;
        reset                                   : in std_logic;

        i_flag                                  : in std_logic_vector(7 downto 0) := x"00";
        i_packet_length                         : in std_logic_vector(15 downto 0) := x"0000";
        i_expect_packet_length                  : in std_logic_vector(15 downto 0) := x"0000";
        i_checksum                              : in std_logic_vector(15 downto 0) := x"0000";
        i_expect_checksum                       : in std_logic_vector(15 downto 0) := x"0000";
        i_seqnum                                : in std_logic_vector(31 downto 0) := x"00000000";
        i_expect_seqnum                         : in std_logic_vector(31 downto 0) := x"00000000";

        i_destination_address                   : in std_logic_vector(15 downto 0) := x"0000"; 
        i_source_address                        : in std_logic_vector(15 downto 0) := x"0000";
        
        i_packet_length_error                   : in std_logic := '0';
        i_checksum_error                        : in std_logic := '0';
        i_seqnum_error                          : in std_logic := '0';
        i_destination_address_error             : in std_logic := '0';

        i_start_output                          : in std_logic := '0';

        o_last                                  : out std_logic := '0';
        o_valid                                 : out std_logic := '0';
        o_flag_error                            : out std_logic_vector(5 downto 0) := "000000";
        o_data                                  : out std_logic_vector(7 downto 0) := x"00";
        o_destination_address                   : out std_logic_vector(15 downto 0) := x"0000"; 
        o_source_address                        : out std_logic_vector(15 downto 0) := x"0000"
        );
end component;

begin

    Header_Module: header
    port map(
            reset                                   => reset,
            clk                                     => clk,
            i_last                                  => i_last,
            i_valid                                 => i_valid,
            i_byte                                  => i_data,
            o_packet_length                         => w_packet_length,
            o_checksum                              => w_checksum,
            o_seqnum                                => w_seqnum,
            o_flag                                  => w_flag,
            o_protocol                              => w_protocol,
            o_dummy                                 => w_dummy,
            o_source_address                        => w_source_address,
            o_destination_address                   => w_destination_address,
            o_sum_without_checksum_without_payload  => w_sum_without_checksum_without_payload,
            o_checksum_32bits                       => w_checksum_32bits,
            o_start_payload                         => w_start_payload,
            o_start_validation                      => w_start_validation_from_header
    );

    Payload_Module: payload_field
    port map (
        i_start_payload    => w_start_payload,
        i_byte             => i_data,
        clk                => clk,
        reset              => reset,
        i_last             => i_last,
        i_valid            => i_valid, 
        o_payload          => w_payload,
        o_sum_payload      => w_sum_payload,
        o_payload_length   => w_payload_length,
        o_start_validation => w_start_validation_from_payload
    );

    Validation_Module: validation
    port map (
        clk                                    => clk,
        reset                                  => reset,
        i_start_validation_from_header         => w_start_validation_from_header,
        i_start_validation_from_payload        => w_start_validation_from_payload,
        i_ready                                => i_ready,
        i_valid                                => i_valid,
        -- checksum error
        i_sum_payload                          => w_sum_payload,
        i_checksum                             => w_checksum_32bits,
        i_sum_without_checksum_without_payload => w_sum_without_checksum_without_payload,    
        o_expect_checksum                      => w_expected_checksum,
        o_checksum_error                       => w_checksum_error,
        -- payload length error
        i_packet_length                        => w_packet_length, 
        i_payload_length                       => w_payload_length,
        o_start_output                         => w_start_output,                      
        o_payload_length_error                 => w_payload_length_error,
        o_waited_packet_length                 => w_expected_packet_length
    );

    Route_Table_Module: route_table
    port map (
        -- input data
        clk                                     => clk,
        reset                                   => reset,
        i_ready                                 => i_ready, 
        -- ports
        i_flag                                  => w_flag,
        i_ports                                 => i_ports,
        i_seqnum                                => w_seqnum,
        i_source_address                        => w_source_address,
        -- validation destination address not found
        i_destination_address                   => w_destination_address,
        o_seqnum_error                          => w_seqnum_error,
        o_expected_seqnum                       => w_expected_seqnum,
        o_destination_address_not_found_error   => w_destination_address_error
        );


    Output_Module: output_switch
    port map (

        clk                                     => clk,
        reset                                   => reset,
        i_flag                                  => w_flag,
        i_packet_length                         => w_packet_length,
        i_expect_packet_length                  => w_expected_packet_length,
        i_checksum                              => w_checksum,
        i_expect_checksum                       => w_expected_checksum,
        i_seqnum                                => w_seqnum,
        i_expect_seqnum                         => w_expected_seqnum,
        i_destination_address                   => w_destination_address,
        i_source_address                        => w_source_address,
        i_packet_length_error                   => w_payload_length_error,
        i_checksum_error                        => w_checksum_error,
        i_seqnum_error                          => w_seqnum_error,
        i_destination_address_error             => w_destination_address_error,
        i_start_output                          => w_start_output,
        o_last                                  => w_output_last,
        o_valid                                 => w_output_valid,
        o_flag_error                            => o_flag_error,
        o_data                                  => o_data,
        o_destination_address                   => o_destination_address, 
        o_source_address                        => o_source_address
        );


    process(clk)
    begin
        if rising_edge(clk) then
           output_ready_reg <= output_ready_next;
           start_output_reg <= start_output_next;
        end if;
    end process;



    Transition_signals: process(i_valid, i_last, i_ready, output_ready_reg,w_start_output,start_output_reg)
    begin 
        output_ready_next <= output_ready_reg;
        start_output_next <= w_start_output;
        reset             <= '0';

        if i_last = '1' then
            output_ready_next <= '0';        
        end if;

        if i_ready = '0' and start_output_reg = '1' then
            reset             <= '1';
            output_ready_next <= '1';
        end if;
    end process;

    o_ready <= output_ready_reg;
    o_valid <= w_output_valid;
    o_last  <= w_output_last;

end arch_switch;







