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
        o_expected_seqnum                       : out std_logic_vector(31 downto 0) := (others => '0');
        o_destination_address_not_found_error   : out std_logic := '0'
        );
end route_table;

architecture arch_route_table of route_table is
    type t_ROUTE_TABLE_STATE_TYPE is (IDLE, CONNECTING_PORT, DISCONNECTING_PORT, NEW_SEQNUM);
    signal route_table_state_reg, route_table_state_next                                    : t_ROUTE_TABLE_STATE_TYPE := IDLE;
    type t_SOURCE_ADDRESS_FIELD is array (1 to 5) of unsigned(15 downto 0);
    signal source_address_reg, source_address_next                                          : t_SOURCE_ADDRESS_FIELD := (others => (others => '0'));
    type t_SEQNUM_FIELD is array (1 to 5) of unsigned(31 downto 0);
    signal seqnum_reg, seqnum_next                                                          : t_SEQNUM_FIELD := (others => (others => '0'));
    type t_DISCONNECT_SEQNUM_FIELD is array (1 to 5) of unsigned(31 downto 0);
    signal seqnum_if_disconnection_reg, seqnum_if_disconnection_next                        : t_DISCONNECT_SEQNUM_FIELD := (others => (others => '0'));
    signal seqnum_error_reg, seqnum_error_next                                              : std_logic:= '0';
    signal expected_seqnum_reg, expected_seqnum_next                                        : unsigned(31 downto 0) := (others => '0');
    signal destination_address_not_found_error_reg, destination_address_not_found_error_next: std_logic:= '0';
    signal route_table_filled_reg, route_table_filled_next                                  : std_logic:= '0'; 
    signal w_port                                                                           : integer := 0;

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
            route_table_state_reg                   <= IDLE;
            route_table_filled_reg                  <= '0'; 
            seqnum_error_reg                        <= '0';
            destination_address_not_found_error_reg <= '0';
            expected_seqnum_reg                     <= (others => '0');
        end if;

        if rising_edge(clk) and reset = '0' then
            route_table_state_reg                   <= route_table_state_next;
            source_address_reg                      <= source_address_next; 
            seqnum_reg                              <= seqnum_next; 
            seqnum_if_disconnection_reg             <= seqnum_if_disconnection_next; 
            route_table_filled_reg                  <= route_table_filled_next;
            destination_address_not_found_error_reg <= destination_address_not_found_error_next;
            seqnum_error_reg                        <= seqnum_error_next;
            expected_seqnum_reg                     <= expected_seqnum_next;
        end if;
    end process;

    Route_Table_State_Transition_Logic: process(i_flag, i_ready, route_table_state_reg,route_table_filled_reg)
    begin
        route_table_state_next <= route_table_state_reg;

        case route_table_state_reg is
            when IDLE =>

                if (i_flag(7) = '1' and i_flag(0) = '0') and i_ready = '1' and route_table_filled_reg = '0' then
                    route_table_state_next <= CONNECTING_PORT;
                end if;

                if (i_flag(7) = '0' and i_flag(0) = '1') and i_ready = '1' and route_table_filled_reg = '0' then
                    route_table_state_next <= DISCONNECTING_PORT;
                end if;

                if  (i_flag(7) = '0' and i_flag(0) = '0') and i_ready = '1' and route_table_filled_reg = '0' then
                    route_table_state_next <= NEW_SEQNUM;
                end if;
            
            when CONNECTING_PORT =>

            when DISCONNECTING_PORT =>
            
            when NEW_SEQNUM =>
        
        end case;

    end process;

    Route_Table_State_Attribution_Logic: process(w_port, i_seqnum, i_source_address, route_table_filled_reg, source_address_reg,seqnum_reg,
     seqnum_if_disconnection_reg,route_table_state_reg)
    begin

        source_address_next          <= source_address_reg; 
        seqnum_next                  <= seqnum_reg; 
        seqnum_if_disconnection_next <= seqnum_if_disconnection_reg; 
        route_table_filled_next      <= route_table_filled_reg;

        case route_table_state_reg is
            when IDLE =>

            when CONNECTING_PORT =>
                if (route_table_filled_reg = '0')  then
                    source_address_next(w_port)      <= unsigned(i_source_address);
                    seqnum_next(w_port)              <= unsigned(i_seqnum);
                    route_table_filled_next          <= '1';
                end if;

            when DISCONNECTING_PORT =>
                if (route_table_filled_reg = '0') then
                    source_address_next(w_port)             <= (others => '0');
                    seqnum_next(w_port)                     <= (others => '0');
                    seqnum_if_disconnection_next(w_port)    <= seqnum_reg(w_port) + 1;
                    route_table_filled_next                 <= '1';
                end if;

            when NEW_SEQNUM =>
                if (route_table_filled_reg = '0') then
                    seqnum_next(w_port)              <= seqnum_reg(w_port) + 1;
                    route_table_filled_next          <= '1';
                end if;

            when others =>

        end case;
    end process;

    Seqnum_Validation_Attribution_Logic: process(i_seqnum, w_port,route_table_state_reg, seqnum_error_reg, route_table_filled_reg, seqnum_reg,
    seqnum_if_disconnection_reg,expected_seqnum_reg)
    begin

        seqnum_error_next    <= seqnum_error_reg;
        expected_seqnum_next <= expected_seqnum_reg;

        case route_table_state_reg is
            when IDLE =>

            when CONNECTING_PORT =>

            when DISCONNECTING_PORT =>
                if (route_table_filled_reg = '1' and seqnum_if_disconnection_reg(w_port) /= unsigned(i_seqnum)) then
                    expected_seqnum_next <= seqnum_if_disconnection_reg(w_port);
                    seqnum_error_next    <= '1';
                end if;

            when NEW_SEQNUM =>
                if (route_table_filled_reg = '1' and seqnum_reg(w_port) /= unsigned(i_seqnum)) then
                    expected_seqnum_next <=  seqnum_reg(w_port); 
                    seqnum_error_next    <= '1';
                end if;

            when others =>

        end case;
    end process;

    Destination_Address_Validation: process(i_flag,i_destination_address,route_table_filled_reg, destination_address_not_found_error_reg,
     source_address_reg)
    begin

        destination_address_not_found_error_next <= destination_address_not_found_error_reg;

        if (i_flag(0) = '0') and (i_flag(7) = '0') and (route_table_filled_reg = '1') and (i_destination_address /= std_logic_vector(source_address_reg(w_port))) then
            destination_address_not_found_error_next <= '1';
        end if;
    end process;

o_seqnum_error                        <= seqnum_error_reg;
o_destination_address_not_found_error <= destination_address_not_found_error_reg;
o_expected_seqnum                     <= std_logic_vector(expected_seqnum_reg);

end arch_route_table;



