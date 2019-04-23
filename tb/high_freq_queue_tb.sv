module high_freq_queue_tb();

// Stimulate inputs.
reg clk, rst_n;
reg [15:0] lft_in, rght_in;
reg wrt;
// DUT outputs.
wire sequencing;
wire [15:0] lft_out, rght_out;

// For test bench.
int i;
reg [15:0] expct;
reg fail;// Will become high when test bench fails.

high_freq_queue iDUT(.lft_out(lft_out), .rght_out(rght_out), .sequencing(sequencing), 
	.clk(clk), .rst_n(rst_n), .lft_smpl(lft_in), .rght_smpl(rght_in), .wrt_smpl(wrt));

initial begin
	clk = 1'b0;
	rst_n = 1'b0;
	wrt = 1'b0;
	lft_in = 16'h0000;
	rght_in = 16'h0000;
	fail = 1'b0;
	i = 0;
	expct = 16'h0000;
	repeat(2) @(negedge clk) rst_n = 1'b1;
	@(posedge clk);

	fork
	begin
		for(i = 0; i < 1531; i = i + 1) begin
			wrt = 1'b1;
			@(posedge clk);
			wrt = 1'b0;
			lft_in = lft_in + 1'b1;
			rght_in = rght_in + 1'b1;
			repeat(3) @(posedge clk);
		end
		disable monitor1;
	end
	begin: monitor1
		@(posedge sequencing) fail = 1'b1;
		$display("FAILED: Asserted sequencing before queue was full.");
		$stop;
	end
	join

	@(posedge clk);

	fork
	begin: timer
		lft_in = lft_in + 1'b1;
		rght_in = rght_in + 1'b1;
		wrt = 1'b1;
		@(posedge clk);
		wrt = 1'b0;
		repeat(100000) @(posedge clk);
		fail = 1'b1;
		$display("FAILED: Timed out while waiting for sequencing.");
		$stop;
		$finish;
	end
	begin: monitor2
		@(posedge sequencing);
		@(posedge clk);
		while(sequencing) begin
			@(negedge clk);
			if((lft_out != expct) || (rght_out != expct))
				fail = 1'b1;
			expct = expct + 1'b1;
		end
		if(expct != 16'd1531)
			fail = 1'b1;
		disable timer;
	end
	join
	if(fail)
		$display("Test failed.");
	else
		$display("All tests passed!");
	$stop;
end

always
	#5 clk = ~clk;

endmodule