`timescale 1ns / 1ps
//output multiplexer for software read 
//read access through load instruction

module soc_mmr_op_mux
/*#( 
parameter MMR_CTL_ADDR 		= 0 ,			
parameter MMR_ATTR_ADDR		= 0 ,	
parameter MMR_IE_ADDR  		= 0 ,	
parameter MMR_IP_ADDR 		= 0 ,
parameter MMR_EOI_ADDR		= 0 ,	
parameter MMR_ACK_ADDR		= 0 ,	
parameter MMR_CFG_ADDR		= 0 ,	
parameter MMR_INFO_ADDR		= 0 ,	
parameter MMR_NXTP_ADDR		= 0 	
)*/

(
input 	[7 :0] 			soc_ack_int_id_i	,	
input 	[7 :0]   		soc_eoi_i  		, 
input 	[7 :0]   		soc_cfg_i   		,
input 	[31:0] 			soc_info_i  		,
input 	[7 :0]			soc_nxtp_i  		,
input 	[31:0]			irq0_ctrl_i 		,
input 	[31:0]			irq1_ctrl_i 		,
input 	[31:0]			irq2_ctrl_i 		,
input 	[31:0]			irq3_ctrl_i 		,
input 	[31:0]			irq4_ctrl_i 		,
input 	[31:0]			irq5_ctrl_i 		,
input 	[31:0]			irq6_ctrl_i 		,
input 	[31:0]			irq7_ctrl_i 		,
input 	[31:0]			irq8_ctrl_i 		,
input 	[31:0]			irq9_ctrl_i 		,
input 	[31:0]			irq10_ctrl_i		,	
input 	[31:0]			irq11_ctrl_i		,	
input 	[31:0]			irq12_ctrl_i		,	
input 	[31:0]			irq13_ctrl_i		,	
input 	[31:0]			irq14_ctrl_i		,	
input 	[31:0]			irq15_ctrl_i		,	
//input 	[31:0]			irq16_ctrl_i		,	
//input 	[31:0]			irq17_ctrl_i		,	
//input 	[31:0]			irq18_ctrl_i		,	
//input 	[31:0]			irq19_ctrl_i		,	
//input 	[31:0]			irq20_ctrl_i		,	
//input 	[31:0]			irq21_ctrl_i		,	
//input 	[31:0]			irq22_ctrl_i		,	
//input 	[31:0]			irq23_ctrl_i		,	
//input 	[31:0]			irq24_ctrl_i		,	
//input 	[31:0]			irq25_ctrl_i		,	
//input 	[31:0]			irq26_ctrl_i		,	
//input 	[31:0]			irq27_ctrl_i		,	
//input 	[31:0]			irq28_ctrl_i		,	
//input 	[31:0]			irq29_ctrl_i		,	
//input 	[31:0]			irq30_ctrl_i		,	
//input 	[31:0]			irq31_ctrl_i		,	
//input 	[31:0]			irq32_ctrl_i		,	
//input 	[31:0]			irq33_ctrl_i		,	
//input 	[31:0]			irq34_ctrl_i		,	
//input 	[31:0]			irq35_ctrl_i		,	
//input 	[31:0]			irq36_ctrl_i		,	
//input 	[31:0]			irq37_ctrl_i		,	
//input 	[31:0]			irq38_ctrl_i		,	
//input 	[31:0]			irq39_ctrl_i		,	
//input 	[31:0]			irq40_ctrl_i		,	
//input 	[31:0]			irq41_ctrl_i		,	
//input 	[31:0]			irq42_ctrl_i		,	
//input 	[31:0]			irq43_ctrl_i		,	
//input 	[31:0]			irq44_ctrl_i		,	
//input 	[31:0]			irq45_ctrl_i		,	
//input 	[31:0]			irq46_ctrl_i		,	
//input 	[31:0]			irq47_ctrl_i		,
input 				soc_mmr_read_en_i	,
input 	[15:0] 			soc_mmr_read_addr_i	,
input 				soc_ack_read_valid	,//from program control (processor core)
output  [31 :0] 		soc_mmr_read_data_o	,
output  [7 :0] 			soc_ack_int_id_o	, //to program control(processor core)
input [31:0] 			wdt_counter_i		,
  input [31:0] 			wdt_ctrl_i,
  input [31:0] wdt_timeout_reg_i

);
  
  reg [31:0]  soc_mmr_read_data_r;

assign soc_ack_int_id_o = soc_ack_read_valid ? soc_ack_int_id_i : 8'd0;

always@(*)
begin
case(soc_mmr_read_addr_i[15:0])
16'h1000:soc_mmr_read_data_r = {24'd0,irq0_ctrl_i[7 : 0]};	
16'h1001:soc_mmr_read_data_r = {24'd0,irq0_ctrl_i[15: 8]};      
16'h1002:soc_mmr_read_data_r = {24'd0,irq0_ctrl_i[23:16]};      
16'h1003:soc_mmr_read_data_r = {24'd0,irq0_ctrl_i[31:24]};
16'h1004:soc_mmr_read_data_r = {24'd0,irq1_ctrl_i[7 : 0]};      
16'h1005:soc_mmr_read_data_r = {24'd0,irq1_ctrl_i[15: 8]};      
16'h1006:soc_mmr_read_data_r = {24'd0,irq1_ctrl_i[23:16]};      
16'h1007:soc_mmr_read_data_r = {24'd0,irq1_ctrl_i[31:24]};
16'h1008:soc_mmr_read_data_r = {24'd0,irq2_ctrl_i[7 : 0]};      
16'h1009:soc_mmr_read_data_r = {24'd0,irq2_ctrl_i[15: 8]};      
16'h100A:soc_mmr_read_data_r = {24'd0,irq2_ctrl_i[23:16]};      
16'h100B:soc_mmr_read_data_r = {24'd0,irq2_ctrl_i[31:24]};
16'h100c:soc_mmr_read_data_r = {24'd0,irq3_ctrl_i[7 : 0]};      
16'h100D:soc_mmr_read_data_r = {24'd0,irq3_ctrl_i[15: 8]};      
16'h100E:soc_mmr_read_data_r = {24'd0,irq3_ctrl_i[23:16]};      
16'h100F:soc_mmr_read_data_r = {24'd0,irq3_ctrl_i[31:24]};
16'h1010:soc_mmr_read_data_r = {24'd0,irq4_ctrl_i[7 : 0]};      
16'h1011:soc_mmr_read_data_r = {24'd0,irq4_ctrl_i[15: 8]};      
16'h1012:soc_mmr_read_data_r = {24'd0,irq4_ctrl_i[23:16]};      
16'h1013:soc_mmr_read_data_r = {24'd0,irq4_ctrl_i[31:24]};
16'h1014:soc_mmr_read_data_r = {24'd0,irq5_ctrl_i[7 : 0]};      
16'h1015:soc_mmr_read_data_r = {24'd0,irq5_ctrl_i[15: 8]};      
16'h1016:soc_mmr_read_data_r = {24'd0,irq5_ctrl_i[23:16]};      
16'h1017:soc_mmr_read_data_r = {24'd0,irq5_ctrl_i[31:24]};
16'h1018:soc_mmr_read_data_r = {24'd0,irq6_ctrl_i[7 : 0]};      
16'h1019:soc_mmr_read_data_r = {24'd0,irq6_ctrl_i[15: 8]};      
16'h101A:soc_mmr_read_data_r = {24'd0,irq6_ctrl_i[23:16]};      
16'h101B:soc_mmr_read_data_r = {24'd0,irq6_ctrl_i[31:24]};
16'h101c:soc_mmr_read_data_r = {24'd0,irq7_ctrl_i[7 : 0]};      
16'h101D:soc_mmr_read_data_r = {24'd0,irq7_ctrl_i[15: 8]};      
16'h101E:soc_mmr_read_data_r = {24'd0,irq7_ctrl_i[23:16]};      
16'h101F:soc_mmr_read_data_r = {24'd0,irq7_ctrl_i[31:24]};
16'h1020:soc_mmr_read_data_r = {24'd0,irq8_ctrl_i[7 : 0]};      
16'h1021:soc_mmr_read_data_r = {24'd0,irq8_ctrl_i[15: 8]};      
16'h1022:soc_mmr_read_data_r = {24'd0,irq8_ctrl_i[23:16]};      
16'h1023:soc_mmr_read_data_r = {24'd0,irq8_ctrl_i[31:24]};
16'h1024:soc_mmr_read_data_r = {24'd0,irq9_ctrl_i[7 : 0]};      
16'h1025:soc_mmr_read_data_r = {24'd0,irq9_ctrl_i[15: 8]};      
16'h1026:soc_mmr_read_data_r = {24'd0,irq9_ctrl_i[23:16]};      
16'h1027:soc_mmr_read_data_r = {24'd0,irq9_ctrl_i[31:24]};
16'h1028:soc_mmr_read_data_r = {24'd0,irq10_ctrl_i[7 : 0]};	
16'h1029:soc_mmr_read_data_r = {24'd0,irq10_ctrl_i[15: 8]};	
16'h102A:soc_mmr_read_data_r = {24'd0,irq10_ctrl_i[23:16]};	
16'h102B:soc_mmr_read_data_r = {24'd0,irq10_ctrl_i[31:24]};
16'h102c:soc_mmr_read_data_r = {24'd0,irq11_ctrl_i[7 : 0]};	
16'h102D:soc_mmr_read_data_r = {24'd0,irq11_ctrl_i[15: 8]};	
16'h102E:soc_mmr_read_data_r = {24'd0,irq11_ctrl_i[23:16]};	
16'h102F:soc_mmr_read_data_r = {24'd0,irq11_ctrl_i[31:24]};
16'h1030:soc_mmr_read_data_r = {24'd0,irq12_ctrl_i[7 : 0]};	
16'h1031:soc_mmr_read_data_r = {24'd0,irq12_ctrl_i[15: 8]};	
16'h1032:soc_mmr_read_data_r = {24'd0,irq12_ctrl_i[23:16]};	
16'h1033:soc_mmr_read_data_r = {24'd0,irq12_ctrl_i[31:24]};
16'h1034:soc_mmr_read_data_r = {24'd0,irq13_ctrl_i[7 : 0]};	
16'h1035:soc_mmr_read_data_r = {24'd0,irq13_ctrl_i[15: 8]};	
16'h1036:soc_mmr_read_data_r = {24'd0,irq13_ctrl_i[23:16]};	
16'h1037:soc_mmr_read_data_r = {24'd0,irq13_ctrl_i[31:24]};
16'h1038:soc_mmr_read_data_r = {24'd0,irq14_ctrl_i[7 : 0]};	
16'h1039:soc_mmr_read_data_r = {24'd0,irq14_ctrl_i[15: 8]};	
16'h103A:soc_mmr_read_data_r = {24'd0,irq14_ctrl_i[23:16]};	
16'h103B:soc_mmr_read_data_r = {24'd0,irq14_ctrl_i[31:24]};
16'h103c:soc_mmr_read_data_r = {24'd0,irq15_ctrl_i[7 : 0]};	
16'h103D:soc_mmr_read_data_r = {24'd0,irq15_ctrl_i[15: 8]};	
16'h103E:soc_mmr_read_data_r = {24'd0,irq15_ctrl_i[23:16]};	
16'h103F:soc_mmr_read_data_r = {24'd0,irq15_ctrl_i[31:24]};
/*16'h1040:soc_mmr_read_data_r = {24'd0,irq16_ctrl_i[7 : 0]};	
16'h1041:soc_mmr_read_data_r = {24'd0,irq16_ctrl_i[15: 8]};	
16'h1042:soc_mmr_read_data_r = {24'd0,irq16_ctrl_i[23:16]};	
16'h1043:soc_mmr_read_data_r = {24'd0,irq16_ctrl_i[31:24]};
16'h1044:soc_mmr_read_data_r = {24'd0,irq17_ctrl_i[7 : 0]};	
16'h1045:soc_mmr_read_data_r = {24'd0,irq17_ctrl_i[15: 8]};	
16'h1046:soc_mmr_read_data_r = {24'd0,irq17_ctrl_i[23:16]};	
16'h1047:soc_mmr_read_data_r = {24'd0,irq17_ctrl_i[31:24]};
16'h1048:soc_mmr_read_data_r = {24'd0,irq18_ctrl_i[7 : 0]};	
16'h1049:soc_mmr_read_data_r = {24'd0,irq18_ctrl_i[15: 8]};	
16'h104A:soc_mmr_read_data_r = {24'd0,irq18_ctrl_i[23:16]};	
16'h104B:soc_mmr_read_data_r = {24'd0,irq18_ctrl_i[31:24]};
16'h104c:soc_mmr_read_data_r = {24'd0,irq19_ctrl_i[7 : 0]};	
16'h104D:soc_mmr_read_data_r = {24'd0,irq19_ctrl_i[15: 8]};	
16'h104E:soc_mmr_read_data_r = {24'd0,irq19_ctrl_i[23:16]};	
16'h104F:soc_mmr_read_data_r = {24'd0,irq19_ctrl_i[31:24]};
16'h1050:soc_mmr_read_data_r = {24'd0,irq20_ctrl_i[7 : 0]};	
16'h1051:soc_mmr_read_data_r = {24'd0,irq20_ctrl_i[15: 8]};	
16'h1052:soc_mmr_read_data_r = {24'd0,irq20_ctrl_i[23:16]};	
16'h1053:soc_mmr_read_data_r = {24'd0,irq20_ctrl_i[31:24]};
16'h1054:soc_mmr_read_data_r = {24'd0,irq21_ctrl_i[7 : 0]};	
16'h1055:soc_mmr_read_data_r = {24'd0,irq21_ctrl_i[15: 8]};	
16'h1056:soc_mmr_read_data_r = {24'd0,irq21_ctrl_i[23:16]};	
16'h1057:soc_mmr_read_data_r = {24'd0,irq21_ctrl_i[31:24]};
16'h1058:soc_mmr_read_data_r = {24'd0,irq22_ctrl_i[7 : 0]};	
16'h1059:soc_mmr_read_data_r = {24'd0,irq22_ctrl_i[15: 8]};	
16'h105A:soc_mmr_read_data_r = {24'd0,irq22_ctrl_i[23:16]};	
16'h105B:soc_mmr_read_data_r = {24'd0,irq22_ctrl_i[31:24]};
16'h105c:soc_mmr_read_data_r = {24'd0,irq23_ctrl_i[7 : 0]};	
16'h105D:soc_mmr_read_data_r = {24'd0,irq23_ctrl_i[15: 8]};	
16'h105E:soc_mmr_read_data_r = {24'd0,irq23_ctrl_i[23:16]};	
16'h105F:soc_mmr_read_data_r = {24'd0,irq23_ctrl_i[31:24]};
16'h1060:soc_mmr_read_data_r = {24'd0,irq24_ctrl_i[7 : 0]};	
16'h1061:soc_mmr_read_data_r = {24'd0,irq24_ctrl_i[15: 8]};	
16'h1062:soc_mmr_read_data_r = {24'd0,irq24_ctrl_i[23:16]};	
16'h1063:soc_mmr_read_data_r = {24'd0,irq24_ctrl_i[31:24]};
16'h1064:soc_mmr_read_data_r = {24'd0,irq25_ctrl_i[7 : 0]};	
16'h1065:soc_mmr_read_data_r = {24'd0,irq25_ctrl_i[15: 8]};	
16'h1066:soc_mmr_read_data_r = {24'd0,irq25_ctrl_i[23:16]};	
16'h1067:soc_mmr_read_data_r = {24'd0,irq25_ctrl_i[31:24]};
16'h1068:soc_mmr_read_data_r = {24'd0,irq26_ctrl_i[7 : 0]};	
16'h1069:soc_mmr_read_data_r = {24'd0,irq26_ctrl_i[15: 8]};	
16'h106A:soc_mmr_read_data_r = {24'd0,irq26_ctrl_i[23:16]};	
16'h106B:soc_mmr_read_data_r = {24'd0,irq26_ctrl_i[31:24]};
16'h106c:soc_mmr_read_data_r = {24'd0,irq27_ctrl_i[7 : 0]};	
16'h106D:soc_mmr_read_data_r = {24'd0,irq27_ctrl_i[15: 8]};	
16'h106E:soc_mmr_read_data_r = {24'd0,irq27_ctrl_i[23:16]};	
16'h106F:soc_mmr_read_data_r = {24'd0,irq27_ctrl_i[31:24]};
16'h1070:soc_mmr_read_data_r = {24'd0,irq28_ctrl_i[7 : 0]};	
16'h1071:soc_mmr_read_data_r = {24'd0,irq28_ctrl_i[15: 8]};	
16'h1072:soc_mmr_read_data_r = {24'd0,irq28_ctrl_i[23:16]};	
16'h1073:soc_mmr_read_data_r = {24'd0,irq28_ctrl_i[31:24]};
16'h1074:soc_mmr_read_data_r = {24'd0,irq29_ctrl_i[7 : 0]};	
16'h1075:soc_mmr_read_data_r = {24'd0,irq29_ctrl_i[15: 8]};	
16'h1076:soc_mmr_read_data_r = {24'd0,irq29_ctrl_i[23:16]};	
16'h1077:soc_mmr_read_data_r = {24'd0,irq29_ctrl_i[31:24]};
16'h1078:soc_mmr_read_data_r = {24'd0,irq30_ctrl_i[7 : 0]};	
16'h1079:soc_mmr_read_data_r = {24'd0,irq30_ctrl_i[15: 8]};	
16'h107A:soc_mmr_read_data_r = {24'd0,irq30_ctrl_i[23:16]};	
16'h107B:soc_mmr_read_data_r = {24'd0,irq30_ctrl_i[31:24]};
16'h107c:soc_mmr_read_data_r = {24'd0,irq31_ctrl_i[7 : 0]};	
16'h107D:soc_mmr_read_data_r = {24'd0,irq31_ctrl_i[15: 8]};	
16'h107E:soc_mmr_read_data_r = {24'd0,irq31_ctrl_i[23:16]};	
16'h107F:soc_mmr_read_data_r = {24'd0,irq31_ctrl_i[31:24]};
16'h1080:soc_mmr_read_data_r = {24'd0,irq32_ctrl_i[7 : 0]};	
16'h1081:soc_mmr_read_data_r = {24'd0,irq32_ctrl_i[15: 8]};	
16'h1082:soc_mmr_read_data_r = {24'd0,irq32_ctrl_i[23:16]};	
16'h1083:soc_mmr_read_data_r = {24'd0,irq32_ctrl_i[31:24]};
16'h1084:soc_mmr_read_data_r = {24'd0,irq33_ctrl_i[7 : 0]};	
16'h1085:soc_mmr_read_data_r = {24'd0,irq33_ctrl_i[15: 8]};	
16'h1086:soc_mmr_read_data_r = {24'd0,irq33_ctrl_i[23:16]};	
16'h1087:soc_mmr_read_data_r = {24'd0,irq33_ctrl_i[31:24]};
16'h1088:soc_mmr_read_data_r = {24'd0,irq34_ctrl_i[7 : 0]};	
16'h1089:soc_mmr_read_data_r = {24'd0,irq34_ctrl_i[15: 8]};	
16'h108A:soc_mmr_read_data_r = {24'd0,irq34_ctrl_i[23:16]};	
16'h108B:soc_mmr_read_data_r = {24'd0,irq34_ctrl_i[31:24]};
16'h108c:soc_mmr_read_data_r = {24'd0,irq35_ctrl_i[7 : 0]};	
16'h108D:soc_mmr_read_data_r = {24'd0,irq35_ctrl_i[15: 8]};	
16'h108E:soc_mmr_read_data_r = {24'd0,irq35_ctrl_i[23:16]};	
16'h108F:soc_mmr_read_data_r = {24'd0,irq35_ctrl_i[31:24]};
16'h1090:soc_mmr_read_data_r = {24'd0,irq36_ctrl_i[7 : 0]};	
16'h1091:soc_mmr_read_data_r = {24'd0,irq36_ctrl_i[15: 8]};	
16'h1092:soc_mmr_read_data_r = {24'd0,irq36_ctrl_i[23:16]};	
16'h1093:soc_mmr_read_data_r = {24'd0,irq36_ctrl_i[31:24]};
16'h1094:soc_mmr_read_data_r = {24'd0,irq37_ctrl_i[7 : 0]};	
16'h1095:soc_mmr_read_data_r = {24'd0,irq37_ctrl_i[15: 8]};	
16'h1096:soc_mmr_read_data_r = {24'd0,irq37_ctrl_i[23:16]};	
16'h1097:soc_mmr_read_data_r = {24'd0,irq37_ctrl_i[31:24]};
16'h1098:soc_mmr_read_data_r = {24'd0,irq38_ctrl_i[7 : 0]};	
16'h1099:soc_mmr_read_data_r = {24'd0,irq38_ctrl_i[15: 8]};	
16'h109A:soc_mmr_read_data_r = {24'd0,irq38_ctrl_i[23:16]};	
16'h109B:soc_mmr_read_data_r = {24'd0,irq38_ctrl_i[31:24]};
16'h109c:soc_mmr_read_data_r = {24'd0,irq39_ctrl_i[7 : 0]};	
16'h109D:soc_mmr_read_data_r = {24'd0,irq39_ctrl_i[15: 8]};	
16'h109E:soc_mmr_read_data_r = {24'd0,irq39_ctrl_i[23:16]};	
16'h109F:soc_mmr_read_data_r = {24'd0,irq39_ctrl_i[31:24]};
16'h10A0:soc_mmr_read_data_r = {24'd0,irq40_ctrl_i[7 : 0]};	
16'h10A1:soc_mmr_read_data_r = {24'd0,irq40_ctrl_i[15: 8]};	
16'h10A2:soc_mmr_read_data_r = {24'd0,irq40_ctrl_i[23:16]};	
16'h10A3:soc_mmr_read_data_r = {24'd0,irq40_ctrl_i[31:24]};
16'h10A4:soc_mmr_read_data_r = {24'd0,irq41_ctrl_i[7 : 0]};	
16'h10A5:soc_mmr_read_data_r = {24'd0,irq41_ctrl_i[15: 8]};	
16'h10A6:soc_mmr_read_data_r = {24'd0,irq41_ctrl_i[23:16]};	
16'h10A7:soc_mmr_read_data_r = {24'd0,irq41_ctrl_i[31:24]};
16'h10A8:soc_mmr_read_data_r = {24'd0,irq42_ctrl_i[7 : 0]};	
16'h10A9:soc_mmr_read_data_r = {24'd0,irq42_ctrl_i[15: 8]};	
16'h10AA:soc_mmr_read_data_r = {24'd0,irq42_ctrl_i[23:16]};	
16'h10AB:soc_mmr_read_data_r = {24'd0,irq42_ctrl_i[31:24]};
16'h10AC:soc_mmr_read_data_r = {24'd0,irq43_ctrl_i[7 : 0]};	
16'h10AD:soc_mmr_read_data_r = {24'd0,irq43_ctrl_i[15: 8]};	
16'h10AE:soc_mmr_read_data_r = {24'd0,irq43_ctrl_i[23:16]};	
16'h10AF:soc_mmr_read_data_r = {24'd0,irq43_ctrl_i[31:24]};
16'h10B0:soc_mmr_read_data_r = {24'd0,irq44_ctrl_i[7 : 0]};	
16'h10B1:soc_mmr_read_data_r = {24'd0,irq44_ctrl_i[15: 8]};	
16'h10B2:soc_mmr_read_data_r = {24'd0,irq44_ctrl_i[23:16]};	
16'h10B3:soc_mmr_read_data_r = {24'd0,irq44_ctrl_i[31:24]};
16'h10B4:soc_mmr_read_data_r = {24'd0,irq45_ctrl_i[7 : 0]};	
16'h10B5:soc_mmr_read_data_r = {24'd0,irq45_ctrl_i[15: 8]};	
16'h10B6:soc_mmr_read_data_r = {24'd0,irq45_ctrl_i[23:16]};	
16'h10B7:soc_mmr_read_data_r = {24'd0,irq45_ctrl_i[31:24]};
16'h10B8:soc_mmr_read_data_r = {24'd0,irq46_ctrl_i[7 : 0]};	
16'h10B9:soc_mmr_read_data_r = {24'd0,irq46_ctrl_i[15: 8]};	
16'h10BA:soc_mmr_read_data_r = {24'd0,irq46_ctrl_i[23:16]};	
16'h10BB:soc_mmr_read_data_r = {24'd0,irq46_ctrl_i[31:24]};
16'h10BC:soc_mmr_read_data_r = {24'd0,irq47_ctrl_i[7 : 0]};	
16'h10BD:soc_mmr_read_data_r = {24'd0,irq47_ctrl_i[15: 8]};	
16'h10BE:soc_mmr_read_data_r = {24'd0,irq47_ctrl_i[23:16]};	
16'h10BF:soc_mmr_read_data_r = {24'd0,irq47_ctrl_i[31:24]};*/
16'h0000:soc_mmr_read_data_r = {24'd0,soc_cfg_i[7:0]	      };   		
16'h0004:soc_mmr_read_data_r = {soc_info_i		        };  
16'h0800:soc_mmr_read_data_r = {24'd0,soc_nxtp_i[7:0]	        };  	
16'h0804:soc_mmr_read_data_r = {24'd0,soc_ack_int_id_i[7:0]	};	
16'h0808:soc_mmr_read_data_r = {24'd0,soc_eoi_i[7:0]	        };
16'h080c:soc_mmr_read_data_r = wdt_counter_i ;
16'h0810:soc_mmr_read_data_r = wdt_ctrl_i ;
16'h0814:soc_mmr_read_data_r = wdt_timeout_reg_i;
default: soc_mmr_read_data_r = 0 ;	

endcase
end

assign soc_mmr_read_data_o = soc_mmr_read_en_i ? soc_mmr_read_data_r : 0 ;
endmodule
