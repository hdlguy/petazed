# timing
create_clock -period 8.000 -name rx_clk [get_ports rx_clk_in_p]

# False paths between register file and dsp clock and vice versa
#set_max_delay -from [get_pins axi_regfile/slv_reg_reg*/C]              -to [get_clocks clkout_data_clk_wiz]               11
#set_max_delay -from [get_clocks clkout_data_clk_wiz]                   -to [get_pins {axi_regfile/axi_rdata_reg[*]/D}]    11
#clk_fpga_0 clk_fpga_1 rx_clk clkfbout_data_clk_wiz clkout_data_clk_wiz clkfbout_tx_clock_wiz clkout_tx_clock_wiz tx_clk_out_p

# false paths inside frequency counter
set_max_delay -datapath_only -from [get_pins freq_counter_i/trigger_reg/C]            -to [get_pins freq_counter_i/trigger_fb_reg/D]     11
set_max_delay -datapath_only -from [get_pins freq_counter_i/clk_count_latch_reg[*]/C] -to [get_pins freq_counter_i/freq_count_reg[*]/D]  11
set_max_delay -datapath_only -from [get_pins freq_counter_i/trigger_fb_reg/C]         -to [get_pins freq_counter_i/trigger_fb_axi_reg/D] 11

#set_max_delay -datapath_only -from [get_pins capture_ram_inst/sr_reg/C]               -to [get_pins {axi_regfile/axi_rdata_reg[*]/D}]    11
#set_max_delay -datapath_only -from [get_pins {axi_regfile/slv_reg_reg*/C}]            -to [get_pins {stim_ram_i/addrb_reg*/R}]           11.0
#set_max_delay -datapath_only -from [get_pins axi_regfile/slv_reg_reg*/C]              -to [get_pins tx_dds/sin_prod_reg/A[*]]            11
#set_max_delay -datapath_only -from [get_pins axi_regfile/slv_reg_reg*/C]              -to [get_pins tx_dds/cos_prod_reg/A[*]]            11
#set_max_delay -datapath_only -from [get_pins axi_regfile/slv_reg_reg*/C]              -to [get_pins axi_regfile/slv_reg_reg*/D]          11
#set_max_delay -datapath_only -from [get_pins axi_regfile/slv_reg_reg*/C]              -to [get_pins stim_ram_i/addrb_reg[*]/R]           11
#set_max_delay -datapath_only -from [get_pins axi_regfile/slv_reg_reg*/C]              -to [get_pins tx_dds/freq_acc_reg*/D]              11
#set_max_delay -datapath_only -from [get_pins axi_regfile/slv_reg_reg*/C]              -to [get_pins tx_data_imag_reg*/D]                 11
#set_max_delay -datapath_only -from [get_pins axi_regfile/slv_reg_reg*/C]              -to [get_pins tx_data_real_reg*/D]                 11
#set_max_delay -datapath_only -from [get_pins axi_regfile/slv_reg_reg*/C]              -to [get_pins tx_data_dv_reg/D]                    11
#set_max_delay -datapath_only -from [get_pins axi_regfile/slv_reg_reg*/C]              -to [get_pins stim_ram_i/dv_count_reg*/D]          11
#set_max_delay -datapath_only -from [get_pins axi_regfile/slv_reg_reg*/C]              -to [get_pins stim_ram_i/dv_out_reg/D]             11
#set_max_delay -datapath_only -from [get_pins axi_regfile/slv_reg_reg*/C]              -to [get_pins tx_dds/enable_reg_reg/D]             11

# ad9361

# Rx
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_clk_in_p]
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_clk_in_n]
set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_frame_in_p]
set_property -dict {PACKAGE_PIN N20 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_frame_in_n]
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[0]}]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[0]}]
set_property -dict {PACKAGE_PIN N22 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[1]}]
set_property -dict {PACKAGE_PIN P22 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[1]}]
set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[2]}]
set_property -dict {PACKAGE_PIN M22 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[2]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[3]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[3]}]
set_property -dict {PACKAGE_PIN L21 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[4]}]
set_property -dict {PACKAGE_PIN L22 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[4]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[5]}]
set_property -dict {PACKAGE_PIN T17 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[5]}]

# Tx
set_property -dict {PACKAGE_PIN J21 IOSTANDARD LVDS_25} [get_ports tx_clk_out_p]
set_property -dict {PACKAGE_PIN J22 IOSTANDARD LVDS_25} [get_ports tx_clk_out_n]
set_property -dict {PACKAGE_PIN R20 IOSTANDARD LVDS_25} [get_ports tx_frame_out_p]
set_property -dict {PACKAGE_PIN R21 IOSTANDARD LVDS_25} [get_ports tx_frame_out_n]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[0]}]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[0]}]
set_property -dict {PACKAGE_PIN P20 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[1]}]
set_property -dict {PACKAGE_PIN P21 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[1]}]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[2]}]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[2]}]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[3]}]
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[3]}]
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[4]}]
set_property -dict {PACKAGE_PIN K20 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[4]}]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[5]}]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[5]}]

# GPIO
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS25} [get_ports {gpio_status[0]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS25} [get_ports {gpio_status[1]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS25} [get_ports {gpio_status[2]}]
set_property -dict {PACKAGE_PIN E20 IOSTANDARD LVCMOS25} [get_ports {gpio_status[3]}]
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS25} [get_ports {gpio_status[4]}]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS25} [get_ports {gpio_status[5]}]
set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS25} [get_ports {gpio_status[6]}]
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS25} [get_ports {gpio_status[7]}]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[0]}]
set_property -dict {PACKAGE_PIN A19 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[1]}]
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[2]}]
set_property -dict {PACKAGE_PIN C22 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[3]}]
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS25} [get_ports gpio_en_agc]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS25} [get_ports gpio_sync]
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS25} [get_ports gpio_resetb]

set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS25} [get_ports enable]
set_property -dict {PACKAGE_PIN K21 IOSTANDARD LVCMOS25} [get_ports txnrx]

#  SPI interface on AD9361
set_property PACKAGE_PIN F18 [get_ports spi_csn]
set_property IOSTANDARD LVCMOS25 [get_ports spi_csn]
set_property PULLUP true [get_ports spi_csn]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS25} [get_ports spi_clk]
set_property -dict {PACKAGE_PIN E21 IOSTANDARD LVCMOS25} [get_ports spi_mosi]
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS25} [get_ports spi_miso]

# pmod signals (unused)
#set_property  -dict {PACKAGE_PIN  Y11    IOSTANDARD LVCMOS33}     [get_ports spi_udc_csn_tx]             ; ## JA1
#set_property  -dict {PACKAGE_PIN  AB11   IOSTANDARD LVCMOS33}     [get_ports spi_udc_csn_rx]             ; ## JA7
#set_property  -dict {PACKAGE_PIN  AA9    IOSTANDARD LVCMOS33}     [get_ports spi_udc_sclk]               ; ## JA4
#set_property  -dict {PACKAGE_PIN  AA11   IOSTANDARD LVCMOS33}     [get_ports spi_udc_data]               ; ## JA2
set_property -dict {PACKAGE_PIN Y10 IOSTANDARD LVCMOS33} [get_ports gpio_muxout_tx]
set_property -dict {PACKAGE_PIN AB9 IOSTANDARD LVCMOS33} [get_ports gpio_muxout_rx]


set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
