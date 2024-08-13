# ghdl -a o_switch.vhd &&
# ghdl -a route_table.vhd &&
ghdl -a validation.vhd &&
ghdl -a payload.vhd &&
ghdl -a header.vhd &&
ghdl -a switch.vhd &&
ghdl -a testbench_switch.vhd &&
ghdl -r tb_switch --vcd=switch.vcd --stop-time=40000ns && 
gtkwave switch.vcd 2>/dev/null
 
