// top.v is a the top-level of a design to exercise the Analog Devices FMCOMMS3 eval board.
// A DDS can be used to drive either Tx port with a synthesized pure tone.
// Also, an arbitrary waveform memory can be used to transmit modulated signals.
// Finally, a frequency selected fader can be insterted, after the ARB or on the ADC Rx data.
`timescale 1ns/100ps

module top (

    inout logic  [14:0]  ddr_addr,
    inout logic  [ 2:0]  ddr_ba,
    inout logic          ddr_cas_n,
    inout logic          ddr_ck_n,
    inout logic          ddr_ck_p,
    inout logic          ddr_cke,
    inout logic          ddr_cs_n,
    inout logic  [ 3:0]  ddr_dm,
    inout logic  [31:0]  ddr_dq,
    inout logic  [ 3:0]  ddr_dqs_n,
    inout logic  [ 3:0]  ddr_dqs_p,
    inout logic          ddr_odt,
    inout logic          ddr_ras_n,
    inout logic          ddr_reset_n,
    inout logic          ddr_we_n,

    inout logic          fixed_io_ddr_vrn,
    inout logic          fixed_io_ddr_vrp,
    inout logic  [53:0]  fixed_io_mio,
    inout logic          fixed_io_ps_clk,
    inout logic          fixed_io_ps_porb,
    inout logic          fixed_io_ps_srstb,

//    inout logic  [31:0]  gpio_bd,
    
    output logic [7:0]   led,

//    output logic         i2s_mclk,
//    output logic         i2s_bclk,
//    output logic         i2s_lrclk,
//    output logic         i2s_sdata_out,
//    input  logic         i2s_sdata_in,
    
    // ad9361 Rx
    input  logic         rx_clk_in_p,
    input  logic         rx_clk_in_n,
    input  logic         rx_frame_in_p,
    input  logic         rx_frame_in_n,
    input  logic [ 5:0]  rx_data_in_p,
    input  logic [ 5:0]  rx_data_in_n,

    // ad9361 Tx
    output logic         tx_clk_out_p,
    output logic         tx_clk_out_n,
    output logic         tx_frame_out_p,
    output logic         tx_frame_out_n,
    output logic [ 5:0]  tx_data_out_p,
    output logic [ 5:0]  tx_data_out_n,
    
    output logic         txnrx,
    output logic         enable,
    
    //input  logic         otg_vbusoc,
    
    inout  logic         iic_scl,
    inout  logic         iic_sda,
    
    inout  logic         gpio_muxout_tx,
    inout  logic         gpio_muxout_rx,
    inout  logic         gpio_resetb,
    inout  logic         gpio_sync,
    inout  logic         gpio_en_agc,
    inout  logic [ 3:0]  gpio_ctl,
    inout  logic [ 7:0]  gpio_status,

    // spi interface to AD9361 transceiver.
    output logic         spi_csn,
    output logic         spi_clk,
    output logic         spi_mosi,
    input  logic         spi_miso,
    //
    inout  logic  [1:0]  iic_mux_sda,
    inout  logic  [1:0]  iic_mux_scl
    //    
    //output logic         spi_udc_csn_tx,
    //output logic         spi_udc_csn_rx,
    //output logic         spi_udc_sclk,
    //output logic         spi_udc_data
);


    // declare some signals and attach them to the register file for software control
    logic [31:0] freq_count;
    logic [31:0] tx_freq, tx_chirp_rate;
    logic [17:0] tx_dds_gain;
    logic tx_dds_enable;    
    logic [1:0][3:0] tx_source_sel;    
    logic [3:0] fader_source_sel;    
    logic [13:0] tx_stim_ram_mod;   
    logic tx_stim_ram_enable; 
    logic capt_start, capt_done;
    
    localparam Nregs = 512;
    logic [Nregs-1:0][31:0] slv_read, slv_reg;
    
    assign slv_read[0] = 32'hDEAD_BEEF;
    assign slv_read[1] = 32'h76543210;
    assign slv_read[2] = freq_count;   

    assign tx_freq            = slv_reg[4];
    assign tx_chirp_rate      = slv_reg[5];
    assign tx_dds_enable      = slv_reg[6][0];    
    assign tx_dds_gain        = slv_reg[7][17:0];
    assign tx_source_sel      = slv_reg[8][7:0];
    assign tx_stim_ram_mod    = slv_reg[9][13:0];
    assign tx_stim_ram_enable = slv_reg[10][0];

    assign slv_read[10:3]     = slv_reg[10:3];

    assign capt_start         = slv_reg[11][0];

    assign slv_read[11][4]    = capt_done;
    assign slv_read[11][31:5] = slv_reg[11][31:5];
    assign slv_read[11][ 3:0] = slv_reg[11][3:0];

    assign fader_source_sel   = slv_reg[12][3:0]; // 0=stim ram, 1=dds, 2=rx0, 3=rx1

    assign slv_read[15:12]    = slv_reg[15:12];
    
    // here we wire up the fader run-time parameters.
    localparam N = 9; // number of delay channels in fader.
    localparam M = 8; // number of summed sinusoids per delay channel.
    logic [N-1:0][M-1:0][31:0]    fade_wd_sin_alpha; 
    logic [N-1:0][M-1:0][31:0]    fade_wd_cos_alpha; 
    logic [N-1:0][M-1:0][31:0]    fade_phi_imag;     // uniform random over [-pi:pi) ie, [-2^31:+(2^31)-1]
    logic [N-1:0][M-1:0][31:0]    fade_phi_real;     // uniform random over [-pi:pi) ie, [-2^31:+(2^31)-1]
    logic [N-1:0][24:0]           fade_gain;  // signed, 2.23 format, [-2.0, 2.0)
    logic [N-1:0][8:0]            fade_delay; // delay in baseband sample rate (1/30.72MHz) steps.
    localparam Fade_Base = 64;  // first register
    localparam Chan_Step = 40;  // spacing of register sets of each delay channel.
    genvar chan, soid;
    generate 
        for (chan=0; chan<N; chan++) begin
            for (soid=0; soid<M; soid++) begin
                // assign wd_cos_alpha
                assign fade_wd_cos_alpha [chan][soid] = slv_reg[Fade_Base+chan*Chan_Step+soid*4+0];
                // assign phi_real
                assign fade_phi_real     [chan][soid] = slv_reg[Fade_Base+chan*Chan_Step+soid*4+1];
                // assign wd_sin_alpha
                assign fade_wd_sin_alpha [chan][soid] = slv_reg[Fade_Base+chan*Chan_Step+soid*4+2];
                // assign phi_imag
                assign fade_phi_imag     [chan][soid] = slv_reg[Fade_Base+chan*Chan_Step+soid*4+3];
            end
            // assign delay value for channel.
            assign fade_delay [chan] = slv_reg[Fade_Base+chan*Chan_Step+4*M][8:0];
            // assign gain value for channel. 
            assign fade_gain  [chan] = slv_reg[Fade_Base+chan*Chan_Step+4*M+1][24:0];
            // make registers readable.
            assign slv_read[Fade_Base+chan*Chan_Step +: 34] = slv_reg[Fade_Base+chan*Chan_Step +: 34]; 
        end
    endgenerate

    logic axi_aclk; 
    logic axi_aresetn; 
    logic [31:0]M01_AXI_araddr;
    logic [2:0]M01_AXI_arprot;
    logic [0:0]M01_AXI_arready;
    logic [0:0]M01_AXI_arvalid;
    logic [31:0]M01_AXI_awaddr;
    logic [2:0]M01_AXI_awprot;
    logic [0:0]M01_AXI_awready;
    logic [0:0]M01_AXI_awvalid;
    logic [0:0]M01_AXI_bready;
    logic [1:0]M01_AXI_bresp;
    logic [0:0]M01_AXI_bvalid;
    logic [31:0]M01_AXI_rdata;
    logic [0:0]M01_AXI_rready;
    logic [1:0]M01_AXI_rresp;
    logic [0:0]M01_AXI_rvalid;
    logic [31:0]M01_AXI_wdata;
    logic [0:0]M01_AXI_wready;
    logic [3:0]M01_AXI_wstrb;
    logic [0:0]M01_AXI_wvalid;     
            
	axi_regfile_v1_0_S00_AXI #	(
		.C_S_AXI_DATA_WIDTH(32),
		.C_S_AXI_ADDR_WIDTH(11)
	) axi_regfile_inst (
        // register interface
        .slv_read(slv_read), 
        .slv_reg (slv_reg),  
        // axi interface
		.S_AXI_ACLK    (axi_aclk),
		.S_AXI_ARESETN (axi_aresetn),
        //
		.S_AXI_ARADDR  (M01_AXI_araddr ),
		.S_AXI_ARPROT  (M01_AXI_arprot ),
		.S_AXI_ARREADY (M01_AXI_arready),
		.S_AXI_ARVALID (M01_AXI_arvalid),
		.S_AXI_AWADDR  (M01_AXI_awaddr ),
		.S_AXI_AWPROT  (M01_AXI_awprot ),
		.S_AXI_AWREADY (M01_AXI_awready),
		.S_AXI_AWVALID (M01_AXI_awvalid),
		.S_AXI_BREADY  (M01_AXI_bready ),
		.S_AXI_BRESP   (M01_AXI_bresp  ),
		.S_AXI_BVALID  (M01_AXI_bvalid ),
		.S_AXI_RDATA   (M01_AXI_rdata  ),
		.S_AXI_RREADY  (M01_AXI_rready ),
		.S_AXI_RRESP   (M01_AXI_rresp  ),
		.S_AXI_RVALID  (M01_AXI_rvalid ),
		.S_AXI_WDATA   (M01_AXI_wdata  ),
		.S_AXI_WREADY  (M01_AXI_wready ),
		.S_AXI_WSTRB   (M01_AXI_wstrb  ),
		.S_AXI_WVALID  (M01_AXI_wvalid )
	);
    

    assign txnrx = 1;
    assign enable = 1;
    
    // The rx interface
    logic clk;
    logic              rx_data_dv;
    logic [1:0][11:0]  rx_data_imag,rx_data_real;
    rx_if rx_if_inst (
        .reset        (0),
        // external rx interface
        .rx_clk_p     (rx_clk_in_p),
        .rx_clk_n     (rx_clk_in_n),
        .rx_frame_p   (rx_frame_in_p),
        .rx_frame_n   (rx_frame_in_n),
        .rx_data_p    (rx_data_in_p),
        .rx_data_n    (rx_data_in_n),
        // internal processing clock.
        .data_clk     (clk),
        // internal rx interface
        .rx_data_dv   (rx_data_dv),
        .rx_data_imag (rx_data_imag),
        .rx_data_real (rx_data_real)
    );
    
    bb_ila rx_ila (.clk(clk), .probe0(rx_data_dv), .probe1({rx_data_imag, rx_data_real}) ); 
    
    // this is the capture ram used to grab raw rx data for software processing.
    logic        capt_bram_ena;
    logic [ 3:0] capt_bram_wea;
    logic [13:0] capt_bram_addr;
    logic [31:0] capt_bram_din;
    logic [31:0] capt_bram_dout;
    capture_ram capture_ram_inst(
        .clk(clk),
        .dv_in(rx_data_dv),
        .start(capt_start),
        .done(capt_done),
        .din_imag(rx_data_imag), 
        .din_real(rx_data_real),
        //
        .bram_clk(axi_aclk),
        .bram_ena(capt_bram_en),
        .bram_wea(capt_bram_we),
        .bram_addr(capt_bram_addr),
        .bram_din(capt_bram_din),
        .bram_dout(capt_bram_dout)
    );

    // this is a double accumulator DDS that can make linear FM chirps.
    logic tx_dds_dv;
    logic [11:0] tx_dds_cos, tx_dds_sin;
    logic [1:0][11:0]  tx_data_imag, tx_data_real;
    dds tx_dds (.clk(clk), .enable(tx_dds_enable), .freq(tx_freq), .chirp_rate(tx_chirp_rate), .gain(tx_dds_gain), .dv_out(tx_dds_dv), .cosout(tx_dds_cos), .sinout(tx_dds_sin) );

    logic        tx_stim_ram_dv_out;
    logic [31:0] tx_stim_ram_dout;

    logic [15:0]stim_bram_addr;
    logic [31:0]stim_bram_din;
    logic [31:0]stim_bram_dout;
    logic stim_bram_ena;
    logic [3:0]stim_bram_we;

    stim_ram stim_ram_inst (
        .clk(clk), 
        .enable (tx_stim_ram_enable),
        .mod    (tx_stim_ram_mod),
        .dv_out (tx_stim_ram_dv_out),
        .dout   (tx_stim_ram_dout),
        .bram_clk  (axi_aclk),
        .bram_ena  (stim_bram_ena),
        .bram_wea  (stim_bram_we),
        .bram_addr (stim_bram_addr[15:2]),
        .bram_din  (stim_bram_din),
        .bram_dout (stim_bram_dout)
    );

    // here we select the tx data sources.
    logic tx_data_dv;
    //logic [17:0] fader_imag_out, fader_real_out;
    logic [11:0] fader_imag_out, fader_real_out;
    always_ff @(posedge clk) begin
        case (tx_source_sel[0]) 
            0 : begin
                tx_data_dv      <= tx_dds_dv; 
                tx_data_imag[0] <= tx_dds_sin;
                tx_data_real[0] <= tx_dds_cos;
            end
            1 : begin
                tx_data_dv      <= tx_stim_ram_dv_out;
                tx_data_imag[0] <= tx_stim_ram_dout[31:20];
                tx_data_real[0] <= tx_stim_ram_dout[15: 4];             
            end 
            2 : begin
                tx_data_dv      <= rx_data_dv;
                tx_data_imag[0] <= rx_data_imag[0];
                tx_data_real[0] <= rx_data_real[0];                       
            end
            3 : begin
                tx_data_dv      <= rx_data_dv;
                tx_data_imag[0] <= rx_data_imag[1];
                tx_data_real[0] <= rx_data_real[1];                       
            end
            4 : begin
                tx_data_dv      <= rx_data_dv;
                tx_data_imag[0] <= fader_imag_out;
                tx_data_real[0] <= fader_real_out;                       
                //tx_data_imag[0] <= fader_imag_out[16:5];
                //tx_data_real[0] <= fader_real_out[16:5];                       
            end
            5 : begin
                tx_data_dv      <= rx_data_dv;
                tx_data_imag[0] <= 0;
                tx_data_real[0] <= 0;                       
            end
            6 : begin
                tx_data_dv      <= rx_data_dv;
                tx_data_imag[0] <= 0;
                tx_data_real[0] <= 16'h7ff;                       
            end
            default : begin
                tx_data_dv      <= rx_data_dv;
                tx_data_imag[0] <= rx_data_imag[0];
                tx_data_real[0] <= rx_data_real[0];               
            end
        endcase
        case (tx_source_sel[1]) 
            0 : begin
                tx_data_dv      <= tx_dds_dv; 
                tx_data_imag[1] <= tx_dds_sin;
                tx_data_real[1] <= tx_dds_cos;
            end
            1 : begin
                tx_data_dv      <= tx_stim_ram_dv_out;
                tx_data_imag[1] <= tx_stim_ram_dout[31:20];
                tx_data_real[1] <= tx_stim_ram_dout[15: 4];             
            end 
            2 : begin
                tx_data_dv      <= rx_data_dv;
                tx_data_imag[1] <= rx_data_imag[0];
                tx_data_real[1] <= rx_data_real[0];                       
            end
            3 : begin
                tx_data_dv      <= rx_data_dv;
                tx_data_imag[1] <= rx_data_imag[1];
                tx_data_real[1] <= rx_data_real[1];                       
            end            
            4 : begin
                tx_data_dv      <= rx_data_dv;
                tx_data_imag[1] <= fader_imag_out;
                tx_data_real[1] <= fader_real_out;                       
                //tx_data_imag[1] <= fader_imag_out[16:5];
                //tx_data_real[1] <= fader_real_out[16:5];                       
            end
            5 : begin
                tx_data_dv      <= rx_data_dv;
                tx_data_imag[1] <= 0;
                tx_data_real[1] <= 0;                       
            end
            6 : begin
                tx_data_dv      <= rx_data_dv;
                tx_data_imag[1] <= 0;
                tx_data_real[1] <= 16'h7ff;                       
            end
            default : begin
                tx_data_dv      <= rx_data_dv;
                tx_data_imag[1] <= rx_data_imag[0];
                tx_data_real[1] <= rx_data_real[0];               
            end
        endcase        
      
    end
  
    // The Tx Interface
    tx_if tx_if_inst (
        .reset        (0),
        .clk          (clk),
        // external tx interface
        .tx_clk_p     (tx_clk_out_p),
        .tx_clk_n     (tx_clk_out_n),
        .tx_frame_p   (tx_frame_out_p),
        .tx_frame_n   (tx_frame_out_n),
        .tx_data_p    (tx_data_out_p),
        .tx_data_n    (tx_data_out_n),
        // internal tx interface
        .tx_data_dv   (tx_data_dv),
        .tx_data_imag (tx_data_imag),
        .tx_data_real (tx_data_real)
    );
    
    bb_ila tx_ila (.clk(clk), .probe0(tx_data_dv), .probe1({tx_data_imag, tx_data_real}) ); 


    logic    [63:0]  gpio_i;
    logic    [63:0]  gpio_o;
    logic    [63:0]  gpio_t;
    ad_iobuf #(.DATA_WIDTH(49-32)) i_iobuf_gpio (
        .dio_t ({gpio_t[50:49], gpio_t[46:32]}), 
        .dio_i ({gpio_o[50:49], gpio_o[46:32]}), 
        .dio_o ({gpio_i[50:49], gpio_i[46:32]}),
        .dio_p ({gpio_muxout_tx, gpio_muxout_rx, gpio_resetb, gpio_sync, gpio_en_agc, gpio_ctl, gpio_status})
    );
              
//    logic    [ 1:0]  iic_mux_scl_i_s;
//    logic    [ 1:0]  iic_mux_scl_o_s;
//    logic            iic_mux_scl_t_s;
//    logic    [ 1:0]  iic_mux_sda_i_s;
//    logic    [ 1:0]  iic_mux_sda_o_s;
//    logic            iic_mux_sda_t_s;
//    ad_iobuf #(.DATA_WIDTH(2)) i_iobuf_iic_scl (.dio_t({iic_mux_scl_t_s,iic_mux_scl_t_s}), .dio_i (iic_mux_scl_o_s), .dio_o (iic_mux_scl_i_s), .dio_p (iic_mux_scl));
//    ad_iobuf #(.DATA_WIDTH(2)) i_iobuf_iic_sda (.dio_t({iic_mux_sda_t_s,iic_mux_sda_t_s}), .dio_i (iic_mux_sda_o_s), .dio_o (iic_mux_sda_i_s), .dio_p (iic_mux_sda));

    logic iic_fmc_scl_i;
    logic iic_fmc_scl_o;
    logic iic_fmc_scl_t;
    logic iic_fmc_sda_i;
    logic iic_fmc_sda_o;
    logic iic_fmc_sda_t;
    IOBUF iic_fmc_scl_iobuf (.I(iic_fmc_scl_o), .IO(iic_scl), .O(iic_fmc_scl_i), .T(iic_fmc_scl_t));
    IOBUF iic_fmc_sda_iobuf (.I(iic_fmc_sda_o), .IO(iic_sda), .O(iic_fmc_sda_i), .T(iic_fmc_sda_t));
    
    system system_inst  (
        .M01_AXI_araddr  (M01_AXI_araddr ),
        .M01_AXI_arprot  (M01_AXI_arprot ),
        .M01_AXI_arready (M01_AXI_arready),
        .M01_AXI_arvalid (M01_AXI_arvalid),
        .M01_AXI_awaddr  (M01_AXI_awaddr ),
        .M01_AXI_awprot  (M01_AXI_awprot ),
        .M01_AXI_awready (M01_AXI_awready),
        .M01_AXI_awvalid (M01_AXI_awvalid),
        .M01_AXI_bready  (M01_AXI_bready ),
        .M01_AXI_bresp   (M01_AXI_bresp  ),
        .M01_AXI_bvalid  (M01_AXI_bvalid ),
        .M01_AXI_rdata   (M01_AXI_rdata  ),
        .M01_AXI_rready  (M01_AXI_rready ),
        .M01_AXI_rresp   (M01_AXI_rresp  ),
        .M01_AXI_rvalid  (M01_AXI_rvalid ),
        .M01_AXI_wdata   (M01_AXI_wdata  ),
        .M01_AXI_wready  (M01_AXI_wready ),
        .M01_AXI_wstrb   (M01_AXI_wstrb  ),
        .M01_AXI_wvalid  (M01_AXI_wvalid ),
        .ddr_addr(ddr_addr),
        .ddr_ba(ddr_ba),
        .ddr_cas_n(ddr_cas_n),
        .ddr_ck_n(ddr_ck_n),
        .ddr_ck_p(ddr_ck_p),
        .ddr_cke(ddr_cke),
        .ddr_cs_n(ddr_cs_n),
        .ddr_dm(ddr_dm),
        .ddr_dq(ddr_dq),
        .ddr_dqs_n(ddr_dqs_n),
        .ddr_dqs_p(ddr_dqs_p),
        .ddr_odt(ddr_odt),
        .ddr_ras_n(ddr_ras_n),
        .ddr_reset_n(ddr_reset_n),
        .ddr_we_n(ddr_we_n),
        .fixed_io_ddr_vrn(fixed_io_ddr_vrn),
        .fixed_io_ddr_vrp(fixed_io_ddr_vrp),
        .fixed_io_mio(fixed_io_mio),
        .fixed_io_ps_clk(fixed_io_ps_clk),
        .fixed_io_ps_porb(fixed_io_ps_porb),
        .fixed_io_ps_srstb(fixed_io_ps_srstb),
        .gpio_i(gpio_i),
        .gpio_o(gpio_o),
        .gpio_t(gpio_t),
        //.otg_vbusoc(otg_vbusoc),
        .iic_fmc_scl_i(iic_fmc_scl_i),
        .iic_fmc_scl_o(iic_fmc_scl_o),
        .iic_fmc_scl_t(iic_fmc_scl_t),
        .iic_fmc_sda_i(iic_fmc_sda_i),
        .iic_fmc_sda_o(iic_fmc_sda_o),
        .iic_fmc_sda_t(iic_fmc_sda_t),        
        .spi0_clk_i (1'b0),
        .spi0_clk_o (spi_clk),
        .spi0_csn_0_o (spi_csn),
        .spi0_csn_1_o (),
        .spi0_csn_2_o (),
        .spi0_csn_i (1'b1),
        .spi0_sdi_i (spi_miso),
        .spi0_sdo_i (1'b0),
        .spi0_sdo_o (spi_mosi),
        .axi_aclk(axi_aclk),
        .axi_aresetn(axi_aresetn),
        .stim_bram_addr(stim_bram_addr),
        .stim_bram_clk (stim_bram_clk),
        .stim_bram_din (stim_bram_din),
        .stim_bram_dout(stim_bram_dout),
        .stim_bram_en  (stim_bram_ena),
        .stim_bram_rst (),
        .stim_bram_we  (stim_bram_we),
        .capt_bram_addr(capt_bram_addr),
        .capt_bram_clk (capt_bram_clk),
        .capt_bram_din (capt_bram_din),
        .capt_bram_dout(capt_bram_dout),
        .capt_bram_en  (capt_bram_en),
        .capt_bram_rst (),
        .capt_bram_we  (capt_bram_we)
    );
    
    spi_ila spi0_ila (.clk(axi_aclk), .probe0({spi_clk, spi_csn, spi_miso, spi_mosi}) );
    
    logic [31:0] led_count;
    always_ff @(posedge axi_aclk) led_count <= led_count + 1;
    always_ff @(posedge axi_aclk) led[0] <= led_count[27];
    
    logic [31:0] rx_clk_count;
    always_ff @(posedge clk)      rx_clk_count <= rx_clk_count + 1;
    always_ff @(posedge clk)      led[1] <= rx_clk_count[27];
    
    assign led[7:2] = 0;
    
    logic freq_tc;
    freq_counter freq_counter_i(.axi_aclk(axi_aclk), .clk(clk), .freq_count(freq_count), .tc(freq_tc));


    // 0=stim ram, 1=dds, 2=rx0, 3=rx1
    logic fader_dv_in;
    logic [11:0] fader_imag_in, fader_real_in;
    always_ff @(posedge clk) begin
        case (fader_source_sel)  
            0 : begin
                fader_dv_in   <= tx_stim_ram_dv_out;
                fader_imag_in <= tx_stim_ram_dout[31:20];
                fader_real_in <= tx_stim_ram_dout[15: 4];             
            end
            1 : begin
                fader_dv_in   <= tx_dds_dv; 
                fader_imag_in <= tx_dds_sin;
                fader_real_in <= tx_dds_cos;
            end 
            2 : begin
                fader_dv_in   <= rx_data_dv;
                fader_imag_in <= rx_data_imag[0];
                fader_real_in <= rx_data_real[0];                       
            end
            3 : begin
                fader_dv_in   <= rx_data_dv;
                fader_imag_in <= rx_data_imag[1];
                fader_real_in <= rx_data_real[1];                       
            end            
        endcase
    end


    // This is the fade processor. 
    fader2 fader2_inst (
        .clk(clk),
        .reset(1'b0),
        // randomization parameters from software.
        .wd_sin_alpha(fade_wd_sin_alpha),
        .wd_cos_alpha(fade_wd_cos_alpha),
        .phi_imag(fade_phi_imag),
        .phi_real(fade_phi_real),
        .gain(fade_gain),
        .delay(fade_delay),
        // input data selected above.
        .dv_in(fader_dv_in),
        .din_imag(fader_imag_in),
        .din_real(fader_real_in),
        //
        .dv_out(fader_dv_out),
        .dout_imag(fader_imag_out),
        .dout_real(fader_real_out)
    );

endmodule

