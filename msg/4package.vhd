         -- quarto pacote (porta 2 envia para porta 1)
            input_test_last <= '0';
            if (input_test_last = '0') then

                -- Packet length
                clock_cycle_with_data(input_test_clk, input_test_data , X"00");
                clock_cycle_with_data(input_test_clk, input_test_data , X"07");

                -- checksum
                clock_cycle_with_data(input_test_clk, input_test_data , X"10");
                clock_cycle_with_data(input_test_clk, input_test_data , X"86");

                -- seq_num
                clock_cycle_with_data(input_test_clk, input_test_data , X"00");
                clock_cycle_with_data(input_test_clk, input_test_data , X"00");
                clock_cycle_with_data(input_test_clk, input_test_data , X"00");
                clock_cycle_with_data(input_test_clk, input_test_data , X"06");

                -- clpr
                clock_cycle_with_data(input_test_clk, input_test_data , X"00"); -- flag
                clock_cycle_with_data(input_test_clk, input_test_data , X"18"); -- protocol

                -- dummy
                clock_cycle_with_data(input_test_clk, input_test_data , X"00");
                clock_cycle_with_data(input_test_clk, input_test_data , X"00");

                -- src_addr
                clock_cycle_with_data(input_test_clk, input_test_data , X"00");
                clock_cycle_with_data(input_test_clk, input_test_data , X"02");

                -- dest_addr
                clock_cycle_with_data(input_test_clk, input_test_data , X"00");
                clock_cycle_with_data(input_test_clk, input_test_data , X"01");

                -- payload
                clock_cycle_with_data(input_test_clk, input_test_data , X"00");
                clock_cycle_with_data(input_test_clk, input_test_data , X"01");
                clock_cycle_with_data(input_test_clk, input_test_data , X"21");
                clock_cycle_with_data(input_test_clk, input_test_data , X"64");
                clock_cycle_with_data(input_test_clk, input_test_data , X"6C");
                clock_cycle_with_data(input_test_clk, input_test_data , X"72");
                clock_cycle_with_data(input_test_clk, input_test_data , X"6F");
                clock_cycle_with_data(input_test_clk, input_test_data , X"57");
                clock_cycle_with_data(input_test_clk, input_test_data , X"20");
                clock_cycle_with_data(input_test_clk, input_test_data , X"6F");
                clock_cycle_with_data(input_test_clk, input_test_data , X"6C");
                clock_cycle_with_data(input_test_clk, input_test_data , X"6C");
                clock_cycle_with_data(input_test_clk, input_test_data , X"65");
                clock_cycle_with_data(input_test_clk, input_test_data , X"48");
                
                input_test_last <= '1';
                
            end if;

            if (input_test_last = '1') then 
                clock_cycle(input_test_clk);
            end if;
           -- fim do quarto pacote