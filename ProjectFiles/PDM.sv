module PDM(PDM, clk, rst_n, duty);
	/////////////////////////////
	// Modified for spkr_drc. //
	///////////////////////////

	// I/O signals
	input clk, rst_n;	// clk is 50 MHz
	input [15:0] duty;	// unsigned 15-bit duty;
	output PDM;
	
	reg counter;
	reg [15:0] regA;
	reg [15:0] regB;
	wire [15:0] ALU1, ALU2;
	wire update;
	
	// Counter register
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			counter <= 1'b0;
		else
			counter <= ~counter;
	end
	
	assign update = &counter; // High when counter is full.
	
	// Register A (regA)
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			regA <= 16'h0000;
		else if(update) // Infers mux
			regA <= duty + 16'h8000;
	end
	
	assign ALU1 = (PDM ? 16'hFFFF : 16'h0000) - regA;
	
	assign ALU2 = ALU1 + regB;
	
	// Register B (regB)
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			regB <= 0;
		else if(update)
			regB <= ALU2;
	end
	
	assign PDM = (regA >= regB) ? 1'b1 : 1'b0; // Assigns output.

endmodule
