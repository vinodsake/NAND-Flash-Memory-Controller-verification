/************************************************************************************************************************************************
*																		*
* 							  FLASH MEMORY CONTROLLER - BFM								*															*
*																		*
************************************************************************************************************************************************/

`timescale 1 ns / 1 fs

parameter clk_cycle = 16;
parameter clk_width = clk_cycle/2;

import flash_pkg::*;

interface flash_bfm;

/********************************* Interface variables *****************************************/
 bit clk,rst;

 wire [7:0] DIO;
 logic CLE;		// -- CLE
 logic ALE;		//  -- ALE
 logic WE_n;		// -- ~WE
 logic RE_n; 		//-- ~RE
 logic CE_n; 		//-- ~CE
 logic R_nB; 		//-- R/~B

 logic BF_sel;
 logic [10:0] BF_ad;
 logic [7:0] BF_din;
 logic BF_we;
 logic [15:0] RWA; 	//-- row addr
 logic [7:0] BF_dou;

 logic PErr ; 		// -- progr err
 logic EErr ; 		// -- erase err
 logic RErr ;

 bit [2:0] nfc_cmd; 	// -- command see below       
 logic nfc_strt;	//  -- pos edge (pulse) to start
 logic nfc_done;	//  -- operation finished if '1'
/***********************************************************************************************/

/********************************* Internal variables ******************************************/
 bit check_start;
 int check_counter;

 bit sb_checkstart1,sb_checkstart2,sb_checkstart3,sb_checkstart4;
 int sb_counter1, sb_counter2,sb_counter3,sb_counter4;

 bit sb_checkstart;

/************************************** System clock *******************************************/
initial clk = 0;
always	#clk_width clk = ~clk;
/***********************************************************************************************/

/************************************ Checker Counter ******************************************/
always@ (posedge clk or posedge check_start) begin
	if(check_start)
		check_counter = check_counter + 1;
	else begin
		check_counter = 0;
		check_start = 0;
	end
end
/***********************************************************************************************/

/********************************* Scoreboard Counters *****************************************/
always@(posedge clk  or posedge sb_checkstart1) begin
	if(sb_checkstart1)
     		sb_counter1 =sb_counter1+1;
  	else 
      		sb_counter1=0;
end

always@(posedge clk or posedge sb_checkstart2) begin
  	if(sb_checkstart2)
     		sb_counter2 =sb_counter2+1;
  	else 
      		sb_counter2=0;
end

always@(posedge clk or posedge sb_checkstart3) begin
  	if(sb_checkstart3)
     		sb_counter3 =sb_counter3+1;
  	else 
      		sb_counter3=0;
end

always@(posedge clk or posedge sb_checkstart4 ) begin
  	if(sb_checkstart4)
     		sb_counter4 =sb_counter4+1;
  	else 
      		sb_counter4=0;
end
/***********************************************************************************************/

/************************************** Send task **********************************************/
task send(input int cmd, input logic [15:0] address);

	case(cmd)
		program_page :	begin
					@(posedge clk) ;
  					#3;
    					RWA=address;
    					nfc_cmd=3'b001;
    					nfc_strt=1'b1;      
    					BF_sel=1'b1;
    					@(posedge clk) ;
    					#3;
    					nfc_strt=1'b0; 
    					BF_ad=0;
				end
		
		read_page :	begin
					@(posedge clk) ;
    					#3;
    					RWA=address;
    					nfc_cmd=3'b010;
    					nfc_strt=1'b1;
    					BF_sel=1'b1;
    					BF_we=1'b0;
    					BF_ad=#3 0;
    					@(posedge clk) ;
    					#3;
    					nfc_strt=1'b0; 
					BF_ad=0; 
				end

		erase : 	begin
					@(posedge clk) ;
    					#3;
    					RWA=address;
    					nfc_cmd=3'b100;
    					nfc_strt=1'b1;	
    					@(posedge clk) ;
    					#3;
    					nfc_strt=1'b0; 
				end

		reset : 	begin
					@(posedge clk) ;
    					nfc_cmd=3'b011;
    					nfc_strt=1'b1;
					@(posedge clk) ;
    					nfc_strt=1'b0; 
				end
				
		read_id : 	begin
					@(posedge clk) ;
    					#3;
   			  	      	RWA=address;
    					nfc_cmd=3'b101;
    					nfc_strt=1'b1;
    					BF_sel=1'b1;
    					@(posedge clk) ;
    					#3;
    					nfc_strt=1'b0;    
			  	end	
	endcase
	
endtask : send
/***********************************************************************************************/

/******************************** write buffer task ********************************************/
task write_buffer(input bit bf_we, input bit[7:0] bf_din, input int i);
	@(posedge clk);
	#3;
	BF_we = bf_we;
	BF_din <= bf_din;
     	BF_ad <= #3 i; 
endtask : write_buffer

task read_buffer(input int i);                                                                
       		@(posedge clk);                                                                
       		BF_ad<=#3 i; 
endtask : read_buffer
/***********************************************************************************************/

/********************************* System reset task *******************************************/
task system_reset(input int count);
	@(posedge clk)
	rst <= 1'b1;
        $display($time,"Entered reset block to check if it is entering in same clk");
	repeat (count) @(posedge clk);
	rst <= 1'b0;
endtask : system_reset
/***********************************************************************************************/

/************************************ Kill time task *******************************************/
task kill_time;                                                         
  begin                                                                 
    @(posedge clk);                                                 
    @(posedge clk);                                                 
    @(posedge clk);                                                 
    @(posedge clk);                                                 
    @(posedge clk);                                                 
  end                                                                   
endtask : kill_time
/***********************************************************************************************/

endinterface : flash_bfm                                                                         



