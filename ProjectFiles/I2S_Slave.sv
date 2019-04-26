module I2S_Slave(lft_chnnl, rght_chnnl, vld, clk, rst_n, I2S_sclk, I2S_ws, I2S_data);

	// I/O
	input clk, rst_n;
	input I2S_sclk;							// SCLK signal of I2S master. Register should shift on rising edge.
	input I2S_ws;							// Word select from I2S master.
	input I2S_data;							// Serial data from master. Should be shifted into LSB of shft_reg.
	output [23:0] lft_chnnl, rght_chnnl;	// Parallel 24-bit representaion of left/right audio channel data.
	output reg vld;								// Output from FSM. High when shift is done.
	
	// Regs and wires part of module..
	reg [47:0] shft_reg;
	reg [4:0] bit_cntr;
	reg sclk_reg1, sclk_reg2, sclk_reg3;	// Used to synch and detect rise.
	reg ws_reg1, ws_reg2, ws_reg3;			// Used to synch and detect fall.
	reg in_sync;							// Used to check if slave and master are in sync.
	reg clr_cnt, set_vld;					// FSM output.
	wire sclk_rise, ws_fall;				// Detects sclk rise and ws fall.
	wire eq22, eq23, eq24;					// bit_cntr is equal to 22, 23, or 24.
	
	typedef enum reg [1:0] {IDLE, SYNC, LEFT, RIGHT} state_t;
	state_t state, nxt_state;
	
	// bit_cntr reg.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			bit_cntr <= 5'b00000;
		else if(clr_cnt)
			bit_cntr <= 5'b00000;
		else if(sclk_rise)
			bit_cntr <= bit_cntr + 5'b00001;
	end
	
	// shft_reg
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			shft_reg <= 5'b00000;
		else if(sclk_rise)
			shft_reg <= {shft_reg[46:0], I2S_data};
	end
	
	// Combinational logic.
	assign {lft_chnnl, rght_chnnl} = shft_reg;
	assign eq22 = (bit_cntr == 5'd22) ? 1'b1 : 1'b0;
	assign eq23 = (bit_cntr == 5'd23) ? 1'b1 : 1'b0;
	assign eq24 = (bit_cntr == 5'd24) ? 1'b1 : 1'b0;
	assign in_sync = (eq22 && !I2S_ws) || (eq23 && I2S_ws && sclk_rise) ? 1'b0 : 1'b1;
	
	
	////////////////////////////////////
	// Synch and posedge detect sclk.//
	//////////////////////////////////
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			sclk_reg1 <= 1'b1;
		else
			sclk_reg1 <= I2S_sclk;
	end
	
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			sclk_reg2 <= 1'b1;
		else
			sclk_reg2 <= sclk_reg1;
	end
	
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			sclk_reg3 <= 1'b1;
		else
			sclk_reg3 <= sclk_reg2;
	end
	
	// Combinational logic.
	assign sclk_rise = sclk_reg2 & ~sclk_reg3;
	
	/////////////////////////////////////////////////////
	// Synch and negedge detect ws.                   //
	// Three flops, followed by combinational logic. //
	//////////////////////////////////////////////////
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			ws_reg1 <= 1'b1;
		else
			ws_reg1 <= I2S_ws;
	end
	
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			ws_reg2 <= 1'b1;
		else
			ws_reg2 <= ws_reg1;
	end
	
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			ws_reg3 <= 1'b1;
		else
			ws_reg3 <= ws_reg2;
	end
	
	// Combinational logic.
	assign ws_fall = ~ws_reg2 & ws_reg3;
	
	///////////////////////////
	// Finite State Machine.//
	/////////////////////////
	// state flop.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	end
	// vld flop.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			vld <= 1'b0;
		else
			vld <= set_vld;
	end
	// FSM outputs are clr_cnt and vld.
	always_comb begin
		nxt_state = IDLE;
		clr_cnt = 1'b0;
		set_vld = 1'b0;
		
		case(state)
			SYNC: begin
				if(sclk_rise) begin
					nxt_state = LEFT;
					clr_cnt = 1'b1;
				end
				else
					nxt_state = SYNC;
			end
			LEFT: begin
				if(eq24) begin
					nxt_state = RIGHT;
					clr_cnt = 1'b1;
				end
				else
					nxt_state = LEFT;
			end
			RIGHT: begin
				if(eq24) begin
					nxt_state = LEFT;
					clr_cnt = 1'b1;
					set_vld = 1'b1;
				end
				else if(!in_sync)
					nxt_state = IDLE;
				else
					nxt_state = RIGHT;
			end
			default: begin	// Default is IDLE.
				if(ws_fall)
					nxt_state = SYNC;
			end
		endcase
	end

endmodule