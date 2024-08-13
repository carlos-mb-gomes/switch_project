library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity o_switch is
    Port (
        -- input data
        clk: in std_logic;
        
        o_ready: out std_logic;
        i_valid: in std_logic; 
        i_last: in std_logic;

        i_ready: in std_logic;
        o_valid: out std_logic;
        o_last: out std_logic;    
        
        -- input
        i_sync: in std_logic:= '0';
        i_close: in std_logic:= '0';
        i_checksum_validation: in std_logic:= '0';
        i_payload_legth_validation: in std_logic:= '0';
        i_destination_not_found_validation: in std_logic:= '0';
        i_seqnum_validation: in std_logic:= '0';
        i_destination_address: in std_logic_vector(15 downto 0) := (others =>'0') ;
        i_source_address: in std_logic_vector(15 downto 0) := (others =>'0') ;
        i_ports: in std_logic_vector(4 downto 0):= (others =>'0') ;

        -- output
        o_data: out std_logic_vector(7 downto 0):= (others =>'0');
        o_ports: out std_logic_vector(4 downto 0):= (others =>'0');
        o_flag_error: out std_logic_vector(5 downto 0):= (others =>'0');
        o_source_address: out std_logic_vector(15 downto 0):= (others =>'0');
        o_destination_address: out std_logic_vector(15 downto 0):= (others =>'0')

        

        );
end o_switch;

architecture arch_o_switch of o_switch is

begin
    process(i_sync)
    begin
        if i_sync = '1' then
            o_last <= '1';
        end if;
    end process;

end arch_o_switch;



