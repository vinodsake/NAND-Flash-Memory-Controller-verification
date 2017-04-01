`define DEBUG_RAM
//`timescale 1ns / 1fs
module ebr_buffer
(
    input wire [7:0] DataInA,
    input wire [7:0] DataInB,
    input wire [10:0] AddressA,
    input wire [10:0] AddressB,
    input wire ClockA,
    input wire ClockB,
    input wire ClockEnA,
    input wire ClockEnB,
    input wire WrA,
    input wire WrB,
    input wire ResetA,
    input wire ResetB,
   // input disp,
    output wire [7:0] QA,
    output wire [7:0] QB
	  
);
	// Declare the RAM variable
	reg [7:0] ram[0:2047];
	
	reg [7:0] q_a, q_b;
	
	assign QA = q_a;
	assign QB = q_b;
	
	// Port A
	always_ff @ (posedge ClockA)
	begin
	if(ClockEnA)
	begin
		if (WrA) 
		begin
			ram[AddressA] <= DataInA;
			q_a <= DataInA;
		end
		else 
		begin
			q_a <= ram[AddressA];
		end
	end
	end
	
	// Port B
	always_ff @ (posedge ClockB)
	begin
	if (ClockEnB)
	begin
	if (WrB)
		begin
			ram[AddressB] <= DataInB;
			q_b <= DataInB;
		end
		else
		begin
			q_b <= ram[AddressB];
		end
	end
	end
	
	/*`ifdef DEBUG_RAM
	always @ (posedge disp)
	begin: named
	  // integer i;
	  if (disp)
	    begin
	      for(int i=0; i<10; i=i+1)
	      $display ("mem[%0d] = %0d", i, ram[i]);
	      
	      for(int i=51; i<68; i=i+1)
	      $display ("mem[%0d] = %0d", i, ram[i]);
		  
		    for (int i=2040; i<2048; i=i+1)
		    $display ("mem[%0d] = %0d", i, ram[i]);
	    end
	end
	`endif*/
	      
	
endmodule