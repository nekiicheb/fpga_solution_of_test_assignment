////////////
// Функционал модуля:
// 	1) выполняет преобразование из буферизованных данных в два потока avalon-st
////////////
//module rep_data2stream
module rep_data2stream
#( 
  parameter DATA_W   		= 8, // 1:32
	parameter OPER_W      = 4 
)
(
  input                     nrst_i,
  input                     clk_i,
	
	// fifo interface : show-ahead mode
	input 									  fifo_empty_i,
	input 			 [DATA_W-1:0]	fifo_data_i,
	input 			 [OPER_W-1:0]	fifo_operand_i,
	output logic 						  fifo_rd_o, 
	
	//avalon st interface
	input 						  [1:0]	src_rdy_i,
	output logic [DATA_W-1:0]	src_data_o,
	output logic        [1:0] src_sop_o,
	output logic 			  [1:0]	src_eop_o,
	output logic 			  [1:0]	src_vd_o
		
);

// запускаем модуль если входное fifo не пустое  
logic first_rd_w;
assign first_rd_w = !fifo_empty_i;
logic first_rd_r;
always_ff @( negedge nrst_i or posedge clk_i )
begin
	if( !nrst_i ) first_rd_r <= '0;
	else
	begin
		first_rd_r <= first_rd_w;
	end
end 
logic first_rd_ris_w;
assign first_rd_ris_w = first_rd_w && !first_rd_r;

 
always_ff @( negedge nrst_i or posedge clk_i )
begin
	if( !nrst_i ) src_data_o[DATA_W-1:0] <= '0;
	else
	begin
		if( (src_eop_o && src_rdy_i[0] ) || first_rd_ris_w ) src_data_o[DATA_W-1:0] <= fifo_data_i[DATA_W-1:0];
	end
end

// счетчик переданных word, за один такт может быть передан double_word
logic [OPER_W-1:0] operand_cnt_r;
always_ff @( negedge nrst_i or posedge clk_i )
begin
	if( !nrst_i ) operand_cnt_r[OPER_W-1:0] <= '0;
	else
	begin
		if( (src_eop_o && src_rdy_i[0] ) || first_rd_ris_w )									operand_cnt_r[OPER_W-1:0] <= fifo_operand_i[OPER_W-1:0];
		else if( src_vd_o[0] && src_rdy_i[0] && src_vd_o[1] && src_rdy_i[1] ) operand_cnt_r[OPER_W-1:0] <= operand_cnt_r[OPER_W-1:0] - 2'd_2;
		else if( src_vd_o[0] && src_rdy_i[0] ) 																operand_cnt_r[OPER_W-1:0] <= operand_cnt_r[OPER_W-1:0] - 1'd_1;
	end
end
 
assign fifo_rd_o = !fifo_empty_i && ( first_rd_ris_w || ( src_eop_o[0] && src_rdy_i[0] ) ); 

assign src_vd_o[0] = first_rd_r;
assign src_vd_o[1] = first_rd_r && !( operand_cnt_r[OPER_W-1:0] == '0 );

assign src_eop_o[0] = ( ( operand_cnt_r[OPER_W-1:0] <= 32'd_1 ) && src_rdy_i[0] && src_vd_o[0] && src_rdy_i[1] && src_vd_o[1] ) ||   
										  ( ( operand_cnt_r[OPER_W-1:0] == '0     ) && src_rdy_i[0] && src_vd_o[0] );
assign src_eop_o[1] = src_eop_o[0];											


endmodule
