////////////
// ТЗ: Блок должен по запуску (run) приступить к выемки данных и раскручиванию этих данных по значению операнда команды таким образом, 
//		 чтобы на выходе блока получить непрерывный поток данных с изменением данных синхронно входной частоте. 
//		 Данные поступают в соответствии с запросом (rd_req) на следующий такт после запроса, в два потока одновременно. 
//		 Два потока обусловлены необходимостью работы устройства на пониженной частоте: 
//     за один такт вдвое больше данных, с точки зрения значимости сначала четный (even), далее нечетный (odd). 
//		 На выход раскручивать данные следует по тому же принципу.
//     1) В отдельном проекте (входы и выходы протриггеровать до и после блока) 
//		 2) Операнд 32 бита / Данные 32 бита; 
//		 3) Требуемая частота 300 МГц; Кристалл: StratixIV (3-я градация скорости)
//
// Для подключения модулей использовал 
// 	интерфейс fifo https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/ug/ug_fifo.pdf
// 	интерфейс avalon-st https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/manual/mnl_avalon_spec.pdf
////////////
//module rep_execute_block_top
module rep_execute_block_top
#( 
  parameter DATA_W   				= 32, // ширина данных   8 / 32  
	parameter OPER_W   		    = 32, // ширина операнда 4 / 32
	parameter FIFO_USE_MEMORY = 1  // 0 -> fifo in logic ; 1 -> fifo in memory	
)
(
  input                									nReset,  
	input 						   									clk,
	
	input 						   									run,
	
	//// fifo interface. latency = 1 
  input         [DATA_W + OPER_W - 1:0] zip_data_even, 	
  input         [DATA_W + OPER_W - 1:0] zip_data_odd,
	output logic  		   									rd_req,
	
	//// avalon-st
	// synthesis translate_off
	output logic         									data_out_vd_o,	// для симуляции
	// synthesis translate_on
	output logic   					 [DATA_W-1:0] data_out_even,
	output logic   					 [DATA_W-1:0] data_out_odd
	
);

logic [1:0] 											 fifo_almost_full_w;
logic [1:0][DATA_W + OPER_W - 1:0] fifo_wrdata_w;
logic [1:0] 											 fifo_wr_w;
logic [1:0] 											 fifo_rd_w;
logic [1:0]       								 fifo_empty_w;
logic [1:0][OPER_W-1:0] 					 fifo_rdoperand_w;
logic [1:0][DATA_W-1:0] 					 fifo_rddata_w;

// защелкивает входные buffered данные и операнд, затем разветвляет в два канала fifo,
//  шина данных защёлкиваются на fifo
rep_input_buf
#(
	.DATA_W( DATA_W + OPER_W )
	
) rep_input_buf
(
	.nrst_i							( nReset ),
	.clk_i							( clk ),
	
	.run_i							( run ),
	.data_i							( { zip_data_odd[DATA_W + OPER_W - 1:0], zip_data_even[DATA_W + OPER_W - 1:0] } ),	
	.rd_o								( rd_req ),
	
	.fifo_almost_full_i	( fifo_almost_full_w ),
	.fifo_data_o				( fifo_wrdata_w ),
	.fifo_wr_o					( fifo_wr_w[1:0] )
		
);

logic [1:0][1:0] 				st_rdy_w;
logic [1:0][1:0] 				st_vd_w;
logic [1:0][DATA_W-1:0] st_data_w;
logic [1:0][1:0] 				st_sop_w;
logic [1:0][1:0] 				st_eop_w;

genvar i;
generate
	for( i = 0; i < 2; i++ ) 
	begin : port_generation
		
		scfifo	scfifo_component 
		(
			.aclr   				( !nReset ),
			.clock  				( clk ),
			.data 					( fifo_wrdata_w[i][DATA_W + OPER_W - 1:0] ),
			.rdreq 					( fifo_rd_w[i] ),
			.wrreq 					( fifo_wr_w[i] ),	
			.empty 					( fifo_empty_w[i] ),
			.full 					(  ),
			.q 							( { fifo_rdoperand_w[i][OPER_W-1:0], fifo_rddata_w[i][DATA_W-1:0] } ),
			.almost_empty 	(),
			.almost_full 		( fifo_almost_full_w[i] ),
			.eccstatus 			(),
			.sclr 					(),
			.usedw 					()
		);
		defparam
			scfifo_component.add_ram_output_register = "OFF",
			scfifo_component.almost_full_value 			 = 6,		
			scfifo_component.intended_device_family  = "Stratix IV",
			scfifo_component.lpm_numwords 					 = 8,
			scfifo_component.lpm_showahead 				 	 = "ON",
			scfifo_component.lpm_type 							 = "scfifo",
			scfifo_component.lpm_width 							 = ( DATA_W + OPER_W ),
			scfifo_component.lpm_widthu 						 = 3,
			scfifo_component.overflow_checking 			 = "OFF",
			scfifo_component.underflow_checking 		 = "OFF",
			scfifo_component.use_eab 								 = ( FIFO_USE_MEMORY == 1 )? "ON" : "OFF"; //OFF -> logic ; ON -> memory	
		
		// преобразовывает входные buffered данные и операнд в два stream данных
		rep_data2stream 
		#(
			.DATA_W( DATA_W ),
			.OPER_W( OPER_W )		
			
		)	rep_data2stream	
		(
			.nrst_i					( nReset ),
			.clk_i					( clk ),
			
			.fifo_empty_i		( fifo_empty_w[i] ),
			.fifo_data_i		( fifo_rddata_w[i][DATA_W-1:0] ),
			.fifo_operand_i	( fifo_rdoperand_w[i][OPER_W-1:0] ),
			.fifo_rd_o			( fifo_rd_w[i] ), 
			
			.src_rdy_i			( st_rdy_w[i] ),
			.src_data_o			( st_data_w[i][DATA_W-1:0] ),
			.src_sop_o			( st_sop_w[i] ),
			.src_eop_o			( st_eop_w[i] ),
			.src_vd_o				( st_vd_w[i] )
				
		);
	end	
endgenerate

logic data_out_vd_w;
// мультплексирует 4 канала stream данных в 2 канала stream данных
rep_mux 
#(
	.DATA_W( DATA_W )	
	
) rep_mux
(
	.nrst_i				( nReset ),
	.clk_i				( clk ),
	
	.snk_data_i		( st_data_w ),
	.snk_vd_i			( st_vd_w ),
	.snk_sop_i		( st_sop_w ),
	.snk_eop_i		( st_eop_w ),
	.snk_rdy_o		( st_rdy_w ),	
	
	.src_data_o		( { data_out_odd[DATA_W-1:0], data_out_even[DATA_W-1:0] } ),
	.src_vd_o			( data_out_vd_w )
); 

// synthesis translate_off
assign data_out_vd_o = data_out_vd_w;
// synthesis translate_on
	
endmodule
