module high_freq_queue (clk, rst_n, lft_smpl, rght_smpl, wrt_smpl, lft_out, rght_out, sequencing);
	input clk, rst_n, wrt_smpl;
	input [15:0] lft_smpl, rght_smpl;
	output sequencing;
	output [15:0] lft_out, rght_out;
	
	/* state machine */
	
	/* instantiate low freq dual port RAMs */
	dualPort1536x16 left (.clk(clk), .we(), .waddr(), .readdr(), .wdata(lft_smpl), .rdata(lft_out));
	dualPort1536x16 rght (.clk(clk), .we(), .waddr(), .readdr(), .wdata(rght_smpl), .rdata(rght_out));
endmodule