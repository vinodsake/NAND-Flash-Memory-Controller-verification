/************************************************************************************************************************************************
*																		*
* 							  FLASH MEMORY CONTROLLER CHECKER							*															*
*																		*
************************************************************************************************************************************************/

`include "scoreboard.sv"

import flash_pkg::*;										// Import flash package								
		
class check;

virtual flash_bfm bfm;	

function new (virtual flash_bfm b);
	bfm = b;
endfunction : new 

scoreboard scoreboard_i = new(bfm);

/************************************* Internal Variables ***************************************/
static bit [4:0] command [9:0];
static bit [4:0] address [9:0];
static bit [7:0] cmd_data;
static bit [7:0] adr_data;
static bit [2:0] cmnd;

bit CE_rec = FALSE;
static bit start = FALSE;
static bit done = FALSE;
/***********************************************************************************************/

/********************************** command & address signals  *********************************/
// signals : CE_n, CLE, ALE, RE_n, WE_n
task cmd_sig;
	command[1] = 5'b01010;
	command[2] = 5'b01010;
	command[3] = 5'b01010;
	command[4] = 5'b01011;
	command[5] = 5'b10011;
endtask

task adr_sig;
	address[1] = 5'b00110;
	address[2] = 5'b00110;
	address[3] = 5'b00110;
	address[4] = 5'b00111;
	address[5] = 5'b10011;

endtask
/***********************************************************************************************/

/************************************** Execute task *******************************************/
task execute();
	forever begin : check
		@(negedge bfm.clk);
		if(bfm.CE_n == FALSE) begin
			done = FALSE;
			if(start == FALSE) begin
				scoreboard_i.Check_valid_cmd(cmnd);				// Request scoreboard for valid output signals
				start = TRUE;
			end
			if(bfm.CLE == TRUE) begin
				cmd;
			end
			else if(bfm.ALE == TRUE) begin
				adr;
			end
		end
		if(bfm.nfc_done == TRUE && done == FALSE) begin
			start = FALSE;
			scoreboard_i.Reset_LUT();						// Confirm scoreboard about completion of operation
			done = TRUE;
			
		end
	end : check
endtask
/***********************************************************************************************/

/**************************************** cmd task *********************************************/
task cmd();
	cmd_sig;
	#2;
	if(command[1] != {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n}) begin
		$display("%3d Error!! --> Expected cntl signals: %b, Actual cntl signals: %b",`__LINE__, command[1], {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n});
	end
	else if(DEBUG) begin
		$display("%3d success!!",`__LINE__);
	end
	
	@(negedge bfm.clk);
	scoreboard_i.CLE(cmd_data);	
	#2;
	if(cmd_data != bfm.DIO) begin
		$display("%3d Error!! time is %0t--> Expected cntl data: %b, Actual cntl data: %b",`__LINE__, $time ,cmd_data, bfm.DIO);
	end
	else if(DEBUG) begin
		$display("%3d success!!",`__LINE__);
	end
	if(command[2] != {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n}) begin
		$display("%3d Error!! --> Expected cntl signals: %b, Actual cntl signals: %b",`__LINE__, command[2], {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n});
	end
	else if(DEBUG) begin
		$display("%3d success!!",`__LINE__);
	end

	@(negedge bfm.clk);
	if(command[3] != {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n}) begin
		$display(" %3d Error!! --> Expected cntl signals: %b, Actual cntl signals: %b",`__LINE__, command[3], {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n});
	end
	else if(DEBUG) begin
		$display("%3d success!!",`__LINE__);
	end

	@(negedge bfm.clk);
	if(command[4] != {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n}) begin
		$display("%3d Error!! --> Expected cntl signals: %b, Actual cntl signals: %b",`__LINE__, command[4], {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n});
	end
	else if(DEBUG) begin
		$display("%3d success!!",`__LINE__);
	end

	@(negedge bfm.clk);
	if(command[5] != {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n}) begin
		$display("%3d Error!! --> Expected cntl signals: %b, Actual cntl signals: %b",`__LINE__, command[5], {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n});
	end
	else if(DEBUG) begin
		$display("%3d success!!",`__LINE__);
	end
endtask : cmd
/***********************************************************************************************/

/**************************************** adr task *********************************************/
task adr();
	adr_sig;
	#2;
	if(address[1] != {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n}) begin
		$display("%3d Error!! --> Expected cntl signals: %b, Actual cntl signals: %b",`__LINE__, address[1], {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n});
	end
	else if(DEBUG) begin
		$display("%3d success!!",`__LINE__);
	end
	
	@(negedge bfm.clk);
	scoreboard_i.ALE(adr_data);
	#2;
	if(adr_data != bfm.DIO) begin
		$display("%3d Error!! --> Expected adr data: %b, Actual adr data: %b",`__LINE__, adr_data, bfm.DIO);
	end
	else if(DEBUG) begin
		$display("%3d success!!",`__LINE__);
	end
	if(address[2] != {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n}) begin
		$display("%3d Error!! --> Expected cntl signals: %b, Actual cntl signals: %b",`__LINE__, address[2], {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n});
	end
	else if(DEBUG) begin
		$display("%3d success!!",`__LINE__);
	end

	@(negedge bfm.clk);
	if(address[3] != {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n}) begin
		$display("%3d Error!! --> Expected cntl signals: %b, Actual cntl signals: %b",`__LINE__, address[3], {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n});
	end
	else if(DEBUG) begin
		$display("%3d success!!",`__LINE__);
	end

	@(negedge bfm.clk);
	if(address[4] != {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n}) begin
		$display("%3d Error!! --> Expected cntl signals: %b, Actual cntl signals: %b",`__LINE__, address[4], {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n});
	end
	else if(DEBUG) begin
		$display("%3d success!!",`__LINE__);
	end

	@(negedge bfm.clk);
	if(address[5] != {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n}) begin
		$display("%3d Error!! --> Expected cntl signals: %b, Actual cntl signals: %b",`__LINE__, address[5], {bfm.CE_n,bfm.CLE,bfm.ALE,bfm.RE_n,bfm.WE_n});
	end
	else if(DEBUG) begin
		$display("%3d success!!",`__LINE__);
	end
endtask : adr
/***********************************************************************************************/

endclass : check


























