// +FHDR============================================================================/
// Author       : huangjie
// Creat Time   : 2023/03/16 10:29:16
// File Name    : asfifo_ip.v
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
// asfifo_ip
//    |---
// 
`timescale 1ns/1ps

module asfifo_ip #
(
// The constant FPGA_DEV allows values such as
//  "XC7S" -> xinlinx 7series
//  "XCUS" -> xinlinx ultrascale
//  "XCUSP" -> xinlinx ultrascale pluse
//  "AT_C10LP" -> altera Cyclone 10LP
//  "EFX_TI" -> elitestek Titanium
//  "EFX_T" -> elitestek Trion
//  "MT_PF" -> Microchip Polarfire
    parameter                           FPGA_DEV = "XC_7S"          ,    

    parameter                           DW_WR  = 8                  ,    
    parameter                           AW_WR   = 10                ,
    parameter                           DW_RD  = 8                  ,    
    parameter                           TRSH_FULL = 15              ,
    parameter                           BLKMEM_EN = "TRUE"          , // "TRUE" or "FALSE"
    parameter                           RD_AS_ACK = "TRUE"          , // "TRUE" OR "FALSE"

    parameter                           DEPTH_WR = 2**AW_WR         ,
    parameter                           DEPTH_RD = DEPTH_WR*DW_WR/DW_RD,
    parameter                           AW_RD    = LOG2(DEPTH_RD-1) ,
    parameter                           U_DLY = 1                     // 
)
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    input                               clk_wr                      , 
    input                               clk_rd                      , 
    input                               rst_n                       , 
// ---------------------------------------------------------------------------------
// Write
// --------------------------------------------------------------------------------- 
    input                               wren                        , 
    input                   [DW_WR-1:0] wrdata                      , 

    output                              full                        , 
    output                              wrpfull                     , 
    output                              wrready                     , 
    output                  [AW_WR-1:0] wrcnt                       , 
// ---------------------------------------------------------------------------------
// AXI
// --------------------------------------------------------------------------------- 
    input                               rden                        , 
    output                  [DW_RD-1:0] rddata                      , 
    output                              empty                       , 
    output                  [AW_RD-1:0] rdcnt                         
);

generate
if((FPGA_DEV == "XC_7S") || (FPGA_DEV == "XC_US") || (FPGA_DEV == "XC_USP")) begin:xc_if

localparam FIFO_MEMORY_TYPE = (BLKMEM_EN == "FALSE") ? "distributed" : (BLKMEM_EN == "TRUE") ? "block" : "auto";
localparam READ_MODE = (RD_AS_ACK == "TRUE") ? "fwft" : "std";


wire                          [AW_WR:0] wrcount                     ; 
wire                          [AW_RD:0] rdcount                     ; 

xpm_fifo_async #
(

    .FIFO_MEMORY_TYPE               (FIFO_MEMORY_TYPE           ), //string; "auto", "block", or "distributed";
    .ECC_MODE                       ("no_ecc"                   ), //string; "no_ecc" or "en_ecc";
    .RELATED_CLOCKS                 (0                          ), //positive integer; 0 or 1
    .FIFO_WRITE_DEPTH               (DEPTH_WR                   ), //positive integer
    .WRITE_DATA_WIDTH               (DW_WR                      ), //positive integer
    .WR_DATA_COUNT_WIDTH            (AW_WR+1                    ), //positive integer
    .PROG_FULL_THRESH               (TRSH_FULL                  ), //positive integer
    .FULL_RESET_VALUE               (0                          ), //positive integer; 0 or 1
    .READ_MODE                      (READ_MODE                  ), //string; "std" or "fwft";
    .FIFO_READ_LATENCY              (0                          ), //positive integer;
    .READ_DATA_WIDTH                (DW_RD                      ), //positive integer
    .RD_DATA_COUNT_WIDTH            (AW_RD+1                    ), //positive integer
    .PROG_EMPTY_THRESH              (10                         ), //positive integer
    .DOUT_RESET_VALUE               ("0"                        ), //string
    .CDC_SYNC_STAGES                (2                          ), //positive integer
    .WAKEUP_TIME                    (0                          )  //positive integer; 0 or 2;
) 
u_xpm_fifo_async 
(
    .rst                            (!rst_n                     ), 
    .wr_clk                         (clk_wr                     ), 
    .wr_en                          (wren                       ), 
    .din                            (wrdata[DW_WR-1:0]          ), 
    .full                           (full                       ), 
    .overflow                       (                           ), 
    .wr_rst_busy                    (                           ), 
    .rd_clk                         (clk_rd                     ), 
    .rd_en                          (rden                       ), 
    .dout                           (rddata[DW_RD-1:0]          ), 
    .empty                          (empty                      ), 
    .underflow                      (                           ), 
    .rd_rst_busy                    (                           ), 
    .prog_full                      (wrpfull                    ), 
    .wr_data_count                  (wrcount[AW_WR:0]           ), 
    .prog_empty                     (                           ), 
    .rd_data_count                  (rdcount[AW_RD:0]           ), 
    .sleep                          (1'b0                       ), 
    .injectsbiterr                  (1'b0                       ), 
    .injectdbiterr                  (1'b0                       ), 
    .sbiterr                        (                           ), 
    .dbiterr                        (                           )  
);

assign wrcnt = wrcount[AW_WR-1:0];
assign rdcnt = rdcount[AW_RD-1:0];

end
else if(FPGA_DEV == "AT_C10LP") begin:atc10lp_if
if(DW_WR == DW_RD) begin:equal_if

localparam DEV_FAMILY = (FPGA_DEV == "AT_C10LP") ? "Cyclone 10 LP" : "";
localparam SHOWAHEAD = (RD_AS_ACK == "TRUE")  ? "ON" : "OFF";

dcfifo u_dcfifo
(
    .aclr                           (!rst_n                     ), 
    .wrclk                          (clk_wr                     ), 
    .rdclk                          (clk_rd                     ), 
    .wrreq                          (wren                       ), 
    .data                           (wrdata[DW_WR-1:0]          ), 
    .wrfull                         (full                       ), 
    .wrusedw                        (wrcnt[AW_WR-1:0]           ), 

    .rdreq                          (rden                       ), 
    .q                              (rddata[DW_RD-1:0]          ), 
    .rdempty                        (empty                      ), 
    .rdusedw                        (rdcnt[AW_RD-1:0]           ), 

    .eccstatus                      (                           ), 
    .wrempty                        (                           ), 
    .rdfull                         (                           )  
);
defparam u_dcfifo.intended_device_family = DEV_FAMILY;
defparam u_dcfifo.lpm_numwords = DEPTH_WR;
defparam u_dcfifo.lpm_showahead = SHOWAHEAD;		
defparam u_dcfifo.lpm_type = "dcfifo";		
defparam u_dcfifo.lpm_width = DW_WR;		
defparam u_dcfifo.lpm_widthu = AW_WR;		
defparam u_dcfifo.overflow_checking = "ON";		
defparam u_dcfifo.rdsync_delaypipe = 4;		
defparam u_dcfifo.read_aclr_synch = "ON";		
defparam u_dcfifo.underflow_checking = "ON";		
defparam u_dcfifo.use_eab = "ON";		
defparam u_dcfifo.write_aclr_synch = "ON";		
defparam u_dcfifo.wrsync_delaypipe = 4;		
end
else begin:other_if

localparam DEV_FAMILY = (FPGA_DEV == "AT_C10LP") ? "Cyclone 10 LP" : "";
localparam SHOWAHEAD = (RD_AS_ACK == "TRUE")  ? "ON" : "OFF";

dcfifo_mixed_widths	u_dcfifo_mixed_widths
(
    .aclr                           (!rst_n                     ), 
    .wrclk                          (clk_wr                     ), 
    .rdclk                          (clk_rd                     ), 
    .wrreq                          (wren                       ), 
    .data                           (wrdata[DW_WR-1:0]          ), 
    .wrfull                         (full                       ), 
    .wrusedw                        (wrcnt[AW_WR-1:0]           ), 

    .rdreq                          (rden                       ), 
    .q                              (rddata[DW_RD-1:0]          ), 
    .rdempty                        (empty                      ), 
    .rdusedw                        (rdcnt[AW_RD-1:0]           ), 

    .eccstatus                      (                           ), 
    .rdfull                         (                           ), 
    .wrempty                        (                           )  
);

defparam u_dcfifo_mixed_widths.intended_device_family = DEV_FAMILY;
defparam u_dcfifo_mixed_widths.lpm_numwords = DEPTH_WR;
defparam u_dcfifo_mixed_widths.lpm_showahead = SHOWAHEAD;		//fwft
defparam u_dcfifo_mixed_widths.lpm_type = "dcfifo";		
defparam u_dcfifo_mixed_widths.lpm_width = DW_WR;		
defparam u_dcfifo_mixed_widths.lpm_widthu = AW_WR;		
defparam u_dcfifo_mixed_widths.lpm_widthu_r = DW_RD;		
defparam u_dcfifo_mixed_widths.lpm_width_r = AW_RD;
defparam u_dcfifo_mixed_widths.overflow_checking = "ON";		
defparam u_dcfifo_mixed_widths.rdsync_delaypipe = 4;		
defparam u_dcfifo_mixed_widths.read_aclr_synch = "ON";		
defparam u_dcfifo_mixed_widths.underflow_checking = "ON";		
defparam u_dcfifo_mixed_widths.use_eab = "ON";		
defparam u_dcfifo_mixed_widths.write_aclr_synch = "ON";		
defparam u_dcfifo_mixed_widths.wrsync_delaypipe = 4;		

end

assign wrpfull = wrcnt > TRSH_FULL ? 1'd1 : 1'd0;

end
else if((FPGA_DEV == "EFX_TI") || (FPGA_DEV == "EFX_T")) begin :efx_if

wire                        [AW_WR-1:0] prog_data                   ; 
assign prog_data = TRSH_FULL;

asfifo_efx #
(
    .FPGA_DEV                       (FPGA_DEV                   ), 
    .PA_DW                          (DW_WR                      ), // It must be a multiple of 8.
    .PA_AW                          (AW_WR                      ), // Must not be less than log2(PB_DW/PA_DW).
    .PB_DW                          (DW_RD                      ), // It must be a multiple of PA_DW.
    .RD_AS_ACK                      (RD_AS_ACK                  ), // "TRUE" OR "FALSE"
    .PIPLI_STAGE                    (2                          ), //Must be >= 2  
    .PA_DEPTH                       (DEPTH_WR                   ), 
    .PB_AW                          (AW_RD                      ), 
    .U_DLY                          (U_DLY                      )  // 
)
u_asfifo_efx
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_wr                         (clk_wr                     ), // (input )
    .clk_rd                         (clk_rd                     ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Write Control & Status
// ---------------------------------------------------------------------------------
    .wr_en                          (wren                       ), // (input )
    .wr_data                        (wrdata                     ), // (input )
    .prog_data                      (prog_data                  ), // (input )
    .wr_cnt                         (wrcnt                      ), // (output)
    .full                           (full                       ), // (output)
    .pfull                          (wrpfull                    ), // (output)
// ---------------------------------------------------------------------------------
// Read Control & Status
// ---------------------------------------------------------------------------------
    .rd_en                          (rden                       ), // (input )
    .rd_data                        (rddata                     ), // (output)
    .rd_cnt                         (rdcnt                      ), // (output)
    .empty                          (empty                      ), // (output)
    .aempty                         (                           )  // (output)
);
end
else begin:dev_other_if

wire                        [AW_WR-1:0] prog_data                   ; 
assign prog_data = TRSH_FULL;

asfifo_v02 #
(
    .PA_DW                          (DW_WR                      ), // It must be a multiple of 8.
    .PA_AW                          (AW_WR                      ), // Must not be less than log2(PB_DW/PA_DW).
    .PB_DW                          (DW_RD                      ), // It must be a multiple of PA_DW.
    .RD_AS_ACK                      (RD_AS_ACK                  ), // "TRUE" OR "FALSE"
    .PIPLI_STAGE                    (2                          ), //Must be >= 2  
    .PA_DEPTH                       (DEPTH_WR                   ), 
    .PB_AW                          (AW_RD                      ), 
    .U_DLY                          (U_DLY                      )  // 
)
u_asfifo_v02
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_wr                         (clk_wr                     ), // (input )
    .clk_rd                         (clk_rd                     ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Write Control & Status
// ---------------------------------------------------------------------------------
    .wr_en                          (wr_en                      ), // (input )
    .wr_data                        (wrdata                     ), // (input )
    .prog_data                      (prog_data                  ), // (input )
    .wr_cnt                         (wrcnt                      ), // (output)
    .full                           (full                       ), // (output)
    .pfull                          (wrpfull                    ), // (output)
// ---------------------------------------------------------------------------------
// Read Control & Status
// ---------------------------------------------------------------------------------
    .rd_en                          (rden                       ), // (input )
    .rd_data                        (rddata                     ), // (output)
    .rd_cnt                         (rdcnt                      ), // (output)
    .empty                          (empty                      ), // (output)
    .aempty                         (                           )  // (output)
);    

end

endgenerate

assign wrready = ~wrpfull;

function integer LOG2 ;
input integer d;
begin
    LOG2 = 1;
    while((2**LOG2-1) < d)
        LOG2 = LOG2 + 1;
end
endfunction

endmodule

