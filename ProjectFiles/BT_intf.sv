module BT_intf(cmd_n, TX, RX, next_n, prev_n, clk, rst_n);

input clk, rst_n;
input next_n, prev_n;
input RX;
output TX;
output cmd_n;

// FSM input.
wire resp_rcvd;
// FSM outputs.
reg [4:0] cmd_start;
reg send, FSM_cmd_n;
reg [3:0] cmd_len;
// Other FSM logic.
reg [16:0] timer;
// next_n and prev_n edge detected. PB_rise outputs.
wire nxt_rise, prev_rise;

typedef enum reg [2:0] {INIT, WAIT, CONFIG1, CONFIG2, IDLE, PREV, NEXT} state_t;
state_t state, nxt_state;

snd_cmd snd(.resp_rcvd(resp_rcvd), .TX(TX), .clk(clk), .rst_n(rst_n), .RX(RX), 
		.cmd_start(cmd_start), .send(send), .cmd_len(cmd_len));
PB_rise PB_nxt(.rise(nxt_rise), .PB(next_n), .clk(clk), .rst_n(rst_n));
PB_rise PB_prev(.rise(prev_rise), .PB(prev_n), .clk(clk), .rst_n(rst_n));

///////////////////////////////////////////////////////////////
// Finite State Machine sequential and combinational logic. //
/////////////////////////////////////////////////////////////
// Flop state reg.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= INIT;
	else
		state <= nxt_state;
end
// Flop timer.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		timer <= 17'h00000;
	else
		timer <= timer + 1'b1;
end

assign cmd_n = FSM_cmd_n;// Connect FSM output to module output.

always_comb begin
	// FSM outputs.
	FSM_cmd_n = 1'b0;
	nxt_state = INIT;
	send = 1'b0;
	cmd_start = 5'b0000;
	cmd_len = 4'd6;

	case(state)
		WAIT: begin
			if(resp_rcvd) begin
				send = 1'b1;
				nxt_state = CONFIG1;
			end
			else
				nxt_state = WAIT;
		end
		CONFIG1: begin
			if(resp_rcvd) begin
				send = 1'b1;
				cmd_start = 5'b00110;
				cmd_len = 4'd10;
				nxt_state = CONFIG2;
			end
			else
				nxt_state = CONFIG1;
		end
		CONFIG2: begin
			if(resp_rcvd)
				nxt_state = IDLE;
			else
				nxt_state = CONFIG2;
		end
		IDLE: begin
			cmd_len = 4'd4;// Both commands have same length.
			if(nxt_rise) begin// Next button was pushed.
				send = 1'b1;
				cmd_start = 5'b10000;
				nxt_state = NEXT;
			end
			else if(prev_rise) begin// Previous button was pushed.
				send = 1'b1;
				cmd_start = 5'b10100;
				nxt_state = PREV;
			end
			else
				nxt_state = IDLE;
		end
		NEXT: begin
			cmd_start = 5'b10000;
			cmd_len = 4'd4;
			if(resp_rcvd)
				nxt_state = IDLE;
			else
				nxt_state = NEXT;
		end
		PREV: begin
			cmd_start = 5'b10100;
			cmd_len = 4'd4;
			if(resp_rcvd)
				nxt_state = IDLE;
			else
				nxt_state = PREV;
		end
		default: begin// Default state is INIT.
			FSM_cmd_n = 1'b1;
			if(&timer) begin
				nxt_state = WAIT;
			end
		end
	endcase
end

endmodule
