module Equalizer(clk,RST_n,LED,ADC_SS_n,ADC_MOSI,ADC_SCLK,ADC_MISO,
                 I2S_data,I2S_ws,I2S_sclk,cmd_n,sht_dwn,lft_PDM,
				 rght_PDM,Flt_n,next_n,prev_n,RX,TX);
				  
	input clk;			// 50MHz CLOCK
	input RST_n;		// unsynched active low reset from push button
	output [7:0] LED;	// Extra credit opportunity, otherwise tie low
	output ADC_SS_n;	// Next 4 are SPI interface to A2D
	output ADC_MOSI;
	output ADC_SCLK;
	input ADC_MISO;
	input I2S_data;		// serial data line from BT audio
	input I2S_ws;		// word select line from BT audio
	input I2S_sclk;		// clock line from BT audio
	output cmd_n;		// hold low to put BT module in command mode
	output reg sht_dwn;	// hold high for 5ms after reset
	output lft_PDM;		// Duty cycle of this drives left speaker
	output rght_PDM;	// Duty cycle of this drives right speaker
	input Flt_n;		// when low Amp(s) had a fault and needs sht_dwn
	input next_n;		// active low to skip to next song
	input prev_n;		// active low to repeat previous song
	input RX;			// UART RX (115200) from BT audio module
	output TX;			// UART TX to BT audio module
		
	///////////////////////////////////////////////////////
	// Declare and needed wires or registers below here //
	/////////////////////////////////////////////////////
	wire rst_n;		// Synchronized reset for entire module.
	// Connect Slide_intf and EQ_engine.
	wire [11:0] POT_LP;
	wire [11:0] POT_B1;
	wire [11:0] POT_B2;
	wire [11:0] POT_B3;
	wire [11:0] POT_HP;
	wire [11:0] VOLUME;
	// Connect I2S_Slave and EQ_engine.
	wire vld;
	wire [23:0] aud_in_lft, aud_in_rght;
	// Connect EQ_engine and spkr_drv.
	wire [15:0] aud_out_lft, aud_out_rght;
	// Used for sht_dwn/Flt_n logic.
	reg [17:0] timer;


	/////////////////////////////////////
	// Instantiate Reset synchronizer //
	///////////////////////////////////
	rst_synch rst_edge(.rst_n(rst_n), .RST_n(RST_n), .clk(clk));


	//////////////////////////////////////
	// Instantiate Slide Pot Interface //
	////////////////////////////////////
	slide_intf slide(.POT_LP(POT_LP), .POT_B1(POT_B1), .POT_B2(POT_B2), .POT_B3(POT_B3), 
		.POT_HP(POT_HP), .VOLUME(VOLUME), .SS_n(ADC_SS_n), .SCLK(ADC_SCLK), .MOSI(ADC_MOSI), 
		.MISO(ADC_MISO), .clk(clk), .rst_n(rst_n));

				  
	//////////////////////////////////////
	// Instantiate BT module interface //
	////////////////////////////////////
	BT_intf intf(.cmd_n(cmd_n), .TX(TX), .RX(RX), .next_n(next_n), .prev_n(prev_n), .clk(clk), .rst_n(rst_n));
					
			
	//////////////////////////////////////
	// Instantiate I2S_Slave interface //
	////////////////////////////////////
	I2S_Slave slave(.lft_chnnl(aud_in_lft), .rght_chnnl(aud_in_rght), .vld(vld), .clk(clk), .rst_n(rst_n), 
		.I2S_sclk(I2S_sclk), .I2S_ws(I2S_ws), .I2S_data(I2S_data));


	//////////////////////////////////////////
	// Instantiate EQ_engine or equivalent //
	////////////////////////////////////////
	EQ_engine engine(.aud_out_lft(aud_out_lft), .aud_out_rght(aud_out_rght), .aud_in_lft(aud_in_lft[23:8]), 
		.aud_in_rght(aud_in_rght[23:8]), .vld(vld), .POT_LP(POT_LP), .POT_B1(POT_B1), .POT_B2(POT_B2), 
		.POT_B3(POT_B3), .POT_HP(POT_HP), .VOLUME(VOLUME), .clk(clk), .rst_n(rst_n));

	
	/////////////////////////////////////
	// Instantiate PDM speaker driver //
	///////////////////////////////////
	spkr_drv spkr(.lft_PDM(lft_PDM), .rght_PDM(rght_PDM), .lft_chnnl(aud_out_lft), 
		.rght_chnnl(aud_out_rght), .vld(vld), .clk(clk), .rst_n(rst_n));

	
	///////////////////////////////////////////////////////////////
	// Infer sht_dwn/Flt_n logic or incorporate into other unit //
	/////////////////////////////////////////////////////////////
	// Flop timer.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			timer <= 18'h00000;
		else if(!Flt_n)
			timer <= 18'h00000;
		else
			timer <= timer + 1'b1;
	end
	// Flop sht_dwn.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			sht_dwn <= 1'b1;
		else if(!Flt_n)
			sht_dwn <= 1'b1;
		else if(timer >= 18'd250000)
			sht_dwn <= 1'b0;
	end
	
	assign LED = 8'h00;


endmodule
