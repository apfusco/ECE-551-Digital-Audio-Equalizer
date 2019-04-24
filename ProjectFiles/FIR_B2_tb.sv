module FIR_B2_tb;

	reg clk, rst_n;
	wire I2S_sclk, I2S_ws, I2S_data, vld, sequencing; 
	wire [15:0] lq_lft_out, lq_rght_out;
	wire [23:0] lft_chnnl, rght_chnnl;
	wire [15:0] fir_lft_out, fir_rght_out;

	/* instantiate modules */
	RN52 rn52 (.clk(clk),.RST_n(rst_n), .RX(1'b1), .cmd_n(1'b0), .I2S_sclk(I2S_sclk), .I2S_data(I2S_data), .I2S_ws(I2S_ws));
	I2S_Slave i2s (.clk(clk), .rst_n(rst_n), .I2S_sclk(I2S_sclk), .I2S_data(I2S_data), .I2S_ws(I2S_ws), .lft_chnnl(lft_chnnl), .vld(vld), .rght_chnnl(rght_chnnl));
	high_freq_queue hq (.clk(clk), .rst_n(rst_n), .lft_smpl(lft_chnnl[23:8]), .wrt_smpl(vld), .rght_smpl(rght_chnnl[23:8]), .lft_out(lq_lft_out), .sequencing(sequencing), .rght_out(lq_rght_out));
	FIR_B2 fir (.clk(clk), .rst_n(rst_n), .lft_in(lq_lft_out), .lft_out(fir_lft_out), .sequencing(sequencing), .rght_in(lq_rght_out), .rght_out(fir_rght_out));

	/* flop outputs */
	reg [15:0] lft_out_flop, rght_out_flop;
	
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin 
			lft_out_flop <= 16'h0000;
			rght_out_flop <= 16'h0000;
		end 
		else if (vld) begin //FIXME valid
			lft_out_flop <= fir_lft_out;
			rght_out_flop <= fir_rght_out;
		end
	end
	
	initial begin 
		clk = 1;
		rst_n = 0;
		@(negedge clk);
		rst_n = 1;
		@(posedge clk);
		repeat (3000000) @(posedge clk);
		$stop;
	end

	always 
		#1 clk = ~clk;
endmodule