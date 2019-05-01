module band_scale(scaled, POT, audio, clk, rst_n);

	input [11:0] POT;
	input signed [15:0] audio;
	input clk, rst_n;
	output reg signed [15:0] scaled;
	
	//reg sat_neg;
	
	wire [23:0] POT_squ;
	reg signed [12:0] s_POT_squ;
	reg signed [28:0] out_scale_full;
	wire signed [18:0] out_scale;
	wire signed [15:0] scaled_comb;
	
	assign POT_squ = POT * POT;
	
	//assign s_POT_squ = {1'b0, POT_squ[23:12]};
	// Flop s_POT_squ.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			s_POT_squ <= 13'h0000;
		else
			s_POT_squ <= {1'b0, POT_squ[23:12]};
	end
	
	//assign out_scale_full = s_POT_squ * audio;
	// Flop out_scale_full.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			out_scale_full <= 29'h00000000;
		else
			out_scale_full <= s_POT_squ * audio;
	end
	
	assign out_scale = out_scale_full[28:10];
	
	assign scaled_comb = out_scale[18] ? ((&(out_scale[17:15])) ? out_scale[15:0] : 16'h8000) : ((|(out_scale[17:15])) ? 16'h7FFF : out_scale[15:0]);
	// Flop scaled.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			scaled <= 16'h0000;
		else
			scaled <= scaled_comb;
	end
	
endmodule
