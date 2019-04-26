module SPI_mstr(done, MOSI, SS_n, SCLK, rd_data, clk, rst_n, MISO, wrt, wt_data);

	// I/O signals
	input clk, rst_n, MISO, wrt;
	input [15:0] wt_data;
	output done, MOSI, SS_n, SCLK;
	output [15:0] rd_data;
	
	// Enumerator used in finite state machine.
	typedef enum reg [1:0] {idle, trans, backporch} state_t;
	state_t state, nxt_state;
	
	// Registers used in implementing peripheral.
	reg [15:0] shft_reg;
	reg [4:0] bit_cntr;
	reg [3:0] SCLK_div;
	reg shft, done, SS_n;
	
	// Inputs to FSM
	wire done16, full;
	// Outputs from FSM.
	reg ld_SCLK, set_done, init;
	
	//bit_cntr register.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			bit_cntr <= 5'b00000;
		else if(init)
			bit_cntr <= 5'b00000;
		else if(shft)
			bit_cntr <= bit_cntr + 1;
	end
	
	//SCLK_div register.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			SCLK_div <= 4'b1011;
		else if(ld_SCLK)
			SCLK_div <= 4'b1011;
		else
			SCLK_div <= SCLK_div + 1;
	end

	// Combinational logic after register.
	assign SCLK = SCLK_div[3];					// Connects SCLK to most significant bit.
	assign full = &SCLK_div;					// 
	assign shft = (SCLK_div == 4'b1001);			//TODO
	assign rd_data = shft_reg;

	//Shift register.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			shft_reg <= 16'h0000;
		else begin
			if(init)
				shft_reg <= wt_data;
			else if(shft)
				shft_reg <= {shft_reg[14:0], MISO};
		end
	end
	
	// SS_n register
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			SS_n <= 1;
		else if(set_done)
			SS_n <= 1;
		else if(init)
			SS_n <= 0;
	end
	
	// Comb logic after shft_reg and bit_cntr registers.
	assign done16 = bit_cntr[4];	//Will be high when counter is full.
	assign MOSI = shft_reg[15];	//Bit to go to send to slave device.
	
	// Register for finite state machine.
	always_comb begin
		// defaults
		nxt_state = idle;
		init = 0;
		ld_SCLK = 0;
		set_done = 0;
		
		case(state)
			idle: begin
				if(wrt) begin
					nxt_state = trans;
					init = 1;
				end
				else
					ld_SCLK = 1;
			end
			trans: begin
				if(done16)
					nxt_state = backporch;
				else
					nxt_state = trans;
			end
			backporch: begin
				if(full) begin
					set_done = 1;
					ld_SCLK = 1;
					nxt_state = idle;
				end
				else
					nxt_state = backporch;
			end
		endcase
	end
	
	// register for FSM state.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= idle;
		else
			state <= nxt_state;
	end
	
	// register for done output.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			done <= 0;
		else if(set_done)
			done <= 1;
		else if(init)
			done <= 0;
	end

endmodule