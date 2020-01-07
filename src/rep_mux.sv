////////////
// Функционал модуля:
// 	1) приоритетный мултиплексор четырех потоков avalon-st в два потока avalon-st 
////////////
//module rep_mux
module rep_mux
#( 
  parameter DATA_W   		= 12,
	parameter DATA_OUT_W  = ( DATA_W * 2 )
)
(
  input                   			 nrst_i,
  input                   			 clk_i,
	
	input      	 [1:0][DATA_W-1:0] snk_data_i,
	input 			     				 [3:0] snk_vd_i,
	input 			    	 			 [3:0] snk_sop_i,
	input 			     				 [3:0] snk_eop_i,
	output logic 		 				 [3:0] snk_rdy_o,	
	
	output logic [DATA_OUT_W-1:0]  src_data_o,
	output logic 									 src_vd_o
);

/////////
// автомат состояния
/////////
enum logic [2:0] { IDLE_S, PORT0_S, PORT1_S } main_state,
																							next_main_state;
																							
logic  is_port0_full_word_eop;
assign is_port0_full_word_eop = snk_vd_i[0] && snk_eop_i[0] && snk_rdy_o[0] && snk_vd_i[1] && snk_eop_i[1] && snk_rdy_o[1];
logic  is_port1_full_word_eop;
assign is_port1_full_word_eop = snk_vd_i[2] && snk_eop_i[2] && snk_rdy_o[2] && snk_vd_i[3] && snk_eop_i[3] && snk_rdy_o[3];

//// случай с передачей невыровненного слова.
//   	например последнее слово с 0-го порта и одно слово с 1-го порта
logic  is_port0_half_word_eop;
assign is_port0_half_word_eop = snk_vd_i[0] && snk_eop_i[0] && snk_rdy_o[0] && !snk_vd_i[1] && snk_vd_i[2] && !snk_eop_i[2]; 
logic  is_port1_half_word_eop;
assign is_port1_half_word_eop = snk_vd_i[2] && snk_eop_i[2] && snk_rdy_o[2] && !snk_vd_i[3] && snk_vd_i[1] && !snk_eop_i[1];
																							
always_comb begin
	next_main_state = main_state;
		unique case ( main_state )
			IDLE_S         			    : if( snk_vd_i[0] ) 																					next_main_state = PORT0_S;
			
			PORT0_S									: if( !( |snk_vd_i[3:0] ) )													 					next_main_state = IDLE_S;
																else if( is_port0_full_word_eop || is_port0_half_word_eop ) next_main_state = PORT1_S;	
			
			PORT1_S			    			  : if( !( |snk_vd_i[3:0] ) )			      												next_main_state = IDLE_S;
																else if( is_port1_full_word_eop || is_port1_half_word_eop ) next_main_state = PORT0_S;		
    endcase 	 
end	

always_ff @( negedge nrst_i or posedge clk_i )
begin
	if( !nrst_i ) main_state <= IDLE_S;
	else
	begin
		main_state <= next_main_state;
	end
end
/////////
/////////
/////////

//// случай с передачей невыровненного слова.
//   	например одно слово с 0-го порта и одно слово с 1-го порта
assign snk_rdy_o[0] = snk_vd_i[0] && ( ( main_state == PORT0_S ) || ( ( main_state == PORT1_S ) && !snk_vd_i[3] ) );
assign snk_rdy_o[1] = snk_vd_i[1] &&   ( main_state == PORT0_S );
assign snk_rdy_o[2] = snk_vd_i[2] && ( ( main_state == PORT1_S ) || ( ( main_state == PORT0_S ) && !snk_vd_i[1] ) );
assign snk_rdy_o[3] = snk_vd_i[3] &&   ( main_state == PORT1_S );


logic [DATA_OUT_W-1:0] port0_data_w;
assign port0_data_w[DATA_OUT_W-1:0] = ( snk_rdy_o[1] )? { snk_data_i[0][DATA_W-1:0], snk_data_i[0][DATA_W-1:0] } : 
																												{ snk_data_i[1][DATA_W-1:0], snk_data_i[0][DATA_W-1:0] };
logic [DATA_OUT_W-1:0] port1_data_w;
assign port1_data_w[DATA_OUT_W-1:0] = ( snk_rdy_o[3] )? { snk_data_i[1][DATA_W-1:0], snk_data_i[1][DATA_W-1:0] } : 
																												{ snk_data_i[0][DATA_W-1:0], snk_data_i[1][DATA_W-1:0] };

logic [DATA_OUT_W-1:0] src_data_w;
assign src_data_w[DATA_OUT_W-1:0] = ( main_state == PORT0_S )? port0_data_w[DATA_OUT_W-1:0] : port1_data_w[DATA_OUT_W-1:0];

always_ff @( negedge nrst_i or posedge clk_i )
begin
	if( !nrst_i ) src_data_o[DATA_OUT_W-1:0] <= '0;
	else
	begin
		src_data_o[DATA_OUT_W-1:0] <= src_data_w[DATA_OUT_W-1:0];
	end
end

always_ff @( negedge nrst_i or posedge clk_i )
begin
	if( !nrst_i ) src_vd_o <= '0;
	else
	begin
		src_vd_o <= ( main_state != IDLE_S );
	end
end

endmodule
