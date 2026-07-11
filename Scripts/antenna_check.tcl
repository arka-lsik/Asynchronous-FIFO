set DESIGN  "async_fifo"
set PDK     "/home/lenovo_arka/OpenROAD-flow-scripts/flow/platforms/sky130hd"
set WORK    "/home/lenovo_arka/async_fifo_pd"

read_lef   $PDK/lef/sky130_fd_sc_hd.tlef
read_lef   $PDK/lef/sky130_fd_sc_hd_merged.lef
read_liberty $PDK/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog $WORK/netlist/async_fifo_netlist.v
link_design  $DESIGN
read_sdc     $WORK/async_fifo.sdc
read_def     $WORK/results/step8_detailed_route.def

puts "Antenna Check"
check_antennas -report_file $WORK/results/antenna.rpt
puts "Antenna Check COMPLETE"
