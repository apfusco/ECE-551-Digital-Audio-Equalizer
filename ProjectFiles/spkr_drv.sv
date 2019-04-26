module spkr_drv(lft_PDM, rght_PDM, lft_chnnl, rght_chnnl, vld, clk, rst_n);

input [15:0] lft_chnnl, rght_chnnl;
input vld, clk, rst_n;
output lft_PDM, rght_PDM;

reg [15:0] left, right;

// Instantiate hierarchy. 
PDM leftPDM(.PDM(lft_PDM), .clk(clk), .rst_n(rst_n), .duty(left));
PDM rightPDM(.PDM(rght_PDM), .clk(clk), .rst_n(rst_n), .duty(right));

// flop left
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		left <= 16'h0000;
	else if(vld)
		left <= lft_chnnl;
	else
		left <= left;
end

// flop right
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		right <= 16'h0000;
	else if(vld)
		right <= rght_chnnl;
	else
		right <= right;
end

endmodule
