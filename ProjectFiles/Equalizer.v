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
	 


	/////////////////////////////////////
	// Instantiate Reset synchronizer //
	///////////////////////////////////


	//////////////////////////////////////
	// Instantiate Slide Pot Interface //
	////////////////////////////////////					

				  
	//////////////////////////////////////
	// Instantiate BT module interface //
	////////////////////////////////////

					
			
    //////////////////////////////////////
    // Instantiate I2S_Slave interface //
    ////////////////////////////////////


    //////////////////////////////////////////
    // Instantiate EQ_engine or equivalent //
    ////////////////////////////////////////


	
	/////////////////////////////////////
	// Instantiate PDM speaker driver //
	///////////////////////////////////

	
	///////////////////////////////////////////////////////////////
	// Infer sht_dwn/Flt_n logic or incorporate into other unit //
	/////////////////////////////////////////////////////////////
	
	
	assign LED = 8'h00;


endmodule
