`ifndef GUARD_IN_DATA
`define GUARD_IN_DATA

`include "globals.vh"

class InData;

virtual in_data_if  in_data_intf;

int i;
//// constructor method ////
function new( virtual in_data_if in_data_intf_new );

  this.in_data_intf    = in_data_intf_new  ;
	
endfunction : new  

task rst();
  $display("%0t : INFO    : InData    : rst() method ",$time ); 
	@( posedge in_data_intf.clk );
  in_data_intf.data_i     <= '0;
  in_data_intf.operand_i  <= '0;	
 	@( posedge in_data_intf.clk ); 
endtask : rst

task setData( ref bit [1:0][`OPER_W-1:0] operand, ref bit [1:0][`DATA_W-1:0] data );
	$display("%0t : INFO    : InData    : setData() method ", $time );
	forever 
	begin
		#0;
		if( in_data_intf.rd_o )
		begin
			@( posedge in_data_intf.clk );
			$display("%0t : INFO    : InData    : setData set", $time );	
			in_data_intf.operand_i <= operand;
			in_data_intf.data_i    <=    data;
			disable setData;				
		end
		else 
		begin
			@( posedge in_data_intf.clk );
		end
	end
endtask : setData;	

endclass

`endif