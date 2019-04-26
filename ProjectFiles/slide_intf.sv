module slide_intf(POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME, SS_n, SCLK, MOSI, MISO, clk, rst_n);

// Device inputs.
input clk, rst_n;			// Run functionality.
input MISO;					// Master In Slave Out.
// Device outputs
output MOSI;				// Master Out Slave In.
output SS_n;				// Slave select active low.
output SCLK;				// Slave clock.
// Output A2D channels.
output reg [11:0] POT_LP;
output reg [11:0] POT_B1;
output reg [11:0] POT_B2;
output reg [11:0] POT_B3;
output reg [11:0] POT_HP;
output reg [11:0] VOLUME;
// A2D_intf outputs to be used.
wire cnv_cmplt;
wire [11:0] res;
// RRSequencer control. Enables control when flops are updated.
reg [2:0] chnnl;
reg strt_cnv;
reg en;
wire POT_LP_en, POT_B1_en, POT_B2_en, POT_B3_en, POT_HP_en, VOLUME_en;
// State registers for FSM.
typedef enum reg {START, WAIT} state_t;
state_t state, nxt_state;
// Instantiate modules.
A2D_intf a2d(.cnv_cmplt(cnv_cmplt), .res(res), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), 
		.clk(clk), .rst_n(rst_n), .strt_cnv(strt_cnv), .chnnl(chnnl), .MISO(MISO));

		
//////////////////////////////////
// RRSequencer implementation. //
////////////////////////////////
// Flop state reg.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= START;
	else
		state <= nxt_state;
end
// Flop chnnl.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		chnnl <= 3'b001;
	else if(en)
		chnnl <= {((~(chnnl[1] ^ chnnl[0])) & ~chnnl[2]), ((chnnl[1] & ~chnnl[2]) | (chnnl[2] & ~chnnl[0])), chnnl[1]};
		// Above combinational logic will implement round robin in order listed below.
end
// Finite State Machine
always_comb begin
	strt_cnv = 1'b0;
	nxt_state = START;
	en = 1'b0;

	case(state)
		WAIT: begin
			if(cnv_cmplt) begin
				en = 1'b1;
			end
			else
				nxt_state = WAIT;
		end
		default: begin// Default is START
			strt_cnv = 1'b1;
			nxt_state = WAIT;
		end
	endcase
end

assign POT_LP_en = ((chnnl == 3'b001) && en) ? 1'b1 : 1'b0;
assign POT_B1_en = ((chnnl == 3'b000) && en) ? 1'b1 : 1'b0;
assign POT_B2_en = ((chnnl == 3'b100) && en) ? 1'b1 : 1'b0;
assign POT_B3_en = ((chnnl == 3'b010) && en) ? 1'b1 : 1'b0;
assign POT_HP_en = ((chnnl == 3'b011) && en) ? 1'b1 : 1'b0;
assign VOLUME_en = ((chnnl == 3'b111) && en) ? 1'b1 : 1'b0;


/////////////////////////////////////
// Flop outputs for each channel. //
///////////////////////////////////
// Flop POT_LP.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		POT_LP <= 12'h000;
	else if(POT_LP_en)
		POT_LP <= res;
end

// Flop POT_B1.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		POT_B1 <= 12'h000;
	else if(POT_B1_en)
		POT_B1 <= res;
end

// Flop POT_B2.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		POT_B2 <= 12'h000;
	else if(POT_B2_en)
		POT_B2 <= res;
end

// Flop POT_B3.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		POT_B3 <= 12'h000;
	else if(POT_B3_en)
		POT_B3 <= res;
end

// Flop POT_HP.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		POT_HP <= 12'h000;
	else if(POT_HP_en)
		POT_HP <= res;
end

// Flop VOLUME.
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		VOLUME <= 12'h000;
	else if(VOLUME_en)
		VOLUME <= res;
end

endmodule
