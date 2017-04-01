
//   ==================================================================
//   >>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
//   ------------------------------------------------------------------
//   Copyright (c) 2013 by Lattice Semiconductor Corporation
//   ALL RIGHTS RESERVED 
//   ------------------------------------------------------------------
//
//   Permission:
//
//      Lattice SG Pte. Ltd. grants permission to use this code
//      pursuant to the terms of the Lattice Reference Design License Agreement. 
//
//
//   Disclaimer:
//
//      This VHDL or Verilog source code is intended as a design reference
//      which illustrates how these types of functions can be implemented.
//      It is the user's responsibility to verify their design for
//      consistency and functionality through the use of formal
//      verification methods.  Lattice provides no warranty
//      regarding the use or functionality of this code.
//
//   --------------------------------------------------------------------
//
//                  Lattice SG Pte. Ltd.
//                  101 Thomson Road, United Square #07-02 
//                  Singapore 307591
//
//
//                  TEL: 1-800-Lattice (USA and Canada)
//                       +65-6631-2000 (Singapore)
//                       +1-503-268-8001 (other locations)
//
//                  web: http://www.latticesemi.com/
//                  email: techsupport@latticesemi.com
//
//   --------------------------------------------------------------------
//
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author      :| Mod. Date :| Changes Made:
//   V01.0:| J.T         :| 06/20/09  :| Initial ver
// --------------------------------------------------------------------
//
// 
//Description of module:
//--------------------------------------------------------------------------------
// 
// -------------------------------------------------------------------------------

`timescale 1 ns / 1 fs

module flash_interface(
    DIO,
    CLE,	// -- CLE
    ALE,	//  -- ALE
    WE_n,	// -- ~WE
    RE_n, 	//-- ~RE
    CE_n, 	//-- ~CE
    R_nB, 	//-- R/~B
    rst
);

parameter page = ((2*(2**10))+64);
parameter block = page*64;
parameter size = block*10;

  inout [7:0] DIO;
  input CLE;		// -- CLE
  input ALE;		//  -- ALE
  input WE_n;		// -- ~WE
  input RE_n; 		//-- ~RE
  input CE_n; 		//-- ~CE
  output reg R_nB; 	//-- R/~B
  input rst;
                                   

reg [7:0] memory [10:0][63:0][0:page-1];
reg dat_en;
reg[7:0] datout;
reg[7:0] command;
reg[7:0] row1,row2,col1,col2,idaddr;
reg[9:0] block_addr;
reg[5:0] page_addr;
assign DIO=dat_en?datout:8'hzz;  

//assign DIO=dat_en?datout:8'hFF;

always@(posedge WE_n or rst) 
 if(rst) begin
  command<= 8'hff;
 end else 
  if(!CE_n && CLE) begin
   command=DIO;   
   case(command)
    8'h60:
      $display($time,"ns : auto block erase setup command");
    8'hd0:
      $display($time,"ns : erase address:%h",{row1,row2});   
    8'h70:
      $display($time,"ns : read status command"); 
    8'h80:
      $display($time,"ns : write page setup command"); 
    8'h85:begin
      $display($time,"ns : write page row address:%h",{row1,row2});
      $display($time,"ns : random data write command");               
    end
    8'h10:begin
      $display($time,"ns : random write page column address:%h",{col1,col2}); 
      $display($time,"ns : write page command");                             
    end
    8'h00:
       $display($time,"ns : read page setup command"); 
    8'h30:begin
       $display($time,"ns : read page row address:%h,column address:%h",{row1,row2},{col1,col2});
       $display($time,"ns : read page command");  
    end
    8'h05:
       $display($time,"ns : random read page setup command"); 
    8'he0:begin
       $display($time,"ns : random read page column address:%h",{col1,col2});
       $display($time,"ns : random read page command");                      
    end  
    8'hff:begin
       $display($time,"ns:  reset function ");   
    end
    8'h90:begin
        $display($time,"ns:  read ID function "); 
    end
   endcase   
  end 

always@(posedge WE_n or rst) 
begin
 if(rst) begin
  row1<= 8'h00;
  row2<= 8'h00;
  col1<= 8'h00;
  col2<= 8'h00;
  idaddr<=8'h00;
  block_addr <= 10'd0;
  page_addr <= 6'd0;
 end 
else begin

  if(!CE_n && ALE) begin  

   case(command)
    8'h60: begin
      row1<=DIO;
      row2<=row1;      
    end
//    8'hd0: 
//      $display($time,"ns : erase address:%h",{row1,row2});   
    8'h80:begin
      row1<= DIO;
      row2<= row1;
      col1<= row2;
      col2<= col1;     
    end          
    8'h85:begin
      col1<= DIO;
      col2<= col1;
  //    $display($time,"ns : write page row address:%h, column address:%h",{row1,row2},{col1,col2});               
    end
//    8'h10:
//      $display($time,"ns : random write page column address:%h",{col1,col2});                             
    8'h00:begin
      row1<= DIO;
      row2<= row1;
      col1<= row2;
      col2<= col1;
    end
//    8'h30:       
//       $display($time,"ns : read page row address:%h,column address:%h",{row1,row2},{col1,col2});  
    8'h05:begin
       col1<= DIO;
       col2<= col1;
    end
//    8'he0:
//       $display($time,"ns : random read page column address:%h",{col1,col2});  
    8'h90:begin
       idaddr<=DIO;
    end                      
   endcase 

end
	block_addr <=  {row1,row2[7:6]};
	page_addr <= row2[5:0];  

end
  end 
  
reg [11:0] con1,con1_835;  
integer i;
always@(posedge WE_n or rst) 
 if(rst) begin
  con1_835<=12'h835;   
  con1<=0;
	for(int i=0;i<1024;i++) begin
  		for(int j=0;j<64;j++) begin
			for(int k=0;k<page-1;k++) begin
				memory[i][j][k] = 8'h00;
			end
		end
	end
 end else   
  if(!CE_n && !ALE && !CLE && command==8'h80) begin 
    	memory[block_addr][page_addr][con1] = DIO;
    con1 <= con1 + 1;
  end else if(!CE_n && !ALE && !CLE && command==8'h85) begin 
    memory[block_addr][page_addr][con1_835]=DIO;
    con1_835 <= con1_835+1;
  end

reg [1:0] con;
always@(negedge RE_n or rst)// or CE_n or ALE or CLE) 
 if(rst) begin
  con<=0;
 end else if(!CE_n && !ALE && !CLE && command==8'h90) begin 
  con<=con+1;
 end 
  
  

reg [11:0] con2,con2_835;  
always@(negedge RE_n or rst)// or CE_n or ALE or CLE) 
begin
 if(rst) begin
  con2<=0;
  datout<=0;
  con2_835<=12'h835;
 end 
	else if(!CE_n && !ALE && !CLE && command==8'h30) begin     
     datout<=memory[block_addr][page_addr][con2];    
     con2<=con2+1;   
     con2_835<=12'h835;          
  end 
	else if(!CE_n && !ALE && !CLE && command==8'he0) begin 
    datout<=memory[block_addr][page_addr][con2_835];            
    con2_835<=con2_835+1;
	con2 <= 0;
  end 
	else if(!CE_n && !ALE && !CLE && command==8'h70) begin 
    datout<=8'h00;            
    con2<=0; 
	con1 <=0;
    con2_835<=12'h835;
	con1_835<=12'h835;
  end 
	else if(!CE_n && !ALE && !CLE && command==8'h90) begin               
    con2<=0; 
	con1 <=0;
    con2_835<=12'h0;
	//con1_835<=12'h835;
    if(con==2'b00) begin
      datout<=8'hec;
      $display($time,"ns : id code:%h",datout);      
    end 
	else if(con==2'b01) begin
      datout<=8'ha1;  
      $display($time,"ns : id code:%h",datout); 
    end 
	else if(con==2'b10) begin
      datout<=8'h00;  
      $display($time,"ns : id code:%h",datout); 
    end 
	else if(con==2'b11) begin
      datout<=8'h15;      
      $display($time,"ns : id code:%h",datout); 
    end
  end 
	else begin
    con2<=0;
    //datout<=0;
	con1 <=0;
    con2_835<=12'h835;
  end 

end
  
always@(/*posedge*/negedge RE_n or rst or con2 or con2_835)// or CE_n or ALE or CLE) 
 if(rst) begin  
  dat_en<=0; 
 end else begin  
  if(!CE_n && !ALE && !CLE && command==8'h30) begin
    if(con2!=2048)
      dat_en<=1;
    else
      #50 
      dat_en<=0;           
  end else if(!CE_n && !ALE && !CLE && command==8'he0) begin 
    if(con2_835!=2113)
      dat_en<=1;
    else
      #50 
      dat_en<=0;   
      
   end else if(!CE_n && !ALE && !CLE && command==8'h90) begin 
      dat_en<=1;
       #50
       dat_en<=0;    
  end else if(command==8'h70) begin 
    dat_en<=1;
    #151
    dat_en<=0;
    
  end //else if begin
 
  end

always@(RE_n or rst or CE_n or ALE or CLE or WE_n) 
 if(rst) begin
  R_nB<=1;
 end else   
  if(command==8'hd0) begin 
    #60
    R_nB<=0;
    #200;
    R_nB<=1;
	
  end else if(command==8'h10) begin 
    #60
    R_nB<=0;
    #200;
    R_nB<=1;
  end else if(command==8'h30) begin 
    #60
    R_nB<=0;
    #200
    R_nB<=1;
	
  end else
    R_nB<=1;
       
  

endmodule