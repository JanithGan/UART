module UART_tx (Clk, Rst_n, TxEn, TxData, TxDone, Tx, Tick, NBits);	// Tx Module

	// Input Output Declaration
	input Clk, Rst_n, TxEn,Tick;
	input [3:0]NBits;
	input [7:0]TxData;
	
	output Tx;
	output TxDone;

	// Declare Variabels Used for the State Machine
	parameter IDLE = 1'b0, WRITE = 1'b1;	// Two States of the State Machine (WRITE = 1 and IDLE = 0)
	reg  		 State, Next;						// Registers to Store the State
	reg  		 Tx;									// Register for the input value
	reg  		 TxDone 		  = 1'b0;			// Declare End of Data Transmission
	reg 		 write_enable = 1'b0;			// Enables Data Transmission		
	reg 		 start_bit 	  = 1'b1;			// Starts Bit Detection (First Falling Edge of TX)
	reg 		 stop_bit 	  = 1'b0;			// Stops Bit Detection
	reg [4:0] Bit 			  = 5'b00000;		// 8 Bits Counter for Data Reading
	reg [3:0] counter 	  = 4'b0000;		// Counts the Tick Pulses up to 16
	reg [7:0] in_data		  = 8'b00000000;	// Register to Store the Tx Input Bits before Transmission
	reg [1:0] R_edge;								// Avoid Debounce of the Write Enable Pin
	
	wire 		 D_edge;								// Wire Used to Connect the D_edge


	//////////////////////////////////////////////////////////////////////////////
	/////////////////////////////// STATE MACHINE ////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////
	
	/////////////////////////////////// Reset ////////////////////////////////////
	
	always @ (posedge Clk or negedge Rst_n)
	begin
		if (!Rst_n)	State <= IDLE;				// If Reset Pin is low, Go to IDLE 
		else 		State <= Next;					// If Not, Go to Next State
	end

	/////////////////////////// Next Step Decision ///////////////////////////////
	
	always @ (State or D_edge or TxData or TxDone) 
	begin
		case(State)	
			IDLE:	 if(D_edge)	Next = WRITE;	// Starts the WRITE Process When D_edge Gets Activated
					 else			Next = IDLE;
			WRITE: if(TxDone)	Next = IDLE;  	// Get back to IDLE when TxDone Gets High While Writing
					 else			Next = WRITE;
			default 				Next = IDLE;
		endcase
	end


	///////////////////////////////////////////////////////////////////////////////
	/////////////////////////////// WRITING DATA //////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////
	
	////////////////////////// Enable Write or Not ////////////////////////////////
	
	always @ (State)
	begin
		case (State)
		WRITE: begin
					write_enable <= 1'b1;	// Enables the Write Process for WRITE State
				 end
		IDLE: begin
					write_enable <= 1'b0;	// Disables the Write Process in IDLE state 
				end
		endcase
	end

	////////////////////////////// Write the Data //////////////////////////////////

	always @ (posedge Tick)
	begin
		if (!write_enable) // Resets All Variables, If write_enable is not Activated
		begin
			TxDone = 1'b0;
			start_bit <= 1'b1;
			stop_bit <= 1'b0;
		end

		if (write_enable) // Start Counting and Changing the Tx Output, If write_enable is Activated
		begin
			counter <= counter + 4'b1;	  // Increase the Counter
			
			if(start_bit & !stop_bit) // Set Tx to LOW (Start Bit), Pass the TxData into the in_data Register
			begin
				Tx <= 1'b0;	 
				in_data <= TxData;
			end		

			if ((counter == 4'b1111) & (start_bit)) // Create the start_bit (LOW), When Counter Reaches 16
			begin		
				start_bit <= 1'b0;
				in_data <= {1'b0,in_data[7:1]};
				Tx <= in_data[0];
			end


			if ((counter == 4'b1111) & (!start_bit) &  (Bit < NBits-1)) // Looping for Next 7 Bits
			begin		
				in_data <= {1'b0,in_data[7:1]};
				Bit <= Bit + 5'b1;
				Tx <= in_data[0];
				start_bit <= 1'b0;
				counter <= 4'b0000;
			end	

			if ((counter == 4'b1111) & (Bit == NBits-1) & (!stop_bit)) // Set Tx to HIGH (Stop Bit), When Finished
			begin
				Tx <= 1'b1;	
				counter <= 4'b0000;	
				stop_bit <= 1'b1;
			end

			if ((counter == 4'b1111) & (Bit == NBits-1) & (stop_bit)) // Reset Variables to Get Next Set of Data
			begin
				Bit <= 4'b0000;
				TxDone <= 1'b1;
				counter <= 4'b0000;
				//start_bit <=1'b1;
			end
		end
	end

	
	////////////////////////////////////////////////////////////////////////////
	/////////////////////////// INPUT ENABLE DETECT ////////////////////////////
	////////////////////////////////////////////////////////////////////////////

	always @ (posedge Clk or negedge Rst_n)
	begin
		if(!Rst_n)
		begin
			R_edge <= 2'b00;
		end
		
		else
		begin
			R_edge <= {R_edge[0], TxEn};
		end
	end
		
	assign D_edge = !R_edge[1] & R_edge[0];

endmodule
