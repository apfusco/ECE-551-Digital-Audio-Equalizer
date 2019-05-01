module sqrt(sqrt, done, mag, go, clk, rst_n);

	input [15:0] mag;		// unsigned 16-bit number to take square root of.
	input go, clk, rst_n;	// go sig will start calculation.
	output [7:0] sqrt;		// Square root of input.
	output done;			// High when calculation is done.

	reg [7:0] guess, cnt;	// Will hold value of guess to answer, and will count which digit the module is checking.
	
	wire [15:0] guess_squ;				// Will be driven by value of guess squared.
	
	assign guess_squ = guess * guess;	// Comb logic drives guess_squ.
	
	// guess register.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			guess <= 8'h80;
		else if(go)
			if(guess_squ > mag)
				guess <= (guess & ~cnt) | (cnt >> 1);
			else
				guess <= guess | (cnt >> 1);
	end

	// cnt register.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			cnt <= 8'h80;
		else if(go)
			cnt = cnt >> 1;
	end

	assign done = !(|cnt);
	assign sqrt = guess;
/*
	// done register/output. Should be delayed by one clock cycle from cnt
	// register.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			done <= 0;
		else
			done <= !(|cnt);
	end;*/

endmodule