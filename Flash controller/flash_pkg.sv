/************************************************************************************************************************************************
*																		*
* 							  FLASH MEMORY CONTROLLER PACKAGE							*															*
*																		*
************************************************************************************************************************************************/

package flash_pkg;
	typedef enum bit [2:0] {program_page  	= 3'b001,
				read_page  	= 3'b010,
				erase  		= 3'b100,
				reset  		= 3'b011,
				read_id  	= 3'b101
				} operations;

operations op, exp_op, scr_op;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter SIGNAL_WIDTH=4;
parameter SB_DEPTH=24;
parameter LUT=3;

parameter DEBUG = TRUE;

endpackage : flash_pkg
