/************************************************************************************************************************************************
*																		*
* 							  	TOP MODULE									*															*
*																		*
************************************************************************************************************************************************/

`include "testbench.sv"

import flash_pkg::*;

module top;

flash_bfm bfm();									

nfcm_top nfcm(
 	.DIO(bfm.DIO),
 	.CLE(bfm.CLE),
 	.ALE(bfm.ALE),
 	.WE_n(bfm.WE_n),
 	.RE_n(bfm.RE_n),
 	.CE_n(bfm.CE_n),
 	.R_nB(bfm.R_nB),
	
 	.CLK(bfm.clk),
 	.RES(bfm.rst),
 	.BF_sel(bfm.BF_sel),
 	.BF_ad (bfm.BF_ad ),
 	.BF_din(bfm.BF_din),
 	.BF_we (bfm.BF_we ),
 	.RWA   (bfm.RWA   ), 

 	.BF_dou(bfm.BF_dou),
 	.PErr(bfm.PErr), 
 	.EErr(bfm.EErr), 
 	.RErr(bfm.RErr),
      
 	.nfc_cmd (bfm.nfc_cmd ), 
 	.nfc_strt(bfm.nfc_strt),  
 	.nfc_done(bfm.nfc_done)
);
 
flash_interface nand_flash(
    .DIO(bfm.DIO),
    .CLE(bfm.CLE),	// -- CLE
    .ALE(bfm.ALE),	//  -- ALE
    .WE_n(bfm.WE_n),	// -- ~WE
    .RE_n(bfm.RE_n), 	//-- ~RE
    .CE_n(bfm.CE_n), 	//-- ~CE
    .R_nB(bfm.R_nB), 	//-- R/~B
    .rst(bfm.rst)
);

testbench testbench_h;

initial begin
	testbench_h = new(bfm);
	testbench_h.execute();
end

endmodule : top
