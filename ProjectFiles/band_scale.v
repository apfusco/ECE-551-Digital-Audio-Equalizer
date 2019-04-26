module band_scale(scaled, POT, audio);

	input [11:0] POT;
	input signed [15:0] audio;
	output signed [15:0] scaled;
	
	//reg sat_neg;
	
	wire [23:0] POT_squ;
	wire signed [12:0] s_POT_squ;
	wire signed [28:0] out_scale_full;
	wire signed [18:0] out_scale;
	
	assign POT_squ = POT ** 2;
	
	assign s_POT_squ = {1'b0, POT_squ[23:12]};
	
	assign out_scale_full = s_POT_squ * audio;
	
	assign out_scale = out_scale_full[28:10];
	
	assign scaled = out_scale[18] ? ((&(out_scale[17:15])) ? out_scale[15:0] : 16'h8000) : ((|(out_scale[17:15])) ? 16'h7FFF : out_scale[15:0]);
	
endmodule
