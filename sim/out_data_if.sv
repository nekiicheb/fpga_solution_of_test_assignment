`ifndef OUT_DATA_INTERFACE
`define OUT_DATA_INTERFACE

`include "globals.vh"

interface out_data_if(input bit clk);
  logic [1:0][`DATA_W-1:0] data_o;	 	
  logic 					 				 vd_o;
	logic      				 [1:0] eop_o;

endinterface

`endif 
