/************************************************************************************************************************************************
*																		*
* 						FLASH MEMORY CONTROLLER - TESTER/STIMULUS GENERATOR						*															*
*																		*
************************************************************************************************************************************************/

import flash_pkg::*;

class tester;

/************************************* Internal Variables ***************************************/
logic [15:0] Addr;
operations random_cmd1;
operations random_cmd2;
/***********************************************************************************************/

/*************************************** Temp Memory *******************************************/
logic [7:0] memory[0:2047];
/***********************************************************************************************/

virtual flash_bfm bfm;

function new (virtual flash_bfm b);
	 bfm = b;
endfunction : new 

/******************************** Random command generation ************************************/
protected function operations get_cmd();
	bit [2:0] cmd_choice;
	cmd_choice = $urandom_range(5,1);
	case (cmd_choice)
		3'b001 : return program_page;
		3'b010 : return read_page;
		3'b100 : return erase;
		3'b011 : return reset;
		3'b101 : return read_id;
	endcase	
endfunction : get_cmd
/***********************************************************************************************/

/******************************** Random Address generation ************************************/
protected function logic [15:0] Address_Rand();
	logic [15:0]Address;
	Address= $urandom_range(1023,0);
	return Address;
endfunction
/***********************************************************************************************/

/************************************* Execute task ********************************************/
task execute();
	
        bfm.system_reset(2);
	kill(10);


	stress_test;
	random(50);
	Cross;
	basic_operations;

	$stop;
endtask : execute
/***********************************************************************************************/

/************************************ random task ********************************************/
task random(input int count);
	
	for(int i=0; i<= count; i++) begin
		@(posedge bfm.clk);
		random_cmd1 = get_cmd();
		Addr =Address_Rand();
		pick(random_cmd1,Addr);
       		wait(bfm.nfc_done);
        	@(posedge bfm.clk) ;
   		bfm.nfc_cmd=3'b111;

		kill(10);
		@(posedge bfm.clk);
		random_cmd2 = get_cmd();
		Addr =Address_Rand();
		pick(random_cmd2,Addr);
        	wait(bfm.nfc_done);
        	@(posedge bfm.clk) ;
   		bfm.nfc_cmd=3'b111;
	end
endtask
/***********************************************************************************************/

/********************************* pick random command *****************************************/
task pick(input bit[2:0]random_cmd, bit [9:0]Addr);
	case(random_cmd)
		program_page:	write_cycle(Addr);
			
		read_page:	read_cycle(Addr);

		erase:		erase_cycle(Addr);

		reset:		reset_cycle;

		read_id:	read_id_cycle;
	endcase
endtask
/***********************************************************************************************/

/************************************* stress test *********************************************/
task stress_test;

	//5 consecutive writes from same block and consecutive pages
	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h00c1);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h00c2);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h00c3);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h00c4);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h00c5);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h00c6);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//5 consecutive reads with same block and consecutive reads
	@(posedge bfm.clk);
	read_cycle(16'h00c1);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	read_cycle(16'h00c2);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	read_cycle(16'h00c3);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	read_cycle(16'h00c4);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	read_cycle(16'h00c5);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	// Write's to pages in different blocks
	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h0041);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h0008);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;


	// Read's from pages in different blocks
	kill(10); 
	@(posedge bfm.clk);
	read_cycle(16'h0041);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	read_cycle(16'h0008);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	// write's to random pages in same block
	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h0043);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h0049);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//read's to random pages in same block
	kill(10); 
	@(posedge bfm.clk);
	read_cycle(16'h0043);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	read_cycle(16'h0049);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	// Erase to page program
	kill(10);
	erase_cycle(16'h00c8);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h0246);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//reset to program page
	kill(10);
	reset_cycle();
	repeat(10)@(posedge bfm.clk);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h0042);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//page program to erase
	kill(10);
	erase_cycle(16'h0042);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//read to program page 
	kill(10); 
	@(posedge bfm.clk);
	read_cycle(16'h0042);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h0043);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//page program to read_id
	kill(10);
	read_id_cycle();
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//Write and Read from first and last location in memory
	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h0000);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//Read from first location
	kill(10); 
	@(posedge bfm.clk);
	read_cycle(16'h0000);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//Write and read from last location
	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'h03FF);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//Read from last location
	kill(10); 
	@(posedge bfm.clk);
	read_cycle(16'h03FF);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//back to back reset
	kill(10);
	reset_cycle();
	repeat(10)@(posedge bfm.clk);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10);
	reset_cycle();
	repeat(10)@(posedge bfm.clk);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//back to back erase
	kill(10);
	erase_cycle(16'h0000);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10);
	erase_cycle(16'h03FF);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;
endtask
/***********************************************************************************************/

/************************************* cross task **********************************************/
task Cross;
	// Commands with System Reset at the same time
	// System reset with write command
	kill(10); 
	@(posedge bfm.clk);
        write_cycle(16'hxxxx);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	//System reset with read_page command
	kill(10);
	bfm.rst= 1'b1;
	read_cycle(16'h00c8);
	bfm.rst= 1'b0;

	// System Reset with Erase command
	kill(10);
	bfm.rst= 1'b1;
	erase_cycle(16'h00c5);
	bfm.rst= 1'b0;

	//System Reset with reset command
	kill(10);
	bfm.rst= 1'b1;
	reset_cycle();
	bfm.rst= 1'b0;

	//System Reset with Read_id command
	kill(10);
	bfm.rst= 1'b1;
	read_id_cycle();
	bfm.rst= 1'b0;

	// System Reset with Invalid command
	kill(10);
	bfm.rst= 1'b1;
	Invalid_Cmd();
	bfm.rst= 1'b0;

	// Invalid Row Address with Write Command
	kill(10); 
	@(posedge bfm.clk);
	write_cycle(16'hxxxx);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	// Invalid Row Address with Read Command
	kill(10); 
	@(posedge bfm.clk);
	read_cycle(16'hxxxx);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	// Invalid Row Address with Erase command
	kill(10);
	erase_cycle(16'hxxxx);
        wait(bfm.nfc_done);
        @(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

endtask : Cross
/***********************************************************************************************/

/*********************************** basic operations ******************************************/
task basic_operations;
	write_cycle(16'h00c8);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;
	
	kill(10);
	read_cycle(16'h00c8);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;
	//read_buffer();

	kill(10);
	write_cycle(16'h00c7);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10);
	erase_cycle(16'h00c8);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10);
	reset_cycle();
	repeat(10)@(posedge bfm.clk);
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;

	kill(10);
	read_id_cycle();
	wait(bfm.nfc_done);
	@(posedge bfm.clk) ;
   	bfm.nfc_cmd=3'b111;
endtask
/***********************************************************************************************/

/************************************ Commands task ********************************************/
task Invalid_Cmd();
	bfm.send(3'b000, 16'h0000);
endtask

task write_cycle(input logic [15:0]addr);
	bfm.send(3'b001,addr);
	for(int i=0; i<2048; i++) begin
		memory[i]=$random % 256; 
		bfm.write_buffer(1'b1,memory[i],i);
	end
endtask

task read_data();
	for(int i=0; i<2048; i++) begin
		bfm.read_buffer(i);
	end
endtask

task read_cycle(input bit [15:0]addr);
	bfm.send(3'b010,addr);
endtask

task erase_cycle(input bit [15:0]addr);
	bfm.send(3'b100,addr);
endtask

task reset_cycle();
	bfm.send(3'b011,16'h1234);
endtask

task read_id_cycle();
	bfm.send(3'b101,16'h0000);
endtask
/***********************************************************************************************/

/************************************ Kill time task *******************************************/
task kill(input int i);
	repeat(i)@(posedge bfm.clk);		
endtask
/***********************************************************************************************/
endclass : tester