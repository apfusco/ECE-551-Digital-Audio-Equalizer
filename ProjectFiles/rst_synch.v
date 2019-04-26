module rst_synch(rst_n, RST_n, clk);

	input RST_n;	// Asynchronous acitve low reset.
	input clk;		// Clock to synchronize to.
	output rst_n;	// Synchronous acitve low reset.
	
	reg reg1, reg2;
	wire w1;
	
	// Registers have synchronous resets, so always blocks are only triggered by clock.
	// Register reg1.
	always @(negedge clk) begin
		if(!RST_n)
			reg1 <= 1'b0;
		else
			reg1 <= 1'b1;
	end
	
	assign w1 = reg1;	// Wire w1 connectes the two registers.
	
	// Register reg2.
	always @(negedge clk) begin
		if(!RST_n)
			reg2 <= 1'b0;
		else
			reg2 <= w1;
	end
	
	assign rst_n = reg2;	// Connect register reg2 to ouput rst_n.

endmodule