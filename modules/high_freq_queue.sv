module high_freq_queue(lft_out, rght_out, sequencing, clk, rst_n, lft_smpl, rght_smpl, wrt_smpl);
	
// High sampling frequency is 44.1kHz. With a 50MHz clk, the clocks per sample is about 1134.
input clk, rst_n;						// Clock and reset.
input [15:0] lft_smpl, rght_smpl;		// Newest sample from I2S_slave to go into queue.
input wrt_smpl;							// If high, write sample then start readout of 1021 samples.
output [15:0] lft_out, rght_out;		// Data being readout.
output reg sequencing;					// High the whole time 1021 samples are begin read out from queue. FSM output.

reg [10:0] new_ptr, old_ptr, read_ptr;	// Ptr for read/write addresses.
wire [10:0] end_ptr;					// Ptr for end of read out.
wire full;								// High when circular queue is full

// Make up Finite State Machine.
typedef enum reg [1:0] {FILL, READ, WRITE} state_t;
state_t state, nxt_state;
reg inc_old, inc_new;					// FSM outputs. Will be high when ptr should be incrememnted.

// Instantiate left and right DP RAM.
dualPort1536x16 lft_RAM(.clk(clk), .we(wrt_smpl), .waddr(new_ptr), .raddr(read_ptr), .wdata(lft_smpl), .rdata(lft_out));
dualPort1536x16 rght_RAM(.clk(clk), .we(wrt_smpl), .waddr(new_ptr), .raddr(read_ptr), .wdata(rght_smpl), .rdata(rght_out));

// Combinational logic to assert full signal.
assign full = ((new_ptr - old_ptr) > 11'd1530) ? 1'b1 : 1'b0;// Becomes high when it becomes full while in FILL state.
assign end_ptr = (old_ptr < 11'd516) ? (old_ptr + 11'd1020) : (old_ptr - 11'd516);

///////////////////////////
// Finite State Machine //
/////////////////////////
// Flop register recording state.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= FILL;
	else
		state <= nxt_state;
end
// Flop new_ptr.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		new_ptr <= 11'h000;
	else if(inc_new) begin
		if(new_ptr < 11'd1535)
			new_ptr <= new_ptr + 1'b1;
		else
			new_ptr <= 11'h000;
	end
end
// Flop old_ptr.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		old_ptr <= 11'h000;
	else if(inc_old) begin
		if(old_ptr < 11'd1535)
			old_ptr <= old_ptr + 1'b1;
		else
			old_ptr <= 11'h000;
	end
end
// Flop read_ptr.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		read_ptr <= 11'h000;
	else if(sequencing && (read_ptr != end_ptr)) begin
		if(read_ptr < 11'd1535)
			read_ptr <= read_ptr + 1'b1;
		else
			read_ptr <= 11'h000;
	end
	else
		read_ptr <= old_ptr;
end
// FSM comb logic.
always_comb begin
	// FSM outputs.
	sequencing = 1'b0;
	inc_new = 1'b0;
	inc_old = 1'b0;

	nxt_state = FILL;// Default state.

	case(state)
		READ: begin
			sequencing = 1'b1;
			if(read_ptr != end_ptr)// Hasn't reached end of readout.
				nxt_state = READ;
			else
				nxt_state = WRITE;
		end
		WRITE: begin
			if(wrt_smpl) begin// Will do a write and begin readout.
				inc_new = 1'b1;
				inc_old = 1'b1;
				nxt_state = READ;
			end
			else
				nxt_state = WRITE;
		end
		default: begin// Default state is FILL.
			if(wrt_smpl) begin
				inc_new = 1'b1;
				if(full) begin// Will start first read out.
					inc_old = 1'b1;// Will use read_ptr for first read out.
					nxt_state = READ;
				end
			end
		end
	endcase
end
	
endmodule
