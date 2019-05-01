module LED_drv(LED, audio, clk, rst_n);
	
	input [15:0] audio;
	input clk, rst_n;
	output reg [7:0] LED;
	
	reg go;
	reg [15:0] mag;
	wire [7:0] audio_sqrt;
	wire done;
	
	sqrt sqrt_calc(.sqrt(audio_sqrt), .done(done), .mag(mag), .go(go), .clk(clk), .rst_n(rst_n));
	
	// Flop mag.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			mag <= audio;
		else if(done)
			mag <= audio;
	end
	
	// Flop go.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			go <= 1'b1;
		else if(done)
			go <= 1'b1;
		else
			go <= 1'b0;
	end
	
	// Flop LED.
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			LED <= 8'h00;
		else if(done)
			LED <= audio_sqrt;
	end
	
endmodule