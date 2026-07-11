create_clock -name wr_clk -period 10.000 [get_ports wr_clk]
create_clock -name rd_clk -period 10.000 [get_ports rd_clk]

set_clock_groups -asynchronous \
  -group [get_clocks wr_clk] \
  -group [get_clocks rd_clk]

set_input_delay  3.0 -clock wr_clk [get_ports {wr_en wr_data}]
set_input_delay  3.0 -clock rd_clk [get_ports {rd_en}]
set_output_delay 3.0 -clock rd_clk [get_ports {rd_data empty}]
set_output_delay 3.0 -clock wr_clk [get_ports {full}]

set_false_path -from [get_ports wr_rst_n]
set_false_path -from [get_ports rd_rst_n]

set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 [all_inputs]
set_load 0.01 [all_outputs]
