set DESIGN  "async_fifo"
set PDK     "/home/lenovo_arka/OpenROAD-flow-scripts/flow/platforms/sky130hd"
set WORK    "/home/lenovo_arka/async_fifo_pd"

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

puts "ERC Power Grid Check"
check_power_grid -net VDD
check_power_grid -net VSS
puts "ERC COMPLETE"
