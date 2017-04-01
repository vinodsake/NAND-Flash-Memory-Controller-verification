/************************************************************************************************************************************************
*																		*
* 							  	TESTBENCH									*															*
*																		*
************************************************************************************************************************************************/

`include "tester.sv"
`include "coverage.sv"
`include "checker.sv"

class testbench;
	virtual flash_bfm bfm;
	
	function new(virtual flash_bfm b);
		bfm = b;
	endfunction : new

	tester tester_h;
	coverage coverage_h;
	scoreboard scoreboard_h;
	check check_h;

	task execute();
		tester_h = new(bfm);
		coverage_h = new(bfm);
		scoreboard_h = new(bfm);
		check_h = new(bfm);
		fork
			tester_h.execute();
			coverage_h.execute();
			check_h.execute();
			scoreboard_h.update_memory();
		join_none 
	endtask : execute
endclass : testbench

