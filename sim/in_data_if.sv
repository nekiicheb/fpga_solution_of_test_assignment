`ifndef IN_DATA_INTERFACE
`define IN_DATA_INTERFACE

`include "globals.vh"

interface in_data_if(input bit clk);
  logic [1:0][`DATA_W-1:0] data_i;
	logic [1:0][`OPER_W-1:0] operand_i;			 	
  logic 					 				 rd_o;

endinterface

`endif 
