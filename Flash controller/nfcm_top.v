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
//   Ver  :| Author  :| Mod. Date :| Changes Made:
//   V01.0:| A.Y     :| 09/30/06  :| Initial ver
//   v01.1:| J.T    :| 06/21/09  :| just use one buffer and change ecc generator
// --------------------------------------------------------------------
//
// 
//Description of module:
//--------------------------------------------------------------------------------
//  This block is the top level Verilog module for this
//  reference Design.  It instantiates the following modules:
//    - MFSM.v
//    - TFSM.v
//    - ACounter.v
//    - H_gen.v
//    - ErrLoc.v
//    - ebr_buffer.v
// --------------------------------------------------------------------
`timescale 1 ns / 1 fs
module nfcm_top(
//-- Flash mem i/f (Samsung 128Mx8)  
  DIO,
  CLE ,
  ALE ,
  WE_n,
  RE_n,
  CE_n,
  R_nB,
//-- system
  CLK,
  RES,
//-- Host I/F
  BF_sel ,
  BF_ad  ,
  BF_din ,
  BF_dou ,
  BF_we  ,
  RWA    ,
//  ADS    ,
//-- Status
  PErr,
  EErr,
  RErr,
//-- control & handshake
  nfc_cmd ,
  nfc_strt,
  nfc_done
);
//-- Flash mem i/f (Samsung 128Mx8)  
 inout [7:0] DIO;
 output reg CLE;// -- CLE
 output reg ALE;//  -- ALE
 output reg WE_n;// -- ~WE
 output reg RE_n; //-- ~RE
 output reg CE_n; //-- ~CE
 input R_nB; //-- R/~B
//-- system
 input CLK ;
 input RES ;
//-- Host I/F 
 input BF_sel;
 input [10:0] BF_ad;
 input [7:0] BF_din;
 input BF_we;
 input [15:0] RWA; //-- row addr
// output ADS;  //-- addr strobe
 output [7:0] BF_dou;
//-- Status
 output reg PErr ; // -- progr err
 output reg EErr ; // -- erase err
 output reg RErr ;

//-- control & handshake
 input [2:0] nfc_cmd; // -- command see below
 input nfc_strt;//  -- pos edge (pulse) to start
 output reg nfc_done;//  -- operation finished if '1'

//-- NFC commands (all remaining encodings are ignored = NOP):
//-- WPA 001=write page
//-- RPA 010=read page
//-- EBL 100=erase block
//-- RET 011=reset
//-- RID 101= read ID


parameter HI= 1'b1;
parameter LO= 1'b0;

reg ires, res_t;
//
wire [7:0] FlashDataIn;
reg [7:0] FlashCmd;
reg [7:0] FlashDataOu;
wire [1:0] adc_sel;
wire [7:0] QA_1,QB_1;
wire [7:0] BF_data2flash, ECC_data;
wire Flash_BF_sel, Flash_BF_we, DIS, F_we;

//-- ColAd, RowAd
wire rar_we;
reg [7:0] addr_data;
reg [7:0] rad_1;
reg [7:0] rad_2;

wire [7:0] cad_1;
wire [7:0] cad_2;
wire [1:0] amx_sel;
//-- counter ctrls
wire CntEn, tc3, tc2048, cnt_res, acnt_res;
wire [11:0] CntOut;
//--TFSM
reg DOS;  //-- data out strobe
wire t_start, t_done;
wire [2:0] t_cmd;
//-- ECC byte sel
//wire ByteCntRes, ByteSelCntEn;
//wire [1:0] eccByteSel, eccWrSectSel;
//-- wait counter
wire WCountRes, WCountCE;
reg TC4, TC8;  //-- term counts
//reg [3:0] WCountOut;
//--
wire cmd_we ;
wire [7:0] cmd_reg;
//reg [1:0] TBF_i, RBF_i;
//reg [1:0] setRBF, resTBF;
wire SetPrErr, SetErErr,SetRrErr;
//--
wire WrECC, WrECC_e, enEcc, Ecc_en,ecc_en_tfsm;
wire setDone, set835;

//-- internal sigs before the out registers
wire ALE_i, CLE_i, WE_ni, CE_ni, RE_ni;
wire DOS_i;
reg [7:0] FlashDataOu_i ; 


assign BF_dou =  QA_1;
assign BF_data2flash = QB_1;                                                     
assign cad_1 = CntOut[7:0];
assign cad_2 = {4'b0000,CntOut[11:8]};

assign acnt_res = (ires | cnt_res);
assign WrECC_e = WrECC & DIS;
assign Flash_BF_we = DIS & F_we;

assign Ecc_en = enEcc & ecc_en_tfsm;


ebr_buffer buff( 
          .DataInA(BF_din),
          .QA(QA_1),
          .AddressA(BF_ad),
          .ClockA(CLK),
          .ClockEnA(BF_sel),
          .WrA(BF_we),
          .ResetA(LO),
          .DataInB(FlashDataIn),
          .QB(QB_1),
          .AddressB(CntOut[10:0]),
          .ClockB(CLK),
          .ClockEnB(Flash_BF_sel),
          .WrB(Flash_BF_we),
          .ResetB(LO)
);

ACounter addr_counter (
          .clk(CLK),
          .Res(acnt_res),
          .Set835(set835),
          .CntEn(CntEn),
          .CntOut(CntOut),
          .TC2048(tc2048),
          .TC3(tc3)
);
          
TFSM tim_fsm(
          .CLE(CLE_i),
          .ALE (ALE_i),
          .WE_n(WE_ni),
          .RE_n(RE_ni),
          .CE_n(CE_ni),
          .DOS (DOS_i),
          .DIS (DIS),
          .cnt_en(CntEn),
          .TC3(tc3),
          .TC2048(tc2048),
          .CLK(CLK),
          .RES(ires),
          .start(t_start),
          .cmd_code(t_cmd),
          .ecc_en(ecc_en_tfsm),
          .Done(t_done)
);
          
MFSM main_fsm
(
  .CLK ( CLK ),
  .RES ( ires ),
  .start ( nfc_strt),
  .command(nfc_cmd),
  .setDone(setDone),
  .R_nB (R_nB),
  .BF_sel( BF_sel),
//  .TBF ( TBF_i),
//  .RBF ( RBF_i),
//  .ResTBF ( Wr_done), 
//  .SetRBF ( Rd_done),
  .mBF_sel ( Flash_BF_sel),
  .BF_we( F_we),
  .io_0( FlashDataIn[0]),
  .t_start ( t_start),
  .t_cmd  ( t_cmd),
  .t_done ( t_done),
  .WrECC ( WrECC),
  .EnEcc ( enEcc),
//  .ecc2flash ( ecc2flash),
//  .byteSelCntEn ( ByteSelCntEn),
//  .byteSelCntRes( ByteCntRes), 
  .AMX_sel ( amx_sel),
  .cmd_reg ( cmd_reg),
  .cmd_reg_we( cmd_we),
  .RAR_we ( rar_we),
//  .ADS (ads),
  .set835 ( set835),
  .cnt_res ( cnt_res),
  .tc8  ( TC8), 
  .tc4  ( TC4),
  .wCntRes( WCountRes), 
  .wCntCE ( WCountCE),
  .SetPrErr  ( SetPrErr), 
  .SetErErr  (  SetErErr),
//  .SetBFerr ( setBFerr),
  .ADC_sel ( adc_sel)
);
  
H_gen ecc_gen(
     . clk( CLK),
     . Res( acnt_res),
     . Din( BF_data2flash[3:0]),
     . EN (Ecc_en),
      
     . eccByte ( ECC_data)
);
      
ErrLoc ecc_err_loc 
 (
      .clk( CLK),
      .Res (acnt_res),
      .F_ecc_data (FlashDataIn[6:0]),
      .WrECC (WrECC_e),
            
      .ECC_status (SetRrErr)      
);        

always@(posedge CLK)
begin
  res_t <= RES;
  ires <= res_t;
end

always@(posedge CLK)
  if (rar_we) begin
    rad_1=RWA[7:0];
    rad_2=RWA[15:8];
  end

always@(posedge CLK)
begin
  FlashDataOu <= FlashDataOu_i;
  DOS <= DOS_i;
  ALE <= ALE_i;
  CLE <= CLE_i;
  WE_n <= WE_ni;
  CE_n <= CE_ni;
  RE_n <= RE_ni;
end

  
always@(cad_1 or cad_2 or rad_1 or rad_2 or amx_sel)
 begin
  case (amx_sel)
     2'b11 : addr_data <= rad_2;
     2'b10 : addr_data <= rad_1;
     2'b01 : addr_data <= cad_2;
     default: addr_data <= cad_1;
  endcase
 end

always@(adc_sel or BF_data2flash or FlashCmd or addr_data or ECC_data)
begin
case (adc_sel)
   2'b11 : FlashDataOu_i <= FlashCmd;
   2'b10 : FlashDataOu_i <= addr_data;
   2'b01 : FlashDataOu_i <= ECC_data;
   default: FlashDataOu_i <= BF_data2flash;
endcase
end

reg [3:0] WC_tmp;
always@(posedge CLK)
begin
  if ((ires ==1'b1) | (WCountRes ==1'b1))
    WC_tmp<= 4'b0000;
  else if (WCountCE ==1'b1)
    WC_tmp<= WC_tmp + 1;

  
  if (WC_tmp ==4'b0100) begin
    TC4 <= 1'b1; 
    TC8 <= 1'b0;
  end else if (WC_tmp ==4'b1000) begin
    TC8<= 1'b1; 
    TC4 <=1'b0;
  end else begin
    TC4 <=1'b0;
    TC8 <=1'b0;
  end
//  WCountOut <= WC_tmp;
end


always@(posedge CLK)
begin
  if (ires)
    FlashCmd <=8'b00000000;
  else if (cmd_we)
    FlashCmd <= cmd_reg;
end

always@(posedge CLK)
begin
  if (ires)
    nfc_done <= 1'b0;
  else if (setDone) 
    nfc_done <=1'b1;
  else if (nfc_strt) 
    nfc_done <=1'b0;
 
end


always@(posedge CLK)
begin
  if (ires)
    PErr <=1'b0;
  else if (SetPrErr)
    PErr <= 1'b1;
  else if (nfc_strt)
    PErr <= 1'b0;
end

always@(posedge CLK)
begin
  if (ires)
    EErr <=1'b0;
  else if (SetErErr)
    EErr <=1'b1;
  else if (nfc_strt)
    EErr <= 1'b0;
end

always@(posedge CLK)
begin
  if (ires)
    RErr <=1'b0;
  else if (SetRrErr)
    RErr <= 1'b1;
  else if (nfc_strt)
    RErr <= 1'b0;
end


assign FlashDataIn = DIO;
assign DIO =(DOS == 1'b1)?FlashDataOu:8'hzz;


endmodule
