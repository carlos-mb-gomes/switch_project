library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity route_table is
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
        o_waited_seqnum                         : out std_logic_vector(31 downto 0) := (others => '0');
        o_destination_address_not_found_error   : out std_logic := '0'
        );
end route_table;

architecture arch_route_table of route_table is
    type t_ROUTE_TABLE_STATE_TYPE is (IDLE, CONNECTING_PORT, DISCONNECTING_PORT, NEW_SEQNUM);
    signal r_route_table_state_reg, r_route_table_state_next: t_ROUTE_TABLE_STATE_TYPE := IDLE;
    signal r_seqnum_1_reg, r_seqnum_1_next, r_seqnum_2_reg, r_seqnum_2_next, r_seqnum_3_reg, r_seqnum_3_next, r_seqnum_4_reg, r_seqnum_4_next, r_seqnum_5_reg, r_seqnum_5_next: unsigned(31 downto 0) := (others => '0');
    signal r_source_address_1_reg, r_source_address_1_next, r_source_address_2_reg, r_source_address_2_next, r_source_address_3_reg, r_source_address_3_next, r_source_address_4_reg, r_source_address_4_next, r_source_address_5_reg, r_source_address_5_next: unsigned(15 downto 0) := (others => '0');
     
    signal r_destination_address_not_found_error_reg, r_destination_address_not_found_error_next: std_logic:= '0';
    signal r_seqnum_error_reg, r_seqnum_error_next                                              : std_logic:= '0';
    signal r_route_table_filled_reg, r_route_table_filled_next                                        : std_logic:= '0'; 
    signal r_check_seqnum_1_reg,r_check_seqnum_2_reg,r_check_seqnum_3_reg,r_check_seqnum_4_reg,r_check_seqnum_5_reg,r_check_seqnum_1_next,r_check_seqnum_2_next,r_check_seqnum_3_next,r_check_seqnum_4_next,r_check_seqnum_5_next: unsigned(31 downto 0) := (others => '0');
    signal r_waited_seqnum_reg, r_waited_seqnum_next: unsigned(31 downto 0) := (others => '0');
begin

    State_atualization: process(clk, reset)
    begin
        if reset = '1' then
            r_route_table_state_reg                   <= IDLE;
            r_route_table_filled_reg                     <= '0'; 
            r_seqnum_error_reg                        <= '0';
            r_destination_address_not_found_error_reg <= '0';
            r_waited_seqnum_reg                       <= (others => '0');
        end if;

        if rising_edge(clk) and reset = '0' then
            r_route_table_state_reg                   <= r_route_table_state_next;
            r_route_table_filled_reg                     <= r_route_table_filled_next;
            
            r_seqnum_1_reg                            <= r_seqnum_1_next;
            r_seqnum_2_reg                            <= r_seqnum_2_next;
            r_seqnum_3_reg                            <= r_seqnum_3_next;
            r_seqnum_4_reg                            <= r_seqnum_4_next;
            r_seqnum_5_reg                            <= r_seqnum_5_next;
            
            r_source_address_1_reg                    <= r_source_address_1_next;
            r_source_address_2_reg                    <= r_source_address_2_next;
            r_source_address_3_reg                    <= r_source_address_3_next;
            r_source_address_4_reg                    <= r_source_address_4_next;
            r_source_address_5_reg                    <= r_source_address_5_next;

            r_check_seqnum_1_reg                      <= r_check_seqnum_1_next;
            r_check_seqnum_2_reg                      <= r_check_seqnum_2_next;
            r_check_seqnum_3_reg                      <= r_check_seqnum_3_next;
            r_check_seqnum_4_reg                      <= r_check_seqnum_4_next;
            r_check_seqnum_5_reg                      <= r_check_seqnum_5_next;

            r_destination_address_not_found_error_reg <= r_destination_address_not_found_error_next;
            r_seqnum_error_reg                        <= r_seqnum_error_next;
            r_waited_seqnum_reg                       <= r_waited_seqnum_next;
        end if;
    end process;

    Route_Table_State_Transition_Logic: process(i_flag, i_ready, r_route_table_state_reg)
    begin
        r_route_table_state_next <= r_route_table_state_reg;

        if i_ready = '0' then
            r_route_table_state_next <= IDLE;
        end if;

        if (i_flag(7) = '1' and i_flag(0) = '0') and i_ready = '1' and r_route_table_filled_reg = '0' then
            r_route_table_state_next <= CONNECTING_PORT;
        end if;

        if (i_flag(7) = '0' and i_flag(0) = '1') and i_ready = '1' and r_route_table_filled_reg = '0' then
            r_route_table_state_next <= DISCONNECTING_PORT;
        end if;

        if  (i_flag(7) = '0' and i_flag(0) = '0') and i_ready = '1' and r_route_table_filled_reg = '0' then
            r_route_table_state_next <= NEW_SEQNUM;
        end if;

    end process;

    Route_Table_State_Attribution_Logic: process(i_ports, i_seqnum, i_source_address, r_route_table_filled_reg,
     r_route_table_state_reg, r_seqnum_1_reg, r_seqnum_2_reg, r_seqnum_3_reg, r_seqnum_4_reg, r_seqnum_5_reg, r_source_address_1_reg,
     r_source_address_2_reg, r_source_address_3_reg, r_source_address_4_reg, r_source_address_5_reg,r_check_seqnum_1_reg,r_check_seqnum_2_reg,
     r_check_seqnum_3_reg,r_check_seqnum_4_reg,r_check_seqnum_5_reg)
    begin

        r_seqnum_1_next          <= r_seqnum_1_reg; 
        r_seqnum_2_next          <= r_seqnum_2_reg; 
        r_seqnum_3_next          <= r_seqnum_3_reg; 
        r_seqnum_4_next          <= r_seqnum_4_reg; 
        r_seqnum_5_next          <= r_seqnum_5_reg; 
        r_source_address_1_next  <= r_source_address_1_reg; 
        r_source_address_2_next  <= r_source_address_2_reg;
        r_source_address_3_next  <= r_source_address_3_reg;
        r_source_address_4_next  <= r_source_address_4_reg;
        r_source_address_5_next  <= r_source_address_5_reg;
        r_check_seqnum_1_next    <= r_check_seqnum_1_reg;
        r_check_seqnum_2_next    <= r_check_seqnum_2_reg;
        r_check_seqnum_3_next    <= r_check_seqnum_3_reg;
        r_check_seqnum_4_next    <= r_check_seqnum_4_reg;
        r_check_seqnum_5_next    <= r_check_seqnum_5_reg;
        r_route_table_filled_next   <= r_route_table_filled_reg;
 
        case i_ports is
            when "00001" =>
                if (r_route_table_state_reg = CONNECTING_PORT) and (r_route_table_filled_reg = '0')  then
                    r_seqnum_1_next         <= unsigned(i_seqnum);
                    r_source_address_1_next <= unsigned(i_source_address);
                    r_route_table_filled_next  <= '1';
                end if;
                
                if (r_route_table_state_reg = DISCONNECTING_PORT) and (r_route_table_filled_reg = '0') then
                    r_check_seqnum_1_next   <= unsigned(i_seqnum);
                    r_seqnum_1_next         <= (others => '0');
                    r_source_address_1_next <= (others => '0');
                    r_route_table_filled_next  <= '1';
                end if;
                
                if (r_route_table_state_reg = NEW_SEQNUM) and (r_route_table_filled_reg = '0') then
                    r_seqnum_1_next        <= r_seqnum_1_reg + 1;
                    r_route_table_filled_next <= '1';
                end if;

            when "00010" =>
                if (r_route_table_state_reg = CONNECTING_PORT) and (r_route_table_filled_reg = '0') then
                    r_seqnum_2_next         <= unsigned(i_seqnum);
                    r_source_address_2_next <= unsigned(i_source_address);
                    r_route_table_filled_next  <= '1';
                end if;
                
                if (r_route_table_state_reg = DISCONNECTING_PORT) and (r_route_table_filled_reg = '0') then
                    r_check_seqnum_2_next   <= unsigned(i_seqnum);
                    r_seqnum_2_next         <= (others => '0');
                    r_source_address_2_next <= (others => '0');
                    r_route_table_filled_next  <= '1';
                end if;
                
                if (r_route_table_state_reg = NEW_SEQNUM) and (r_route_table_filled_reg = '0') then
                    r_seqnum_2_next        <= r_seqnum_2_reg + 1;
                    r_route_table_filled_next <= '1';
                end if;

            when "00100" =>     
                if (r_route_table_state_reg = CONNECTING_PORT) and (r_route_table_filled_reg = '0') then
                    r_seqnum_3_next         <= unsigned(i_seqnum);
                    r_source_address_3_next <= unsigned(i_source_address);
                    r_route_table_filled_next  <= '1';
                end if;
                
                if (r_route_table_state_reg = DISCONNECTING_PORT) and (r_route_table_filled_reg = '0') then
                    r_check_seqnum_3_next   <= unsigned(i_seqnum);
                    r_seqnum_3_next         <= (others => '0');
                    r_source_address_3_next <= (others => '0');
                    r_route_table_filled_next  <= '1';
                end if;
                
                if (r_route_table_state_reg = NEW_SEQNUM) and (r_route_table_filled_reg = '0') then
                    r_seqnum_3_next        <= r_seqnum_3_reg + 1;
                    r_route_table_filled_next <= '1';
                end if;

            when "01000" =>
                if (r_route_table_state_reg = CONNECTING_PORT) and (r_route_table_filled_reg = '0') then
                    r_seqnum_4_next         <= unsigned(i_seqnum);
                    r_source_address_4_next <= unsigned(i_source_address);
                    r_route_table_filled_next  <= '1';
                end if;
                
                if (r_route_table_state_reg = DISCONNECTING_PORT) and (r_route_table_filled_reg = '0') then
                    r_check_seqnum_4_next   <= unsigned(i_seqnum);
                    r_seqnum_4_next         <= (others => '0');
                    r_source_address_4_next <= (others => '0');
                    r_route_table_filled_next  <= '1';
                end if;
                
                if (r_route_table_state_reg = NEW_SEQNUM) and (r_route_table_filled_reg = '0') then
                    r_seqnum_4_next        <= r_seqnum_4_reg + 1;
                    r_route_table_filled_next <= '1';
                end if;

            when "10000" =>
                if (r_route_table_state_reg = CONNECTING_PORT) and (r_route_table_filled_reg = '0') then
                    r_seqnum_5_next         <= unsigned(i_seqnum);
                    r_source_address_5_next <= unsigned(i_source_address);
                    r_route_table_filled_next  <= '1';
                end if;
                
                if (r_route_table_state_reg = DISCONNECTING_PORT) and (r_route_table_filled_reg = '0') then
                    r_check_seqnum_5_next   <= unsigned(i_seqnum);
                    r_seqnum_5_next         <= (others => '0');
                    r_source_address_5_next <= (others => '0');
                    r_route_table_filled_next  <= '1';
                    
                end if;

                if (r_route_table_state_reg = NEW_SEQNUM) and (r_route_table_filled_reg = '0') then
                    r_seqnum_5_next        <= r_seqnum_5_reg + 1;
                    r_route_table_filled_next <= '1';
                end if;

            when others =>

        end case;
    end process;

    Seqnum_Validation_Attribution_Logic: process(i_seqnum, i_ports,r_route_table_state_reg, r_seqnum_error_reg,
    r_route_table_filled_reg, r_seqnum_1_reg, r_seqnum_2_reg, r_seqnum_3_reg, r_seqnum_4_reg, r_seqnum_5_reg,r_check_seqnum_1_reg,
    r_check_seqnum_2_reg,r_check_seqnum_3_reg,r_check_seqnum_4_reg,r_check_seqnum_5_reg)
    begin

        r_seqnum_error_next <= r_seqnum_error_reg;
        r_waited_seqnum_next <= r_waited_seqnum_reg;

        case i_ports is
            when "00001" =>
                if (r_route_table_state_reg = NEW_SEQNUM and r_route_table_filled_reg = '1' and r_seqnum_1_reg /= unsigned(i_seqnum)) then
                    r_seqnum_error_next <= '1';
                    r_waited_seqnum_next <=  r_seqnum_1_reg; 
                end if;

                if (r_route_table_state_reg = DISCONNECTING_PORT and r_route_table_filled_reg = '1' and r_check_seqnum_1_reg /= unsigned(i_seqnum)) then
                    r_seqnum_error_next <= '1';
                    r_waited_seqnum_next <= r_check_seqnum_1_reg;
                end if;

            when "00010" =>
                if (r_route_table_state_reg = NEW_SEQNUM and r_route_table_filled_reg = '1' and r_seqnum_2_reg /= unsigned(i_seqnum)) then
                    r_seqnum_error_next <= '1';
                    r_waited_seqnum_next <=  r_seqnum_2_reg; 
                end if;

                if (r_route_table_state_reg = DISCONNECTING_PORT and r_route_table_filled_reg = '1' and r_check_seqnum_2_reg /= unsigned(i_seqnum)) then
                    r_seqnum_error_next <= '1';
                    r_waited_seqnum_next <= r_check_seqnum_2_reg;
                end if;

            when "00100" =>
                if (r_route_table_state_reg = NEW_SEQNUM and r_route_table_filled_reg = '1' and r_seqnum_3_reg /= unsigned(i_seqnum)) then
                    r_seqnum_error_next <= '1';
                    r_waited_seqnum_next <=  r_seqnum_3_reg; 
                end if;

                if (r_route_table_state_reg = DISCONNECTING_PORT and r_route_table_filled_reg = '1' and r_check_seqnum_2_reg /= unsigned(i_seqnum)) then
                    r_seqnum_error_next <= '1';
                    r_waited_seqnum_next <= r_check_seqnum_3_reg;
                end if;

            when "01000" =>
                if (r_route_table_state_reg = NEW_SEQNUM and r_route_table_filled_reg = '1' and r_seqnum_4_reg /= unsigned(i_seqnum)) then
                    r_seqnum_error_next <= '1';
                    r_waited_seqnum_next <=  r_seqnum_4_reg; 
                end if;

                if (r_route_table_state_reg = DISCONNECTING_PORT and r_route_table_filled_reg = '1' and r_check_seqnum_4_reg /= unsigned(i_seqnum)) then
                    r_seqnum_error_next <= '1';
                    r_waited_seqnum_next <= r_check_seqnum_4_reg;
                end if;

            when "10000" =>
                if (r_route_table_state_reg = NEW_SEQNUM and r_route_table_filled_reg = '1' and r_seqnum_5_reg /= unsigned(i_seqnum)) then
                    r_seqnum_error_next <= '1';
                    r_waited_seqnum_next <=  r_seqnum_5_reg; 
                end if;

                if (r_route_table_state_reg = DISCONNECTING_PORT and r_route_table_filled_reg = '1' and r_check_seqnum_5_reg /= unsigned(i_seqnum)) then
                    r_seqnum_error_next <= '1';
                    r_waited_seqnum_next <= r_check_seqnum_5_reg;
                end if;
            when others =>

        end case;
    end process;

    Destination_Address_Validation: process(i_flag,i_destination_address,r_route_table_filled_reg,r_destination_address_not_found_error_reg,
    r_source_address_1_reg,r_source_address_2_reg,r_source_address_3_reg,r_source_address_4_reg,r_source_address_5_reg)
    begin

    r_destination_address_not_found_error_next <= r_destination_address_not_found_error_reg;

        if (i_flag(0) = '0') and (i_flag(7) = '0') and (r_route_table_filled_reg = '1') 
        and ((i_destination_address /= std_logic_vector(r_source_address_1_reg)) and (i_destination_address /= std_logic_vector(r_source_address_2_reg)) 
        and (i_destination_address /= std_logic_vector(r_source_address_3_reg)) and (i_destination_address /= std_logic_vector(r_source_address_4_reg))
        and (i_destination_address /= std_logic_vector(r_source_address_5_reg))) then
            r_destination_address_not_found_error_next <= '1';
        end if;
    end process;

o_seqnum_error                        <= r_seqnum_error_reg;
o_destination_address_not_found_error <= r_destination_address_not_found_error_reg;
o_waited_seqnum                       <= std_logic_vector(r_waited_seqnum_reg);

end arch_route_table;



