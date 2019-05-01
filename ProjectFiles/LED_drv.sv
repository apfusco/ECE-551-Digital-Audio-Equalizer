module LED_drv(LED, aud_lft, aud_rght, vld, clk, rst_n);
	
	input [15:0] aud_lft, aud_rght;		// Left and right audio coming from EQ_engine.
	input vld;				// Indicates value from audio is valid.
	input clk, rst_n;			// Clock and reset.
	output [7:0] LED;			// Output for which LELDs should light up.

	wire [14:0] aud_mag_lft, aud_mag_rght;	// Magnitude of audio.

	reg [12:0] cntr;			// Counter used to sample audio.
	reg [3:0] lft_val, rght_val;		// Counter used to output high.

	// Takes absolute value of audio inputs.
	assign aud_mag_lft = aud_lft[15] ? ~(aud_lft[14:0]) + 1'b1 : aud_lft[14:0];
	assign aud_mag_rght = aud_rght[15] ? ~(aud_rght[14:0]) + 1'b1 : aud_rght[14:0];

	// Flop cntr.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			cntr <= 13'h0000;
		else if(|cntr || vld)
			cntr <= cntr + 1'b1;
	end

	// Flop lft_val.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			lft_val <= 16'h0000;
		else if(!(|cntr) && vld)
			lft_val <= {|(aud_mag_lft[14:12]), |(aud_mag_lft[14:9]), |(aud_mag_lft[14:6]), |(aud_mag_lft[14:3])};
		else if(!(|{cntr[10:0]}))
			lft_val <= {1'b0, lft_val[3:1]};
	end

	// Flop rght_val.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			rght_val <= 16'h0000;
		else if(!(|cntr) && vld)
			rght_val <= {|(aud_mag_rght[14:12]), |(aud_mag_rght[14:9]), |(aud_mag_rght[14:6]), |(aud_mag_rght[14:3])};
		else if(!(|{cntr[10:0]}))
			rght_val <= {1'b0, rght_val[3:1]};
	end

	assign LED = {lft_val, rght_val};
	
endmodule
