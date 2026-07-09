`timescale 1ns / 1ps
//memory mapped register - register file

module soc_mmr_reg_file
(
input 				soc_clk				,
input 				soc_rst				,
input 				soc_mmr_write_en_i		,//store write enable
input  [15:0]			soc_mmr_write_addr_i		,//store write address
input  [31:0]			soc_mmr_write_data_i		,//store write data
input  				soc_int_pending_valid_i 	,	
input  [15:0] 	    		soc_int_pending_bit_i		,//soc interrupt pending bits
input  [15:0]	    		global_int_enable_bit_i		,//soc interrupt enable signal
input 				global_int_enable_valid_i	,
input 				soc_ack_valid_i			,//from soc 
input  [7:0] 			soc_ack_int_id_i		,
input 				soc_nxtp_valid_i		,	
input  [7 :0]			soc_nxtp_id_i			,
input 				soc_eoi_valid_i			,
input  [7 :0]			soc_eoi_id_i			,
output [7 :0] 			soc_ack_int_id_o		,
output [7 :0]   		soc_eoi_o			,
output [7 :0]   		soc_cfg_o			,
output [31:0] 			soc_info_o			,
output [7 :0]			soc_nxtp_o			,
output [31:0]			irq0_ctrl_o 			,		
output [31:0]			irq1_ctrl_o 			,
output [31:0]			irq2_ctrl_o 			,
output [31:0]			irq3_ctrl_o 			,
output [31:0]			irq4_ctrl_o 			,
output [31:0]			irq5_ctrl_o 			,
output [31:0]			irq6_ctrl_o 			,
output [31:0]			irq7_ctrl_o 			,
output [31:0]			irq8_ctrl_o 			,
output [31:0]			irq9_ctrl_o 			,
output [31:0]			irq10_ctrl_o			,
output [31:0]			irq11_ctrl_o			,
output [31:0]			irq12_ctrl_o			,
output [31:0]			irq13_ctrl_o			,
output [31:0]			irq14_ctrl_o			,
output [31:0]			irq15_ctrl_o			,
//    output [31:0]			irq16_ctrl_o			,
//    output [31:0]			irq17_ctrl_o			,
//    output [31:0]			irq18_ctrl_o			,
//    output [31:0]			irq19_ctrl_o			,
//    output [31:0]			irq20_ctrl_o			,
//    output [31:0]			irq21_ctrl_o			,
//    output [31:0]			irq22_ctrl_o			,
//    output [31:0]			irq23_ctrl_o			,
//    output [31:0]			irq24_ctrl_o			,
//    output [31:0]			irq25_ctrl_o			,
//    output [31:0]			irq26_ctrl_o			,
//    output [31:0]			irq27_ctrl_o			,
//    output [31:0]			irq28_ctrl_o			,
//    output [31:0]			irq29_ctrl_o			,
//    output [31:0]			irq30_ctrl_o			,
//    output [31:0]			irq31_ctrl_o			,
//    output [31:0]			irq32_ctrl_o			,
//    output [31:0]			irq33_ctrl_o			,
//    output [31:0]			irq34_ctrl_o			,
//    output [31:0]			irq35_ctrl_o			,
//    output [31:0]			irq36_ctrl_o			,
//    output [31:0]			irq37_ctrl_o			,
//    output [31:0]			irq38_ctrl_o			,
//    output [31:0]			irq39_ctrl_o			,
//    output [31:0]			irq40_ctrl_o			,
//    output [31:0]			irq41_ctrl_o			,
//    output [31:0]			irq42_ctrl_o			,
//    output [31:0]			irq43_ctrl_o			,
//    output [31:0]			irq44_ctrl_o			,
//    output [31:0]			irq45_ctrl_o			,
//    output [31:0]			irq46_ctrl_o			,
//    output [31:0]			irq47_ctrl_o			,
output [15:0] 			soc_int_en_o			,//to soc 
output [31:0] 			wdt_counter_o			,		
output [31:0] 			wdt_ctrl_o			,
output 			wdt_irq_o			,
output [31:0] 			wdt_timeout_reg_o   ,
input debug_mode_valid_i             ,
input debug_mode_reset_i             ,
input debug_ndm_reset_i             ,
output wdt_reset_o  


);

soc_mmr_ack  
soc_mmr_ack_inst
(
.soc_clk			(soc_clk		),
.soc_rst			(soc_rst		),
.wdt_reset_i        (wdt_reset_o),
//.soc_mmr_write_addr		(soc_mmr_write_addr_i	),
//.soc_mmr_write_data		(soc_mmr_write_data_i	),
//.soc_mmr_write_en		(soc_mmr_write_en_i	),
.soc_ack_valid			(soc_ack_valid_i	),//from soc 
.soc_ack_int_id_i		(soc_ack_int_id_i	),
.soc_ack_int_id_o		(soc_ack_int_id_o	),
//.debug_mode_valid_i             (debug_mode_valid_i         ),
.debug_mode_reset_i             (debug_mode_reset_i        ),
.debug_ndm_reset_i              (debug_ndm_reset_i               )

);

/*wdt_mmr_csr wdt_mmr_csr_inst
(
.soc_clk				(soc_clk			),
.soc_rst				(soc_rst			),
.soc_mmr_write_en_i			(soc_mmr_write_en_i		),//store write enable
.soc_mmr_write_addr_i			(soc_mmr_write_addr_i		),//store write address
.soc_mmr_write_data_i			(soc_mmr_write_data_i		),//store write data
.wdt_counter_o				(wdt_counter_o			),
.wdt_ctrl_o				(wdt_ctrl_o			),
.wdt_irq_o				(wdt_irq_o			)
);*/
	
wdt_mmr_csr wdt_mmr_csr_inst
(
	.wdt_clk_i		(soc_clk		),
	.wdt_rst_i		(soc_rst		),
	.wdt_write_addr_i 	(soc_mmr_write_addr_i	),
	.wdt_write_data_i 	(soc_mmr_write_data_i	),
	.wdt_write_en_i		(soc_mmr_write_en_i	),
	.wdt_counter_o		(wdt_counter_o		),
	.wdt_timeout_reg_o	(wdt_timeout_reg_o	),
	.wdt_ctrl_o		(wdt_ctrl_o		),
	.wdt_interrupt_o  	(wdt_irq_o		), // WDT interrupt request signal output
	.wdt_reset_o		(wdt_reset_o), // WDT reset output, active low //unconnected
	.stop_mode_i		(1'b0), // System STOP Mode
	.wait_mode_i		(1'b0), // System WAIT Mode
	.debug_mode_i		(debug_mode_valid_i)		  // System DEBUG Mode
    //.debug_mode_valid_i             (debug_mode_valid_i         ),
//.debug_mode_reset_i             (debug_mode_reset_i        ),
//.debug_ndm_reset_i              (debug_ndm_reset_i               )

);


soc_mmr_cfg #(.CFG_MMR_ADDR(16'h0000)) 
soc_mmr_cfg_inst
(
.soc_clk			        (soc_clk		),
.soc_rst			        (soc_rst		),
.wdt_reset_i        (wdt_reset_o),
.soc_mmr_write_addr		    (soc_mmr_write_addr_i	),
.soc_mmr_write_data		    (soc_mmr_write_data_i	),
.soc_mmr_write_en		    (soc_mmr_write_en_i	),
.soc_cfg_o			        (soc_cfg_o		),
.debug_mode_valid_i             (debug_mode_valid_i         ),
.debug_mode_reset_i             (debug_mode_reset_i        ),
.debug_ndm_reset_i              (debug_ndm_reset_i               )

);


soc_mmr_info #(.INFO_MMR_ADDR(16'h0004)) 
soc_mmr_info_inst(
.soc_clk			(soc_clk		),
.soc_rst			(soc_rst		),
.wdt_reset_i        (wdt_reset_o),
.soc_mmr_write_addr		(soc_mmr_write_addr_i	),
.soc_mmr_write_data		(soc_mmr_write_data_i	),
.soc_mmr_write_en		(soc_mmr_write_en_i	),
.soc_info_o			(soc_info_o		)
);


soc_mmr_eoi 
soc_eoi_cfg_inst(
.soc_clk			(soc_clk		),
.soc_rst			(soc_rst		),
.wdt_reset_i        (wdt_reset_o),
.soc_eoi_valid		(soc_eoi_valid_i	),
.soc_eoi_id			(soc_eoi_id_i		),
.soc_eoi_o			(soc_eoi_o		),
.debug_mode_valid_i             (debug_mode_valid_i         ),
.debug_mode_reset_i             (debug_mode_reset_i        ),
.debug_ndm_reset_i              (debug_ndm_reset_i               )

);

soc_mmr_nxtp 
soc_mmr_nxtp_inst
(
.soc_clk			(soc_clk		),
.soc_rst			(soc_rst		),
.wdt_reset_i        (wdt_reset_o),
.soc_nxtp_valid		(soc_nxtp_valid_i	),
.soc_nxtp_id		(soc_nxtp_id_i		),
.soc_nxtp_o			(soc_nxtp_o		),
.debug_mode_valid_i             (debug_mode_valid_i         ),
.debug_mode_reset_i             (debug_mode_reset_i        ),
.debug_ndm_reset_i              (debug_ndm_reset_i               )

);

soc_mmr_ctrl soc_mmr_ctrl_inst
(
.soc_clk			(soc_clk			),
.soc_rst			(soc_rst			),
.wdt_reset_i        (wdt_reset_o),
.soc_mmr_write_addr		(soc_mmr_write_addr_i		),
.soc_mmr_write_data		(soc_mmr_write_data_i		),
.soc_mmr_write_en		(soc_mmr_write_en_i		),
.soc_int_pending_bit		(soc_int_pending_bit_i		),
.soc_int_pending_valid		(soc_int_pending_valid_i	),
.global_int_enable_bit		(global_int_enable_bit_i	),
.global_int_enable_valid 	(global_int_enable_valid_i	),
.irq0_ctrl_o			(irq0_ctrl_o 			),
.irq1_ctrl_o			(irq1_ctrl_o 			),
.irq2_ctrl_o			(irq2_ctrl_o 			),
.irq3_ctrl_o			(irq3_ctrl_o 			),
.irq4_ctrl_o			(irq4_ctrl_o 			),
.irq5_ctrl_o			(irq5_ctrl_o 			),
.irq6_ctrl_o			(irq6_ctrl_o 			),
.irq7_ctrl_o			(irq7_ctrl_o 			),
.irq8_ctrl_o			(irq8_ctrl_o 			),
.irq9_ctrl_o			(irq9_ctrl_o 			),
.irq10_ctrl_o			(irq10_ctrl_o			),
.irq11_ctrl_o			(irq11_ctrl_o			),
.irq12_ctrl_o			(irq12_ctrl_o			),
.irq13_ctrl_o			(irq13_ctrl_o			),
.irq14_ctrl_o			(irq14_ctrl_o			),
.irq15_ctrl_o			(irq15_ctrl_o			),
//.irq16_ctrl_o			(irq16_ctrl_o			),
//.irq17_ctrl_o			(irq17_ctrl_o			),
//.irq18_ctrl_o			(irq18_ctrl_o			),
//.irq19_ctrl_o			(irq19_ctrl_o			),
//.irq20_ctrl_o			(irq20_ctrl_o			),
//.irq21_ctrl_o			(irq21_ctrl_o			),
//.irq22_ctrl_o			(irq22_ctrl_o			),
//.irq23_ctrl_o			(irq23_ctrl_o			),
//.irq24_ctrl_o			(irq24_ctrl_o			),
//.irq25_ctrl_o			(irq25_ctrl_o			),
//.irq26_ctrl_o			(irq26_ctrl_o			),
//.irq27_ctrl_o			(irq27_ctrl_o			),
//.irq28_ctrl_o			(irq28_ctrl_o			),
//.irq29_ctrl_o			(irq29_ctrl_o			),
//.irq30_ctrl_o			(irq30_ctrl_o			),
//.irq31_ctrl_o			(irq31_ctrl_o			),
//.irq32_ctrl_o			(irq32_ctrl_o			),
//.irq33_ctrl_o			(irq33_ctrl_o			),
//.irq34_ctrl_o			(irq34_ctrl_o			),
//.irq35_ctrl_o			(irq35_ctrl_o			),
//.irq36_ctrl_o			(irq36_ctrl_o			),
//.irq37_ctrl_o			(irq37_ctrl_o			),
//.irq38_ctrl_o			(irq38_ctrl_o			),
//.irq39_ctrl_o			(irq39_ctrl_o			),
//.irq40_ctrl_o			(irq40_ctrl_o			),
//.irq41_ctrl_o			(irq41_ctrl_o			),
//.irq42_ctrl_o			(irq42_ctrl_o			),
//.irq43_ctrl_o			(irq43_ctrl_o			),
//.irq44_ctrl_o			(irq44_ctrl_o			),
//.irq45_ctrl_o			(irq45_ctrl_o			),
//.irq46_ctrl_o			(irq46_ctrl_o			),
//.irq47_ctrl_o			(irq47_ctrl_o			),
.soc_int_en_o			(soc_int_en_o			)
/*.debug_mode_valid_i             (debug_mode_valid_i         ),
.debug_mode_reset_i             (debug_mode_reset_i        ),
.debug_ndm_reset_i              (debug_ndm_reset_i               )*/

);
endmodule

////////////////////////////////////////////////////
//acknowledge mmr
//stores the interrupt id value of requested interrupt
////////////////////////////////////////////////////
module soc_mmr_ack #(parameter CFG_MMR_ACK = 16'h0804) 
(
input 		soc_clk			,
input 		soc_rst			,
input       wdt_reset_i     ,
//input [15:0] 	soc_mmr_write_addr	,
//input [31:0] 	soc_mmr_write_data	,
//input 	     	soc_mmr_write_en	,
input 		soc_ack_valid		,//from soc 
input [7:0]	soc_ack_int_id_i	,
output [7:0]	soc_ack_int_id_o,
//input debug_mode_valid_i             ,
input debug_mode_reset_i             ,
input debug_ndm_reset_i              


);

reg [7:0] soc_ack_int_id_r;

always@(posedge soc_clk or negedge soc_rst )
begin
	if((!soc_rst) )
	begin
		soc_ack_int_id_r <= 8'd0;
	end
    else if(debug_mode_reset_i |debug_ndm_reset_i| wdt_reset_i )
    begin
        		soc_ack_int_id_r <= 8'd0;

    end
	else
	begin
		if(soc_ack_valid)
			begin
				soc_ack_int_id_r <= soc_ack_int_id_i;
			end
	end
end

assign soc_ack_int_id_o = soc_ack_int_id_r;
endmodule

////////////////////////////////////////////////////////////////////
//soc memory mapped configuration register
//defines how many previlege modes are supported
//defines how level and priority bits are devided

module soc_mmr_cfg #(parameter CFG_MMR_ADDR = 16'h0000) 
(
input 		soc_clk			,
input 		soc_rst			,
input       wdt_reset_i     ,
input [15:0] 	soc_mmr_write_addr	,
input [31:0] 	soc_mmr_write_data	,
input 	     	soc_mmr_write_en	,
output 	[7:0]   soc_cfg_o		,
input debug_mode_valid_i             ,
input debug_mode_reset_i             ,
input debug_ndm_reset_i              


);

//reg [7:0] soc_cfg_r;

localparam NMBITS = 2'b00;
localparam NLBITS = 4'b0011;
localparam NVBITS = 1'b1;

assign soc_cfg_o = {1'b0,NMBITS,NLBITS,NVBITS};
endmodule
/////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////
//soc memory mapped information register
//has required information about soc

module soc_mmr_info #(parameter INFO_MMR_ADDR = 16'd0004) 
(
input 		soc_clk			,
input 		soc_rst			,
input       wdt_reset_i     ,
input [15:0] 	soc_mmr_write_addr	,
input [31:0] 	soc_mmr_write_data	,
input 	     	soc_mmr_write_en	,
output 	[31:0]   soc_info_o		
);

//reg [31:0] soc_info_r;
localparam NUM_TRIG	= 6'd0	;
localparam ZIC_INT_CTL	= 4'd6	;
localparam ARCH_VER	= 4'd0	;
localparam IMPL_VER	= 4'd0	;
localparam NUM_IRQ 	= 13'd16;


assign soc_info_o = {1'b0,NUM_TRIG,ZIC_INT_CTL,ARCH_VER,IMPL_VER,NUM_IRQ};
endmodule

//////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////
//soc memory mapped end of interrupt id register
//stores the id of a interrup whose service is completed by the processor
///////////////////////////////////////////////////////////////////////////////////

module soc_mmr_eoi 
(
input 		soc_clk			,
input 		soc_rst			,
input       wdt_reset_i     ,
input 		soc_eoi_valid		,
input 	[7:0]	soc_eoi_id		,
output 	[7:0]   soc_eoi_o		,
input debug_mode_valid_i             ,
input debug_mode_reset_i             ,
input debug_ndm_reset_i              


);

reg [7:0] soc_eoi_r;

always@(posedge soc_clk or negedge soc_rst )
begin
	if((!soc_rst) )
	begin
		soc_eoi_r <= 8'd0;
	end
    else if(debug_mode_reset_i |debug_ndm_reset_i| wdt_reset_i )
    begin
        		soc_eoi_r <= 8'd0;
    end
	else
	begin
		if(soc_eoi_valid)
			begin
				soc_eoi_r <= soc_eoi_id;
			end
	end
end

assign soc_eoi_o = soc_eoi_r;
endmodule

////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
//stores the level and priority of highest pending interrupt
//for software read purpose
/////////////////////////////////////////////////////////////////////////////////

module soc_mmr_nxtp 
(
input 		soc_clk			,
input 		soc_rst			,
input       wdt_reset_i     ,
input 		soc_nxtp_valid		,
input 	[7:0]	soc_nxtp_id		,
output 	[7:0]   soc_nxtp_o		,
input debug_mode_valid_i             ,
input debug_mode_reset_i             ,
input debug_ndm_reset_i              


);

reg [7:0] soc_nxtp_r;

always@(posedge soc_clk or negedge soc_rst )
begin
	if((!soc_rst) )
	begin

		soc_nxtp_r <= 8'd0;
	end
    else if(debug_mode_reset_i |debug_ndm_reset_i | wdt_reset_i )
    begin
        		soc_nxtp_r <= 8'd0;

    end
	else
	begin
		if(soc_nxtp_valid)
			begin
				soc_nxtp_r <= soc_nxtp_id;
			end
	end
end

assign soc_nxtp_o = soc_nxtp_r;
endmodule

module wdt_mmr_csr
(
input  		       wdt_clk_i		 ,
input  		       wdt_rst_i		 ,
input   [15 :0]    wdt_write_addr_i	    ,
input   [31:0] 	   wdt_write_data_i	    ,
input   	       wdt_write_en_i	,
output  [31:0]     wdt_counter_o	,
output  [31:0]     wdt_timeout_reg_o	,
output  [31:0] 	   wdt_ctrl_o		,
output  	       wdt_interrupt_o	, // WDT interrupt request signal output
output  	    wdt_reset_o		, // WDT reset output, active low
input   	    stop_mode_i		, // System STOP Mode
input  	 	    wait_mode_i		, // System WAIT Mode
input   	    debug_mode_i		  // System DEBUG Mode
//input debug_mode_valid_i             ,
//input debug_mode_reset_i             ,
//input debug_ndm_reset_i              


);


//wire    [31:0]	timeout_value	;		
wire    [1:0] 	wdt_interrupt	;	
wire 		debug_enable 	;
wire 		stop_enable	;
wire 		wait_enable	;
//wire 		reload_event	;
wire		wdt_event	;
wire		clear_event	;


WDT_COUNTER wdt_counter_inst
(
.wdt_clk		(wdt_clk_i	), 				
.wdt_rst		(wdt_rst_i	),	
.wdt_counter		(wdt_counter_o	),	
.wdt_reset_o		(wdt_reset_o	),	
.wdt_interrupt_o	(wdt_interrupt_o),	
.clear_event		(clear_event	),	
.reload_count		(reload_count	),
.wdt_event		(wdt_event	),	
.debug_mode_i		(debug_mode_i	),
.debug_enable		(debug_enable	),
.wait_enable		(wait_enable	),	
.wait_mode_i		(wait_mode_i	),	
.stop_enable		(stop_enable	),	
.stop_mode_i		(stop_mode_i	),	
.wdt_enable		(wdt_enable	),	
.wdt_interrupt_sel	(wdt_interrupt	),  
.timeout_value		(wdt_timeout_reg_o	)
/*.debug_mode_valid_i             (debug_mode_valid_i         ),
.debug_mode_reset_i             (debug_mode_reset_i        ),
.debug_ndm_reset_i              (debug_ndm_reset_i               )*/

);


WDT_REG_FILE wdt_reg_file_inst
(
.wdt_clk	 (wdt_clk_i		),      				
.wdt_rst	 (wdt_rst_i		),       
.wdt_reg_addr    (wdt_write_addr_i		),//from top input	
.wdt_reg_data	 (wdt_write_data_i		),//from top input
.wdt_enable	 (wdt_enable		),//to wdt counter       
.debug_enable	 (debug_enable		),
.wait_enable	 (wait_enable		),       
.stop_enable	 (stop_enable		),       
.wdt_event	 (wdt_event		),       
.wdt_interrupt	 (wdt_interrupt		),
.timeout_limit	 (wdt_timeout_reg_o		),//to wdt counter
.reload_count	 (reload_count		),//to wdt counter
.clear_event     (clear_event		), //to wdt counter
.wdt_ctrl_o      (wdt_ctrl_o		),
.wdt_write_en_i	 (wdt_write_en_i	)
/*.debug_mode_valid_i             (debug_mode_valid_i         ),
.debug_mode_reset_i             (debug_mode_reset_i        ),
.debug_ndm_reset_i              (debug_ndm_reset_i               )*/


);

endmodule

//register file for watch dog timer 
//control register
//timeout register

module WDT_REG_FILE
(
input 		    wdt_clk		,
input 		    wdt_rst		,//global asyc reset
input 		    wdt_write_en_i	,
input [15:0] 	    wdt_reg_addr	,
input [31:0] 	    wdt_reg_data	,
output 		reg wdt_enable		,//to enable the WDT counter to decrement its value bit 2
output 		reg debug_enable	,//stop the counter decrement in debug mode	    bit 5
output 		reg wait_enable		,//halt the counter decrement			    bit 3
output 		reg stop_enable		,//to stop the counter decrement		    bit 4
output [31:0]       wdt_ctrl_o		,
input  		    clear_event		,//status of the WDT				    bit 8//clear event
output reg [1:0]    wdt_interrupt	,//to decide when the interrupt has to be generated bit 7:6
output reg [31:0]   timeout_limit	,//reset value of the watch dog counter
output 		reg reload_count	,//when two words are written to count: two service words 
output 		    wdt_event      	 //8th bit in data bus when control register address is selected


);
localparam SERVICE_WORD_0 = 16'h5555 ;
localparam SERVICE_WORD_1 = 16'haaaa ;
localparam WDT_CTRL = 16'h0810;
localparam WDT_SERVICE_WORD = 16'h818;
localparam WDT_TIMEOUT_REG = 16'h814;
reg wdt_protect;
reg wdt_lock;
reg service_wdt;


reg wdt_event_r;

assign wdt_event = clear_event ? 1'b0 : wdt_event_r;

always@(posedge wdt_clk or negedge wdt_rst)
begin
	if(!wdt_rst)
	begin
		wdt_enable	<= 1'b0;		 
		debug_enable	<= 1'b0; 
		wait_enable 	<= 1'b0;   
		stop_enable 	<= 1'b0; 
		wdt_interrupt	<= 2'b00;
		timeout_limit	<= 32'h0000ffff;
		reload_count	<= 1'b0; 
		wdt_event_r 	<= 1'b0; 
		wdt_protect         	<= 1'b0;
             	wdt_lock        	<= 1'b0;
		service_wdt 	<= 1'b0;

	end
	else
	begin
	/*	case(wdt_reg_addr)
			2'b00://editing the control bits of control registers
			begin
				wdt_event_r 	<= wdt_reg_data[8]	;
             			wdt_interrupt   <= wdt_reg_data[7:6]	;
             			debug_enable    <= (!wdt_enable || !wdt_reg_data[2]) ? wdt_reg_data[5]  : debug_enable	;
             			stop_enable     <= (!wdt_enable || !wdt_reg_data[2]) ? wdt_reg_data[4]  : stop_enable	;
             			wait_enable     <= (!wdt_enable || !wdt_reg_data[2]) ? wdt_reg_data[3]  : wait_enable	;
             			wdt_enable      <= wdt_protect  ?  wdt_enable 	     : wdt_reg_data[2]	;
             			wdt_protect     <= wdt_lock 	?  wdt_protect 	     : wdt_reg_data[1]	;
             			wdt_lock        <= wdt_lock 	|| wdt_reg_data[0]			;
			

			end
			2'b01://loading timeout limit
			begin
				timeout_limit  <= wdt_reg_data;
			end
			2'b10:
			begin
	     			service_wdt  <= (wdt_reg_data == SERVICE_WORD_0);
	     			reload_count <= service_wdt && (wdt_reg_data == SERVICE_WORD_1);
				//wdt_service_word_o <= 

			end
			default:
			begin
				reload_count <= 1'b0;
	     			wdt_event_r  <= 1'b0;

			end
		endcase*/
	       if(wdt_write_en_i && (wdt_reg_addr == WDT_CTRL))
	       begin
				wdt_event_r 	<= wdt_reg_data[8]	;
             			wdt_interrupt   <= wdt_reg_data[7:6]	;
             			debug_enable    <= (!wdt_enable || !wdt_reg_data[2]) ? wdt_reg_data[5]  : debug_enable	;
             			stop_enable     <= (!wdt_enable || !wdt_reg_data[2]) ? wdt_reg_data[4]  : stop_enable	;
             			wait_enable     <= (!wdt_enable || !wdt_reg_data[2]) ? wdt_reg_data[3]  : wait_enable	;
             			wdt_enable      <= wdt_protect  ?  wdt_enable 	     : wdt_reg_data[2]	;
             			wdt_protect     <= wdt_lock 	?  wdt_protect 	     : wdt_reg_data[1]	;
             			wdt_lock        <= wdt_lock 	|| wdt_reg_data[0]			;

	       end
	       else if(wdt_write_en_i && (wdt_reg_addr == WDT_TIMEOUT_REG))
	       begin
				timeout_limit  <= wdt_reg_data;

	       end
	       else if(wdt_write_en_i && (wdt_reg_addr == WDT_SERVICE_WORD))
	       begin
	     			service_wdt  <= (wdt_reg_data == SERVICE_WORD_0);
	     			reload_count <= service_wdt && (wdt_reg_data == SERVICE_WORD_1);

	       end
	end
end

assign wdt_ctrl_o = {16'd0,7'd0,wdt_event_r,wdt_interrupt,debug_enable,stop_enable,wait_enable,wdt_enable,wdt_protect,wdt_lock};
endmodule

//watch dog counter module

module WDT_COUNTER
//#(parameter 16 = 16)
(
input 			    wdt_clk		,
input 			    wdt_rst		,
output reg [31:0] 	    wdt_counter		, // Modulo Counter value
output reg                  wdt_reset_o		, // WDT Reset
output reg                  wdt_interrupt_o	, // WDT Interrupt Request
output reg                  clear_event		, // WDT status bit
input                       reload_count	, // Correct control words written
input                       wdt_event		, // Reset the WDT event register
input                       debug_mode_i	, // System DEBUG Mode
input                       debug_enable	, // Enable WDT in system debug mode
input                       wait_enable		, // Enable WDT in system wait mode
input                       wait_mode_i		, // System WAIT Mode
input                       stop_enable		, // Enable WDT in system stop mode
input                       stop_mode_i		, // System STOP Mode
input                       wdt_enable		, // Enable WDT Timout Counter
input                [ 1:0] wdt_interrupt_sel   , // WDT IRQ Enable/Value
input      [31:0] 	    timeout_value	  // WDT Counter initial value
);

wire 			    stop_counter	; // Enable WDT because of external inputs
wire 			    event_reset		; // Clear WDT event status bit
reg  			    wdt_irq_dec		; // WDT Interrupt Request Decode
reg  			    wdt_irq		; // WDT Interrupt Request
reg  			    reload_1		; // Resync register for commands crossing from bus_clk domain to cop_clk domain
reg  			    reload_2		; //

////////// to avoid race condition /////////
wire                reload_1_w;
wire                reload_2_w;

assign              reload_1_w = reload_1;
assign              reload_2_w = reload_2;

////////////////////////////////////////////
assign event_reset  = reload_count || wdt_event;//to reset the count
assign stop_counter = (debug_mode_i && debug_enable) || (wait_mode_i && wait_enable) || (stop_mode_i && stop_enable) || (!wdt_enable) ; // to stop the counter

//  Watchdog Timout Counter
always @(posedge wdt_clk or negedge wdt_rst)
begin
    if (!wdt_rst)
    begin
      wdt_counter  	<= {16'd0,{16{1'b1}}}		;
    end
    else if(reload_1_w)
    begin
      wdt_counter  	<= timeout_value	;
    end
    else if (!stop_counter)
    begin
      wdt_counter  	<= wdt_counter - 32'd1	;
    end
end

  //  wdt reset Output Register
always @(posedge wdt_clk or negedge wdt_rst)
begin
  if ( !wdt_rst )
  begin
    wdt_reset_o 	<= 1'b0			;
  end
  else if ( reload_1_w )
  begin
    wdt_reset_o 	<= 1'b0			;
  end
  else
  begin
    wdt_reset_o 	<= (wdt_counter == 0)	;
  end
end

  // Stage one of pulse strecher and resync
  always @(posedge wdt_clk or negedge wdt_rst)
  begin
    if ( !wdt_rst )
    begin
      reload_1 		<= 1'b0			;
    end
    else
    begin
      reload_1 		<= ( reload_count || !wdt_enable) || (reload_1_w && !reload_2_w);
    end
  end

  // Stage two pulse strecher and resync
  always @(posedge wdt_clk or negedge wdt_rst)
  begin
    if ( !wdt_rst )
    begin
      reload_2 		<= 1'b1			;
    end
    else
    begin
      reload_2 		<= reload_1_w		;
    end
  end



  // Decode WDT Interrupt Request
  always @*
    case (wdt_interrupt_sel) // synopsys parallel_case
       2'b01  : wdt_irq_dec 	= (wdt_counter <= 16'd16);
       2'b10  : wdt_irq_dec 	= (wdt_counter <= 16'd32);
       2'b11  : wdt_irq_dec 	= (wdt_counter <= 16'd64);
       default: wdt_irq_dec 	= 1'b0			 ;
    endcase

  //  Watchdog Interrupt and resync
  always @(posedge wdt_clk or negedge wdt_rst)
  begin
    if ( !wdt_rst )
      begin
        wdt_irq   	<= 1'b0		;
        wdt_interrupt_o <= 1'b0		;
      end
    else
      begin
        wdt_irq   	<= wdt_irq_dec  ;
        wdt_interrupt_o <= wdt_irq	;
      end
end

  //  Watchdog Status Bit
  always @(posedge wdt_clk or negedge wdt_rst)
    if ( !wdt_rst )
      clear_event 	<= 1'b0;
    else
      clear_event 	<= wdt_reset_o || (clear_event && !event_reset);



endmodule

/*module wdt_mmr_csr
(
input 				soc_clk				,
input 				soc_rst				,
input 				soc_mmr_write_en_i		,//store write enable
input  [15:0]			soc_mmr_write_addr_i		,//store write address
input  [31:0]			soc_mmr_write_data_i		,//store write data
output [31:0] 			wdt_counter_o			,
output [31:0] 			wdt_ctrl_o			,
output 				wdt_irq_o			
);
localparam WDT_CNT = 16'h801;
localparam WDT_CTRL = 16'h802;

reg [31:0] wdt_counter_r;
reg [31:0] wdt_ctrl_r	;
reg st1wto;
reg st2wto;
reg st1wto_r;
wire reset_counter;

always@(posedge soc_clk or negedge soc_rst)
begin
	if(!soc_rst)
	begin
		wdt_counter_r <= {22'd0,wdt_ctrl_r[13:4]};
	end
	else
	begin
		if(soc_mmr_write_en_i && (soc_mmr_write_addr_i == WDT_CNT))
		begin
			wdt_counter_r <= soc_mmr_write_data_i;
		end
		else if(reset_counter)
		begin
			wdt_counter_r <= {22'd0,wdt_ctrl_r[13:4]};
		end
		else if(wdt_ctrl_r[0])
		begin
			wdt_counter_r <= wdt_counter_r - 32'd1;
		end
	end
end

always@(posedge soc_clk or negedge soc_rst)
begin
	if(!soc_rst)
	begin
		wdt_ctrl_r <= {32'h00000000,18'h00000,10'h3ff,4'h0};
	end
	else
	begin
		if(soc_mmr_write_en_i && (soc_mmr_write_addr_i == WDT_CTRL))
		begin
			wdt_ctrl_r <= soc_mmr_write_data_i ;
		end
		else 
		begin
			wdt_ctrl_r <= {32'd0,wdt_ctrl_r[13:4],st2wto,st1wto,wdt_ctrl_r[0]};
		end
	end

end
//assign st1wto = ((!st2wto) && (wdt_counter_r == 0)) ? 1'b1 : 1'b0 ;
//assign st2wto = ((st1wto) && (wdt_counter_r == 0)) ? 1'b1 : 1'b0;
always@(posedge soc_clk or negedge soc_rst)
begin
	if(!soc_rst)
	begin
		st1wto <= 1'b0;
		//st2wto <= 1'b0;
	end
	else
	begin
		if(soc_mmr_write_en_i && (soc_mmr_write_addr_i == WDT_CTRL))
		begin
			st1wto <= soc_mmr_write_data_i[2];
		end
		else if((!st2wto) && (wdt_counter_r == 0))
		begin
			st1wto <= 1'b1;
		end

	end
end

always@(posedge soc_clk or negedge soc_rst)
begin
	if(!soc_rst)
	begin
	//	st1wto <= 1'b0;
		st2wto <= 1'b0;
	end
	else
	begin
		if(soc_mmr_write_en_i && (soc_mmr_write_addr_i == WDT_CTRL))
		begin
			st2wto <= soc_mmr_write_data_i[3];
		end
		else if((st1wto) && (wdt_counter_r == 0))
		begin
			st2wto <= 1'b1;
		end

	end
end


assign wdt_counter_o = wdt_counter_r;
assign wdt_ctrl_o =  {32'h00000000,18'h00000,wdt_ctrl_r[13:4],wdt_ctrl_r[3:2],1'b0,wdt_ctrl_r[0]};


always@(posedge soc_clk or negedge soc_rst)
begin
	if(!soc_rst)
	begin
		st1wto_r <= 1'b0;
	end
	else
	begin
		st1wto_r <= st1wto;
	end
end

assign reset_counter =(st1wto & (!st1wto_r)) ? 1'b1 : 1'b0;

assign wdt_irq_o = (st1wto | st2wto );

endmodule*/

