module UART_rx (Clk, Rst_n, RxEn, RxData, RxDone, Rx, Tick, NBits);	// Rx Module

	// Input Output Declaration
	input 			Clk, Rst_n, RxEn, Rx, Tick;		
	input [3:0] 	NBits;
	
	output 			RxDone;
	output [7:0]	RxData;

	// Declare Variabels Used for the State Machine
	parameter IDLE = 1'b0, READ = 1'b1; 	// Two States of the State Machine (READ = 1 and IDLE = 0)
	reg [1:0] State, Next;						// Registers to Store the State
	reg  		 read_enable = 1'b0;				// Enables Data Readings
	reg  		 start_bit 	 = 1'b1;				// Starts Bit Detection (First Falling Edge of RX)
	reg  		 RxDone 		 = 1'b0;				// Declares End of Data Reading
	reg [4:0] Bit 			 = 5'b00000;		// 8 Bits Counter for Data Reading 
	reg [3:0] counter 	 = 4'b0000;			// Counts the Tick Pulses up to 16
	reg [7:0] Read_data	 = 8'b00000000;	// Register to Store the Rx Input Bits before Assigning to the Output
	reg [7:0] RxData;								// To Output the Final Byte Value

	
	//////////////////////////////////////////////////////////////////////////////
	/////////////////////////////// STATE MACHINE ////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////
	
	/////////////////////////////////// Reset ////////////////////////////////////

	always @ (posedge Clk or negedge Rst_n)
	begin
		if (!Rst_n)	State <= IDLE;				// If Reset Pin is low, Go to IDLE 
		else 			State <= Next;				// If Not, Go to Next State
	end


	/////////////////////////// Next Step Decision ///////////////////////////////

	always @ (State or Rx or RxEn or RxDone)
	begin
		case(State)	
			IDLE:	if(!Rx & RxEn)	Next = READ;	 // If Rx is Low (Start Bit Detected), Start the Read Process
					else				Next = IDLE;
			READ:	if(RxDone)		Next = IDLE; 	 // If RxDone is High, Goto IDLE and Wait for Start Bit
					else				Next = READ;
			default 					Next = IDLE;
		endcase
	end
	
	
	///////////////////////////////////////////////////////////////////////////////
	/////////////////////////////// READING DATA //////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////

	/////////////////////////// Enable Read or Not ////////////////////////////////
	
	always @ (State or RxDone)
	begin
		case (State)
			READ: begin
						read_enable <= 1'b1;			// Enable Reading in READ Mode	
					end
			IDLE: begin
						read_enable <= 1'b0;			// Disable Reading in IDLE Mode
					end
		endcase
	end

	/////////////////////////// Read the Input Data ///////////////////////////////
	
	always @ (posedge Tick)
	begin
		if (read_enable)
		begin
			RxDone <= 1'b0;								 // Set the RxDone Register to Low
			counter <= counter + 4'b1;					 // Increase the counter by 1 with Each Tick Detected
			
			if ((counter == 4'b1000) & (start_bit)) // If Counter is 8, Set the Start Bit to 1. 
			begin
				start_bit <= 1'b0;
				counter <= 4'b0000;
			end

			if ((counter == 4'b1111) & (!start_bit) & (Bit < NBits))	// To Read All 8 Bits
			begin
				Bit <= Bit + 5'b1;
				Read_data <= {Rx,Read_data[7:1]};
				counter <= 4'b0000;
			end
			
			if ((counter == 4'b1111) & (Bit == NBits) & (Rx)) // To Detect the Stop Bit (Rx High)
			begin
				Bit <= 4'b0000;
				RxDone <= 1'b1;
				counter <= 4'b0000;
				start_bit <= 1'b1; // Reset All Values to Receive Next Set of Data
			end
		end
	end


	//////////////////////////////////////////////////////////////////////////////
	////////////////////////////// OUTPUT ASSIGN /////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////

	always @ (posedge Clk)
	begin
		if (NBits == 4'b1000)
		begin
			RxData[7:0] <= Read_data[7:0];	
		end

		if (NBits == 4'b0111)
		begin
			RxData[7:0] <= {1'b0,Read_data[7:1]};	
		end

		if (NBits == 4'b0110)
		begin
			RxData[7:0] <= {1'b0,1'b0,Read_data[7:2]};	
		end
	end

endmodule
