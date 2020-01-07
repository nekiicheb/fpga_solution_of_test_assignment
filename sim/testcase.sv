`ifndef GUARD_TESTCASE
`define GUARD_TESTCASE

`include "globals.vh"
`include "in_data_if.sv"
`include "in_data.sv"
`include "out_data_if.sv"
`include "out_data.sv"
			
program testcase(  ref bit nrst,
									 ref bit run,
									 in_data_if  in_data_intf, 
									 out_data_if out_data_intf ); 

InData      inData;
OutData			outData;

mailbox mailDv2Sb;
mailbox mailRv2Sb;
mailbox mailDv2Rv;

event startSb; 

task driverDirect( );
	automatic bit [`DATA_W-1:0] bufData[$];
	automatic bit [1:0][`OPER_W-1:0] operand;
	automatic bit [1:0][`DATA_W-1:0] data;	
	
	for( int i = 0; i < 17; i++ ) // дважды проверим операнд 0 0 
	begin
		for( int j = 0; j < 17; j++ )
		begin
			$display("%0t : INFO    : driver      : i = %0d, j = %0d ", $time, i, j );			
			operand[0][`OPER_W-1:0] = i;
			operand[1][`OPER_W-1:0] = j;
			data[0][`DATA_W-1:0]    = i;
			data[1][`DATA_W-1:0]    = 16-j; 
			inData.setData( operand, data );
			bufData = {}; // clear queue
			for( int k = 0; k <= operand[0][`OPER_W-1:0]; k++ )
			begin
				bufData.push_back( data[0][`DATA_W-1:0] );
			end
			for( int k = 0; k <= operand[1][`OPER_W-1:0]; k++ )
			begin
				bufData.push_back( data[1][`DATA_W-1:0] );
			end			
			mailDv2Sb.put( bufData );
			$display("%0t : INFO    : driver      : bufData size = %0d", $time, bufData.size() );		
			mailDv2Rv.put( bufData.size() );
		end
	end
	$display("%0t : INFO    : driver      : end ", $time );	
endtask : driverDirect

task driverRandom( int numPkt ); 
	automatic bit [`DATA_W-1:0] bufData[$];
	automatic bit [1:0][`OPER_W-1:0] operand;
	automatic bit [1:0][`DATA_W-1:0] data;
	
	for( int i = 0; i < numPkt; i++ )
	begin
		data[0][`DATA_W-1:0] = $random;
		data[1][`DATA_W-1:0] = $random;	
		operand[0][`OPER_W-1:0] =  $unsigned($random) %64;
		operand[1][`OPER_W-1:0] =  $unsigned($random) %64;		
		$display("%0t : INFO    : driver      : data[0] = %0h, operand[0] = %0d, data[1] = %0h, operand[1] = %0d ", $time, data[0], operand[0], data[1], operand[1] );	
	  inData.setData( operand, data );
		bufData = {}; // clear queue
		for( int k = 0; k <= operand[0][`OPER_W-1:0]; k++ )
		begin
			bufData.push_back( data[0][`DATA_W-1:0] );
		end
		for( int k = 0; k <= operand[1][`OPER_W-1:0]; k++ )
		begin
			bufData.push_back( data[1][`DATA_W-1:0] );
		end			
		mailDv2Sb.put( bufData );
		$display("%0t : INFO    : driver      : bufData size = %0d", $time, bufData.size() );		
		mailDv2Rv.put( bufData.size() );		
	end

endtask : driverRandom; 


task receiver( );
	automatic bit [`DATA_W-1:0] bufData[$];
	automatic int 		  length;
	automatic bit [`DATA_W-1:0] overFlowData;
	length = 0;
	forever
	begin
		$display("%0t : INFO    : receiver      : start ", $time );	
		bufData = {}; // clear queue
		//
		if( ( length % 2 ) != 0 )
		begin
			bufData.push_back( overFlowData );
			mailDv2Rv.get( length );
			length--;
		end	
		else 
			mailDv2Rv.get( length );
			
		outData.getData( bufData, length, overFlowData );
		mailRv2Sb.put( bufData );
		-> startSb;		
		$display("%0t : INFO    : receiver      : end  ", $time );	
	end
	
endtask : receiver

task scoreboard( );
	automatic int i = 0;
	automatic bit [`DATA_W-1:0]	DvBuf[$];	
	automatic bit [`DATA_W-1:0]	SbBuf[$];
	forever
	begin
		@startSb;
		$display("%0t : INFO    : scoreboard  : new_transaction", $time );	
		DvBuf = {}; // clear queue
		SbBuf = {}; // clear queue	
		mailDv2Sb.get( DvBuf ); 
		mailRv2Sb.get( SbBuf ); 
		$display("%0t : INFO : scoreboard      : DvBuf.size = %0d", $time, DvBuf.size() );
/* 		foreach(SbBuf[j])
					$display("%0t : INFO    : scoreboard_test    : DvBuf[ %0d ] = %0x, SbBuf[ %0d ] = %0x, data ", $time, j, DvBuf[j], j, SbBuf[j] );			 */		
		if( DvBuf.size() != SbBuf.size() )
		begin
			$display("%0t : ERROR   : scoreboard      : DvBuf.size = %0d, SbBuf.size = %0d, length not compare", $time, DvBuf.size(), SbBuf.size() );	
			@in_data_intf.clk;
			$stop;
		end		
		else
			$display("%0t : INFO    : scoreboard      : DvBuf.size = %0d, SbBuf.size = %0d, length ", $time, DvBuf.size(), SbBuf.size() );	
		foreach(DvBuf[j])
		begin
			$display("%0t : INFO    : scoreboard      : DvBuf[ %0d ] = %0x, SbBuf[ %0d ] = %0x, data ", $time, j, DvBuf[j], j, SbBuf[j] );	
			if( DvBuf[j] != SbBuf[j] )
			begin
			  @in_data_intf.clk;
				$display("%0t : ERROR    : scoreboard      : DvBuf[ %0d ] = %0x, SbBuf[ %0d ] = %0x, data not compare", $time, j, DvBuf[j], j, SbBuf[j] );	
				$stop;					
			end
		end		
	end
	$display("%0t : INFO    : scoreboard      : end ", $time );				
	
endtask : scoreboard

initial
begin
	// $display(" ******************* Start of testcase ****************");
	
	///////////
	//rst 
	///////////
  nrst       <= 0;
  repeat (4) @in_data_intf.clk;
  nrst       <= 1;
  repeat (4) @in_data_intf.clk;

	mailDv2Sb = new(8); 
	mailRv2Sb = new(8); 
	mailDv2Rv = new(8);	
	
	inData    = new( in_data_intf );
	inData.rst();
	outData    = new( out_data_intf );
	outData.rst();
	
	$display("%0t : INFO : direct_test ", $time );	
	run = 1;
	fork
	  driverDirect( );
		receiver( );
		scoreboard( );
	join_any	
  repeat (1000) @in_data_intf.clk;
	run = 0;
	disable driverDirect;
	disable receiver;	
	disable scoreboard;
  repeat (1000) @in_data_intf.clk;
	
	$display("%0t : INFO : random_test ", $time );	
	run = 1;	
	fork
	  driverRandom( 10000 );
		receiver( );
		scoreboard( );
	join_any	
  repeat (1000) @in_data_intf.clk;
	run = 0;
	disable driverRandom;
	disable receiver;	
	disable scoreboard;
  repeat (1000) @in_data_intf.clk;
	
	$display(" ******************** End of testcase *****************");			
	$stop;
	//final
end

endprogram 
`endif
