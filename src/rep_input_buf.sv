////////////
// Функционал модуля:
// 	1) защёлкивает входные данные ( в связи с требованием задачи )
// 	2) разветвляет входные данные в два канала fifo
////////////
//module rep_input_buf
module rep_input_buf
#( 
  parameter DATA_W   		= 12
)
(
  input                    			 nrst_i,
  input                          clk_i,
	
	// fifo interface. latency == 1
	input 									 			 run_i,
	input				 [1:0][DATA_W-1:0] data_i,	
	output logic 						 			 rd_o,
	
	input 					   			 [1:0] fifo_almost_full_i,
	output logic [1:0][DATA_W-1:0] fifo_data_o,
	output logic 			 			 [1:0] fifo_wr_o
		
);

// исходя из требований задачи к защёлкиванию
logic run_r;
always_ff @( negedge nrst_i or posedge clk_i )
begin
	if( !nrst_i ) run_r <= '0;
	else
	begin
		run_r <= run_i;
	end
end  

// исходя из требований задачи к защёлкиванию
// пришлось использовать сигнал fifo_almost_full_i для корректной работы с fifo
always_ff @( negedge nrst_i or posedge clk_i )
begin
	if( !nrst_i ) rd_o <= '0;
	else
	begin
		rd_o <= !fifo_almost_full_i[0] && !fifo_almost_full_i[1] && run_r;
	end
end 

always_ff @( negedge nrst_i or posedge clk_i )
begin
	if( !nrst_i ) fifo_wr_o[0] <= '0;
	else
	begin
		fifo_wr_o[0] <= rd_o;
	end
end 
assign fifo_wr_o[1] = fifo_wr_o[0];

assign fifo_data_o = data_i;

endmodule
