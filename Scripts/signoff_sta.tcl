set DESIGN  "async_fifo"
set PDK     "/path/to/OpenROAD-flow-scripts/flow/platforms/sky130hd"
set WORK    "/path/to/async_fifo_pd"
set PDKLIB  "/path/to/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib"

#Read LEF
read_lef $PDK/lef/sky130_fd_sc_hd.tlef
read_lef $PDK/lef/sky130_fd_sc_hd_merged.lef

puts "TT Corner (25C 1v80)"
read_liberty $PDKLIB/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog $WORK/netlist/async_fifo_netlist.v
link_design  $DESIGN
read_sdc     $WORK/async_fifo.sdc
read_spef    $WORK/results/async_fifo.spef
set wns_tt [sta::worst_slack -max]
set tns_tt [sta::total_negative_slack -max]
set wns_tt_hold [sta::worst_slack -min]
puts "TT Setup WNS: $wns_tt  Hold WNS: $wns_tt_hold  TNS: $tns_tt"

puts "SS Corner (100C 1v60)"
read_liberty $PDKLIB/sky130_fd_sc_hd__ss_100C_1v60.lib
read_verilog $WORK/netlist/async_fifo_netlist.v
link_design  $DESIGN
read_sdc     $WORK/async_fifo.sdc
read_spef    $WORK/results/async_fifo.spef
set wns_ss [sta::worst_slack -max]
set tns_ss [sta::total_negative_slack -max]
set wns_ss_hold [sta::worst_slack -min]
puts "SS Setup WNS: $wns_ss  Hold WNS: $wns_ss_hold  TNS: $tns_ss"

puts "FF Corner (n40C 1v95)"
read_liberty $PDKLIB/sky130_fd_sc_hd__ff_n40C_1v95.lib
read_verilog $WORK/netlist/async_fifo_netlist.v
link_design  $DESIGN
read_sdc     $WORK/async_fifo.sdc
read_spef    $WORK/results/async_fifo.spef
set wns_ff [sta::worst_slack -max]
set tns_ff [sta::total_negative_slack -max]
set wns_ff_hold [sta::worst_slack -min]
puts "FF Setup WNS: $wns_ff  Hold WNS: $wns_ff_hold  TNS: $tns_ff"

set fp [open $WORK/results/pvt_sta.rpt w]
puts $fp "PVT Corner Sign-off STA Results"
puts $fp "-------------------------------"
puts $fp "TT (025C 1v80): Setup WNS=$wns_tt  Hold WNS=$wns_tt_hold  TNS=$tns_tt"
puts $fp "SS (100C 1v60): Setup WNS=$wns_ss  Hold WNS=$wns_ss_hold  TNS=$tns_ss"
puts $fp "FF (n40C 1v95): Setup WNS=$wns_ff  Hold WNS=$wns_ff_hold  TNS=$tns_ff"
close $fp

puts "PVT STA COMPLETE"

