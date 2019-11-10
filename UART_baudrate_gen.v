module UART_baudrate_gen(Clk, Rst_n, Tick, BaudRate);
	
	// Input Output Declaration
	input				Clk; 				// Clock input
	input          Rst_n; 			// Reset Input
	input [15:0]	BaudRate; 		// Signal Baud Rate
	
	output         Tick; 			// Generated Tick Pulse (With 16 Times Frequency)
	
	reg [15:0]     baudRateReg; 	// Register Used to Count

	always @(posedge Clk or negedge Rst_n)
		if (!Rst_n)		baudRateReg <= 16'b1;
		else if (Tick) baudRateReg <= 16'b1;
		else 				baudRateReg <= baudRateReg + 1'b1;
	assign Tick = (baudRateReg == BaudRate);
	
endmodule
