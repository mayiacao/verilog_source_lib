// +FHDR============================================================================/
// Author       : hjie
// Creat Time   : 2024/11/01 12:20:59
// File Name    : tdpram_v01.v
// Module Ver   : Vx.x
//
//
// All Rights Reserved
//
// ---------------------------------------------------------------------------------/
//
// Modification History:
// V1.0         initial
//
// -FHDR============================================================================/
// 
// tdpram_v01
//    |---
// 
`timescale 1ns/1ps

module tdpram_v01 #
(
    parameter                           PA_DW  = 8                  , // It must be a multiple of 8.
    parameter                           PA_AW = 8                   , // Must not be less than log2(PB_DW/PA_DW).
    parameter                           PB_DW = 16                  , // It must be a multiple of PA_DW.
    parameter                           BYTE_NUM = 8                , // It must be a multiple of PA_DW.
    parameter                           BYTE_ENABLE  = "TRUE"       , //Must be >= 2
    parameter                           PAOREG_ENABLE  = "TRUE"       , //Must be >= 2  
    parameter                           PBOREG_ENABLE  = "TRUE"       , //Must be >= 2  
    parameter                           PA_DEPTH = 2**PA_AW         ,
    parameter                           PB_AW = LOG2(PA_DW*PA_DEPTH/PB_DW-1),   
    parameter                           PA_DEW = PA_DW/BYTE_NUM     ,  
    parameter                           PB_DEW = PB_DW/BYTE_NUM     ,      
    parameter                           U_DLY = 1                     // 
)
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    input                               clk_pa                      , 
    input                               clk_pb                      , 
    input                               rst_n                       ,
// ---------------------------------------------------------------------------------
// Port A Write Read
// ---------------------------------------------------------------------------------
    input                               pa_wr                       , 
    input                  [PA_DEW-1:0] pa_wea                      , 
    input                   [PA_AW-1:0] pa_addr                     , 
    input                   [PA_DW-1:0] pa_wdata                    , 
    output                  [PA_DW-1:0] pa_rdata                    , 
// ---------------------------------------------------------------------------------
// Port B Write Read
// ---------------------------------------------------------------------------------
    input                               pb_wr                       , 
    input                  [PA_DEW-1:0] pb_wea                      , 
    input                   [PB_AW-1:0] pb_addr                     , 
    input                   [PB_DW-1:0] pb_wdata                    , 
    output                  [PB_DW-1:0] pb_rdata                      
);

localparam SUB_ABDW = (PA_DW > PB_DW) ? PA_DW/PB_DW : PB_DW/PA_DW;
localparam SUB_ABAW = (PA_DW > PB_DW) ? PB_AW-PA_AW : PA_AW-PB_AW;
localparam MEM_DW = (PA_DW > PB_DW) ? PB_DW : PA_DW;
localparam MEM_DEW = (PA_DW > PB_DW) ? PB_DEW : PA_DEW;
localparam MEM_AW = (PA_DW > PB_DW) ? PA_AW : PB_AW;

reg                         [PA_DW-1:0] pa_rdata_dly0               ; 
reg                         [PA_DW-1:0] pa_rdata_dly1               ; 

reg                         [PB_DW-1:0] pb_rdata_dly0               ; 
reg                         [PB_DW-1:0] pb_rdata_dly1               ; 

genvar                                  i                           ;
genvar                                  j                           ;


generate
if(PA_DW > PB_DW) begin:amaxb_if
reg                      [SUB_ABDW-1:0] pb_subwren                  ; 
wire                        [PA_DW-1:0] pa_rddata_temp              ; 
wire                        [PA_DW-1:0] pb_rddata_temp              ; 

for(i=0;i<SUB_ABDW;i=i+1) begin:subamaxb_loop
always @ (*) begin
    if(pb_wr&pb_addr[SUB_ABAW-1:0] == i)
        pb_subwren[i] = 'd1;
    else
        pb_subwren[i] = 'd0;
end

for(j=0;j<MEM_DEW;j=j+1) begin:byteamaxb_loop

tdpram_core_v01 #
(
    .DW                             (BYTE_NUM                   ), // It must be a multiple of 8.
    .AW                             (MEM_AW                     ), // Must not be less than log2(PB_DW/PA_DW).
    .U_DLY                          (U_DLY                      )  // 
)
u0_tdpram_core_v01
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_pa                         (clk_pa                     ), // (input )
    .clk_pb                         (clk_pb                     ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Port A Write Read
// ---------------------------------------------------------------------------------
    .pa_wr                          (pa_wr & pa_wea[i*MEM_DEW+j]), // (input )
    .pa_addr                        (pa_addr[MEM_AW-1:0]        ), // (input )
    .pa_wdata                       (pa_wdata[(i*MEM_DEW+j)*BYTE_NUM+:BYTE_NUM]), // (input )
    .pa_rdata                       (pa_rddata_temp[(i*MEM_DEW+j)*BYTE_NUM+:BYTE_NUM]), // (output)
// ---------------------------------------------------------------------------------
// Port B Write Read
// ---------------------------------------------------------------------------------
    .pb_wr                          (pb_subwren[i] & pb_wea[j]  ), // (input )
    .pb_addr                        (pb_addr[SUB_ABAW+:MEM_AW]  ), // (input )
    .pb_wdata                       (pb_wdata[j*BYTE_NUM +:BYTE_NUM]), // (input )
    .pb_rdata                       (pb_rddata_temp[(i*MEM_DEW+j)*BYTE_NUM+:BYTE_NUM])  // (output)
);

end
end

always @(*) pa_rdata_dly0 = pa_rddata_temp;

always @ (posedge clk_pa or negedge rst_n) begin
    if(~rst_n) 
        pa_rdata_dly1 <= #U_DLY 'd0;
    else 
        pa_rdata_dly1 <= #U_DLY pa_rdata_dly0;
end

always @(*) pb_rdata_dly0 = pb_rddata_temp[pb_addr[SUB_ABAW-1:0]*MEM_DW+:MEM_DW];

always @ (posedge clk_pb or negedge rst_n) begin
    if(~rst_n) 
        pb_rdata_dly1 <= #U_DLY 'd0;
    else 
        pb_rdata_dly1 <= #U_DLY pb_rdata_dly0;
end

end
else if(PA_DW < PB_DW)begin:aminb_if
reg                      [SUB_ABDW-1:0] pa_subwren                  ; 
wire                        [PB_DW-1:0] pa_rddata_temp              ; 
wire                        [PB_DW-1:0] pb_rddata_temp              ; 

for(i=0;i<SUB_ABDW;i=i+1) begin:subaminb_loop
always @ (*) begin
    if(pa_wr&pa_addr[SUB_ABAW-1:0] == i)
        pa_subwren[i] = 'd1;
    else
        pa_subwren[i] = 'd0;
end

for(j=0;j<MEM_DEW;j=j+1) begin:byteaminb_loop

tdpram_core_v01 #
(
    .DW                             (BYTE_NUM                   ), // It must be a multiple of 8.
    .AW                             (MEM_AW                     ), // Must not be less than log2(PB_DW/PA_DW).
    .U_DLY                          (U_DLY                      )  // 
)
u1_tdpram_core_v01
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_pa                         (clk_pa                     ), // (input )
    .clk_pb                         (clk_pb                     ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Port A Write Read
// ---------------------------------------------------------------------------------
    .pa_wr                          (pa_subwren[i] & pa_wea[j]  ), // (input )
    .pa_addr                        (pa_addr[SUB_ABAW+:MEM_AW]  ), // (input )
    .pa_wdata                       (pa_wdata[j*BYTE_NUM +:BYTE_NUM]), // (input )
    .pa_rdata                       (pa_rddata_temp[(i*MEM_DEW+j)*BYTE_NUM+:BYTE_NUM]), // (output)
// ---------------------------------------------------------------------------------
// Port B Write Read
// ---------------------------------------------------------------------------------
    .pb_wr                          (pb_wr & pb_wea[i*MEM_DEW+j]), // (input )
    .pb_addr                        (pb_addr[MEM_AW-1:0]        ), // (input )
    .pb_wdata                       (pb_wdata[(i*MEM_DEW+j)*BYTE_NUM+:BYTE_NUM]), // (input )
    .pb_rdata                       (pb_rddata_temp[(i*MEM_DEW+j)*BYTE_NUM+:BYTE_NUM])  // (output)
);

end
end

always @(*) pa_rdata_dly0 = pa_rddata_temp[pa_addr[SUB_ABAW-1:0]*MEM_DW+:MEM_DW];

always @ (posedge clk_pa or negedge rst_n) begin
    if(~rst_n) 
        pa_rdata_dly1 <= #U_DLY 'd0;
    else 
        pa_rdata_dly1 <= #U_DLY pa_rdata_dly0;
end

always @(*) pb_rdata_dly0 = pb_rddata_temp;

always @ (posedge clk_pb or negedge rst_n) begin
    if(~rst_n) 
        pb_rdata_dly1 <= #U_DLY 'd0;
    else 
        pb_rdata_dly1 <= #U_DLY pb_rdata_dly0;
end

end
else begin :aeqb_if
wire                       [MEM_DW-1:0] pa_rddata_temp              ; 
wire                       [MEM_DW-1:0] pb_rddata_temp              ; 

for(j=0;j<MEM_DEW;j=j+1) begin:byte_loop
tdpram_core_v01 #
(
    .DW                             (BYTE_NUM                   ), // It must be a multiple of 8.
    .AW                             (MEM_AW                     ), // Must not be less than log2(PB_DW/PA_DW).
    .U_DLY                          (U_DLY                      )  // 
)
u2_tdpram_core_v01
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_pa                         (clk_pa                     ), // (input )
    .clk_pb                         (clk_pb                     ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Port A Write Read
// ---------------------------------------------------------------------------------
    .pa_wr                          (pa_wr & pa_wea[j]          ), // (input )
    .pa_addr                        (pa_addr                    ), // (input )
    .pa_wdata                       (pa_wdata[j*BYTE_NUM+:BYTE_NUM]), // (input )
    .pa_rdata                       (pa_rddata_temp[j*BYTE_NUM+:BYTE_NUM]), // (output)
// ---------------------------------------------------------------------------------
// Port B Write Read
// ---------------------------------------------------------------------------------
    .pb_wr                          (pb_wr & pb_wea[j]          ), // (input )
    .pb_addr                        (pb_addr                    ), // (input )
    .pb_wdata                       (pb_wdata[j*BYTE_NUM+:BYTE_NUM]), // (input )
    .pb_rdata                       (pb_rddata_temp[j*BYTE_NUM+:BYTE_NUM])  // (output)
);
end

always @(*) pa_rdata_dly0 = pa_rddata_temp;

always @ (posedge clk_pa or negedge rst_n) begin
    if(~rst_n) 
        pa_rdata_dly1 <= #U_DLY 'd0;
    else 
        pa_rdata_dly1 <= #U_DLY pa_rdata_dly0;
end

always @(*) pb_rdata_dly0 = pb_rddata_temp;

always @ (posedge clk_pb or negedge rst_n) begin
    if(~rst_n) 
        pb_rdata_dly1 <= #U_DLY 'd0;
    else 
        pb_rdata_dly1 <= #U_DLY pb_rdata_dly0;
end

end

if(PAOREG_ENABLE  == "TRUE" ) begin:paoreg_enif
assign pa_rdata = pa_rdata_dly1;
end
else begin:paoreg_disif
assign pa_rdata = pa_rdata_dly0;
end

if(PBOREG_ENABLE  == "TRUE" ) begin:pboreg_enif
assign pb_rdata = pb_rdata_dly1;
end
else begin:pboreg_disif
assign pb_rdata = pb_rdata_dly0;
end

endgenerate

function integer LOG2 ;
input integer d;
begin
    LOG2 = 1;
    while((2**LOG2-1) < d)
        LOG2 = LOG2 + 1;
end
endfunction

endmodule


