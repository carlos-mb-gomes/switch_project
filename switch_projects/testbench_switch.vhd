library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_switch is
end tb_switch;

architecture behavior of tb_switch is
    signal counter_clk: integer := 10;
    signal i_testbench_clk, i_testbench_last : std_logic := '0';
    signal i_testbench_valid: std_logic := '0';
    signal o_testbench_ready: std_logic := '0';
    
    signal o_testbench_last: std_logic := '0';
    signal o_testbench_valid: std_logic := '0';
    signal i_testbench_ready: std_logic := '0';

    signal i_testbench_data: std_logic_vector(7 downto 0) := "00000000";
    signal input_test_ports: std_logic_vector(4 downto 0) := "00000";

    component switch
        port(
            clk, i_valid, i_last : in std_logic;
            o_ready: out std_logic;
            i_ready: in std_logic;
            i_data : in std_logic_vector(7 downto 0);
            i_ports: in std_logic_vector(4 downto 0);
            o_valid: out std_logic;
            o_last: out std_logic
        );
    end component;

    procedure clock_cycle(signal clk : inout std_logic; signal counter: inout integer) is
    begin
        -- ajustado mudança de clk a cada 2 ns
        for i in 0 to counter-1 loop 
            clk <= '0';
            wait for 2 ns;
            clk <= '1';
            wait for 2 ns;
        end loop;
    end procedure clock_cycle;


    procedure i_valid_signal(signal clk : inout std_logic; signal data : inout std_logic; value : std_logic) is
    begin
        -- ajustado mudança de clk a cada 2 ns
        clk <= '0';
        wait for 2 ns;
        data <= value;
        clk <= '1';
        wait for 2 ns;
    end procedure i_valid_signal;


    procedure i_ready_signal(signal clk : inout std_logic; signal data : inout std_logic; value : std_logic) is
    begin
        -- ajustado mudança de clk a cada 2 ns
        clk <= '0';
        wait for 2 ns;
        data <= value;
        clk <= '1';
        wait for 2 ns;
    end procedure i_ready_signal;


    procedure i_last_signal(signal clk : inout std_logic; signal data1 : inout std_logic; signal data2 : inout std_logic; signal data3 : inout std_logic; value : std_logic; signal data4 : inout std_logic_vector(7 downto 0); value_data : std_logic_vector(7 downto 0)) is
    begin
        -- ajustado mudança de clk a cada 2 ns
        clk <= '0';
        wait for 2 ns;
        data4 <= value_data;
        clk <= '1';
        data1 <= '1';
        wait for 2 ns;
        clk <= '0';
        wait for 2 ns;
        data1 <= value;
        data2 <= value;
        data3 <= value;
        data4 <= x"00";
        clk <= '1';
        wait for 2 ns;
    end procedure i_last_signal;

    procedure clock_cycle_with_data(signal clk : inout std_logic; signal data : inout std_logic_vector(7 downto 0); value : std_logic_vector(7 downto 0)) is
    begin
        -- ajustado mudança de clk a cada 2 ns
        clk <= '0';
        wait for 2 ns;
        data <= value;
        clk <= '1';
        wait for 2 ns;
    end procedure clock_cycle_with_data;

begin
    top_module: switch
        port map (
            clk => i_testbench_clk,
            i_valid => i_testbench_valid,
            i_last => i_testbench_last,
            i_ports => input_test_ports,
            i_data => i_testbench_data,
            o_ready => open,
            i_ready => i_testbench_ready,
            o_valid => open,
            o_last => open  
    );

    process
    begin
        i_testbench_last <= '0';
        i_testbench_valid <= '0';
        if (i_testbench_last = '0' and i_testbench_valid = '0') then
                i_valid_signal(i_testbench_clk, i_testbench_valid ,'1');
                

            -- pacote 1
                input_test_ports <= "00001";

                -- Packet length
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"04");
                -- checksum
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"7F");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"E1");

                -- seq_num
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"02");

                -- clpr
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"80"); -- flag
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"18"); -- protocol

                -- dummy
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");

                -- src_addr
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"01");

                -- dest_addr
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                i_last_signal(i_testbench_clk, i_testbench_last, i_testbench_valid, o_testbench_ready ,'0', i_testbench_data, x"00");

                i_ready_signal(i_testbench_clk, i_testbench_ready ,'1');
                

                clock_cycle(i_testbench_clk, counter_clk);



            -- pacote 2

                i_valid_signal(i_testbench_clk, i_testbench_valid ,'1');



                input_test_ports <= "00010";

                -- Packet length
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"04");

                -- checksum
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"7F");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"DC");

                -- seq_num
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"05");

                -- clpr
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"80"); -- flag
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"18"); -- protocol

                -- dummy
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");

                -- src_addr
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"02");

                -- dest_addr
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                i_last_signal(i_testbench_clk, i_testbench_last, i_testbench_valid, o_testbench_ready ,'0', i_testbench_data, x"00");

                -- transição entre pacotes

                i_ready_signal(i_testbench_clk, i_testbench_ready ,'1');
                
                clock_cycle(i_testbench_clk, counter_clk);


                clock_cycle(i_testbench_clk, counter_clk);


            -- pacote 3
                i_valid_signal(i_testbench_clk, i_testbench_valid ,'1');


                input_test_ports <= "00001";

                -- Packet length
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"07");

                -- checksum
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"AD");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"EC");

                -- seq_num
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"02");

                -- clpr
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00"); -- flag
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"18"); -- protocol

                -- dummy
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");

                -- src_addr
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"01");

                -- dest_addr
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"02");

                -- payload
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"48");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"65"); 
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"6C"); 
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"6C"); 
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"6F"); 
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"20"); 
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"57"); 
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"6F"); 
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"72"); 
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"6C"); 
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"64"); 
                i_last_signal(i_testbench_clk, i_testbench_last, i_testbench_valid, o_testbench_ready ,'0', i_testbench_data, x"61");

                -- transicao entre pacotes
                i_ready_signal(i_testbench_clk, i_testbench_ready ,'1');
                
                clock_cycle(i_testbench_clk, counter_clk);


                clock_cycle(i_testbench_clk, counter_clk);



                -- pacote 4
                i_valid_signal(i_testbench_clk, i_testbench_valid ,'1');

                input_test_ports <= "00010";

                -- Packet length
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"07");

                -- checksum
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"10");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"86");

                -- seq_num
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"06");

                -- clpr
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00"); -- flag
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"18"); -- protocol

                -- dummy
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");

                -- src_addr
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"02");

                -- dest_addr
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"00");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"01");

                -- payload
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"21");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"64");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"6C");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"72");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"6F");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"57");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"20");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"6F");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"6C");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"6C");
                clock_cycle_with_data(i_testbench_clk, i_testbench_data , X"65");
                i_last_signal(i_testbench_clk, i_testbench_last, i_testbench_valid, o_testbench_ready ,'0', i_testbench_data, x"48");

                i_ready_signal(i_testbench_clk, i_testbench_ready ,'1');
                
                clock_cycle(i_testbench_clk, counter_clk);

                clock_cycle(i_testbench_clk, counter_clk);



        end if;

        clock_cycle(i_testbench_clk,counter_clk);

    end process;

end behavior;


