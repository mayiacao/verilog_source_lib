// +FHDR============================================================================/
// Author       : huangjie
// Creat Time   : 2023/03/17 11:58:19
// File Name    : mem_ip.v
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
// mem_ip
//    |---
// 
`timescale 1ns/1ps

module mem_ip #
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
    parameter                           PA_DW   = 8                 ,    
    parameter                           PA_AW   = 10                ,
    parameter                           PB_DW   = 8                 ,  
    parameter                           BYTE_NUM = 8                , // It must be a multiple of PA_DW.
    parameter                           MEM_TYPE = "SDPRAM"         , //  "SDPRAM" or "TDPRAM"
    parameter                           BYTE_ENABLE  = "TRUE"       , //Must be >= 2
    parameter                           PAOREG_ENABLE  = "FALSE"    , //Must be >= 2  
    parameter                           PBOREG_ENABLE  = "FALSE"    , //Must be >= 2  
    parameter                           BLKMEM_EN = "TRUE"          ,

    parameter                           PB_AW = LOG2(PA_DW*(2**PA_AW) /PB_DW-1),   
    parameter                           PA_DEW = PA_DW/BYTE_NUM     ,  
    parameter                           PB_DEW = PB_DW/BYTE_NUM     ,      
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
// Port A
// --------------------------------------------------------------------------------- 
    input                               bram_ena                    , 
    input                  [PA_DEW-1:0] bram_wea                    , 
    input                   [PA_AW-1:0] bram_addra                  , 
    input                   [PA_DW-1:0] bram_dina                   , 
    output                  [PA_DW-1:0] bram_douta                  , 
// ---------------------------------------------------------------------------------
// Port B
// --------------------------------------------------------------------------------- 
    input                               bram_enb                    , 
    input                  [PB_DEW-1:0] bram_web                    , 
    input                   [PB_AW-1:0] bram_addrb                  , 
    input                   [PB_DW-1:0] bram_dinb                   , 
    output                  [PB_DW-1:0] bram_doutb                    
);



generate
if((FPGA_DEV == "XC_7S") || (FPGA_DEV == "XC_US") || (FPGA_DEV == "XC_USP"))
begin:xc_if
if(MEM_TYPE == "SDPRAM")
begin:xc_sdpram_if

localparam MEM_SIZE = PA_DW*(2**PA_AW);
//localparam MEM_PRIMITIVE = (BLKMEM_EN == "TRUE") ? 
//                           (((FPGA_DEV == "XCUS") || (FPGA_DEV == "XCUSP")) ? "ultra" : "block") :
//                           (BLKMEM_EN == "FALSE") ? "distributed" : "auto";
localparam MEM_PRIMITIVE = (BLKMEM_EN == "TRUE") ? "block" :
                           (BLKMEM_EN == "FALSE") ? "distributed" : "auto";     

localparam DW_BYTEA = (BYTE_ENABLE == "TRUE") ? BYTE_NUM : PA_DW;

localparam READ_LATENCY_B = (PBOREG_ENABLE == "TRUE") ? ((BLKMEM_EN == "TRUE") ? 2 : 1) : ((BLKMEM_EN == "TRUE") ? 1 : 0);

xpm_memory_sdpram # 
(

  // Common module parameters
    .MEMORY_SIZE                    (MEM_SIZE                   ), //positive integer
    .MEMORY_PRIMITIVE               (MEM_PRIMITIVE              ), //string; "auto", "distributed", "block" or "ultra";
    .CLOCKING_MODE                  ("independent_clock"        ), //string; "common_clock", "independent_clock" 
    .MEMORY_INIT_FILE               ("none"                     ), //string; "none" or "<filename>.mem" 
    .MEMORY_INIT_PARAM              (""                         ), //string;
    .USE_MEM_INIT                   (0                          ), //integer; 0,1
    .WAKEUP_TIME                    ("disable_sleep"            ), //string; "disable_sleep" or "use_sleep_pin" 
    .MESSAGE_CONTROL                (0                          ), //integer; 0,1
    .ECC_MODE                       ("no_ecc"                   ), //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
    .AUTO_SLEEP_TIME                (0                          ), //Do not Change

// Port A module parameters
    .WRITE_DATA_WIDTH_A             (PA_DW                      ), //positive integer
    .BYTE_WRITE_WIDTH_A             (DW_BYTEA                   ), //integer; 8, 9, or WRITE_DATA_WIDTH_A value
    .ADDR_WIDTH_A                   (PA_AW                      ), //positive integer

// Port B module parameters
    .READ_DATA_WIDTH_B              (PB_DW                      ), //positive integer
    .ADDR_WIDTH_B                   (PB_AW                      ), //positive integer
    .READ_RESET_VALUE_B             ("0"                        ), //string
    .READ_LATENCY_B                 (READ_LATENCY_B             ), //non-negative integer
    .WRITE_MODE_B                   ("read_first"               )  //string; "write_first"  "read_first"  "no_change" 
) 
u0_xpm_memory_sdpram
(
  // Common module ports
    .sleep                          (1'b0                       ), 

// Port A module ports
    .clka                           (clk_wr                     ), 
    .ena                            (bram_ena                   ), 
    .wea                            (bram_wea[PA_DEW-1:0]), 
    .addra                          (bram_addra[PA_AW-1:0]      ), 
    .dina                           (bram_dina[PA_DW-1:0]       ), 
    .injectsbiterra                 (1'b0                       ), 
    .injectdbiterra                 (1'b0                       ), 

// Port B module ports
    .clkb                           (clk_rd                     ), 
    .rstb                           (!rst_n                     ), 
    .enb                            (bram_enb                   ), 
    .regceb                         (1'b1                       ), 
    .addrb                          (bram_addrb[PB_AW-1:0]      ), 
    .doutb                          (bram_doutb[PA_DW-1:0]      ), 
    .sbiterrb                       (                           ), 
    .dbiterrb                       (                           )  
);

end
else if(MEM_TYPE == "TDPRAM")
begin:xc_tdpram_if

localparam MEM_SIZE = PA_DW*(2**PA_AW);
//localparam MEM_PRIMITIVE = (BLKMEM_EN == "TRUE") ? 
//                           (((FPGA_DEV == "XCUS") || (FPGA_DEV == "XCUSP")) ? "ultra" : "block") :
//                           (BLKMEM_EN == "FALSE") ? "distributed" : "auto";
localparam MEM_PRIMITIVE = (BLKMEM_EN == "TRUE") ? "block" :
                           (BLKMEM_EN == "FALSE") ? "distributed" : "auto";   
localparam DW_BYTEA = (BYTE_ENABLE == "TRUE") ? BYTE_NUM : PA_DW;
localparam DW_BYTEB = (BYTE_ENABLE == "TRUE") ? BYTE_NUM : PB_DW;

localparam READ_LATENCY_A = (PAOREG_ENABLE == "TRUE") ? ((BLKMEM_EN == "TRUE") ? 2 : 1) : ((BLKMEM_EN == "TRUE") ? 1 : 0);
localparam READ_LATENCY_B = (PBOREG_ENABLE == "TRUE") ? ((BLKMEM_EN == "TRUE") ? 2 : 1) : ((BLKMEM_EN == "TRUE") ? 1 : 0);

xpm_memory_tdpram # 
(
// Common module parameters
    .MEMORY_SIZE                    (MEM_SIZE                   ), //positive integer
    .MEMORY_PRIMITIVE               (MEM_PRIMITIVE              ), //string; "auto", "distributed", "block" or "ultra";
    .CLOCKING_MODE                  ("independent_clock"        ), //string; "common_clock", "independent_clock" 
    .MEMORY_INIT_FILE               ("none"                     ), //string; "none" or "<filename>.mem" 
    .MEMORY_INIT_PARAM              (""                         ), //string;
    .USE_MEM_INIT                   (0                          ), //integer; 0,1
    .WAKEUP_TIME                    ("disable_sleep"            ), //string; "disable_sleep" or "use_sleep_pin" 
    .MESSAGE_CONTROL                (0                          ), //integer; 0,1
    .ECC_MODE                       ("no_ecc"                   ), //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
    .AUTO_SLEEP_TIME                (0                          ), //Do not Change

// Port A module parameters
    .WRITE_DATA_WIDTH_A             (PA_DW                      ), //positive integer
    .READ_DATA_WIDTH_A              (PA_DW                      ), //positive integer
    .BYTE_WRITE_WIDTH_A             (DW_BYTEA                   ), //integer; 8, 9, or WRITE_DATA_WIDTH_A value
    .ADDR_WIDTH_A                   (PA_AW                      ), //positive integer
    .READ_RESET_VALUE_A             ("0"                        ), //string
    .READ_LATENCY_A                 (READ_LATENCY_A             ), //non-negative integer
    .WRITE_MODE_A                   ("read_first"               ), //string; "write_first", "read_first", "no_change" 

// Port B module parameters
    .WRITE_DATA_WIDTH_B             (PB_DW                      ), //positive integer
    .READ_DATA_WIDTH_B              (PB_DW                      ), //positive integer
    .BYTE_WRITE_WIDTH_B             (DW_BYTEB                   ), //integer; 8, 9, or WRITE_DATA_WIDTH_B value
    .ADDR_WIDTH_B                   (PB_AW                      ), //positive integer
    .READ_RESET_VALUE_B             ("0"                        ), //vector of READ_DATA_WIDTH_B bits
    .READ_LATENCY_B                 (READ_LATENCY_B             ), //non-negative integer
    .WRITE_MODE_B                   ("read_first"               )  //string; "write_first"  "read_first"  "no_change" 
) 
xpm_memory_tdpram_inst
(
  // Common module ports
    .sleep                          (1'b0                       ), 
// Port A module ports
    .clka                           (clk_wr                     ), 
    .rsta                           (!rst_n                     ), 
    .ena                            (bram_ena                   ), 
    .regcea                         (1'b1                       ), 
    .wea                            (bram_wea[PA_DEW-1:0]       ), 
    .addra                          (bram_addra[PA_AW-1:0]      ), 
    .dina                           (bram_dina[PA_DW-1:0]       ), 
    .injectsbiterra                 (1'b0                       ), 
    .injectdbiterra                 (1'b0                       ), 
    .douta                          (bram_douta[PA_DW-1:0]      ), 
    .sbiterra                       (                           ), 
    .dbiterra                       (                           ), 

// Port B module ports
    .clkb                           (clk_rd                     ), 
    .rstb                           (!rst_n                     ), 
    .enb                            (bram_enb                   ), 
    .regceb                         (1'b1                       ), 
    .web                            (bram_web[PB_DEW-1:0]       ), 
    .addrb                          (bram_addrb[PB_AW-1:0]      ), 
    .dinb                           (bram_dinb[PB_DW-1:0]       ), 
    .injectsbiterrb                 (1'b0                       ), 
    .injectdbiterrb                 (1'b0                       ), 
    .doutb                          (bram_doutb[PB_DW-1:0]      ), 
    .sbiterrb                       (                           ), 
    .dbiterrb                       (                           )  
);
end
end
else if(FPGA_DEV == "AT_C10LP") begin:c10lp_if

localparam OP_MODE =(MEM_TYPE == "SDPRAM") ? "DUAL_PORT" : (MEM_TYPE == "TDPRAM") ? "BIDIR_DUAL_PORT" : ""; 

altsyncram u0_altsyncram
(
    .clock0                         (clk_wr                     ), 
    .aclr0                          (!rst_n                     ), 
    .wren_a                         (bram_ena                   ), 
    .byteena_a                      (bram_wea[PA_DEW-1:0]), 
    .rden_a                         (1'b1                       ), 
    .address_a                      (bram_addra[PA_AW-1:0]      ), 
    .data_a                         (bram_dina[PA_DW-1:0]       ), 
    .q_a                            (bram_douta[PA_DW-1:0]      ), 
    .addressstall_a                 (1'b0                       ), 


    .clock1                         (clk_rd                     ), 
    .aclr1                          (!rst_n                     ), 
    .wren_b                         (bram_enb                   ), 
    .byteena_b                      (bram_web[PB_DEW-1:0]), 
    .rden_b                         (1'b1                       ), 
    .address_b                      (bram_addrb[PB_AW-1:0]      ), 
    .data_b                         (bram_dinb[PB_DW-1:0]       ), 
    .q_b                            (bram_doutb[PB_DW-1:0]      ), 
    .addressstall_b                 (1'b0                       ), 

    .clocken0                       (1'b1                       ), 
    .clocken1                       (1'b1                       ), 
    .clocken2                       (1'b1                       ), 
    .clocken3                       (1'b1                       ), 

    .eccstatus                      (                           )  
);
	
defparam u0_altsyncram.address_aclr_b = "NONE";
defparam u0_altsyncram.address_reg_b = "CLOCK1";
defparam u0_altsyncram.byte_size = BYTE_NUM;
defparam u0_altsyncram.clock_enable_input_a = "BYPASS";
defparam u0_altsyncram.clock_enable_input_b = "BYPASS";
defparam u0_altsyncram.clock_enable_output_b = "BYPASS";
defparam u0_altsyncram.intended_device_family = "Cyclone 10 LP";
defparam u0_altsyncram.lpm_type = "altsyncram";
defparam u0_altsyncram.numwords_a = 2**PA_AW;
defparam u0_altsyncram.numwords_b = 2**PB_AW;
defparam u0_altsyncram.operation_mode = OP_MODE;
defparam u0_altsyncram.outdata_aclr_b = "NONE";
defparam u0_altsyncram.outdata_reg_b = "CLOCK1";
defparam u0_altsyncram.power_up_uninitialized = "FALSE";
defparam u0_altsyncram.rdcontrol_reg_b = "CLOCK1";
defparam u0_altsyncram.widthad_a = PA_AW;
defparam u0_altsyncram.widthad_b = PB_AW;
defparam u0_altsyncram.width_a = PA_DW;
defparam u0_altsyncram.width_b = PB_DW;
defparam u0_altsyncram.width_byteena_a = LOG2(PA_DEW - 1);

end
else begin: other_if

tdpram_v01 #
(
    .PA_DW                          (PA_DW                      ), // It must be a multiple of 8.
    .PA_AW                          (PA_AW                      ), // Must not be less than log2(PB_DW/PA_DW).
    .PB_DW                          (PB_DW                      ), // It must be a multiple of PA_DW.
    .BYTE_NUM                       (BYTE_NUM                   ), // It must be a multiple of PA_DW.
    .BYTE_ENABLE                    (BYTE_ENABLE                ), //Must be >= 2
    .PAOREG_ENABLE                  (PAOREG_ENABLE              ), //Must be >= 2  
    .PBOREG_ENABLE                  (PBOREG_ENABLE              ), //Must be >= 2  
    .PB_AW                          (PB_AW                      ), 
    .PA_DEW                         (PA_DEW                     ), 
    .PB_DEW                         (PB_DEW                     ), 
    .U_DLY                          (U_DLY                      )  // 
)
u_tdpram_v01
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_pa                         (clk_wr                     ), // (input )
    .clk_pb                         (clk_rd                     ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Port A Write Read
// ---------------------------------------------------------------------------------
    .pa_wr                          (bram_ena                   ), // (input )
    .pa_wea                         (bram_wea[PA_DEW-1:0]       ), // (input )
    .pa_addr                        (bram_addra[PA_AW-1:0]      ), // (input )
    .pa_wdata                       (bram_dina[PA_DW-1:0]       ), // (input )
    .pa_rdata                       (bram_douta[PA_DW-1:0]      ), // (output)
// ---------------------------------------------------------------------------------
// Port B Write Read
// ---------------------------------------------------------------------------------
    .pb_wr                          (bram_enb                   ), // (input )
    .pb_wea                         (bram_web[PB_DEW-1:0]       ), // (input )
    .pb_addr                        (bram_addrb[PB_AW-1:0]      ), // (input )
    .pb_wdata                       (bram_dinb[PB_DW-1:0]       ), // (input )
    .pb_rdata                       (bram_doutb[PB_DW-1:0]      )  // (output)
);

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


