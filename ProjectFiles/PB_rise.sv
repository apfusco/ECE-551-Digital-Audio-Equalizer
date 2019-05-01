module PB_rise(rise, PB, clk, rst_n);

	input PB, clk, rst_n;
	output rise;
	
	reg r1, r2, r3;
	wire w1, w2;
	
	// First register.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			r1 <= 1'b1;
		else
			r1 <= PB;
	end
	
	assign w1 = r1;
	
	// Second register. Used to stabilize signal.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			r2 <= 1'b1;
		else
			r2 <= w1;
	end
	
	assign w2 = r2;
	
	// Third register. Used to detect rising edge.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			r3 <= 1'b1;
		else
			r3 <= w2;
	end
	
	assign rise = r2 & ~r3;

endmodule