set DESIGN "async_fifo"
set PDK    "/home/lenovo_arka/OpenROAD-flow-scripts/flow/platforms/sky130hd"
set WORK   "/home/lenovo_arka/async_fifo_pd"

puts "Reading PDK"

read_lef $PDK/lef/sky130_fd_sc_hd.tlef
read_lef $PDK/lef/sky130_fd_sc_hd_merged.lef
read_liberty $PDK/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

puts "Reading Design"

read_verilog $WORK/netlist/async_fifo_netlist.v
link_design $DESIGN
read_sdc $WORK/async_fifo.sdc


puts "STEP 1: Floorplan"

initialize_floorplan \
  -die_area "0 0 120 120" \
  -core_area "5 5 115 115" \
  -site unithd

make_tracks
write_def $WORK/results/step1_floorplan.def

puts "DONE: step1 floorplan"


puts "STEP 2: IO Pins"

place_pins \
  -hor_layers met3 \
  -ver_layers met2

write_def $WORK/results/step2_pins.def

puts "DONE: step2 IO pins"


puts "STEP 3: PDN"

add_global_connection \
  -net VDD \
  -pin_pattern {^VPWR$} \
  -power

add_global_connection \
  -net VDD \
  -pin_pattern {^VPB$}

add_global_connection \
  -net VSS \
  -pin_pattern {^VGND$} \
  -ground

add_global_connection \
  -net VSS \
  -pin_pattern {^VNB$}

set_voltage_domain \
  -name CORE \
  -power VDD \
  -ground VSS

define_pdn_grid \
  -name grid \
  -voltage_domain CORE \
  -starts_with POWER

add_pdn_stripe \
  -grid grid \
  -layer met1 \
  -width 0.48 \
  -followpins

add_pdn_stripe \
  -grid grid \
  -layer met4 \
  -width 0.48 \
  -pitch 56.0 \
  -offset 2.0 \
  -starts_with POWER

add_pdn_stripe \
  -grid grid \
  -layer met5 \
  -width 1.60 \
  -pitch 56.0 \
  -offset 2.0 \
  -starts_with POWER

add_pdn_connect \
  -grid grid \
  -layers {met1 met4}

add_pdn_connect \
  -grid grid \
  -layers {met4 met5}

pdngen

write_def $WORK/results/step3_pdn.def

puts "DONE: step3 PDN"


puts "STEP 4: Global Placement"

set_placement_padding \
  -global \
  -left 2 \
  -right 2

global_placement -density 0.65

write_def $WORK/results/step4_global_placement.def

puts "DONE: step4 global placement"


puts "STEP 5: Detailed Placement"

detailed_placement
check_placement -verbose

write_def $WORK/results/step5_detailed_placement.def

puts "DONE: step5 detailed placement"


puts "STEP 6: CTS"

clock_tree_synthesis \
  -root_buf sky130_fd_sc_hd__buf_8 \
  -buf_list {sky130_fd_sc_hd__buf_4 sky130_fd_sc_hd__buf_8} \
  -sink_clustering_enable

set_propagated_clock [all_clocks]

detailed_placement
check_placement -verbose

write_def $WORK/results/step6_cts.def

puts "DONE: step6 CTS"


puts "STEP 7: Pre-Route Reports"

estimate_parasitics -placement

set wns_val [sta::worst_slack -max]
set tns_val [sta::total_negative_slack -max]

set fp [open $WORK/results/wns.rpt w]
puts $fp "wns $wns_val"
close $fp

set fp [open $WORK/results/tns.rpt w]
puts $fp "tns $tns_val"
close $fp

set fp [open $WORK/results/area.rpt w]
puts $fp [report_design_area]
close $fp

report_power -digits 6 > $WORK/results/power.rpt

puts "PRE_ROUTE_TIMING_START"
report_checks -path_delay max -digits 4
puts "PRE_ROUTE_TIMING_END"

puts "PRE_ROUTE_HOLD_START"
report_checks -path_delay min -digits 4
puts "PRE_ROUTE_HOLD_END"

puts "CLOCK_SKEW_START"
report_clock_skew
puts "CLOCK_SKEW_END"

puts "DONE: step7 pre-route reports"


puts "STEP 8: Global Routing"

set_routing_layers \
  -signal met1-met5 \
  -clock met1-met5

set_global_routing_layer_adjustment met1 0.65
set_global_routing_layer_adjustment met2 0.65

global_route \
  -guide_file $WORK/results/route.guide \
  -congestion_iterations 50

write_def $WORK/results/step8_global_route.def

puts "DONE: step8 global routing"


puts "STEP 9: Post-Global-Route Reports"

estimate_parasitics -global_routing

set wns_val [sta::worst_slack -max]
set tns_val [sta::total_negative_slack -max]

set fp [open $WORK/results/wns_routed.rpt w]
puts $fp "wns $wns_val"
close $fp

set fp [open $WORK/results/tns_routed.rpt w]
puts $fp "tns $tns_val"
close $fp

puts "POST_ROUTE_TIMING_START"
report_checks -path_delay max -digits 4
puts "POST_ROUTE_TIMING_END"

puts "POST_ROUTE_HOLD_START"
report_checks -path_delay min -digits 4
puts "POST_ROUTE_HOLD_END"

puts "DONE: step9 post-global-route reports"


puts "STEP 10: Detailed Routing"

detailed_route \
  -guide $WORK/results/route.guide \
  -output_drc $WORK/results/drc.rpt \
  -bottom_routing_layer met1 \
  -top_routing_layer met5 \
  -verbose 1

write_def $WORK/results/step10_detailed_route.def
write_db $WORK/results/step10_detailed_route.odb

puts "DONE: step10 detailed routing"
puts "FLOW COMPLETE"
