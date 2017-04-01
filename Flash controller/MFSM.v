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
//This module interprets commands from the Host, passes control to TFSM to execute 
//repeating regular tasks with strict timing requirements.
// --------------------------------------------------------------------
`timescale 1 ns / 1 fs
module MFSM(
  CLK,
  RES,
  start,
  command,
  setDone,
  R_nB,
  BF_sel,
//  TBF,
//  RBF,//  -- tx & rx buffer rd flags
//  ResTBF,
//  SetRBF,
  mBF_sel,
  BF_we,
  io_0,
  t_start,
  t_cmd,
  t_done,
  WrECC,
  EnEcc,
//  ecc2flash,
//  byteSelCntEn,
//  byteSelCntRes,
  AMX_sel,
  cmd_reg,
  cmd_reg_we,
  RAR_we,
//  ADS,
  set835,
  cnt_res,
  tc8,
  tc4,// -- term counts fm Wait counter
  wCntRes,
  wCntCE,//  -- wait conter ctrl
  SetPrErr,
  SetErErr,
//  SetBFerr,
  ADC_sel// -- ad/dat/cmd mux ctrl
)/*synthesis ugroup="mfsm_group" */;  
 input CLK;
 input RES;    
 input start;
 input [2:0] command;  
 input R_nB;         
 input BF_sel;       
// input TBF;          
// input RBF;//  -- tx 
 input io_0; 
 input t_done; 
 input tc8;          
 input tc4;// -- term
   
 output reg setDone;
// output reg ResTBF;       
// output reg SetRBF;
 output mBF_sel;
 output reg BF_we;       
 output reg t_start;      
 output reg [2:0] t_cmd;
 output reg WrECC;
 output reg EnEcc;
// output reg ecc2flash; 
// output reg byteSelCntEn;
// output reg byteSelCntRes;
 output reg [1:0] AMX_sel;      
 output reg [7:0] cmd_reg;      
 output reg cmd_reg_we; 
 output reg RAR_we;
// output reg ADS;       
 output reg set835;       
 output reg cnt_res;      
 output reg wCntRes;      
 output reg wCntCE;//  -- 
 output reg SetPrErr;     
 output reg SetErErr;     
// output reg SetBFerr;
 output reg [1:0] ADC_sel;// -- a
 
 parameter Init=0,S_ADS=1, S_RAR=2, 
S_CmdL0=3,S_CmdL1=4,S_adL0=5,S_adL1=6, S_CmdL2=7, S_CmdL3=8,//-- EBL
S_WC0=9, S_WC1=10, S_wait=11, S_CmdL4=12, S_CmdL5=13, S_WC3=14, S_WC4=15, S_DR1=16, S_Done=17,
Sr_RAR=18, Sr_DnErr=19, Sr_CmdL0=20, Sr_CmdL1=21, Sr_AdL0=22, Sr_AdL1=23, Sr_AdL2=24,// -- RPA
Sr_AdL3=25, Sr_CmdL2=26, Sr_CmdL3=27, Sr_WC0=28, Sr_WC1=29, Sr_wait=30, Sr_RPA0=31,
Sr_CmdL4=32, Sr_CmdL5=33, Sr_AdL4=34, Sr_AdL5=35, Sr_CmdL6=36, Sr_CmdL7=37, Sr_WC2=38,Sr_RPA1=39,
Sr_wait1=40, Sr_wait2=41, Sr_WC3=42, Sr_Done=43,
Sw_RAR=44, Sw_CmdL0=45, Sw_CmdL1=46, Sw_AdL0=47, Sw_AdL1=48, Sw_AdL2=49, Sw_AdL3=50,Sw_WPA0=51,// -- WPA
Sw_CmdL2=52, Sw_CmdL3=53,  Sw_AdL4=54, Sw_AdL5=55, Sw_WPA1=56, 
Swait3=57, Sw_CmdL4=58, Sw_CmdL5=59, Sw_WC1=60, Sw_WC2=61, Sw_CmdL6=62,
Sw_CmdL7=63, Sw_DR1=64, Sw_Wait4=65, Sw_Wait5=66, Sw_done=67,
Srst_RAR=68, Srst_CmdL0=69, Srst_CmdL1=70,Srst_done=71,
Srid_RAR=72, Srid_CmdL0=73, Srid_CmdL1=74, Srid_AdL0=75,
Srid_Wait=76, Srid_DR1=78, Srid_DR2=79, Srid_DR3=80, Srid_DR4=81, Srid_done=82;


reg [7:0] NxST,CrST;
reg BF_sel_int;

parameter C0=4'b0000,
          C1=4'b0001,
          C3=4'b0011,
          C5=4'b0101,
          C6=4'b0110,
          C7=4'b0111,
          C8=4'b1000,
          CD=4'b1101,
          CE=4'b1110,
          CF=4'b1111,
          C9=4'b1001;
          
assign mBF_sel=BF_sel_int;// buff clock enable

always@(posedge CLK)
 if(start)
  BF_sel_int<=BF_sel;  
  
always@(posedge CLK)
 CrST<=NxST;
 
//always@(RES or command or start or R_nB or TBF or RBF or t_done or tc4 or tc8 or io_0 or CrST)
always@(RES or command or start or R_nB or t_done or tc4 or tc8 or io_0 or CrST)
 if(RES) begin
  NxST <= Init;
  setDone <= 0;
//  ResTBF <= 1;
//  SetRBF <= 0;
  BF_we <= 0;
  t_start <= 0;
  t_cmd <= 3'b011; // nop
  WrECC <= 0;
  EnEcc <= 0;
//  ecc2flash <= 0;
//  byteSelCntEn <= 0;
//  byteSelCntRes <= 1;  
  AMX_sel <= 2'b00;
  cmd_reg <= 8'b00000000;
  cmd_reg_we <= 0;
//  ADS <= 0;
  set835 <= 0;
  cnt_res <= 0;
  wCntRes <= 0;
  wCntCE <= 0;
  ADC_sel <=2'b11;  // cmd to out
  SetPrErr <= 0;
  SetErErr <= 0;
//  SetBFerr <= 0;
  RAR_we <= 0;
  
end else begin           // default values
    setDone <= 0;
//    ResTBF <= 0;
//    SetRBF <= 0;
    BF_we <= 0;
    t_start <=0;
    t_cmd <= 3'b011; // nop
    WrECC <= 0;
    EnEcc <= 0;
//    ecc2flash <= 0;
//    byteSelCntEn <= 0;
//    byteSelCntRes <= 0;  
    AMX_sel <= 2'b00;
    cmd_reg <= 8'b00000000;
    cmd_reg_we <= 0;
//    ADS <= 0;
    set835 <= 0;
    cnt_res <= 0;
    wCntRes <= 0;
    wCntCE <= 0;
    ADC_sel <= 2'b11;
    SetPrErr <= 0;
    SetErErr <= 0;
//    SetBFerr <= 0;
    RAR_we <= 0; 

  case(CrST)
    Init:begin
      if (start)
        NxST <=S_ADS;
      else
        NxST <=Init;
    end
    S_ADS:begin
//      ADS <= 1;
      cnt_res <= 1;
      if (command ==3'b100) //EBL
        NxST <= S_RAR;
      else if (command==3'b010) //RPA
        NxST <= Sr_RAR;
      else if (command==3'b001) //WPA
        NxST <= Sw_RAR;
      else if (command==3'b011)
        NxST <= Srst_RAR; 
      else if (command==3'b101)
        NxST <= Srid_RAR;   
      else begin
        setDone <= 1;       // nop
        NxST <= Init;
        SetPrErr <=1;
        SetErErr <= 1;
      end
    end
    S_RAR:begin //          --EBL
      RAR_we <= 1;//--strobe the row address from the host
      NxST <= S_CmdL0;
    end
    S_CmdL0:begin
      cmd_reg <= {C6,C0};
      cmd_reg_we <= 1;
      NxST <= S_CmdL1;
    end
    S_CmdL1:begin
      t_start <= 1;
      t_cmd <= 3'b000; //-- cmd_latch
      if (t_done == 1)
        NxST <= S_adL0;
      else
        NxST <= S_CmdL1;
    end
    S_adL0:begin
      t_start <= 1;
      t_cmd <= 3'b001;// -- ad_latch
      ADC_sel <= 2'b10;// -- addr to out
      AMX_sel <= 2'b10;// -- ra1
      if (t_done == 1)
        NxST <= S_adL1;
      else
        NxST <= S_adL0;
    end
    S_adL1:begin
      t_start <=1;
      t_cmd <= 3'b001;// -- ad_latch
      ADC_sel <=2'b10;// -- addr to out      
      AMX_sel <=2'b11;// -- ra2
      if (t_done ==1)
        NxST <= S_CmdL2;
      else
        NxST <= S_adL1;
    end 
    S_CmdL2:begin
      cmd_reg <= {CD,C0};
      cmd_reg_we <= 1;
      NxST <= S_CmdL3;
    end
    S_CmdL3:begin
      t_start <= 1;
      t_cmd <=3'b000;// -- cmd_latch
      if (t_done ==1) 
        NxST <= S_WC0;
      else
        NxST <= S_CmdL3;
    end
    S_WC0:begin
      wCntRes <=1;
      NxST <= S_WC1;
    end
    S_WC1:begin
      wCntCE <=1;
      if (tc8 == 1)
        NxST <= S_wait;
      else
        NxST <= S_WC1;
    end
    S_wait:begin
      if (R_nB ==1)
        NxST <= S_CmdL4;
      else
        NxST <= S_wait;
    end 
    S_CmdL4:begin
      cmd_reg <= {C7,C0};
      cmd_reg_we <= 1;
      NxST <= S_CmdL5;
    end
    S_CmdL5:begin
      t_start <= 1;
      t_cmd <= 3'b000;// -- cmd_latch
      if (t_done ==1)
        NxST <= S_WC3;
      else
        NxST <= S_CmdL5;
    end
    S_WC3:begin
      wCntRes <= 1;
      NxST <= S_WC4;
    end
    S_WC4:begin
      wCntCE <=1;
      if (tc4 ==1)
        NxST <= S_DR1;
      else
        NxST <= S_WC4;
    end 
    S_DR1:begin
      t_start <= 1;
      t_cmd <= 3'b010;// -- data read 1 (status)
      if (t_done ==1)
        NxST <= S_Done;
      else
        NxST <= S_DR1;      
    end 
    S_Done:begin
      setDone <=1;
      NxST <= Init;
      if (io_0 == 1)
        SetErErr <= 1;
      else
        SetErErr <= 0;
    end    
    Sr_RAR:begin
      RAR_we <= 1;
  //    if (RBF==0)
        NxST <= Sr_CmdL0;
  //    else begin
  //      NxST <= Init;
  //      SetBFerr <=1;
  //      setDone <=1;
  //    end 
    end
    Sr_CmdL0:begin
      cmd_reg <= {C0,C0};		
      cmd_reg_we <= 1;
      NxST <= Sr_CmdL1;
    end
    Sr_CmdL1:begin
      t_start <= 1;
      t_cmd <= 3'b000;// -- cmd_latch
      if (t_done ==1)
        NxST <= Sr_AdL0;
      else
        NxST <= Sr_CmdL1;
    end 
    Sr_AdL0:begin
      t_start <= 1;
      t_cmd <= 3'b001;// -- ad_latch
      ADC_sel <= 2'b10; //-- addr to out      
      AMX_sel <= 2'b00;// -- ca1
      if (t_done ==1)
        NxST <= Sr_AdL1;
      else
        NxST <= Sr_AdL0;
    end 
    Sr_AdL1:begin
      t_start <= 1;
      t_cmd <= 3'b001;// -- ad_latch
      ADC_sel <= 2'b10; //-- addr to out      
      AMX_sel <= 2'b01;// -- ca2
      if (t_done==1)
        NxST <= Sr_AdL2;
      else
        NxST <= Sr_AdL1;
    end
    Sr_AdL2:begin
      t_start <= 1;
      t_cmd <= 3'b001;// -- ad_latch
      ADC_sel <= 2'b10; //-- addr to out      
      AMX_sel <= 2'b10;// -- ra1
      if (t_done ==1)
        NxST <= Sr_AdL3;
      else
        NxST <= Sr_AdL2;
    end 
    Sr_AdL3:begin
      t_start <= 1;
      t_cmd <= 3'b001;// -- ad_latch
      ADC_sel <= 2'b10;// -- addr to out      
      AMX_sel <= 2'b11;// -- ra2
      if (t_done ==1)
        NxST <= Sr_CmdL2;
      else
        NxST <= Sr_AdL3;
    end
    Sr_CmdL2:begin
      cmd_reg <= {C3,C0};
      cmd_reg_we <= 1;
      NxST <= Sr_CmdL3;
    end
    Sr_CmdL3:begin
      t_start <= 1;
      t_cmd <= 3'b000;// -- cmd_latch
      if (t_done ==1)
        NxST <= Sr_WC0;
      else
        NxST <= Sr_CmdL3;
    end
    Sr_WC0:begin
      wCntRes <=1;
      NxST <= Sr_WC1;
    end
    Sr_WC1:begin
      wCntCE <= 1;
      if (tc8 ==1)
        NxST <= Sr_wait;
      else
        NxST <= Sr_WC1;
    end 
    Sr_wait:begin
      if (R_nB==0)
        NxST <= Sr_wait;
      else
        NxST <= Sr_RPA0;
    end 
    Sr_RPA0:begin
      t_start <= 1;
      t_cmd <= 3'b101; // data read w tc2048
      BF_we <= 1;
//      wCntCE <=1;    //wait no tRR
//      EnEcc <= 1;  //-- ecc ctrl
      if (t_done==1)begin
        NxST <= Sr_CmdL4;
        t_cmd <= 3'b000;
      end else
        NxST <= Sr_RPA0;
    end       
    Sr_CmdL4:begin
      cmd_reg <= {C0,C5};
      cmd_reg_we <= 1;
      set835 <= 1;
      t_cmd <= 3'b000;
      NxST <= Sr_CmdL5;
    end
    Sr_CmdL5:begin
      t_start <= 1;
      t_cmd <=3'b000; //-- cmd_latch
      if (t_done) 
        NxST <= Sr_AdL4;
      else
        NxST <= Sr_CmdL5;
    end
    Sr_AdL4:begin
      t_start <= 1;
      t_cmd <= 3'b001; //-- ad_latch
      ADC_sel <= 2'b10;// -- addr to out      
      AMX_sel <= 2'b00; //-- ca1
      if (t_done)
        NxST <= Sr_AdL5;
      else
        NxST <= Sr_AdL4;
    end 
    Sr_AdL5:begin
      t_start <= 1;
      t_cmd <= 3'b001;// -- ad_latch
      ADC_sel <=2'b10; //-- addr to out      
      AMX_sel <=2'b01; //-- ca2
      if (t_done)
        NxST <= Sr_CmdL6;
      else
        NxST <= Sr_AdL5;
    end     
    Sr_CmdL6:begin
      cmd_reg <= {CE,C0};
      cmd_reg_we <= 1;
      NxST <= Sr_CmdL7;
    end
    Sr_CmdL7:begin
      t_start <= 1;
      t_cmd <= 3'b000;// -- cmd_latch
      wCntRes <= 1; //-- sector sel count
//      byteSelCntRes <= 1;
      if (t_done)
        NxST <= Sr_RPA1;
      else
        NxST <= Sr_CmdL7;
    end 
    Sr_RPA1:begin
      t_start <= 1;
      t_cmd <=3'b100; //-- data read w tc3 (12 times - 835-840)
//      byteSelCntEn <= 1;
      WrECC <=1;
//      EnEcc <= 1;  //-- ecc ctrl
      if (t_done) begin 
        NxST <= Sr_wait1;
        t_cmd <= 3'b011;
      end else
        NxST <= Sr_RPA1;
   end 
    Sr_wait1:begin
      WrECC <=1;    
      NxST <= Sr_wait2;
    end
    Sr_wait2:begin
      WrECC <= 1;
      NxST <= Sr_WC3;
    end
    Sr_WC3:begin
      WrECC <=1;
      wCntCE <=1;
//      byteSelCntRes <=1;
      if (tc4 ==0)
        NxST <= Sr_WC3;
      else
        NxST <= Sr_Done;
    end 
    Sr_Done:begin
      setDone <=1;
//      SetRBF<=1;
      NxST <= Init;
    end
    Sw_RAR:begin      //-- WPA
      RAR_we <=1; //--strobe the row address from the host
   //   if (TBF==1)
        NxST <= Sw_CmdL0;
  //    else begin
  //      NxST <= Init;
  //      SetBFerr <=1;
  //      setDone <= 1;
  //    end
    end     
    Sw_CmdL0:begin
      cmd_reg <= {C5,C0};//--h80 to flash data out		//-------------------->chaged here c8,c0
      cmd_reg_we <= 1;
      NxST <= Sw_CmdL1;
    end
    Sw_CmdL1:begin
      t_start <=1;
      t_cmd <=3'b000;// -- cmd_latch
      if (t_done ==1)
        NxST <= Sw_AdL0;
      else
        NxST <= Sw_CmdL1;
    end       
    Sw_AdL0:begin
      t_start <= 1;
      t_cmd <= 3'b001;// -- ad_latch
      ADC_sel <= 2'b10; //-- addr to out      
      AMX_sel <= 2'b00;// -- ca1
      if (t_done ==1)
        NxST <= Sw_AdL1;
      else
        NxST <= Sw_AdL0;
    end
    Sw_AdL1:begin
      t_start <=1;
      t_cmd <=3'b001; //-- ad_latch
      ADC_sel <= 2'b10;// -- addr to out      
      AMX_sel <= 2'b01;// -- ca2
      if (t_done ==1)
        NxST <= Sw_AdL2;
      else
        NxST <= Sw_AdL1;
    end 
    Sw_AdL2:begin
      t_start <=1;
      t_cmd <= 3'b001;// -- ad_latch
      ADC_sel <= 2'b10; //-- addr to out      
      AMX_sel <= 2'b10;// -- ra1
      if (t_done ==1)
        NxST <= Sw_AdL3;
      else
        NxST <= Sw_AdL2;
    end
    Sw_AdL3:begin
      t_start<=1;
      t_cmd <= 3'b001;// -- ad_latch
      ADC_sel <= 2'b10; //- addr to out      
      AMX_sel <= 2'b11;// -- ra2
      if (t_done ==1)
        NxST <= Sw_WPA0;
      else
        NxST <= Sw_AdL3;
    end 
    Sw_WPA0:begin
      t_start <=1;
      t_cmd <= 3'b111;// -- data write w tc2048
//      wCntCE <= 1;
      ADC_sel <=2'b00;
//      EnEcc <=1;
      if (t_done==1) begin
        NxST <= Sw_CmdL2;
        t_cmd <=3'b000;
      end else
        NxST <= Sw_WPA0;
    end
    Sw_CmdL2:begin
      cmd_reg <= {C8,C5};
      cmd_reg_we <= 1;
      set835 <= 1;
      t_cmd <= 3'b000;
      NxST <= Sw_CmdL3;
    end
    Sw_CmdL3:begin
      t_start <= 1;
      t_cmd <= 3'b000; //-- cmd_latch
      if (t_done)
        NxST <= Sw_AdL4;
      else
        NxST <= Sw_CmdL3;
    end
    Sw_AdL4:begin
      t_start <= 1;
      t_cmd <= 3'b001; //-- ad_latch
      ADC_sel <= 2'b10; //-- addr to out      
      AMX_sel <= 2'b00;// -- ca1
      if (t_done)
        NxST <= Sw_AdL5;
      else
        NxST <= Sw_AdL4;
    end 
    Sw_AdL5:begin
      t_start <= 1;
      t_cmd <= 3'b001; //-- ad_latch
      ADC_sel <= 2'b10; //-- addr to out      
      AMX_sel <= 2'b01;// -- ca2
//      byteSelCntRes <= 1;      
      if (t_done)
        NxST <= Sw_WPA1;
      else
        NxST <= Sw_AdL5;
    end       
    Sw_WPA1:begin
      t_start <= 1;
      t_cmd <= 3'b110; //  -- data write w tc3
//      byteSelCntEn <= 1;
      ADC_sel <= 2'b01;//  -- ecc data to out
//      ecc2flash <= 1;
      EnEcc <= 1;  //-- ecc ctrl
      if (t_done) begin
        NxST <= Sw_CmdL4;
        t_cmd <= 3'b000;
      end else
        NxST <= Sw_WPA1;
    end 
    Sw_CmdL4:begin
      cmd_reg <= {C1,C0};
      t_cmd <= 3'b000;
      cmd_reg_we <= 1;
      NxST <= Sw_CmdL5;
    end
    Sw_CmdL5:begin
      t_start <= 1;
      t_cmd <= 3'b000; //-- cmd_latch
      if (t_done ==1)
        NxST <= Sw_WC1;
      else
        NxST <= Sw_CmdL5;
    end
    Sw_WC1:begin
      wCntRes <=1;
      NxST <= Sw_WC2;
    end
    Sw_WC2:begin
      wCntCE <=1;
      if (tc8 ==1)
        NxST <= Swait3;
      else
        NxST <= Sw_WC2;
    end
    Swait3:begin
      if (R_nB ==1)
        NxST <= Sw_CmdL6;
      else
        NxST <= Swait3;
    end
    Sw_CmdL6:begin
      cmd_reg <= {C7,C0};
      cmd_reg_we <= 1;
      NxST <= Sw_CmdL7;
    end
    Sw_CmdL7:begin
      t_start <=1;
      t_cmd <= 3'b000; //-- cmd_latch
      if (t_done ==1)
        NxST <= Sw_Wait4;
      else
        NxST <= Sw_CmdL7;
    end 
    Sw_Wait4:begin
      NxST <= Sw_Wait5;
    end
    Sw_Wait5:begin
      NxST <= Sw_DR1;
    end
    Sw_DR1:begin
      t_start <=1;
      t_cmd <= 3'b010;// -- read status
      if (t_done ==1)
        NxST <= Sw_done;
      else
        NxST <= Sw_DR1;
    end       
    Sw_done:begin
      setDone <= 1;
      NxST <= Init;
      if (io_0 ==1)
        SetPrErr <=1;
      else begin
        SetPrErr <= 0;
 //       ResTBF<= 1;
      end
    end 
    Srst_RAR:begin               
        NxST <= Srst_CmdL0;
    end     
    Srst_CmdL0:begin
      cmd_reg <= {CF,CF};//--hff to flash data out
      cmd_reg_we <= 1;
      NxST <= Srst_CmdL1;
    end
    Srst_CmdL1:begin
      t_start <=1;
      t_cmd <=3'b000;// -- cmd_latch
      if (t_done ==1)
        NxST <= Srst_done;
      else
        NxST <= Srst_CmdL1;
    end 
    Srst_done:begin
      setDone <= 1;
      NxST <= Init;
    end
    Srid_RAR:begin     
      RAR_we <=1; //--strobe the row address from the host
   //   if (TBF==1)
        NxST <= Srid_CmdL0;
  //    else begin
  //      NxST <= Init;
  //      SetBFerr <=1;
  //      setDone <= 1;
  //    end
    end     
    Srid_CmdL0:begin
      cmd_reg <= {C9,C0};//--h90 to flash data out
      cmd_reg_we <= 1;
      NxST <= Srid_CmdL1;
    end
    Srid_CmdL1:begin
      t_start <=1;
      t_cmd <=3'b000;// -- cmd_latch
      if (t_done ==1)
        NxST <= Srid_AdL0;
      else
        NxST <= Srid_CmdL1;
    end       
    Srid_AdL0:begin
      t_start <= 1;
      t_cmd <= 3'b001;// -- ad_latch
      ADC_sel <= 2'b10; //-- addr to out      
      AMX_sel <= 2'b10;// -- ra1
      if (t_done ==1)
        NxST <= Srid_Wait;
      else
        NxST <= Srid_AdL0;
    end
    Srid_Wait:begin
      wCntRes <=1;
      NxST <= Srid_DR1;
    end
    Srid_DR1:begin
      t_start <=1;
      t_cmd <= 3'b010;// -- read id
      BF_we <= 1;
      if (t_done ==1)
        NxST <= Srid_DR2;
      else
        NxST <= Srid_DR1;
    end   
    Srid_DR2:begin
      t_start <=1;
      t_cmd <= 3'b010;// -- read id
      BF_we <= 1;
      if (t_done ==1)
        NxST <= Srid_DR3;
      else
        NxST <= Srid_DR2;
    end       
    Srid_DR3:begin
      t_start <=1;
      t_cmd <= 3'b010;// -- read id
      BF_we <= 1;
      if (t_done ==1)
        NxST <= Srid_DR4;
      else
        NxST <= Srid_DR3;
    end       
    Srid_DR4:begin
      t_start <=1;
      t_cmd <= 3'b010;// -- read id
      BF_we <= 1;
      if (t_done ==1)
        NxST <= Srid_done;
      else
        NxST <= Srid_DR4;
    end               
    Srid_done:begin
      setDone <= 1;
      NxST <= Init;
    end 
             
    default:begin
      NxST <= Init;
    end
  endcase
 end
endmodule    
