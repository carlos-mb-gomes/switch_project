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
    type t_SOURCE_ADDRESS_FIELD is array (1 to 5) of unsigned(15 downto 0);
    type t_SEQNUM_FIELD is array (1 to 5) of unsigned(31 downto 0);
    type t_DISCONNECT_SEQNUM_FIELD is array (1 to 5) of unsigned(31 downto 0);
    signal r_source_address_reg, r_source_address_next: t_SOURCE_ADDRESS_FIELD := (others => (others => '0'));
    signal r_seqnum_reg, r_seqnum_next: t_SEQNUM_FIELD := (others => (others => '0'));
    signal r_disconnect_seqnum_reg, r_disconnect_seqnum_next: t_DISCONNECT_SEQNUM_FIELD := (others => (others => '0'));
    signal r_destination_address_not_found_error_reg, r_destination_address_not_found_error_next: std_logic:= '0';
    signal r_seqnum_error_reg, r_seqnum_error_next                                              : std_logic:= '0';
    signal r_route_table_filled_reg, r_route_table_filled_next                                        : std_logic:= '0'; 
    signal r_waited_seqnum_reg, r_waited_seqnum_next: unsigned(31 downto 0) := (others => '0');
    signal w_port : integer := 0;

begin
    with i_ports select
        w_port <=   1 when "00001",
                    2 when "00010",
                    3 when "00100",
                    4 when "01000",
                    5 when "10000",
                    0 when others;

    State_atualization: process(clk, reset)
    begin
        if reset = '1' then
            r_route_table_state_reg                   <= IDLE;
            r_route_table_filled_reg                  <= '0'; 
            r_seqnum_error_reg                        <= '0';
            r_destination_address_not_found_error_reg <= '0';
            r_waited_seqnum_reg                       <= (others => '0');
        end if;

        if rising_edge(clk) and reset = '0' then
            r_route_table_state_reg                   <= r_route_table_state_next;
            r_route_table_filled_reg                  <= r_route_table_filled_next;
            r_source_address_reg                     <= r_source_address_next; 
            r_seqnum_reg                             <= r_seqnum_next; 
            r_disconnect_seqnum_reg                  <= r_disconnect_seqnum_next; 
            r_destination_address_not_found_error_reg <= r_destination_address_not_found_error_next;
            r_seqnum_error_reg                        <= r_seqnum_error_next;
            r_waited_seqnum_reg                       <= r_waited_seqnum_next;
        end if;
    end process;

    Route_Table_State_Transition_Logic: process(i_flag, i_ready, r_route_table_state_reg,r_route_table_filled_reg)
    begin
        r_route_table_state_next <= r_route_table_state_reg;

        case r_route_table_state_reg is
            when IDLE =>

                if (i_flag(7) = '1' and i_flag(0) = '0') and i_ready = '1' and r_route_table_filled_reg = '0' then
                    r_route_table_state_next <= CONNECTING_PORT;
                end if;

                if (i_flag(7) = '0' and i_flag(0) = '1') and i_ready = '1' and r_route_table_filled_reg = '0' then
                    r_route_table_state_next <= DISCONNECTING_PORT;
                end if;

                if  (i_flag(7) = '0' and i_flag(0) = '0') and i_ready = '1' and r_route_table_filled_reg = '0' then
                    r_route_table_state_next <= NEW_SEQNUM;
                end if;
            
            when CONNECTING_PORT =>
                r_route_table_state_next <= IDLE;

            when DISCONNECTING_PORT =>
                r_route_table_state_next <= IDLE;
            
            when NEW_SEQNUM =>
                r_route_table_state_next <= IDLE;
        
        end case;

    end process;

    Route_Table_State_Attribution_Logic: process(w_port, i_seqnum, i_source_address, r_route_table_filled_reg,
    r_source_address_reg,r_seqnum_reg, r_disconnect_seqnum_reg,r_route_table_state_reg)
    begin

        r_source_address_next       <= r_source_address_reg; 
        r_seqnum_next               <= r_seqnum_reg; 
        r_disconnect_seqnum_next    <= r_disconnect_seqnum_reg; 
        r_route_table_filled_next   <= r_route_table_filled_reg;

        case r_route_table_state_reg is
            when IDLE =>

            when CONNECTING_PORT =>
                if (r_route_table_filled_reg = '0')  then
                    r_source_address_next(w_port)      <= unsigned(i_source_address);
                    r_seqnum_next(w_port)              <= unsigned(i_seqnum);
                    r_route_table_filled_next          <= '1';
                end if;

            when DISCONNECTING_PORT =>
                if (r_route_table_filled_reg = '0') then
                    r_source_address_next(w_port)      <= (others => '0');
                    r_seqnum_next(w_port)              <= (others => '0');
                    r_disconnect_seqnum_next(w_port)   <= unsigned(i_seqnum);
                    r_route_table_filled_next          <= '1';
                end if;

            when NEW_SEQNUM =>
                if (r_route_table_filled_reg = '0') then
                    r_seqnum_next(w_port)              <= r_seqnum_reg(w_port) + 1;
                    r_route_table_filled_next          <= '1';
                end if;

            when others =>

        end case;
    end process;

    Seqnum_Validation_Attribution_Logic: process(i_seqnum, w_port,r_route_table_state_reg, r_seqnum_error_reg,
    r_route_table_filled_reg, r_seqnum_reg,r_disconnect_seqnum_reg)
    begin

        r_seqnum_error_next <= r_seqnum_error_reg;
        r_waited_seqnum_next <= r_waited_seqnum_reg;

        case r_route_table_state_reg is
            when IDLE =>

            when CONNECTING_PORT =>

            when DISCONNECTING_PORT =>
                if (r_route_table_filled_reg = '1' and r_disconnect_seqnum_reg(w_port) /= unsigned(i_seqnum)) then
                    r_seqnum_error_next  <= '1';
                    r_waited_seqnum_next <= r_disconnect_seqnum_reg(w_port);
                end if;

            when NEW_SEQNUM =>
                if (r_route_table_filled_reg = '1' and r_seqnum_reg(w_port) /= unsigned(i_seqnum)) then
                    r_seqnum_error_next  <= '1';
                    r_waited_seqnum_next <=  r_seqnum_reg(w_port); 
                end if;

            when others =>

        end case;
    end process;

    Destination_Address_Validation: process(i_flag,i_destination_address,r_route_table_filled_reg,
    r_destination_address_not_found_error_reg, r_source_address_reg)
    begin

        r_destination_address_not_found_error_next <= r_destination_address_not_found_error_reg;

        if (i_flag(0) = '0') and (i_flag(7) = '0') and (r_route_table_filled_reg = '1') and (i_destination_address /= std_logic_vector(r_source_address_reg(w_port))) then
            r_destination_address_not_found_error_next <= '1';
        end if;
    end process;

o_seqnum_error                        <= r_seqnum_error_reg;
o_destination_address_not_found_error <= r_destination_address_not_found_error_reg;
o_waited_seqnum                       <= std_logic_vector(r_waited_seqnum_reg);

end arch_route_table;



