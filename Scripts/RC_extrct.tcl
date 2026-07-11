set DESIGN  "async_fifo"
set PDK     "/home/lenovo_arka/OpenROAD-flow-scripts/flow/platforms/sky130hd"
set WORK    "/home/lenovo_arka/async_fifo_pd"
set RCX     "/home/lenovo_arka/eda_tools/pdks/volare/sky130/versions/cd1748bb197f9b7af62a54507de6624e30363943/sky130A/libs.tech/openlane/rules.openrcx.sky130A.nom.spef_extractor"

read_lef   $PDK/lef/sky130_fd_sc_hd.tlef
read_lef   $PDK/lef/sky130_fd_sc_hd_merged.lef
read_liberty $PDK/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog $WORK/netlist/async_fifo_netlist.v
link_design  $DESIGN
read_sdc     $WORK/async_fifo.sdc

initialize_floorplan \
  -die_area  "0 0 120 120" \
  -core_area "5 5 115 115" \
  -site      unithd
make_tracks
place_pins -hor_layers met3 -ver_layers met2

add_global_connection -net VDD -pin_pattern {^VPWR$} -power
add_global_connection -net VDD -pin_pattern {^VPB$}
add_global_connection -net VSS -pin_pattern {^VGND$} -ground
add_global_connection -net VSS -pin_pattern {^VNB$}
set_voltage_domain -name CORE -power VDD -ground VSS
define_pdn_grid -name grid -voltage_domain CORE -starts_with POWER
add_pdn_stripe -grid grid -layer met1 -width 0.48 -followpins
add_pdn_stripe -grid grid -layer met4 -width 0.48 -pitch 56.0 -offset 2.0 -starts_with POWER
add_pdn_stripe -grid grid -layer met5 -width 1.60 -pitch 56.0 -offset 2.0 -starts_with POWER
add_pdn_connect -grid grid -layers {met1 met4}
add_pdn_connect -grid grid -layers {met4 met5}
pdngen

set_placement_padding -global -left 2 -right 2
global_placement -density 0.65
detailed_placement
clock_tree_synthesis \
  -root_buf   sky130_fd_sc_hd__buf_8 \
  -buf_list   {sky130_fd_sc_hd__buf_4 sky130_fd_sc_hd__buf_8} \
  -sink_clustering_enable
set_propagated_clock [all_clocks]
detailed_placement

global_route \
  -guide_file $WORK/results/route.guide \
  -congestion_iterations 50

detailed_route \
  -guide        $WORK/results/route.guide \
  -output_drc   $WORK/results/drc.rpt \
  -bottom_routing_layer met1 \
  -top_routing_layer    met5 \
  -verbose 1

puts "RC Extraction"
set_wire_rc -layer met2
extract_parasitics -ext_model_file $RCX

write_spef $WORK/results/async_fifo.spef

set wns_val [sta::worst_slack -max]
set tns_val [sta::total_negative_slack -max]

set fp [open $WORK/results/wns_rcx.rpt w]
puts $fp "wns $wns_val"

close $fp

set fp [open $WORK/results/tns_rcx.rpt w]
puts $fp "tns $tns_val"
close $fp

puts "WNS after RC: $wns_val"
puts "TNS after RC: $tns_val"
puts "RC Extraction COMPLETE"

