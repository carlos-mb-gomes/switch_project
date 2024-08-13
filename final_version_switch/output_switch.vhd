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
        
        i_packet_length_error                   : in std_logic := '0';
        i_checksum_error                        : in std_logic := '0';
        i_seqnum_error                          : in std_logic := '0';
        i_destination_address_error             : in std_logic := '0';

        i_start_output                          : in std_logic := '0';

        o_last                                  : out std_logic := '0';
        o_flag_error                            : out std_logic_vector(5 downto 0) := "000000";
        o_data                                  : out std_logic_vector(7 downto 0) := x"00"
        );
end output_switch;

architecture arch_output_switch of output_switch is

type t_DATA_OUTPUT_STATE_TYPE is (IDLE, INITIALIZE_AUX_SIGNAL, OUTPUT_STATE);
signal data_output_state_reg, data_output_state_next                            : t_DATA_OUTPUT_STATE_TYPE := IDLE;
signal r_aux_seqnum_reg, r_aux_seqnum_next                                      : std_logic_vector(63 downto 0) := (others => '0');
signal r_aux_checksum_reg, r_aux_checksum_next                                  : std_logic_vector(31 downto 0) := (others => '0');       
signal r_aux_packet_length_reg, r_aux_packet_length_next                        : std_logic_vector(31 downto 0) := (others => '0'); 
signal internal_counter_reg, internal_counter_next                              : integer := 0; 
signal r_data_reg, r_data_next                                                  : std_logic_vector(7 downto 0) := (others => '0');
signal r_flag_error_reg, r_flag_error_next                                      : std_logic_vector(5 downto 0) := (others => '0');
signal r_o_last_next, r_o_last_reg                                              : std_logic := '0';


begin
    
    State_Atualization: process(clk, reset)
    begin
        if reset = '1' then
            data_output_state_reg       <= IDLE;
            internal_counter_reg        <= 0;
            r_aux_seqnum_reg            <= (others => '0');
            r_aux_checksum_reg          <= (others => '0');
            r_aux_packet_length_reg     <= (others => '0');
            r_o_last_reg                <= '0';
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
            r_o_last_reg                    <= r_o_last_next;
        end if;
    end process;

    Error_Flag_Attribution_Logic: process(i_packet_length_error,i_seqnum_error, i_destination_address_error, i_checksum_error)
    begin 

        r_flag_error_next <= r_flag_error_reg;

        if i_start_output = '1' then 
           r_flag_error_next <= i_packet_length_error & i_seqnum_error & i_checksum_error & i_destination_address_error & i_flag(7) & i_flag(0);
        end if;

    end process;


    
    Output_Data_State_Attribution_Logic: process(r_flag_error_reg,r_o_last_reg,data_output_state_reg,r_data_reg,internal_counter_reg,
    r_aux_seqnum_reg,r_aux_checksum_reg,r_aux_packet_length_reg,i_packet_length,i_expect_packet_length,i_expect_checksum,i_checksum,i_seqnum,
    i_expect_seqnum)
    begin

        internal_counter_next           <= internal_counter_reg;
        r_data_next                     <= r_data_reg;
        r_aux_packet_length_next        <= r_aux_packet_length_reg;
        r_aux_checksum_next             <= r_aux_checksum_reg;
        r_aux_seqnum_next               <= r_aux_seqnum_reg;
        r_o_last_next                   <= r_o_last_reg; 


        case data_output_state_reg is
            when IDLE =>
            
            when INITIALIZE_AUX_SIGNAL =>
                r_aux_packet_length_next    <= i_expect_packet_length & i_packet_length;
                r_aux_checksum_next         <= i_expect_checksum & i_checksum;
                r_aux_seqnum_next           <= i_expect_seqnum & i_seqnum;
            when OUTPUT_STATE =>
                internal_counter_next <= internal_counter_reg + 1;     

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

                if (internal_counter_reg = 16) then
                    r_o_last_next <= '1';
                end if;
                
            when others =>
        end case;
    end process;

    Output_Data_State_Transition_Logic: process(data_output_state_reg,r_data_reg,internal_counter_reg,r_aux_seqnum_reg,r_aux_checksum_reg,
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

            when others =>
        end case;
    end process;


    o_flag_error <= r_flag_error_reg;
    o_data <= r_data_reg;
    o_last <= r_o_last_reg;

end arch_output_switch;
