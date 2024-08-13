        -- primeiro pacote (começa a conexão: porta 1)
           input_test_last <= '0';
           wait for 10 ns;
           -- Packet length
           clock_cycle_with_data(input_test_clk, input_test_data , X"10");
           clock_cycle_with_data(input_test_clk, input_test_data , X"04");


        --    clock_cycle_with_data(input_test_clk, input_test_data , X"00");
        --    clock_cycle_with_data(input_test_clk, input_test_data , X"04");
           -- checksum
           clock_cycle_with_data(input_test_clk, input_test_data , X"7F");
           clock_cycle_with_data(input_test_clk, input_test_data , X"E1");

           -- seq_num
           clock_cycle_with_data(input_test_clk, input_test_data , X"23");
           clock_cycle_with_data(input_test_clk, input_test_data , X"05");
           clock_cycle_with_data(input_test_clk, input_test_data , X"04");
           clock_cycle_with_data(input_test_clk, input_test_data , X"70");

        --    clock_cycle_with_data(input_test_clk, input_test_data , X"00");
        --    clock_cycle_with_data(input_test_clk, input_test_data , X"00");
        --    clock_cycle_with_data(input_test_clk, input_test_data , X"00");
        --    clock_cycle_with_data(input_test_clk, input_test_data , X"01");

           -- clpr
           clock_cycle_with_data(input_test_clk, input_test_data , X"80"); -- flag
           clock_cycle_with_data(input_test_clk, input_test_data , X"18"); -- protocol

           -- dummy
           clock_cycle_with_data(input_test_clk, input_test_data , X"54");
           clock_cycle_with_data(input_test_clk, input_test_data , X"13");


        --    clock_cycle_with_data(input_test_clk, input_test_data , X"00");
        --    clock_cycle_with_data(input_test_clk, input_test_data , X"00");

           -- src_addr
           
           clock_cycle_with_data(input_test_clk, input_test_data , X"01");
           clock_cycle_with_data(input_test_clk, input_test_data , X"01");

        --    clock_cycle_with_data(input_test_clk, input_test_data , X"00");
        --    clock_cycle_with_data(input_test_clk, input_test_data , X"01");

           -- dest_addr
           
           clock_cycle_with_data(input_test_clk, input_test_data , X"44");
           clock_cycle_with_data(input_test_clk, input_test_data , X"08");

        --    clock_cycle_with_data(input_test_clk, input_test_data , X"00");
        --    clock_cycle_with_data(input_test_clk, input_test_data , X"00");

           wait for 10 ns;

           input_test_last <= '1';
           -- fim do primeiro pacote 
           wait for 10 ns;