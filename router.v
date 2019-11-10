module router(Clk, Rst_n, Rx, Tx, RxData); // Top Level Entity

	///////////////////////// Input OutPut Declaration /////////////////////////
	
	input     		Clk;			// Clock
	input          Rst_n; 		// Reset
	input          Rx; 			// RS232 RX Pin
	output         Tx; 			// RS232 TX Pin
	output [7:0]	RxData;		// Received Data
	
	/////////////////////////// Net Data Declaration ///////////////////////////
	
	wire [7:0]   TxData; 	// Data to Transmit.
	wire         RxDone; 	// Reception Completed. Data is Valid.
	wire         TxDone;		// Transmission completed. Data Sent.
	wire         tick;		// Baud Rate Clock
	wire			 TxEn;
	wire			 RxEn;
	wire [3:0]   NBits;
	wire [15:0]  BaudRate; 	// 328, 162 etc... (Refer Baud Rate Generator Module)
	
	///////////////////////////// Assigning Values /////////////////////////////
	
	assign 	RxEn = 1'b1;
	assign 	TxEn = 1'b1;
	assign 	BaudRate = 16'd325; 	// Baud Rate Set to 9600
	assign 	NBits = 4'b1000;		// We Send/ Receive 8 Bits
	
	/////////////////////////// Module Instantiation ///////////////////////////

	// Make Connections Between Rx Module and Router Inputs and Outputs and the Other Modules
	UART_rx I_RS232RX(
			.Clk(Clk),
			.Rst_n(Rst_n),
			.RxEn(RxEn),
			.RxData(RxData),
			.RxDone(RxDone),
			.Rx(Rx),
			.Tick(tick),
			.NBits(NBits)
		 );

	// Make Connections Between Tx Module and Router Inputs and Outputs and the Other Modules
	UART_tx I_RS232TX(
			.Clk(Clk),
			.Rst_n(Rst_n),
			.TxEn(TxEn),
			.TxData(TxData),
			.TxDone(TxDone),
			.Tx(Tx),
			.Tick(tick),
			.NBits(NBits)
		 );

	// Make Connections Between Tick Generator Module and Router Inputs and Outputs and the Other Modules
	UART_baudrate_gen I_BAUDGEN(
			.Clk(Clk),
			.Rst_n(Rst_n),
			.Tick(tick),
			.BaudRate(BaudRate)
		 );
		 
endmodule

// Credits:- Electro Noobs - https://www.electronoobs.com/eng_circuitos_tut26.php