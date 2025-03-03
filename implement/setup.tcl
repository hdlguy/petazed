# This script sets up a Vivado project with all ip references resolved.
close_project -quiet
file delete -force proj.xpr *.os *.jou *.log proj.srcs proj.cache proj.runs
#
create_project -force proj 
#set_property part xc7z020clg400-1 [current_project]
set_property board_part avnet-tria:microzed_7020:part0:1.4 [current_project]
#set_property board_part avnet.com:zedboard:part0:1.4 [current_project]
#set_property part xc7z020clg400-1 [current_project]
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]
load_features ipintegrator
tclapp::install ultrafast -quiet

#read_ip ../source/fader2/prod_ila/prod_ila.xci

#upgrade_ip -quiet  [get_ips *]
#generate_target {all} [get_ips *]

# make the Zynq block diagram
source ../source/system.tcl
generate_target {synthesis implementation} [get_files ./proj.srcs/sources_1/bd/system/system.bd]
set_property synth_checkpoint_mode None    [get_files ./proj.srcs/sources_1/bd/system/system.bd]


read_verilog -sv  [glob ../source/top.sv]

read_xdc ../source/top.xdc

close_project




