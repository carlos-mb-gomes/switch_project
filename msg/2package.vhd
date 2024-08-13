
           -- segundo pacote (começa a conexão: porta 2)
           input_test_last <= '0';
           wait for 10 ns;
           -- Packet length
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"04");

           -- checksum
           clock_cycle_with_data(input_test_clk, input_test_data , X"7F");
           clock_cycle_with_data(input_test_clk, input_test_data , X"DC");

           -- seq_num
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"05");

           -- clpr
           clock_cycle_with_data(input_test_clk, input_test_data , X"80"); -- flag
           clock_cycle_with_data(input_test_clk, input_test_data , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");

           -- src_addr
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"02");

           -- dest_addr
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");

           wait for 10 ns;

           input_test_last <= '1';
           -- fim do segundo pacote 

           wait for 10 ns;
