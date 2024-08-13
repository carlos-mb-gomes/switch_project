
           -- terceiro pacote (porta 1 envia para porta 2)
           input_test_last <= '0';
           wait for 10 ns;
           -- Packet length
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"07");

           -- checksum
           clock_cycle_with_data(input_test_clk, input_test_data , X"AD");
           clock_cycle_with_data(input_test_clk, input_test_data , X"EC");

           -- seq_num
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"02");

           -- clpr
           clock_cycle_with_data(input_test_clk, input_test_data , X"00"); -- flag
           clock_cycle_with_data(input_test_clk, input_test_data , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");

           -- src_addr
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"01");

           -- dest_addr
           clock_cycle_with_data(input_test_clk, input_test_data , X"00");
           clock_cycle_with_data(input_test_clk, input_test_data , X"02");

           -- payload
           clock_cycle_with_data(input_test_clk, input_test_data , X"48");
           clock_cycle_with_data(input_test_clk, input_test_data , X"65"); 
           clock_cycle_with_data(input_test_clk, input_test_data , X"6C"); 
           clock_cycle_with_data(input_test_clk, input_test_data , X"6C"); 
           clock_cycle_with_data(input_test_clk, input_test_data , X"6F"); 
           clock_cycle_with_data(input_test_clk, input_test_data , X"20"); 
           clock_cycle_with_data(input_test_clk, input_test_data , X"57"); 
           clock_cycle_with_data(input_test_clk, input_test_data , X"6F"); 
           clock_cycle_with_data(input_test_clk, input_test_data , X"72"); 
           clock_cycle_with_data(input_test_clk, input_test_data , X"6C"); 
           clock_cycle_with_data(input_test_clk, input_test_data , X"64"); 
           clock_cycle_with_data(input_test_clk, input_test_data , X"61"); 

           input_test_last <= '1';
           -- fim do terceiro pacote 