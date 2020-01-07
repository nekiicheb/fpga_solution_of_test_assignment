`ifndef GUARD_TOP
`define GUARD_TOP

//`timescale 1 ns/ 100 ps
`include "globals.vh"

module tb_top();

/////////////////////////////////////////////////////
// Clock Declaration and Generation                //
/////////////////////////////////////////////////////

bit clk_i;
bit nrst_i;
bit run_i;

initial
  forever #5 clk_i = ~clk_i;

in_data_if 		in_data_intf(  clk_i );
out_data_if  	out_data_intf( clk_i );

/////////////////////////////////////////////////////
//  Program block Testcase instance                //
/////////////////////////////////////////////////////

testcase TC( nrst_i, run_i, in_data_intf, out_data_intf );

/////////////////////////////////////////////////////
//  DUT instance and signal connection             //
/////////////////////////////////////////////////////

rep_execute_block_top 
#( 
	.DATA_W 					( `DATA_W ),
	.OPER_W 			    ( `OPER_W )
	
) DUT
(
	.nReset			   ( nrst_i ),   
	.clk			     ( clk_i ),
	
	.zip_data_even		( { in_data_intf.operand_i[0][`OPER_W-1:0], in_data_intf.data_i[0][`DATA_W-1:0] } ),
	.zip_data_odd			( { in_data_intf.operand_i[1][`OPER_W-1:0], in_data_intf.data_i[1][`DATA_W-1:0] } ),
	.rd_req						( in_data_intf.rd_o ),

	.run	  					( run_i ),
	.data_out_even		( out_data_intf.data_o[0][`DATA_W-1:0] ),
	.data_out_odd	    ( out_data_intf.data_o[1][`DATA_W-1:0] ),
	.data_out_vd_o		( out_data_intf.vd_o )
);

endmodule

`endif
