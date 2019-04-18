module low_freq_queue (clk, rst_n, lft_smpl, rght_smpl, wrt_smpl, lft_out, rght_out, sequencing);
	input clk, rst_n, wrt_smpl;
	input [15:0] lft_smpl, rght_smpl;
	output sequencing;
	output [15:0] lft_out, rght_out;
	
	/* instantiate low freq dual port RAM */
	dualPort1024x16 (.clk(), .we(), .waddr(), .readdr(), .wdata(), .rdata());

endmodule