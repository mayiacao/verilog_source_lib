// +FHDR============================================================================/
// Author       : hjie
// Creat Time   : 2023/10/18 13:00:46
// File Name    : iic_m_warper.v
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
// iic_m_warper
//    |---
// 
`timescale 1ns/1ps

module iic_m_warper #
(
// The constant FPGA_DEV allows values such as
//  "XC7S" -> xinlinx 7series
//  "XCUS" -> xinlinx ultrascale
//  "XCUSP" -> xinlinx ultrascale pluse
    parameter                           FPGA_DEV = "XC_7S"          ,    
    parameter                           U_DLY = 1                     // 
)
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    input                               clk_sys                     ,
    input                               rst_n                       ,
//-----------------------------------------------------------------------------------
// LBE(EMIF) bus signals 
//----------------------------------------------------------------------------------- 
    input                               lbe_cs_n                    , // (input ) Chip Select, Active low      
    input                               lbe_wr_en                   , // (input ) Write Enable, Active high, Lasts 1 clock cycle 
    input                               lbe_rd_en                   , // (input ) Read  Enable, Active high, Lasts 1 clock cycle 
    input                        [15:0] lbe_addr                    , // (input ) Address
    input                        [31:0] lbe_wr_dat                  , // (input ) Write Data 
    output                       [31:0] lbe_rd_dat                  , // (output) Read Data 
//-----------------------------------------------------------------------------------
// IIC
//----------------------------------------------------------------------------------- 
    input                               iic_sck_i                   , 
    output                              iic_sck_o                   , 
    output                              iic_sck_t                   , 
    input                               iic_sda_i                   , 
    output                              iic_sda_o                   , 
    output                              iic_sda_t                     
);

wire                             [15:0] baud_rate                   ; 
wire                             [31:0] slave_ack_waittime          ; // (output)

wire                                    txfifo_rst                  ; // (output)
wire                                    txfifo_wr_en                ; // (output) 
wire                             [15:0] txfifo_wr_data              ; // (output)
wire                              [9:0] txfifo_data_cnt             ; // (input ) 
wire                                    txstart                     ; 

wire                             [15:0] txfifo_rd_data              ; 
wire                                    txfifo_empty                ; 

wire                                    rxfifo_rst                  ; // (output)
wire                                    rxfifo_rd_en                ; // (output)
wire                              [7:0] rxfifo_rd_data              ; // (input )
wire                                    rxfifo_empty                ; // (input )
wire                              [9:0] rxfifo_data_cnt             ; // (input ) 

wire                                    dgb_err_sack                ; 
wire                                    dbg_err_abt                 ; 

wire                                    baud_en                     ; 

wire                                    usr_wready                  ; 
wire                                    usr_wvalid                  ; 
wire                              [3:0] usr_wcmd                    ; // bit3 -> master ack status,bit2 -> rd/wrn,bit1 -> end,bit0->start.
wire                              [7:0] usr_wdata                   ; 

wire                              [7:0] usr_rdata                   ; 
wire                                    usr_rvalid                  ; 

iic_m_reg #
(
    .U_DLY                          (U_DLY                      )  // 
)
u_iic_m_reg
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_sys                        (clk_sys                    ), // (input )
    .rst_n                          (rst_n                      ), // (input )
//-----------------------------------------------------------------------------------
// LBE(EMIF) bus signals 
//----------------------------------------------------------------------------------- 
    .lbe_cs_n                       (lbe_cs_n                   ), // (input )  Chip Select, Active low      
    .lbe_wr_en                      (lbe_wr_en                  ), // (input )  Write Enable, Active high, Lasts 1 clock cycle 
    .lbe_rd_en                      (lbe_rd_en                  ), // (input )  Read  Enable, Active high, Lasts 1 clock cycle 
    .lbe_addr                       (lbe_addr[15:0]             ), // (input )  Address
    .lbe_wr_dat                     (lbe_wr_dat[31:0]           ), // (input )  Write Data 
    .lbe_rd_dat                     (lbe_rd_dat[31:0]           ), // (output)  Read Data   
//-----------------------------------------------------------------------------------
// baud_rate
//----------------------------------------------------------------------------------- 
    .baud_rate                      (baud_rate[15:0]            ), // (output)
    .slave_ack_waittime             (slave_ack_waittime[31:0]   ), // (output) 
//-----------------------------------------------------------------------------------
// TXFIFO write port
//----------------------------------------------------------------------------------- 
    .txfifo_rst                     (txfifo_rst                 ), // (output) 
    .txfifo_wr_en                   (txfifo_wr_en               ), // (output)  
    .txfifo_wr_data                 (txfifo_wr_data[15:0]       ), // (output) 
    .txfifo_data_cnt                (txfifo_data_cnt[9:0]       ), // (input )  
    .txstart                        (txstart                    ), // (output)
//-----------------------------------------------------------------------------------
// TXFIFO write port
//----------------------------------------------------------------------------------- 
    .rxfifo_rst                     (rxfifo_rst                 ), // (output) 
    .rxfifo_rd_en                   (rxfifo_rd_en               ), // (output) 
    .rxfifo_rd_data                 (rxfifo_rd_data[7:0]        ), // (input ) 
    .rxfifo_empty                   (rxfifo_empty               ), // (input ) 
    .rxfifo_data_cnt                (rxfifo_data_cnt[9:0]       ), // (input )  
//-----------------------------------------------------------------------------------
// Debug
//----------------------------------------------------------------------------------- 
    .dgb_err_sack                   (dgb_err_sack               ), // (input )
    .dbg_err_abt                    (dbg_err_abt                )  // (input )
);

iic_baudgen #
(
    .U_DLY                          (U_DLY                      ), 
    .DW                             (16                         )  
)
u_iic_baudgen
(
// ---------------------------------------------------------------------------------
// Clock & Reset
// ---------------------------------------------------------------------------------
    .clk_sys                        (clk_sys                    ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------------
    .baud_data                      (baud_rate[15:0]            ), // (input )
// ---------------------------------------------------------------------------------
// Baud Pulse
// ---------------------------------------------------------------------------------
    .baud_en                        (baud_en                    )  // (output)
);

asfifo_ip #
(
    .FPGA_DEV                       (FPGA_DEV                   ), 
    .DW_WR                          (16                         ), 
    .AW_WR                          (10                         ), 
    .DW_RD                          (16                         ), 
    .TRSH_FULL                      (500                        )  
)
u0_asfifo_ip
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_wr                         (clk_sys                    ), // (input )
    .clk_rd                         (clk_sys                    ), // (input )
    .rst_n                          (~txfifo_rst & rst_n        ), // (input )
// ---------------------------------------------------------------------------------
// Write
// --------------------------------------------------------------------------------- 
    .wren                           (txfifo_wr_en               ), // (input )
    .wrdata                         (txfifo_wr_data[15:0]       ), // (input )

    .full                           (                           ), // (output)
    .wrpfull                        (                           ), // (output)
    .wrready                        (                           ), // (output)
    .wrcnt                          (txfifo_data_cnt[9:0]       ), // (output)
// ---------------------------------------------------------------------------------
// AXI
// --------------------------------------------------------------------------------- 
    .rden                           (usr_wready & usr_wvalid    ), // (input )
    .rddata                         (txfifo_rd_data[15:0]       ), // (output)
    .empty                          (txfifo_empty               ), // (output)
    .rdcnt                          (                           )  // (output)
);

assign usr_wcmd[3:0] = txfifo_rd_data[11:8];
assign usr_wdata = txfifo_rd_data[7:0];
assign usr_wvalid = ~txfifo_empty & txstart;

asfifo_ip #
(
    .FPGA_DEV                       (FPGA_DEV                   ), 
    .DW_WR                          (8                          ), 
    .AW_WR                          (10                         ), 
    .DW_RD                          (8                          ), 
    .TRSH_FULL                      (500                        )  
)
u1_asfifo_ip
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_wr                         (clk_sys                    ), // (input )
    .clk_rd                         (clk_sys                    ), // (input )
    .rst_n                          (~rxfifo_rst & rst_n        ), // (input )
// ---------------------------------------------------------------------------------
// Write
// --------------------------------------------------------------------------------- 
    .wren                           (usr_rvalid                 ), // (input )
    .wrdata                         (usr_rdata[7:0]             ), // (input )

    .full                           (                           ), // (output)
    .wrpfull                        (                           ), // (output)
    .wrready                        (                           ), // (output)
    .wrcnt                          (                           ), // (output)
// ---------------------------------------------------------------------------------
// AXI
// --------------------------------------------------------------------------------- 
    .rden                           (rxfifo_rd_en               ), // (input )
    .rddata                         (rxfifo_rd_data[7:0]        ), // (output)
    .empty                          (rxfifo_empty               ), // (output)
    .rdcnt                          (rxfifo_data_cnt[9:0]       )  // (output)
);

iic_m_phy_warper #
(
    .U_DLY                          (U_DLY                      )  // 
)
u_iic_m_phy_warper
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_sys                        (clk_sys                    ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------------
    .baud_en                        (baud_en                    ), // (input )
// ---------------------------------------------------------------------------------
// User Data
// ---------------------------------------------------------------------------------
    .usr_wready                     (usr_wready                 ), // (output)
    .usr_wvalid                     (usr_wvalid                 ), // (input )
    .usr_wcmd                       (usr_wcmd[3:0]              ), // (input ) bit3 -> master ack status,bit2 -> rd/wrn,bit1 -> end,bit0->start.
    .usr_wdata                      (usr_wdata[7:0]             ), // (input )

    .usr_rdata                      (usr_rdata[7:0]             ), // (output)
    .usr_rvalid                     (usr_rvalid                 ), // (output)
// ---------------------------------------------------------------------------------
// IIC Phy
// ---------------------------------------------------------------------------------
    .iic_sck_i                      (iic_sck_i                  ), // (input )
    .iic_sck_o                      (iic_sck_o                  ), // (output)
    .iic_sck_t                      (iic_sck_t                  ), // (output)
    .iic_sda_i                      (iic_sda_i                  ), // (input )
    .iic_sda_o                      (iic_sda_o                  ), // (output)
    .iic_sda_t                      (iic_sda_t                  ), // (output)
// ---------------------------------------------------------------------------------
// Debug
// ---------------------------------------------------------------------------------
    .dgb_err_sack                   (dgb_err_sack               ), // (output)
    .dbg_err_abt                    (dbg_err_abt                )  // (output)
);

endmodule

