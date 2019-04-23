module FIR_B2 (clk, rst_n, lft_in, lft_out, sequencing, rght_in, rght_out);
	input clk, rst_n, sequencing;
	input [15:0] lft_in, rght_in;
	output reg [15:0] lft_out, rght_out;
	
	reg accum, clr, clr_2, addr_incr;
	reg [31:0] lft_out_reg, rght_out_reg;
	
	/* address logic */
	reg [9:0] addr_in;
	
	wire [9:0] addr_incr_in;
	assign addr_incr_in = addr_incr ? addr_in + 1 : addr_in;
	
	wire [9:0] addr_muxed_in;
	assign addr_muxed_in = clr_2 ? 10'h000 : addr_incr_in;
	
	always_ff @(posedge clk, negedge rst_n) 
		if (!rst_n)
			addr_in <= 10'h000;
		else
			addr_in <= addr_muxed_in;
			
	/* instantiate coeff rom */
	wire [15:0] dout;
	ROM_B2 rom (.clk(clk), .addr(addr_in), .dout(dout));
	
	/* signed multiply */
	wire signed [31:0] lft_in_mult, rght_in_mult; // NOTE: signed might need to be looked at
	assign lft_in_mult = lft_in * dout;
	assign rght_in_mult = rght_in * dout;
	
	/* accum and muxing */
	wire [31:0] lft_accum_mux, rght_accum_mux;
	assign lft_accum_mux = accum ? lft_in_mult + lft_out_reg : lft_out_reg;
	assign rght_accum_mux = accum ? rght_in_mult + rght_out_reg : rght_out_reg;
	
	/* muxing to output flops */
	wire [31:0] lft_muxed_in, rght_muxed_in;
	assign lft_muxed_in = clr ? 32'h00000000 : lft_accum_mux;
	assign rght_muxed_in = clr ? 32'h00000000 : rght_accum_mux;
	
	/* output flops */
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			lft_out_reg <= 16'h0000;
			rght_out_reg <= 16'h0000;
		end 
		else begin 
			lft_out_reg <= lft_muxed_in;
			rght_out_reg <= rght_muxed_in;
		end
	end

	assign lft_out = lft_out_reg[30:15];
	assign rght_out = rght_out_reg[30:15];

	/* state machine */
	typedef enum reg {IDLE, ACCM } state_t;
	state_t state, next_state;
	
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else 
			state <= next_state;
			
	always_comb begin 
		next_state = IDLE;
		clr = 1'b0;
		clr_2 = 1'b0;
		accum = 1'b0;  
		addr_incr = 1'b0;
		
		case (state)
			ACCM:
				begin 
					accum = 1'b1;
					addr_incr = 1'b1;
					if (sequencing)
						next_state = ACCM;
				end
				
			default: // IDLE
				begin
					clr_2 = 1'b1; 
					accum = 1'b0;  //extra signal
					if (sequencing) begin
						next_state = ACCM;
						addr_incr = 1'b1;
						clr = 1'b1;
					end
				end
		endcase
	end
	
endmodule