library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- botar o nome de arquivo de switch 

entity switch is
    Port (
        -- input ports
        clk: in std_logic;
        i_ports: in std_logic_vector(4 downto 0);
        -- interface handshake slave
        i_valid: in std_logic;
        o_ready: out std_logic; 
        i_ready: in std_logic;
        o_last: out std_logic;
        o_valid: out std_logic;
        -- output_tvalid: out std_logic;
        i_last: in std_logic; --acho que usado no handshake
        i_data: in std_logic_vector(7 downto 0) -- usado nos campos
        -- output ports
        );
end switch;

architecture arch_switch of switch is
    signal r_o_ready_reg, r_o_ready_next: std_logic:= '1';
    signal r_o_valid_reg, r_o_valid_next: std_logic:= '0';
    signal r_o_last_reg, r_o_last_next: std_logic:= '0'; 
    -- sinais intermerdiarios para preencher campos

    component header is
        port (
        i_o_ready: in std_logic;
        i_last: in std_logic;
        i_valid: in std_logic;

        i_ready: in std_logic;
        i_o_valid: in std_logic;
        i_o_last: in std_logic;
        
        clk: in std_logic;

        i_ports: in std_logic_vector(4 downto 0) := "00000";
        i_byte: in std_logic_vector(7 downto 0);
        
        o_packet_length: out std_logic_vector(15 downto 0) := x"0000";
        o_checksum: out std_logic_vector(15 downto 0) := x"0000";
        o_seqnum: out std_logic_vector(31 downto 0) := x"00000000";
        o_flag: out std_logic_vector(7 downto 0) := x"00";
        o_protocol: out std_logic_vector(7 downto 0) := x"00";
        o_dummy: out std_logic_vector(15 downto 0) := x"0000";
        o_source_address: out std_logic_vector(15 downto 0) := x"0000";
        o_destination_address: out std_logic_vector(15 downto 0) := x"0000"
        -- o_payload: out std_logic_vector(3839 downto 0) := (others => '0');
        -- o_payload_length: out integer
        );
    end component;

    
    -- component o_switch is
    -- Port (
    --     -- input data
    --     clk: in std_logic;
        
    --     o_ready: out std_logic;
    --     i_valid: in std_logic; 
    --     i_last: in std_logic;

    --     i_ready: in std_logic;
    --     o_valid: out std_logic;
    --     o_last: out std_logic;   

    --     i_sync: in std_logic:= '0';
    --     i_close: in std_logic:= '0';
    --     i_checksum_validation: in std_logic:= '0';
    --     i_payload_legth_validation: in std_logic:= '0';
    --     i_destination_not_found_validation: in std_logic:= '0';
    --     i_seqnum_validation: in std_logic:= '0';
    --     i_destination_address: in std_logic_vector(15 downto 0) := (others =>'0') ;
    --     i_source_address: in std_logic_vector(15 downto 0) := (others =>'0') ;
    --     i_ports: in std_logic_vector(4 downto 0):= (others =>'0') ;

    --     -- ports
    --     o_data: out std_logic_vector(7 downto 0):= (others =>'0');
    --     o_ports: out std_logic_vector(4 downto 0):= (others =>'0');
    --     o_flag_error: out std_logic_vector(5 downto 0):= (others =>'0');
    --     o_source_address: out std_logic_vector(15 downto 0):= (others =>'0');
    --     o_destination_address: out std_logic_vector(15 downto 0):= (others =>'0')
    --     );
    -- end component;

begin

    -- output_procesa: o_switch
    -- port map (
    --     clk => clk,
    --     o_ready => r_o_ready_reg,
    --     i_valid => i_valid, 
    --     i_last => i_last,

    --     i_ready => i_ready,
    --     o_valid => r_o_valid_reg,
    --     o_last => r_o_last_reg,    

    --     i_sync => '0',
    --     i_close => '0',
    --     i_checksum_validation => '0',
    --     i_payload_legth_validation => '0',
    --     i_destination_not_found_validation => '0',
    --     i_seqnum_validation => '0',
    --     i_destination_address => (others =>'0') ,
    --     i_source_address => (others =>'0') ,
    --     i_ports => (others =>'0') ,

    --     -- ports
    --     o_data => open,
    --     o_ports => open,
    --     o_flag_error => open,
    --     o_source_address => open, 
    --     o_destination_address => open

    -- );

    -- modulo do cabeçalho
    header_module: header
    port map(
            clk => clk,
            i_last => i_last,
            i_o_ready => r_o_ready_reg,
            i_valid => i_valid,
            i_ready => i_ready,
            i_o_valid => r_o_valid_reg,
            i_o_last => r_o_last_reg,
            i_ports => i_ports,
            i_byte => i_data,
            o_packet_length => open,
            o_checksum => open,
            o_seqnum => open,
            o_flag => open,
            o_protocol => open,
            o_dummy => open,
            o_source_address => open,
            o_destination_address => open
            -- o_payload => open,
            -- o_payload_length => open
    );


    process(clk)
    begin
        if rising_edge(clk) then
           r_o_valid_reg <= r_o_valid_next;
           r_o_ready_reg <= r_o_ready_next;
           r_o_last_reg <= r_o_last_next;
        end if;
    end process;



    Transition_signals: process(i_data, i_valid, i_last, i_ready,r_o_last_reg)
    begin 
        if i_last = '1' then
            r_o_ready_next <= '0';        
        end if;

        if i_ready = '1' then
            r_o_valid_next <= '1';
        end if;

        if r_o_last_reg = '1' then 
            r_o_ready_next <= '1';
            r_o_valid_next <= '0';
            r_o_last_next <= '0';
        end if;
    end process;
    
    o_ready <= r_o_ready_reg;
    o_valid <= r_o_valid_reg;
    o_last <= r_o_last_reg;
end arch_switch;







