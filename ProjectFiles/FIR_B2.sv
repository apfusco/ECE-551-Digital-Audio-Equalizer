module FIR_B2 (clk, rst_n, lft_in, lft_out, sequencing, rght_in, rght_out);

	input clk, rst_n, sequencing;
	input signed [15:0] lft_in, rght_in;
	output reg [15:0] lft_out, rght_out;
	
	reg accum, clr_accum, clr_addr;
	reg [31:0] lft_out_reg, rght_out_reg;
	
	/* address logic */
	reg [9:0] addr_in;
	
	wire [9:0] addr_muxed_in;
	assign addr_muxed_in = clr_addr ? 10'h000 : addr_in + 1'b1;
	
	// Flop addr_in.
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			addr_in <= 10'h000;
		else
			addr_in <= addr_muxed_in;
	end
	
	/* instantiate coeff rom */
	wire signed [15:0] dout;
	ROM_B2 rom(.clk(clk), .addr(addr_in), .dout(dout));
	
	/* signed multiplies */
	wire signed [31:0] lft_in_mult, rght_in_mult; // NOTE: signed might need to be looked at
	assign lft_in_mult = lft_in * dout;
	assign rght_in_mult = rght_in * dout;
	
	/* accum and muxing */
	wire [31:0] lft_accum_mux, rght_accum_mux;
	assign lft_accum_mux = accum ? lft_in_mult + lft_out_reg : lft_out_reg;
	assign rght_accum_mux = accum ? rght_in_mult + rght_out_reg : rght_out_reg;
	
	/* muxing to output flops */
	wire [31:0] lft_muxed_in, rght_muxed_in;
	assign lft_muxed_in = clr_accum ? 32'h00000000 : lft_accum_mux;
	assign rght_muxed_in = clr_accum ? 32'h00000000 : rght_accum_mux;
	
	/* output flops */
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			lft_out_reg <= 32'h00000000;
			rght_out_reg <= 32'h00000000;
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
	
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			state <= IDLE;
		else 
			state <= next_state;
	end
			
	always_comb begin 
		next_state = IDLE;
		clr_accum = 1'b0;
		clr_addr = 1'b0;
		accum = 1'b0;
		
		case (state)
			ACCM: begin
				if(sequencing) begin
					next_state = ACCM;
					accum = 1'b1;
				end
			end
			default: begin// IDLE
				if (sequencing) begin
					next_state = ACCM;
					clr_accum = 1'b1;
				end
				else
					clr_addr = 1'b1;
			end
		endcase
	end
	
endmodule