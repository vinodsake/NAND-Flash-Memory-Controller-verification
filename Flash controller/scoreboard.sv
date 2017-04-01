/************************************************************************************************************************************************
*																		*
* 							  FLASH MEMORY CONTROLLER SCOREBOARD							*															*
*																		*
************************************************************************************************************************************************/

import flash_pkg::*;

class scoreboard;

virtual flash_bfm bfm;	

function new (virtual flash_bfm b);
	bfm = b;
endfunction : new 

/************************************ Internal Variables ***************************************/
bit [SIGNAL_WIDTH:0] scoreboard_db [SB_DEPTH:0];
static bit  [LUT:0] sb_lut [0:3]; 

static int counter1;
static int counter2;
static int counter3;
static int counter4;
static int pointer= 32'd0;
static int count_ptr;
bit [2:0] cmd_store;
static int CMD_State= 32'd0;
static int ALE_State= 32'd0;
static bit [15:0]Row_Addr;
/***********************************************************************************************/

/************************************** Execute task *******************************************/
task execute();
	if(sb_lut[0][3:1]!=0)
		bfm.sb_checkstart1=1;
	else
		bfm.sb_checkstart1=0;
	if(sb_lut[1][3:1]!=0)
		bfm.sb_checkstart2=1;
	else
		bfm.sb_checkstart2=0;
	if(sb_lut[2][3:1]!=0)
		bfm.sb_checkstart3=1;
	else
		bfm.sb_checkstart3=0;
	if(sb_lut[3][3:1]!=0)
		bfm.sb_checkstart4=1;
	else
		bfm.sb_checkstart4=0;
endtask
/***********************************************************************************************/

/*********************************** Update memory task ****************************************/
task update_memory();
    forever begin :update 
	   counter1= bfm.sb_counter1;
	   counter2= bfm.sb_counter2;
	   counter3= bfm.sb_counter3;
	   counter4= bfm.sb_counter4;
	   Row_Addr= bfm.RWA;
 	   @(posedge bfm.clk);
           #2;
       	   if((bfm.nfc_strt == TRUE && bfm.nfc_cmd == reset) || (bfm.nfc_strt == TRUE && bfm.nfc_cmd == program_page)||
		(bfm.nfc_strt == TRUE && bfm.nfc_cmd == read_page)||(bfm.nfc_strt == TRUE && bfm.nfc_cmd == erase)||
		(bfm.nfc_strt == TRUE && bfm.nfc_cmd == read_id))
	    begin
                       if(pointer==0) begin
				sb_lut [pointer][3:1]=bfm.nfc_cmd;
				pointer++;
		               end
			else if(pointer==1) begin
			     sb_lut [pointer][3:1]=bfm.nfc_cmd;
				 pointer++;
			end
			else if(pointer==2) begin
			     sb_lut [pointer][3:1]=bfm.nfc_cmd;
				 pointer++;
			end
			else if(pointer==3) begin
			     sb_lut [pointer][3:1]=bfm.nfc_cmd;
				 pointer=0;
			end
			execute();
		end
	end: update
endtask : update_memory
/***********************************************************************************************/

/************************************* Reset LUT task ******************************************/
task Reset_LUT();
	if (sb_lut[0][0] == 1'b1) begin
		sb_lut[0][3:1] = 3'b0;
		sb_lut[0][0] = 1'b0;
	end
	if (sb_lut[1][0] == 1'b1) begin
		sb_lut[1][3:1] = 3'b0;
		sb_lut[1][0] = 1'b0;
	end
	if (sb_lut[2][0] == 1'b1) begin
		sb_lut[2][3:1] = 3'b0;
		sb_lut[2][0] = 1'b0;
	end
	if (sb_lut[3][0] == 1'b1) begin
		sb_lut[3][3:1] = 3'b0;
		sb_lut[3][0] = 1'b0;
	end
endtask
/***********************************************************************************************/

/************************************ Check valid task *****************************************/
task Check_valid_cmd(output bit [2:0] Checker_cmd);
        if(counter1==32'd8 || counter1==32'd7) 
	begin 
		 sb_lut[0][0] = 1'b1;      									//Update the Valid bit 
            	 cmd_store=sb_lut[0][3:1];
        end
	else
	begin
		sb_lut[0][0] = 1'b0;      
            	sb_lut[0][3:1] = 3'b0;
	end

        if(counter2==32'd8 || counter2==32'd7)
        begin 
		sb_lut[1][0] = 1'b1;      									//Update the Valid bit 
            	cmd_store=sb_lut[1][3:1];
        end	
	else
	begin
		sb_lut[1][0] = 1'b0;      
            	sb_lut[1][3:1] = 3'b0;
	end

        if(counter3==32'd8 || counter3==32'd7)
        begin 
		sb_lut[2][0] = 1'b1;      									//Update the Valid bit 
            	cmd_store=sb_lut[2][3:1];
        end	
	else
	begin
		sb_lut[2][0] = 1'b0;      
            	sb_lut[2][3:1] = 3'b0;
	end

        if(counter4==32'd8 || counter4==32'd7)
            begin 
		    sb_lut[3][0] = 1'b1;      									//Update the Valid bit 
            	    cmd_store=sb_lut[3][3:1];
            end				
	else
	begin
		sb_lut[3][0]=1'b0;      
            	sb_lut[3][3:1] = 3'b0;
	end
	Checker_cmd=cmd_store;		
endtask : Check_valid_cmd
/***********************************************************************************************/

/***************************************** CLE task ********************************************/
task CLE(output bit [7:0] signal_cmd);
	case(cmd_store)
		reset:      
		begin
			Reset_CMD(signal_cmd);
		end
	
		read_id:    
		begin  
			ReadID_CMD(signal_cmd);
		end
	
		erase: 
 		begin 
			BlockErase_CMD(signal_cmd);
		end
 	
		program_page: 
		begin 
        	       	Pageprogram_CMD(signal_cmd);
		end
        	       
		read_page: 
		begin  
			Read_CMD(signal_cmd);
        	end
	endcase
endtask : CLE	   
/***********************************************************************************************/     

/***************************************** ALE task ********************************************/
task ALE (output bit [7:0] signal_Addrcmd);
	case(cmd_store)
		read_id:    
		begin  
			ReadID_ALE(signal_Addrcmd);
		end

		erase:
	  	begin 
			BlockErase_ALE(signal_Addrcmd);
		end
 
		program_page : 
		begin 
               		Pageprogram_ALE(signal_Addrcmd);
		end
               
		read_page: 
		begin  
			Read_ALE(signal_Addrcmd);
           	end
	endcase
endtask : ALE	
/***********************************************************************************************/


/*************************************** CMD Flowcharts ****************************************/
task Reset_CMD(output logic [7:0]Command);
	Command = 8'hFF;
endtask : Reset_CMD

task ReadID_CMD(output logic [7:0]Command);
	Command = 8'h90;
endtask : ReadID_CMD

task BlockErase_CMD(output logic [7:0]Command);
	case(CMD_State)
		32'd0: begin Command = 8'h60;
			CMD_State = CMD_State + 32'd1;
		       end		
		32'd1: begin Command = 8'hd0;
				CMD_State = CMD_State+ 32'd1;
			end
		32'd2: begin Command = 8'h70;
				CMD_State = 32'd0;
			end
	endcase
endtask : BlockErase_CMD

task Pageprogram_CMD(output logic [7:0]Command);
	case(CMD_State)
		32'd0: begin	Command = 8'h80;
				CMD_State = CMD_State+ 32'd1;
			end
				
		32'd1: begin Command = 8'h85;
				CMD_State = CMD_State+ 32'd1;
			end	
		32'd2: begin	Command = 8'h10;
				CMD_State = CMD_State+ 32'd1;
			end			
		32'd3: begin Command = 8'h70;
				CMD_State = 32'd0;
			end		
	endcase
endtask : Pageprogram_CMD

task Read_CMD(output logic [7:0]Command);
	case(CMD_State)
		32'd0: begin	Command = 8'h00;
				CMD_State = CMD_State+ 32'd1;
			end	
		32'd1: begin	Command = 8'h30;
				CMD_State = CMD_State+ 32'd1;
			end
		32'd2: begin	Command = 8'h05;
				CMD_State = CMD_State+ 32'd1;
			end
		32'd3: begin	Command = 8'hE0;
				CMD_State = 32'd0;	
			end	
	endcase
endtask : Read_CMD
/***********************************************************************************************/

/*************************************** Adr Flowcharts ****************************************/
task ReadID_ALE(output logic [7:0]Address);
	Address = 8'h0;
endtask : ReadID_ALE

task BlockErase_ALE(output logic [7:0]Address);
	case(ALE_State)
		32'd0: begin Address = Row_Addr[7:0];
				ALE_State =ALE_State + 32'd1;
			end
		32'd1: begin Address = Row_Addr[15:8];
				ALE_State = 32'd0;
			end
	endcase
endtask : BlockErase_ALE

task Pageprogram_ALE(output logic [7:0]Address);
	case(ALE_State)
		32'd0: begin	Address = 8'h0;
				ALE_State =ALE_State + 32'd1;
			end
		32'd1: begin	Address = 8'h0;
				ALE_State = ALE_State + 32'd1;
			end	
		32'd2: begin	Address = Row_Addr[7:0];
				ALE_State = ALE_State + 32'd1;
			end
		32'd3: begin	Address = Row_Addr[15:8];		
				ALE_State = ALE_State + 32'd1;
			end
		32'd4: begin	Address = 8'h35;
				ALE_State = ALE_State + 32'd1;
			end
		32'd5:	begin	Address = 8'h08;
				ALE_State = 32'd0;
			end
	endcase
endtask : Pageprogram_ALE

task Read_ALE(output logic [7:0]Address);
	case(ALE_State)
		32'd0: begin	Address = 8'h0;
				ALE_State =ALE_State + 32'd1;
			end
		32'd1: begin	Address = 8'h0;
				ALE_State = ALE_State + 32'd1;
			end	
		32'd2: begin	Address = Row_Addr[7:0];
				ALE_State = ALE_State + 32'd1;
			end	
		32'd3: begin	Address = Row_Addr[15:8];		
				ALE_State = ALE_State + 32'd1;
			end	
		32'd4: begin	Address = 8'h35;
				ALE_State = ALE_State + 32'd1;
			end	
		32'd5:	begin	Address = 8'h08;
				ALE_State = 32'd0;
			end
	endcase
endtask : Read_ALE
/***********************************************************************************************/

endclass : scoreboard


