/************************************************************************************************************************************************
*																		*
* 							  	FLASH MEMORY CONTROLLER - COVERAGE						*															*
*																		*
************************************************************************************************************************************************/

import flash_pkg::*;

class coverage;

virtual flash_bfm bfm;

/************************************* Internal Variables ***************************************/
operations command,casted_cmd;
logic [15:0] address;
bit reset;
/***********************************************************************************************/

/*********************************** Mix Inputs covergroup *************************************/
covergroup Mix_Inputs;

Cross_CMD: coverpoint bfm.nfc_cmd {

		bins Other_to_Write[]	= ({read_page,reset,erase,read_id} => program_page);								// Other commands to program page transition
		bins Write_to_Other[]	= (program_page =>{read_page,reset,erase,read_id});								// Program page to other command transition
		bins Read_to_Other[]	= (read_page => program_page);											// Read page to other command transition	
		bins Other_to_Read[]	= ({program_page,reset,erase} =>read_page);									// Other commands to read page transition
		bins Erase_to_Other[]	= (erase => {program_page,read_page} );										// Erase to other command transition
		bins Other_to_Erase[]	= ({program_page,read_page,reset} => erase);									// Other commands to Erase transition
		bins Reset_to_Other[]	= (reset => {program_page,read_page,erase,read_id});								// Reset to other command transition
		bins Other_to_Reset[]	= ([program_page:read_page] => reset);										// Other command to reset transition
		bins read_to_read[]	= (read_page => read_page);											// read_page followed by read_page
		bins Write_to_Write[] 	= (program_page => program_page);										// write page followed by write page
		bins Erase_to_Erase[] 	= (erase => erase);												// erase followed by erase
		bins reset_to_reset[]	= (reset => reset);												//reset followed by reset
		bins read_5times[]	= (read_page => read_page =>read_page => read_page =>read_page);						// five consecutive reads
		bins Write_5times[]	= (program_page =>program_page => program_page =>program_page =>program_page);					// five consecutive writes
}

Commands: coverpoint bfm.nfc_cmd {
		bins CMDS = {program_page, read_page, erase, reset, read_id};										// check for all basic command execution
}

Invalid: coverpoint bfm.nfc_cmd {
		bins Invalid_Command= {3'b000, 3'b111};													// Invalid command input
}
RowAddr: coverpoint bfm.RWA {
		bins RWA_Start	= {16'h0000};
		bins RWA_Last	= {16'h03FF};
		bins RWA_Range1	= {[16'h0001:16'h0100]};	
		bins RWA_Range2	= {[16'h0101:16'h0200]};
		bins RWA_Range3	= {[16'h0201:16'h0300]};
		bins RWA_Range4	= {[16'h0301:16'h03FF]};												// Extremes cases for Row address
		bins InvalidRWD	= {16'hxxxx};														// Invalid row address
}

SystemReset: coverpoint bfm.rst{
		bins SysReset	= {1'b1, 1'b0};														//System reset set to 1 and 0
}

CrossInputs: cross SystemReset,Commands,RowAddr,Invalid {
		bins SysReset_and_Write		= binsof(Commands) intersect {program_page} && (binsof(SystemReset.SysReset));				// System reset and write command active at the same time 
		bins SysReset_and_Read		= binsof(Commands) intersect {read_page} && (binsof(SystemReset.SysReset));				// System reset and Read command active at the same time 
		bins SysReset_and_Erase		= binsof(Commands) intersect {erase} && (binsof(SystemReset.SysReset));					// System reset and Erase command active at the same time 
		bins SysReset_and_reset		= binsof(Commands) intersect {reset} && (binsof(SystemReset.SysReset));					// System reset and reset command active at the same time 
		bins SysReset_and_read_id	= binsof(Commands) intersect {read_id} && (binsof(SystemReset.SysReset));				// System reset and read_id command active at the same time 
		bins SysReset_and_InvalidCmd 	= binsof(Invalid) intersect {3'b000} && (binsof(SystemReset.SysReset));					// System reset and Invalid command at the same time
}

RowCross: cross Commands,RowAddr {
		bins InvalidRWA_and_Write	= binsof(Commands) intersect {program_page} &&(binsof(RowAddr.InvalidRWD));				// Invalid Row Address and all Program page command
		bins InvalidRWA_and_Read	= binsof(Commands) intersect {read_page} &&(binsof(RowAddr.InvalidRWD));				// Invalid Row Address and all read_page command
		bins InvalidRWA_and_erase	= binsof(Commands) intersect {erase} &&(binsof(RowAddr.InvalidRWD));					// Invalid Row Address and all erase command
		bins FirstPage_Write 		= binsof(Commands) intersect {program_page} && (binsof(RowAddr.RWA_Start));				// Write to first block first page in memory
		bins FirstPage_Read 		= binsof(Commands) intersect {read_page} && (binsof(RowAddr.RWA_Start));				// Read from first block first page in memory
		bins LastPage_Write 		= binsof(Commands) intersect {program_page} && (binsof(RowAddr.RWA_Last));				// Write to last block first page in memory
		bins LastPage_Read 		= binsof(Commands) intersect {read_page} && (binsof(RowAddr.RWA_Last));					// Read from last block first page in memory
}

endgroup
/***********************************************************************************************/

function new (virtual flash_bfm b);
	 Mix_Inputs = new();
	 bfm = b;
endfunction : new 

/************************************** Execute task *******************************************/
task execute();
	forever begin : sampling_block
		@(negedge bfm.clk);
		Mix_Inputs.sample();
	end : sampling_block

endtask : execute
/***********************************************************************************************/

endclass : coverage



