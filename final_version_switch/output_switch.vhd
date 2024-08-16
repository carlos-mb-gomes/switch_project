library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity output_switch is
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
end output_switch;

architecture arch_output_switch of output_switch is

type t_DATA_OUTPUT_STATE_TYPE is (IDLE, INITIALIZE_AUX_SIGNAL, OUTPUT_STATE, END_OUTPUT);
signal data_output_state_reg, data_output_state_next                        : t_DATA_OUTPUT_STATE_TYPE := IDLE;
signal aux_seqnum_reg, aux_seqnum_next                                      : std_logic_vector(63 downto 0) := (others => '0');
signal aux_checksum_reg, aux_checksum_next                                  : std_logic_vector(31 downto 0) := (others => '0');       
signal aux_packet_length_reg, aux_packet_length_next                        : std_logic_vector(31 downto 0) := (others => '0'); 
signal internal_counter_reg, internal_counter_next                          : integer := 0; 
signal data_reg, data_next                                                  : std_logic_vector(7 downto 0) := (others => '0');
signal flag_error_reg, flag_error_next                                      : std_logic_vector(5 downto 0) := (others => '0');
signal flag_error_to_output_reg, flag_error_to_output_next                  : std_logic_vector(5 downto 0) := (others => '0');
signal destination_address_to_output_reg, destination_address_to_output_next: std_logic_vector(15 downto 0) := x"0000";
signal source_address_to_output_reg, source_address_to_output_next          : std_logic_vector(15 downto 0) := x"0000";
signal output_valid_reg, output_valid_next                                  : std_logic := '0';
signal w_output_last                                                        : std_logic := '0';


begin
    
    State_Atualization: process(clk, reset)
    begin
        if reset = '1' then
            data_output_state_reg               <= IDLE;
            internal_counter_reg                <= 0;
            aux_seqnum_reg                      <= (others => '0');
            aux_checksum_reg                    <= (others => '0');
            aux_packet_length_reg               <= (others => '0');
            flag_error_reg                      <= (others => '0');
            data_reg                            <= (others => '0');
            flag_error_to_output_reg            <= (others => '0');
            destination_address_to_output_reg   <= (others => '0');  
            source_address_to_output_reg        <= (others => '0');

        end if;

        if rising_edge(clk) and reset = '0' then
           flag_error_reg                    <= flag_error_next;
           data_output_state_reg             <= data_output_state_next;
           internal_counter_reg              <= internal_counter_next;  
           aux_packet_length_reg             <= aux_packet_length_next;
           aux_checksum_reg                  <= aux_checksum_next;
           aux_seqnum_reg                    <= aux_seqnum_next;
           source_address_to_output_reg      <= source_address_to_output_next;
           destination_address_to_output_reg <= destination_address_to_output_next;
           flag_error_to_output_reg          <= flag_error_to_output_next; 
           output_valid_reg                  <= output_valid_next;
           data_reg                          <= data_next;
        end if;
    end process;
    
    Output_Data_State_Attribution_Logic: process(flag_error_reg,data_output_state_reg,data_reg,internal_counter_reg,aux_seqnum_reg,aux_checksum_reg,
    aux_packet_length_reg,i_packet_length,i_expect_packet_length,i_expect_checksum,i_checksum,i_seqnum,i_expect_seqnum,output_valid_reg,w_output_last,
    i_source_address,i_destination_address,destination_address_to_output_reg,source_address_to_output_reg,flag_error_to_output_reg,i_packet_length_error,
    i_seqnum_error,i_checksum_error,i_destination_address_error,i_flag,flag_error_reg)
    begin
        internal_counter_next               <= internal_counter_reg;
        aux_packet_length_next              <= aux_packet_length_reg;
        aux_checksum_next                   <= aux_checksum_reg;
        aux_seqnum_next                     <= aux_seqnum_reg;
        output_valid_next                   <= output_valid_reg;
        w_output_last                       <= '0';
        data_next                           <= data_reg;
        destination_address_to_output_next  <= destination_address_to_output_reg;
        source_address_to_output_next       <= source_address_to_output_reg;
        flag_error_to_output_next           <= flag_error_to_output_reg;
        flag_error_next                     <= flag_error_reg;

        case data_output_state_reg is
            when IDLE =>
            
            when INITIALIZE_AUX_SIGNAL =>
                aux_packet_length_next <= i_expect_packet_length & i_packet_length;
                aux_checksum_next      <= i_expect_checksum & i_checksum;
                aux_seqnum_next        <= i_expect_seqnum & i_seqnum;
                flag_error_next        <= i_packet_length_error & i_seqnum_error & i_checksum_error & i_destination_address_error & i_flag(7) & i_flag(0);

            when OUTPUT_STATE =>
                internal_counter_next <= internal_counter_reg + 1;

                destination_address_to_output_next <= i_destination_address;
                source_address_to_output_next      <= i_source_address;
                flag_error_to_output_next          <= flag_error_reg;
                output_valid_next                  <= '1';

                if internal_counter_reg < 4 and i_packet_length_error = '1' then 
                    data_next              <= aux_packet_length_next(31 downto 24);
                    aux_packet_length_next <= aux_packet_length_reg(23 downto 0) & x"00";
                end if;        

                if (internal_counter_reg < 12 and internal_counter_reg >= 4 and i_packet_length_error = '1' and i_seqnum_error = '1') 
                or (internal_counter_reg < 8 and i_packet_length_error = '0' and i_seqnum_error = '1') then 
                    data_next       <= aux_seqnum_next(63 downto 56);
                    aux_seqnum_next <= aux_seqnum_reg(55 downto 0) & x"00";
                end if;     

                if (internal_counter_reg < 16 and internal_counter_reg >= 12 and i_packet_length_error = '1' and i_seqnum_error = '1' 
                and i_checksum_error = '1') or (internal_counter_reg < 12 and internal_counter_reg >= 8 and i_packet_length_error = '0' 
                and i_seqnum_error = '1' and i_checksum_error = '1') or (internal_counter_reg < 8 and internal_counter_reg >= 4 
                and i_packet_length_error = '1' and i_seqnum_error = '0' and i_checksum_error = '1') or (internal_counter_reg < 4 
                and i_packet_length_error = '0' and i_seqnum_error = '0'  and i_checksum_error = '1') then 
                    data_next         <= aux_checksum_next(31 downto 24);
                    aux_checksum_next <= aux_checksum_reg(23 downto 0) & x"00";
                end if; 

                if (internal_counter_reg = 16 and flag_error_reg(5 downto 3) = "111") 
                or (internal_counter_reg = 12 and (flag_error_reg(5 downto 3) = "011" or flag_error_reg(5 downto 3) = "110")) 
                or (internal_counter_reg = 8 and (flag_error_reg(5 downto 3) = "101" or flag_error_reg(5 downto 3) = "010")) 
                or (internal_counter_reg = 4 and (flag_error_reg(5 downto 3) = "100" or flag_error_reg(5 downto 3) = "001")) 
                or (internal_counter_reg = 1 and flag_error_reg(5 downto 3) = "000")   then
                    w_output_last     <= '1';
                    output_valid_next <= '0';
                end if;

            when END_OUTPUT =>

            when others =>
        end case;
    end process;

    Output_Data_State_Transition_Logic: process(data_output_state_reg,data_reg,internal_counter_reg,aux_seqnum_reg,aux_checksum_reg,
    aux_packet_length_reg,i_packet_length,i_expect_packet_length,i_expect_checksum,i_checksum,i_seqnum,i_expect_seqnum)
    begin
        data_output_state_next <= data_output_state_reg;

        case data_output_state_reg is
            when IDLE =>
                if i_start_output = '1' then
                    data_output_state_next <= INITIALIZE_AUX_SIGNAL;
                end if;
            when INITIALIZE_AUX_SIGNAL =>
                data_output_state_next <= OUTPUT_STATE;
            when OUTPUT_STATE =>
                if (internal_counter_reg = 16 and flag_error_reg(5 downto 3) = "111") 
                or (internal_counter_reg = 12 and (flag_error_reg(5 downto 3) = "011" or flag_error_reg(5 downto 3) = "110")) 
                or (internal_counter_reg = 8 and (flag_error_reg(5 downto 3) = "101" or flag_error_reg(5 downto 3) = "010")) 
                or (internal_counter_reg = 4 and (flag_error_reg(5 downto 3) = "100" or flag_error_reg(5 downto 3) = "001")) 
                or (internal_counter_reg = 1 and flag_error_reg(5 downto 3) = "000")   then
                    data_output_state_next <= END_OUTPUT;
                end if;

            when END_OUTPUT =>

            when others =>
        end case;
    end process;

    o_flag_error          <= flag_error_to_output_reg;
    o_destination_address <= destination_address_to_output_reg;
    o_source_address      <= source_address_to_output_reg;
    o_data                <= data_reg;
    o_last                <= w_output_last;
    o_valid               <= output_valid_reg;


end arch_output_switch;