# Script to compile the FPGA all the way to bit file.
close_project -quiet

open_project proj.xpr
update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
open_run synth_1
report_drc                  -file ./results/post_synth_drc.rpt

reset_run   impl_1
launch_runs impl_1 -jobs 4
wait_on_run impl_1

open_run impl_1
write_checkpoint     -force ./results/post_route.dcp
write_bitstream      -force ./results/top.bit
write_debug_probes   -force ./results/probes.ltx
report_timing_summary -file ./results/post_route_timing_summary.rpt
report_utilization    -file ./results/post_route_utilization.rpt
close_project








