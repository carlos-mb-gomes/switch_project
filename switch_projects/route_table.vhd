library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity route_table is
    Port (
        -- input data
        clk: in std_logic;
        
        o_ready: out std_logic;
        i_valid: in std_logic; 
        i_last: in std_logic;

        i_ready: in std_logic;
        o_valid: out std_logic;
        o_last: out std_logic;    
        -- ports
        i_flag: in std_logic_vector(7 downto 0) := x"00";
        i_ports: in std_logic_vector(4 downto 0) := "00000";
        i_seqnum: in std_logic_vector(31 downto 0) := x"00000000";
        i_source_address: in std_logic_vector(15 downto 0) := x"0000";
        -- validation destination address not found
        i_destination_address: in std_logic_vector(15 downto 0) := x"0000"
        );
end route_table;

architecture arch_route_table of route_table is
    type t_ROUTE_TABLE_STATE_TYPE is (IDLE, CONNECTING_PORT, DISCONNECTING_PORT, NEW_SEQNUM);
    type t_PORT_SELECT_TYPE is (IDLE, FIRST_PORT, SECOND_PORT, THIRD_PORT, FOURTH_PORT, FIFTH_PORT);
    signal r_route_table_state_reg, r_route_table_state_next: t_ROUTE_TABLE_STATE_TYPE := IDLE;
    signal r_port_select: t_PORT_SELECT_TYPE := IDLE;
    signal r_seqnum_1_reg, r_seqnum_1_next, r_seqnum_2_reg, r_seqnum_2_next, r_seqnum_3_reg, r_seqnum_3_next, r_seqnum_4_reg, r_seqnum_4_next, r_seqnum_5_reg, r_seqnum_5_next: unsigned(31 downto 0) := (others => '0');
    signal r_source_address_1_reg, r_source_address_1_next, r_source_address_2_reg, r_source_address_2_next, r_source_address_3_reg, r_source_address_3_next, r_source_address_4_reg, r_source_address_4_next, r_source_address_5_reg, r_source_address_5_next: unsigned(15 downto 0) := (others => '0');
    signal r_port_1_reg, r_port_1_next, r_port_2_reg, r_port_2_next, r_port_3_reg, r_port_3_next, r_port_4_reg, r_port_4_next, r_port_5_reg, r_port_5_next: std_logic := '0';
    signal r_destination_address_not_found_error: std_logic:= '0';

begin
    with i_ports select 
        r_port_select <= FIRST_PORT when "00001",
                         SECOND_PORT when "00010",
                         THIRD_PORT when  "00100",
                         FOURTH_PORT when "01000",
                         FIFTH_PORT when "10000",
                         IDLE when others;

    State_atualization: process(clk)
    begin
        if i_valid = '0' then
            r_route_table_state_reg <= IDLE;
        elsif rising_edge(clk) then
            r_route_table_state_reg <= r_route_table_state_next;
            -- ports
            r_port_1_reg <= r_port_1_next;
            r_port_2_reg <= r_port_2_next;
            r_port_3_reg <= r_port_3_next;
            r_port_4_reg <= r_port_4_next;
            r_port_5_reg <= r_port_5_next;
            -- seqnum
            r_seqnum_1_reg <= r_seqnum_1_next;
            r_seqnum_2_reg <= r_seqnum_2_next;
            r_seqnum_3_reg <= r_seqnum_3_next;
            r_seqnum_4_reg <= r_seqnum_4_next;
            r_seqnum_5_reg <= r_seqnum_5_next;
            -- source address 
            r_source_address_1_reg <= r_source_address_1_next;
            r_source_address_2_reg <= r_source_address_2_next;
            r_source_address_3_reg <= r_source_address_3_next;
            r_source_address_4_reg <= r_source_address_4_next;
            r_source_address_5_reg <= r_source_address_5_next;

        end if;
    end process;

    Port_Select :process(i_source_address)
    begin
        case r_port_select is
            when IDLE =>

            when FIRST_PORT =>
                if (r_route_table_state_reg = CONNECTING_PORT ) then
                    r_port_1_next <= '1'; 
                    r_seqnum_1_next <= unsigned(i_seqnum);
                    r_source_address_1_next <= unsigned(i_source_address);
                elsif (r_route_table_state_reg = DISCONNECTING_PORT ) then
                    r_seqnum_1_next <= (others => '0');
                    r_source_address_1_next <= (others => '0');
                elsif (r_route_table_state_reg = NEW_SEQNUM) then
                    r_seqnum_1_next <= r_seqnum_1_reg + 1;
                end if;

            when SECOND_PORT =>
                if (r_route_table_state_reg = CONNECTING_PORT) then
                    r_port_2_next <= '1';
                    r_seqnum_2_next <= unsigned(i_seqnum);
                    r_source_address_2_next <= unsigned(i_source_address);
                elsif (r_route_table_state_reg = DISCONNECTING_PORT) then
                    r_seqnum_2_next <= (others => '0');
                    r_source_address_2_next <= (others => '0');
                elsif (r_route_table_state_reg = NEW_SEQNUM) then
                    r_seqnum_2_next <= r_seqnum_2_reg + 1;
                end if;

            when THIRD_PORT =>     
                if (r_route_table_state_reg = CONNECTING_PORT ) then
                    r_port_3_next <= '1';
                    r_seqnum_3_next <= unsigned(i_seqnum);
                    r_source_address_3_next <= unsigned(i_source_address);
                elsif (r_route_table_state_reg = DISCONNECTING_PORT ) then
                    r_seqnum_3_next <= (others => '0');
                    r_source_address_3_next <= (others => '0');
                elsif (r_route_table_state_reg = NEW_SEQNUM) then
                    r_seqnum_3_next <= r_seqnum_3_reg + 1;
                end if;

            when FOURTH_PORT =>
                if (r_route_table_state_reg = CONNECTING_PORT ) then
                    r_port_4_next <= '1';
                    r_seqnum_4_next <= unsigned(i_seqnum);
                    r_source_address_4_next <= unsigned(i_source_address);
                elsif (r_route_table_state_reg = DISCONNECTING_PORT ) then
                    r_seqnum_4_next <= (others => '0');
                    r_source_address_4_next <= (others => '0');
                elsif (r_route_table_state_reg = NEW_SEQNUM) then
                    r_seqnum_4_next <= r_seqnum_4_reg + 1;
                end if;

            when FIFTH_PORT =>
                if (r_route_table_state_reg = CONNECTING_PORT ) then
                    r_port_5_next <= '1';
                    r_seqnum_5_next <= unsigned(i_seqnum);
                    r_source_address_5_next <= unsigned(i_source_address);
                elsif (r_route_table_state_reg = DISCONNECTING_PORT ) then
                    r_seqnum_5_next <= (others => '0');
                    r_source_address_5_next <= (others => '0');
                elsif (r_route_table_state_reg = NEW_SEQNUM) then
                    r_seqnum_5_next <= r_seqnum_5_reg + 1;
                end if;

        end case;
    end process;

    Route_table_Atualization: process(i_flag, r_route_table_state_reg)
    begin
        r_route_table_state_next <= r_route_table_state_reg;
        if (i_flag(7) = '1' and i_flag(0) = '0') then
            r_route_table_state_next <= CONNECTING_PORT;
        elsif (i_flag(7) = '0' and i_flag(0) = '1') then
            r_route_table_state_next <= DISCONNECTING_PORT;
        else 
            r_route_table_state_next <= NEW_SEQNUM;
        end if;
    end process;

-- REVER O DESTINATION ADDRESS
    -- Destination_address_validation: process(i_destination_address)
    -- begin
    --     if (i_flag(0) = '0') and (i_flag(7) = '0') then
    --         r_destination_address_not_found_error <= 
    --             ((unsigned(i_destination_address) = r_source_address_1_reg) or 
    --             (unsigned(i_destination_address) = r_source_address_2_reg) or 
    --             (unsigned(i_destination_address) = r_source_address_3_reg) or 
    --             (unsigned(i_destination_address) = r_source_address_4_reg) or 
    --             (unsigned(i_destination_address) = r_source_address_5_reg));
    --     end if;
    -- end process;


end arch_route_table;



