module low_freq_queue_tb();

// Stimulate inputs.
reg clk, rst_n;
reg [15:0] lft_in, rght_in;
reg wrt;
// DUT outputs.
wire sequencing;
wire [15:0] lft_out, rght_out;

// For test bench.
int i;
int seq_clks = 0;
reg [15:0] expct, read_num;
reg fail;// Will become high when test bench fails.

low_freq_queue iDUT(.lft_out(lft_out), .rght_out(rght_out), .sequencing(sequencing), 
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
		for(i = 0; i < 1021; i = i + 1) begin
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
	
	for (read_num = 16'h0000; read_num < 16'd12000; read_num = read_num + 1) begin 
		expct = read_num;
		@(posedge clk);
		fork 
		begin: timer1
			wrt = 1'b1;
			@(posedge clk);
			wrt = 1'b0;
			lft_in = lft_in + 1;
			rght_in = rght_in + 1;
			repeat(100000) @(posedge clk);
			fail = 1'b1;
			$display("FAILED: Timed out while waiting for sequencing.");
			$stop;
			$finish;
		end
		begin
			@(posedge sequencing);
			@(posedge clk);
			while(sequencing) begin
				@(negedge clk);
				if((lft_out != expct) || (rght_out != expct)) begin
					fail = 1'b1;
				end
				expct = expct + 1'b1;
			end
			if(expct != 16'd1022 + read_num)
				fail = 1'b1;
			disable timer1;
		end
		join
		@(posedge clk);
	end 
	
	if(fail)
		$display("Test failed.");
	else
		$display("All tests passed!");
	$stop;
end

always
	#5 clk = ~clk;

endmodule