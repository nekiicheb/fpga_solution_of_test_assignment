`ifndef GUARD_OUT_DATA
`define GUARD_OUT_DATA

`include "globals.vh"

class OutData;

virtual out_data_if  out_data_intf;

int i;
//// constructor method ////
function new( virtual out_data_if out_data_intf_new );

  this.out_data_intf    = out_data_intf_new  ;
	
endfunction : new  

task rst();
  $display("%0t : INFO    : OutData    : rst() method ",$time ); 
endtask : rst

task getData( ref bit [`DATA_W-1:0] data[$], int length, ref bit [`DATA_W-1:0] overFlowData );
	automatic int i = 0;
	$display("%0t : INFO    : OutData    : getData() method ", $time );
	forever 
	begin
		@( posedge out_data_intf.clk );
		#0;		
		if( out_data_intf.vd_o )
		begin
			data.push_back( out_data_intf.data_o[0][`DATA_W-1:0] );
			i++;
			if( i == length )
			begin
				overFlowData = out_data_intf.data_o[1][`DATA_W-1:0];
				$display("%0t : INFO    : OutData    : getData() end of packet ", $time );
				disable getData;					
			end
			else 
			begin
				data.push_back( out_data_intf.data_o[1][`DATA_W-1:0] );
				i++;
			end
			if( i == length )
			begin
				$display("%0t : INFO    : OutData    : getData() end of packet ", $time );
				disable getData;			
			end
		end	
	end
endtask : getData;	

endclass

`endif