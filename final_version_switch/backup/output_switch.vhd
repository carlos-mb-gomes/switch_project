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

        i_destination_address                   : in std_logic_vector(15 downto 0);
        i_source_address                        : in std_logic_vector(15 downto 0);
        
        i_packet_length_error                   : in std_logic := '0';
        i_checksum_error                        : in std_logic := '0';
        i_seqnum_error                          : in std_logic := '0';
        i_destination_address_error             : in std_logic := '0';

        i_start_output                          : in std_logic := '0';

        o_source_address                        : out std_logic_vector(15 downto 0);
        o_destination_address                   : out std_logic_vector(15 downto 0);
        o_valid                                 : out std_logic := '0';
        o_last                                  : out std_logic := '0';
        o_flag_error                            : out std_logic_vector(5 downto 0) := "000000";
        o_data                                  : out std_logic_vector(7 downto 0) := x"00"
        );
end output_switch;

architecture arch_output_switch of output_switch is

type t_DATA_OUTPUT_STATE_TYPE is (IDLE, INITIALIZE_AUX_SIGNAL, OUTPUT_STATE,END_OUTPUT);
signal data_output_state_reg, data_output_state_next                            : t_DATA_OUTPUT_STATE_TYPE := IDLE;
signal r_aux_seqnum_reg, r_aux_seqnum_next                                      : std_logic_vector(63 downto 0) := (others => '0');
signal r_aux_checksum_reg, r_aux_checksum_next                                  : std_logic_vector(31 downto 0) := (others => '0');       
signal r_aux_packet_length_reg, r_aux_packet_length_next                        : std_logic_vector(31 downto 0) := (others => '0'); 
signal internal_counter_reg, internal_counter_next                              : integer := 0; 
signal r_data_reg, r_data_next                                                  : std_logic_vector(7 downto 0) := (others => '0');
signal r_flag_error_reg, r_flag_error_next                                      : std_logic_vector(5 downto 0) := (others => '0');
signal w_destination_address                                                    : std_logic_vector(15 downto 0) := (others => '0');
signal w_source_address                                                         : std_logic_vector(15 downto 0) := (others => '0');
signal w_o_valid                                                                : std_logic := '0';
signal w_o_last                                                                  : std_logic := '0';

begin
    
    State_Atualization: process(clk, reset)
    begin
        if reset = '1' then
            data_output_state_reg       <= IDLE;
            internal_counter_reg        <= 0;
            r_aux_seqnum_reg            <= (others => '0');
            r_aux_checksum_reg          <= (others => '0');
            r_aux_packet_length_reg     <= (others => '0');
            r_flag_error_reg            <= (others => '0');
            r_data_reg                  <= (others => '0');

        end if;

        if rising_edge(clk) and reset = '0' then

           r_flag_error_reg                 <= r_flag_error_next;
           data_output_state_reg            <= data_output_state_next;
           r_data_reg                       <= r_data_next;
           internal_counter_reg             <= internal_counter_next;  
           r_aux_packet_length_reg          <= r_aux_packet_length_next;
           r_aux_checksum_reg               <= r_aux_checksum_next;
           r_aux_seqnum_reg                 <= r_aux_seqnum_next;
        end if;
    end process;

    Error_Flag_Attribution_Logic: process(i_packet_length_error,i_seqnum_error, i_destination_address_error, i_checksum_error)
    begin 

        r_flag_error_next <= r_flag_error_reg;

        if i_start_output = '1' then 
           r_flag_error_next <= i_packet_length_error & i_seqnum_error & i_checksum_error & i_destination_address_error & i_flag(7) & i_flag(0);
        end if;

    end process;


    
    Output_Data_State_Attribution_Logic: process(r_flag_error_reg,w_o_valid,w_o_last,data_output_state_reg,r_data_reg,internal_counter_reg,
    r_aux_seqnum_reg,r_aux_checksum_reg,r_aux_packet_length_reg,i_packet_length,i_expect_packet_length,i_expect_checksum,i_checksum,i_seqnum,
    i_expect_seqnum)
    begin

        internal_counter_next           <= internal_counter_reg;
        r_data_next                     <= r_data_reg;
        r_aux_packet_length_next        <= r_aux_packet_length_reg;
        r_aux_checksum_next             <= r_aux_checksum_reg;
        r_aux_seqnum_next               <= r_aux_seqnum_reg;
        w_destination_address           <= (others => '0');
        w_source_address                <= (others => '0');
        w_o_valid         <= '0';
        w_o_last         <= '0';

        case data_output_state_reg is
            when IDLE =>
            
            when INITIALIZE_AUX_SIGNAL =>
                r_aux_packet_length_next    <= i_expect_packet_length & i_packet_length;
                r_aux_checksum_next         <= i_expect_checksum & i_checksum;
                r_aux_seqnum_next           <= i_expect_seqnum & i_seqnum;

            when OUTPUT_STATE =>
                internal_counter_next  <= internal_counter_reg + 1;     
                w_o_valid              <= '1';

                w_destination_address  <= i_destination_address;
                w_source_address       <= i_source_address;

                if internal_counter_reg < 4 and i_packet_length_error = '1' then 
                    r_data_next              <= r_aux_packet_length_next(31 downto 24);
                    r_aux_packet_length_next <= r_aux_packet_length_reg(23 downto 0) & x"00";
                end if;        

                if (internal_counter_reg < 12 and internal_counter_reg >= 4 and i_packet_length_error = '1' and i_seqnum_error = '1') 
                or (internal_counter_reg < 8 and i_packet_length_error = '0' and i_seqnum_error = '1') then 

                    r_data_next       <= r_aux_seqnum_next(63 downto 56);
                    r_aux_seqnum_next <= r_aux_seqnum_reg(55 downto 0) & x"00";
                end if;     

                if (internal_counter_reg < 16 and internal_counter_reg >= 12 and i_packet_length_error = '1' and i_seqnum_error = '1' 
                and i_checksum_error = '1') or (internal_counter_reg < 12 and internal_counter_reg >= 8 and i_packet_length_error = '0' 
                and i_seqnum_error = '1' and i_checksum_error = '1') or (internal_counter_reg < 8 and internal_counter_reg >= 4 
                and i_packet_length_error = '1' and i_seqnum_error = '0' and i_checksum_error = '1') or (internal_counter_reg < 4 
                and i_packet_length_error = '0' and i_seqnum_error = '0'  and i_checksum_error = '1') then 

                    r_data_next         <= r_aux_checksum_next(31 downto 24);
                    r_aux_checksum_next <= r_aux_checksum_reg(23 downto 0) & x"00";
                end if; 

                if (internal_counter_reg = 15 and r_flag_error_reg(5 downto 3) = "111") 
                or (internal_counter_reg = 11 and r_flag_error_reg(5 downto 3) = "110") 
                or (internal_counter_reg = 7 and r_flag_error_reg(5 downto 3) = "101") 
                or (internal_counter_reg = 3 and r_flag_error_reg(5 downto 3) = "100") 
                or (internal_counter_reg = 11 and r_flag_error_reg(5 downto 3) = "011") 
                or (internal_counter_reg = 7 and r_flag_error_reg(5 downto 3) = "010") 
                or (internal_counter_reg = 3 and r_flag_error_reg(5 downto 3) = "001") 
                or (internal_counter_reg = 0 and r_flag_error_reg(5 downto 3) = "000")   then
                    w_o_last <= '1';
                end if;

                if (internal_counter_reg = 16 and r_flag_error_reg(5 downto 3) = "111") 
                or (internal_counter_reg = 12 and r_flag_error_reg(5 downto 3) = "110") 
                or (internal_counter_reg = 8 and r_flag_error_reg(5 downto 3) = "101") 
                or (internal_counter_reg = 4 and r_flag_error_reg(5 downto 3) = "100") 
                or (internal_counter_reg = 12 and r_flag_error_reg(5 downto 3) = "011") 
                or (internal_counter_reg = 8 and r_flag_error_reg(5 downto 3) = "010") 
                or (internal_counter_reg = 4 and r_flag_error_reg(5 downto 3) = "001") 
                or (internal_counter_reg = 1 and r_flag_error_reg(5 downto 3) = "000")   then
                    w_o_valid <= '0';
                end if;
            when END_OUTPUT =>

            when others =>

        end case;
    end process;

    Output_Data_State_Transition_Logic: process(w_o_valid,w_o_last,data_output_state_reg,r_data_reg,internal_counter_reg,r_aux_seqnum_reg,r_aux_checksum_reg,
    r_aux_packet_length_reg,i_packet_length,i_expect_packet_length,i_expect_checksum,i_checksum,i_seqnum,i_expect_seqnum)
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
                if w_o_last = '0' and w_o_valid <= '0' then
                    data_output_state_next <= END_OUTPUT;
                end if;
            when END_OUTPUT =>
            when others =>

        end case;
    end process;


    o_flag_error            <= r_flag_error_reg;
    o_data                  <= r_data_reg;
    o_last                  <= w_o_last;
    o_valid                 <= w_o_valid;
    o_destination_address   <= w_destination_address;
    o_source_address        <= w_source_address;

end arch_output_switch;
