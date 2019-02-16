# This script sets up a Vivado project with all ip references resolved.
close_project -quiet
file delete -force proj.xpr *.os *.jou *.log proj.srcs proj.cache proj.runs
#
create_project -force proj 
set_property board_part em.avnet.com:zed:part0:1.3 [current_project]
#set_property part xc7z020clg400-1 [current_project]
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]
load_features ipintegrator
tclapp::install ultrafast -quiet

file delete -force ./ip
file mkdir ./ip

read_ip ../source/acc_fader/cos_rom/cos_rom.xci
read_ip ../source/fader2/fade_mixer/fade_mixer.xci
read_ip ../source/fader2/fade_ila/fade_ila.xci
#read_ip ../source/fader2/prod_ila/prod_ila.xci
read_ip ../source/fader2/param_vio/param_vio.xci
read_ip ../source/delay_line/delay_bram/delay_bram.xci

read_ip ../source/rx_if/data_clk_wiz/data_clk_wiz.xci
read_ip ../source/tx_if/tx_clock_wiz/tx_clock_wiz.xci
read_ip ../source/bb_ila/bb_ila.xci
read_ip ../source/spi_ila/spi_ila.xci
read_ip ../source/dds/sin_cos_rom/sin_cos_rom.xci
read_ip ../source/stim_ram/stim_bram_core/stim_bram_core.xci
read_ip ../source/capture_ram/capt_bram_core/capt_bram_core.xci
upgrade_ip -quiet  [get_ips *]
generate_target {all} [get_ips *]

# make the Zynq block diagram
source ../source/system.tcl
generate_target {synthesis implementation} [get_files ./proj.srcs/sources_1/bd/system/system.bd]
set_property synth_checkpoint_mode None    [get_files ./proj.srcs/sources_1/bd/system/system.bd]

write_hwdef -force -verbose ./results/system.hdf

# Read in the hdl source.
read_verilog -sv ../source/acc_fader/acc_fader.sv
read_verilog -sv ../source/delay_line/delay_line.sv
read_verilog -sv ../source/fader2/saturate.sv
read_verilog -sv ../source/fader2/fader2.sv

read_verilog -sv  [glob ../source/rx_if/rx_if.v]
read_verilog -sv  [glob ../source/tx_if/tx_if.v]
read_verilog -sv  [glob ../source/ad_iobuf.v]
read_verilog -sv  [glob ../source/freq_counter.sv]
read_verilog -sv  [glob ../source/axi_regfile/axi_regfile_v1_0_S00_AXI.v]
read_verilog -sv  [glob ../source/dds/dds.v]
read_verilog -sv  [glob ../source/stim_ram/stim_ram.v]
read_verilog -sv  [glob ../source/capture_ram/capture_ram.v]
read_verilog -sv  [glob ../source/top.sv]

read_xdc ../source/top.xdc
read_xdc ../source/zed_system_constr.xdc

read_xdc ../source/late.xdc
set_property used_in_synthesis false [get_files ../source/late.xdc]

close_project

#########################



