module EQ_engine(aud_out_lft, aud_out_rght, aud_in_lft, aud_in_rght, vld, POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME, clk, rst_n);

input [15:0] aud_in_lft, aud_in_rght;		// Audio in.
input vld;
input [11:0] POT_LP;
input [11:0] POT_B1;
input [11:0] POT_B2;
input [11:0] POT_B3;
input [11:0] POT_HP;
input [11:0] VOLUME;
input clk, rst_n;							// Clock and reset.
output reg signed [15:0] aud_out_lft, aud_out_rght;// Audio out.

// Low frequency logic.
reg sample;
reg vld_low_freq;							// Will be half as frequent as the vld input.
// Connect queues to FIR modules.
wire [15:0] low_lft, low_rght;						// low_freq_queue output.
wire [15:0] high_lft, high_rght;					// high_freq_queue output.
wire high_sqncng, low_sqncng;
// Connect FIR modules to band_scales.
wire [15:0] FIR_LP_lft, FIR_LP_rght;
wire [15:0] FIR_B1_lft, FIR_B1_rght;
wire [15:0] FIR_B2_lft, FIR_B2_rght;
wire [15:0] FIR_B3_lft, FIR_B3_rght;
wire [15:0] FIR_HP_lft, FIR_HP_rght;
// Connect band_scales to summation.
wire signed [15:0] scale_LP_lft, scale_LP_rght;
wire signed [15:0] scale_B1_lft, scale_B1_rght;
wire signed [15:0] scale_B2_lft, scale_B2_rght;
wire signed [15:0] scale_B3_lft, scale_B3_rght;
wire signed [15:0] scale_HP_lft, scale_HP_rght;
// Registers to pipeline band_scale outputs to summation.
reg signed [15:0] ffscale_LP_lft, ffscale_LP_rght;
reg signed [15:0] ffscale_B1_lft, ffscale_B1_rght;
reg signed [15:0] ffscale_B2_lft, ffscale_B2_rght;
reg signed [15:0] ffscale_B3_lft, ffscale_B3_rght;
reg signed [15:0] ffscale_HP_lft, ffscale_HP_rght;
// Summation and multiply.
wire signed [12:0] sVOLUME;
reg signed [15:0] lft_summ, rght_summ;
wire signed [28:0] lft_product, rght_product;//FIXME: Change back to 28.

///////////////////////////////////
// Instantiate circular queues. //
/////////////////////////////////
low_freq_queue low_freq(.lft_out(low_lft), .rght_out(low_rght), .sequencing(low_sqncng), .clk(clk), 
	.rst_n(rst_n), .lft_smpl(aud_in_lft), .rght_smpl(aud_in_rght), .wrt_smpl(vld_low_freq));
high_freq_queue high_freq(.lft_out(high_lft), .rght_out(high_rght), .sequencing(high_sqncng), .clk(clk), 
	.rst_n(rst_n), .lft_smpl(aud_in_lft), .rght_smpl(aud_in_rght), .wrt_smpl(vld));

///////////////////////////////
// Instantiate FIR modules. //
/////////////////////////////
FIR_LP LP(.clk(clk), .rst_n(rst_n), .lft_in(low_lft), .lft_out(FIR_LP_lft), 
	.sequencing(low_sqncng), .rght_in(low_rght), .rght_out(FIR_LP_rght));
FIR_B1 B1(.clk(clk), .rst_n(rst_n), .lft_in(low_lft), .lft_out(FIR_B1_lft), 
	.sequencing(low_sqncng), .rght_in(low_rght), .rght_out(FIR_B1_rght));
FIR_B2 B2(.clk(clk), .rst_n(rst_n), .lft_in(high_rght), .lft_out(FIR_B2_lft), 
	.sequencing(high_sqncng), .rght_in(high_rght), .rght_out(FIR_B2_rght));
FIR_B3 B3(.clk(clk), .rst_n(rst_n), .lft_in(high_rght), .lft_out(FIR_B3_lft), 
	.sequencing(high_sqncng), .rght_in(high_rght), .rght_out(FIR_B3_rght));
FIR_HP HP(.clk(clk), .rst_n(rst_n), .lft_in(high_rght), .lft_out(FIR_HP_lft), 
	.sequencing(high_sqncng), .rght_in(high_rght), .rght_out(FIR_HP_rght));

//////////////////////////////////////
// Instantiate band_scale modules. //
////////////////////////////////////
band_scale scaleLPlft(.scaled(scale_LP_lft), .POT(POT_LP), .audio(FIR_LP_lft), .clk(clk), .rst_n(rst_n));
band_scale scaleB1lft(.scaled(scale_B1_lft), .POT(POT_B1), .audio(FIR_B1_lft), .clk(clk), .rst_n(rst_n));
band_scale scaleB2lft(.scaled(scale_B2_lft), .POT(POT_B2), .audio(FIR_B2_lft), .clk(clk), .rst_n(rst_n));
band_scale scaleB3lft(.scaled(scale_B3_lft), .POT(POT_B3), .audio(FIR_B3_lft), .clk(clk), .rst_n(rst_n));
band_scale scaleHPlft(.scaled(scale_HP_lft), .POT(POT_HP), .audio(FIR_HP_lft), .clk(clk), .rst_n(rst_n));
band_scale scaleLPrght(.scaled(scale_LP_rght), .POT(POT_LP), .audio(FIR_LP_rght), .clk(clk), .rst_n(rst_n));
band_scale scaleB1rght(.scaled(scale_B1_rght), .POT(POT_B1), .audio(FIR_B1_rght), .clk(clk), .rst_n(rst_n));
band_scale scaleB2rght(.scaled(scale_B2_rght), .POT(POT_B2), .audio(FIR_B2_rght), .clk(clk), .rst_n(rst_n));
band_scale scaleB3rght(.scaled(scale_B3_rght), .POT(POT_B3), .audio(FIR_B3_rght), .clk(clk), .rst_n(rst_n));
band_scale scaleHPrght(.scaled(scale_HP_rght), .POT(POT_HP), .audio(FIR_HP_rght), .clk(clk), .rst_n(rst_n));

/////////////////////////////////////////////
// Logic to half frequency for one queue. //
///////////////////////////////////////////
// Flop sample.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		sample <= 1'b0;
	else if(vld)// This assumes vld will only be asserted for one clk cycle.
		sample <= ~sample;
end
// Flop vld_low_freq
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		vld_low_freq <= 1'b0;
	else
		vld_low_freq <= sample & vld;
end

/////////////////////////////////////////////////
// Flop outputs from band_scales to pipeline. //
///////////////////////////////////////////////
always @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		ffscale_LP_lft <= 16'h0000;
		ffscale_LP_rght <= 16'h0000;
		ffscale_B1_lft <= 16'h0000;
		ffscale_B1_rght <= 16'h0000;
		ffscale_B2_lft <= 16'h0000;
		ffscale_B2_rght <= 16'h0000;
		ffscale_B3_lft <= 16'h0000;
		ffscale_B3_rght <= 16'h0000;
		ffscale_HP_lft <= 16'h0000;
		ffscale_HP_rght <= 16'h0000;
	end
	else begin
		ffscale_LP_lft <= scale_LP_lft;
		ffscale_LP_rght <= scale_LP_rght;
		ffscale_B1_lft <= scale_B1_lft;
		ffscale_B1_rght <= scale_B1_rght;
		ffscale_B2_lft <= scale_B2_lft;
		ffscale_B2_rght <= scale_B2_rght;
		ffscale_B3_lft <= scale_B3_lft;
		ffscale_B3_rght <= scale_B3_rght;
		ffscale_HP_lft <= scale_HP_lft;
		ffscale_HP_rght <= scale_HP_rght;
	end
end

/////////////////////////////////
// Summation and multipliers. //
///////////////////////////////
// Find summ. Use registers to pipeline.
// Flop lft_summ.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		lft_summ <= 16'h0000;
	else
		lft_summ <= ffscale_LP_lft + ffscale_B1_lft + ffscale_B2_lft + ffscale_B3_lft + ffscale_HP_lft;
end
// Flop rght_summ.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		rght_summ <= 16'h0000;
	else
		rght_summ <= ffscale_LP_rght + ffscale_B1_rght + ffscale_B2_rght + ffscale_B3_rght + ffscale_HP_rght;
end
//assign lft_summ = scale_LP_lft + scale_B1_lft + scale_B2_lft + scale_B3_lft + scale_HP_lft;
//assign rght_summ = scale_LP_rght + scale_B1_rght + scale_B2_rght + scale_B3_rght + scale_HP_rght;
// Multiply by volume.
assign sVOLUME = {1'b0, VOLUME};
assign lft_product = lft_summ * sVOLUME;//FIXME: Change back to {1'b0, VOLUME}.
assign rght_product = rght_summ * sVOLUME;//FIXME
// Use correct bits.
//assign aud_out_lft = lft_product[27:12];
//assign aud_out_rght = rght_product[27:12];
// Flop aud_out_lft.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		aud_out_lft <= 16'h0000;
	else
		aud_out_lft <= lft_product[27:12];
end
// Flop aud_out_rght.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		aud_out_rght <= 16'h0000;
	else
		aud_out_rght <= rght_product[27:12];
end

endmodule
