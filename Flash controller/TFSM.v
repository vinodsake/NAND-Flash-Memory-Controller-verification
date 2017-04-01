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
//   Ver  :| Author :| Mod. Date :| Changes Made:
//   V01.0:| A.Y    :| 09/30/06  :| Initial ver
//   v01.1:| J.T    :| 06/21/09  :| just use one buffer
// --------------------------------------------------------------------
//
// 
//Description of module:
//--------------------------------------------------------------------------------
// Timing FSM creating all the necessary control signals for the nand-flash memory.
// --------------------------------------------------------------------
`timescale 1 ns / 1 fs

module TFSM(
  CLE ,
  ALE ,
  WE_n,
  RE_n,
  CE_n,
  DOS ,
  DIS ,
  cnt_en,
  TC3,
  TC2048,
  CLK,
  RES,
  start,
  cmd_code,
  ecc_en,
  Done 
)/*synthesis ugroup="mfsm_group" */;
  
  output reg CLE ; //-- CLE               
  output reg ALE ; //-- ALE               
  output reg WE_n; // -- ~WE              
  output reg RE_n; // -- ~RE              
  output reg CE_n; // -- ~CE              
  output reg DOS ; // -- data out strobe  
  output reg DIS ; //  -- data in strobe  
  output reg cnt_en; //-- ca counter ce   
  input TC3 ; //-- term counts         
  input TC2048;                     
  input CLK ;                        
  input RES ;                        
  input start;                       
  input [2:0] cmd_code; 
  output reg Done;                  
  output reg ecc_en;

// Command codes:
// 000 -Cmd Latch
// 001 -Addr latch
// 010 -Data Read 1 (1 cycle as status)
// 100 -Data Read multiple (w TC3)
// 101 -Data Read multiple (w TC2048)
// 110 -Data Write (w TC3)
// 111 -Data Write (w TC2048)
// others'll return to Init

parameter Init=0, S_Start=1, S_CE=2, 
S_CLE=3, S_CmdOut=4, S_WaitCmd=5, DoneCmd=6, Finish=7, // Cmd latch
S_ALE=8, S_ADout=9, WaitAd=10, DoneAd=11, // Addr latch
S_RE1=12, WaitR1=13, WaitR2=14, DoneR1=15,// -- Read data 1
S_RE=16, WaitR1m=17, WaitR2m=18, WaitR3m=19, S_DIS=20, FinishR=21,//  -- Read data TC
S_WE=22, WaitW=23, WaitW1=24, WaitW2=25, S_nWE=26, FinishW=27;//   -- write data

reg [5:0] NxST, CrST;
reg Done_i;//  -- muxed Term Cnt
wire TC;
reg [2:0] cmd_code_int;

assign TC = cmd_code_int[0]?TC2048:TC3;

always@(posedge CLK)
  if (RES)
    Done <=0;
  else
    Done <= Done_i;


always@(posedge CLK)
  cmd_code_int <= cmd_code;

//the State Machine
always@(posedge CLK)
  CrST <= NxST;


always@(RES or TC or cmd_code_int or start or CrST)
if (RES) begin
  NxST <= Init;
  DIS <= 0;
  DOS <= 0;
  Done_i <=0;
  ALE <= 0;
  CLE <= 0;
  WE_n <= 1;
  RE_n <= 1;
  CE_n <= 1;
  cnt_en <=0;
  ecc_en<=1'b0;
end else begin//            -- default values
   DIS <= 0;
   DOS <= 0;
   Done_i <=0;
   ALE <= 0;
   CLE <= 0;
   WE_n <= 1;
   RE_n <= 1;
   CE_n <= 1;
   cnt_en <=0;
   ecc_en<=1'b0;
  case (CrST)
    Init:begin
      if (start)
        NxST <= S_Start;
      else
        NxST <= Init;
    end
    S_Start:begin
      if (cmd_code_int==3'b011)//  -- nop
        NxST <= Init;
      else
        NxST <= S_CE;
    end
    S_CE:begin
      if (cmd_code_int==3'b000) begin
        NxST <= S_CLE;
        CE_n <= 0;
      end else if (cmd_code_int ==3'b001) begin
        NxST <= S_ALE;
        CE_n <= 0;        
      end else if (cmd_code_int ==3'b010) begin
        NxST <= S_RE1;
        CE_n <= 0;        
      end else if (cmd_code_int[2:1]==2'b10) begin
        NxST <= S_RE;
        CE_n <= 0;        
      end else if (cmd_code_int[2:1] ==2'b11) begin
        NxST <= S_WE;
        CE_n <= 0;        
      end else
        NxST <= Init;
    end 
    S_CLE:begin
      CE_n <=0;
      CLE <= 1;
      WE_n <=0;
      NxST <= S_CmdOut;
    end
    S_CmdOut:begin
      CE_n <=0;
      CLE <= 1;
      WE_n <= 0;
      DOS <= 1;
      NxST <= S_WaitCmd;
    end
    S_WaitCmd:begin
      CE_n <=0;
      CLE <= 1;
      WE_n <=0;
      DOS <= 1;
      NxST <= DoneCmd;
    end
    DoneCmd:begin
      Done_i <=1;      
      CE_n <= 0;
      CLE <= 1;
      DOS <= 1;
      NxST <= Finish;
    end  
    Finish:begin
      DIS <=1; // --1226
      if (start)
        NxST <= S_Start;
      else
        NxST <= Init;
    end
    S_ALE:begin
      CE_n <=0;
      ALE <= 1;
      WE_n <= 0;
      NxST <= S_ADout;
    end
    S_ADout:begin
      CE_n <= 0;
      ALE <= 1;
      WE_n <= 0;
      DOS <= 1;
      NxST <= WaitAd;
    end
    WaitAd:begin
      CE_n <= 0;
      ALE <= 1;
      WE_n <= 0;
      DOS <= 1;
      NxST <= DoneAd;
    end
    DoneAd:begin
      Done_i <= 1;
      CE_n <= 0;
      ALE <= 1;
      DOS <= 1;
      NxST <= Finish;
    end
    S_RE1:begin
      CE_n <= 0;
      RE_n <= 0;
      NxST <= WaitR1;
    end
    WaitR1:begin
      CE_n <= 0;
      RE_n <= 0;
      NxST <= WaitR2;
    end
    WaitR2:begin
      CE_n <= 0;
      RE_n <= 0;
      NxST <= DoneR1;
    end
    DoneR1:begin
      Done_i <= 1; 
      cnt_en <=1;   
      NxST <= Finish; // -- can set DIS there as there'll be no F_we in EBL case
    end  
    S_RE:begin
      CE_n <= 0;
      RE_n <= 0;
      NxST <= WaitR1m;
    end
    WaitR1m:begin
      CE_n <= 0;
      RE_n <= 0;
      NxST <= WaitR2m;
    end
    WaitR2m:begin
      CE_n <= 0;
      RE_n <= 0;
      NxST <= S_DIS;
    end
    S_DIS:begin
      CE_n <=0;
//--    DIS  <=1;
      if (TC ==0)
        NxST <= WaitR3m;
      else
        NxST <= FinishR;
    end
    WaitR3m:begin
      CE_n <=0;
      cnt_en <=1;
      DIS <=1; // --1226
      NxST <= S_RE;
    end
    FinishR:begin
      Done_i <=1;
      cnt_en <=1;  //--AY
      DIS <=1; //    --1226
      if (start)
        NxST <= S_Start;
      else
        NxST <= Init;
    end 
    S_WE:begin
      CE_n <=0;
      WE_n <=0;
      DOS <=1;
      NxST <= WaitW;
    end
    WaitW:begin
      ecc_en<=1'b1;
      CE_n <=0;
      WE_n <= 0;
      DOS <= 1;
      NxST <= WaitW1;
    end
    WaitW1:begin
      CE_n <=0;
      WE_n <=0;
      DOS <=1;
      NxST <= S_nWE;
    end
    S_nWE:begin
      CE_n <=0;
      DOS <= 1;
      if (TC ==0)
        NxST <= WaitW2;
      else
        NxST <= FinishW;
    end 
    WaitW2:begin
      CE_n <= 0;
      DOS <= 1;    
      cnt_en <= 1;
      NxST <= S_WE;
    end
    FinishW:begin
      Done_i <= 1;
      cnt_en <= 1;//  --AY
      DOS <= 1; //    --AY driving data for ECC
      if (start)
        NxST <= S_Start;
      else
        NxST <= Init;
    end 
    default:
       NxST <= Init;
  endcase
 end


endmodule

