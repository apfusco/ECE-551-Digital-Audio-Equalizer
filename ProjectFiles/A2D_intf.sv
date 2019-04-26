module A2D_intf(cnv_cmplt, res, SS_n, SCLK, MOSI, clk, rst_n, strt_cnv, chnnl, MISO);

	input clk, rst_n;		// System clock and active-low asynchronous reset.
	input strt_cnv;			// Asserted for at least one clk cycle to start conversion.
	input MISO;			// Master In Slave Out.
	output reg cnv_cmplt;		// Asserted to indicate complete conversion, and will deassert at next strt_cnv.
	
	// Part of SPI_mstr.
	input [2:0] chnnl;		// Specifies which A2D channel.
	output SS_n;			// Output low slave select.
	output SCLK;			// Serial clock to the A2D.
	output MOSI;			// Master Out Slave In.
	output [11:0] res;		// Result from A2D.
	wire done;			// Used to read SPI_mstr output.
	reg wrt;			// Used as input to SPI_mstr.
	wire [15:0] rd_data;		// Connected directly to SPI_mstr output.
	
	// States for FSM.
	typedef enum reg [1:0] {IDLE, INIT, FETCH, WAIT} state_t;
	state_t state, nxt_state;
	
	SPI_mstr master(.done(done), .MOSI(MOSI), .SS_n(SS_n), .SCLK(SCLK), .rd_data(rd_data),
		.clk(clk), .rst_n(rst_n), .MISO(MISO), .wrt(wrt), .wt_data({2'b00, chnnl, 11'h000}));
					
	assign res = rd_data[11:0];//FIXME: rd_data[11:0] or rd_data[15:4]?
	
	// cnv_cmplt register.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			cnv_cmplt <= 1'b0;
		else if((state == IDLE) && !strt_cnv)
			cnv_cmplt <= 1'b1;
		else
			cnv_cmplt <= 1'b0;
	end
	
	// state register.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	end
	
	// FSM (nxt_state comb logic)
	always_comb begin
		// Defaults
		wrt = 1'b0;
		nxt_state = IDLE;
		
		case(state)
			INIT: begin
				if(done) begin
					nxt_state = WAIT;
				end
				else
					nxt_state = INIT;
			end
			WAIT: begin
				nxt_state = FETCH;
				wrt = 1'b1;// Will assert for only one clock cycle.
			end
			FETCH: begin
				if(done)
					nxt_state = IDLE;
				else
					nxt_state = FETCH;
			end
			default: begin	// IDLE state.
				if(strt_cnv) begin
					nxt_state = INIT;
					wrt = 1'b1;// Will assert for only one clock cycle.
				end
			end
		endcase
	end

endmodule
