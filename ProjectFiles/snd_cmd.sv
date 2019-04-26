module snd_cmd(resp_rcvd, TX, clk, rst_n, RX, cmd_start, send, cmd_len);

	// I/O pins.
	input clk, rst_n;
	input RX;				// Receives transmitted data.
	input [4:0] cmd_start;
	input send;
	input [3:0] cmd_len;
	output resp_rcvd;
	output TX;
	
	// snd_cmd flops.
	reg [4:0] addr;
	reg [4:0] end_addr;
	
	// snd_cmd wires.
	wire rx_rdy;			// Connected to UART. High when rx_data is valid.
	wire [7:0] rx_data;		// Data received via UART.
	wire [7:0] tx_data;		// Connects UART an cmdROM.
	
	// For Finite State Machine.
	typedef enum reg [1:0] {IDLE, WAIT, START, TRANS} state_t;
	state_t state, nxt_state;
	
	// FSM inputs.
	wire send;
	wire last_byte;			// High when last byte has been received.
	wire tx_done;
	
	// FSM outputs.
	reg trmt, inc_addr;
	
	// Instantiate modules.
	UART transceiver(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .rx_rdy(rx_rdy), 
					.clr_rx_rdy(rx_rdy), .rx_data(rx_data), .trmt(trmt), 
					.tx_data(tx_data), .tx_done(tx_done));
	cmdROM cmd(.clk(clk), .addr(addr), .dout(tx_data));
	
	////////////////////////////
	// snd_cmd module logic. //
	//////////////////////////
	
	// addr flop.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			addr <= 5'b00000;
		else if(send)
			addr <= cmd_start;
		else if(inc_addr)
			addr <= addr + 1'b1;
	end
	
	// end_addr flop.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			end_addr <= 5'b00000;
		else if(send)
			end_addr <= cmd_start + cmd_len;
	end
	
	// Combinational logic.
	assign last_byte = (addr == end_addr) ? 1'b1 : 1'b0;
	assign resp_rcvd = ((rx_data == 8'h0A) && rx_rdy) ? 1'b1 : 1'b0;
	
	///////////////////////////
	// Finite State Machine //
	/////////////////////////
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	end
	always_comb begin
		nxt_state = IDLE;
		trmt = 1'b0;
		inc_addr = 1'b0;
		
		case(state)
			WAIT: begin
				nxt_state = START;
			end
			START: begin
				if(last_byte)
					nxt_state = IDLE;
				else begin
					trmt = 1'b1;
					nxt_state = TRANS;
				end
			end
			TRANS: begin
				if(tx_done) begin
					inc_addr = 1'b1;
					nxt_state = WAIT;
				end
				else
					nxt_state = TRANS;
			end
			default: begin	// IDLE is default state.
				if(send)
					nxt_state = WAIT;
			end
		endcase;
	end

endmodule