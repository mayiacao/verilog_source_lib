// +FHDR============================================================================/
// Author       : hjie
// Creat Time   : 2023/10/18 13:00:30
// File Name    : iic_m_reg.v
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
// iic_m_reg
//    |---


`define _baud_rate_                 16'd259   //default 100KHz @100MHz
`define _slave_ack_waittime_        32'd999999 // 10ms @100MHz 

`define _txfifo_rst_                1'b0
`define _txfifo_trig_               10'd500   
    
`define _rxfifo_rst_                1'b0
`define _rxfifo_trig_               10'd0

`define _test_reg_                  32'h55aa_55aa

`include "debug.vh"
`timescale 1ns/1ps

module iic_m_reg #
(
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
    output reg                   [31:0] lbe_rd_dat                  , // (output) Read Data   
//-----------------------------------------------------------------------------------
// baud_rate
//----------------------------------------------------------------------------------- 
    output reg                   [15:0] baud_rate                   , 
    output reg                   [31:0] slave_ack_waittime          , // (output)
//-----------------------------------------------------------------------------------
// TXFIFO write port
//----------------------------------------------------------------------------------- 
    output reg                          txfifo_rst                  , // (output)
    output reg                          txfifo_wr_en                , // (output) 
    output reg                   [15:0] txfifo_wr_data              , // (output)
    input                         [9:0] txfifo_data_cnt             , // (input ) 
    output reg                          txstart                     , 
//-----------------------------------------------------------------------------------
// TXFIFO write port
//----------------------------------------------------------------------------------- 
    output reg                          rxfifo_rst                  , // (output)
    output reg                          rxfifo_rd_en                , // (output)
    input                         [7:0] rxfifo_rd_data              , // (input )
    input                               rxfifo_empty                , // (input )
    input                         [9:0] rxfifo_data_cnt             , // (input ) 
//-----------------------------------------------------------------------------------
// Debug
//----------------------------------------------------------------------------------- 
    input                               dgb_err_sack                , 
    input                               dbg_err_abt                   
);

reg                              [15:0] txfifo_trig                 ; 
wire                                    txfifo_ready                ; // (input )

reg                              [15:0] rxfifo_trig                 ; 
wire                                    rxfifo_pfull                ; // (input ) 

reg                              [15:0] err_sack_cnt                ; 
reg                              [15:0] err_abt_cnt                 ; 

reg                              [31:0] test_reg                    ; 

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0) begin
        test_reg <= #U_DLY `_test_reg_;


        baud_rate <= #U_DLY `_baud_rate_;
        slave_ack_waittime <= #U_DLY `_slave_ack_waittime_; 

        txfifo_rst <= #U_DLY `_txfifo_rst_;
        txfifo_trig <= #U_DLY `_txfifo_trig_;
        txfifo_wr_en <= #U_DLY 1'b0;
        txfifo_wr_data <= #U_DLY 16'd0;
        txstart <= #U_DLY 'd0; 

        rxfifo_rst <= #U_DLY `_rxfifo_rst_;
        rxfifo_trig <= #U_DLY `_rxfifo_trig_;
    end
    else begin
        if((lbe_cs_n == 1'b0) && (lbe_wr_en == 1'b1) && (lbe_addr[15:8] == 8'd0))
            case(lbe_addr[7:0])

                8'h04 : test_reg <= #U_DLY ~lbe_wr_dat;

                8'h10 : baud_rate <= #U_DLY lbe_wr_dat[15:0]; 
                8'h14 : slave_ack_waittime <= #U_DLY lbe_wr_dat; 
                
                8'h20 : txfifo_rst <= #U_DLY lbe_wr_dat[0]; 
                8'h24 : txfifo_trig <= #U_DLY lbe_wr_dat[15:0]; 
                8'h28 : txstart <= #U_DLY lbe_wr_dat[0]; 
//                8'h28 : begin
//                    txfifo_wr_en <= #U_DLY 1'b1;
//                    txfifo_wr_data <= #U_DLY lbe_wr_dat[15:0];
//                end
                
                8'h30 : rxfifo_rst <= #U_DLY lbe_wr_dat[0];
                8'h34 : rxfifo_trig <= #U_DLY lbe_wr_dat[15:0]; 
                default:;
            endcase
        else if((lbe_cs_n == 1'b0) && (lbe_wr_en == 1'b1) && (lbe_addr[15:12] == 4'd1)) begin
            txfifo_wr_en <= #U_DLY 1'b1;
            txfifo_wr_data <= #U_DLY lbe_wr_dat[15:0];
        end
        else begin
            txfifo_wr_en <= #U_DLY 1'b0;
        end
    end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0) begin
        rxfifo_rd_en <= #U_DLY 1'b0;
        lbe_rd_dat <= #U_DLY 32'd0;
    end
    else begin
        if((lbe_cs_n == 1'b0) && (lbe_rd_en == 1'b1) && (lbe_addr[15:8] == 8'd0))
            case(lbe_addr[7:0])
                8'h04   : lbe_rd_dat <= #U_DLY test_reg;
                        
                8'h10   : lbe_rd_dat <= #U_DLY {16'd0,baud_rate};
                8'h14   : lbe_rd_dat <= #U_DLY slave_ack_waittime; 
                        
                8'h20   : lbe_rd_dat <= #U_DLY {31'd0,txfifo_rst};
                8'h24   : lbe_rd_dat <= #U_DLY {16'd0,txfifo_trig};
                8'h28   : lbe_rd_dat <= #U_DLY {15'd0,txstart,txfifo_wr_data};
                8'h2c   : lbe_rd_dat <= #U_DLY {6'd0,txfifo_data_cnt,15'd0,txfifo_ready};
                8'h30   : lbe_rd_dat <= #U_DLY {31'd0,rxfifo_rst};
                8'h34   : lbe_rd_dat <= #U_DLY {16'd0,rxfifo_trig};
//                8'h38   : begin
//                          rxfifo_rd_en <= #U_DLY 1'b1;
//                          lbe_rd_dat <= #U_DLY {24'd0,rxfifo_rd_data};
//                end     
                8'h3c   : lbe_rd_dat <= #U_DLY {6'd0,rxfifo_data_cnt,15'd0,rxfifo_pfull};
                8'h40   : lbe_rd_dat <= #U_DLY {16'd0,err_sack_cnt};
                8'h44   : lbe_rd_dat <= #U_DLY {16'd0,err_abt_cnt};
                default : lbe_rd_dat <= {32{1'b0}};  
            endcase
        else if((lbe_cs_n == 1'b0) && (lbe_rd_en == 1'b1) && (lbe_addr[15:12] == 4'd2)) begin
            rxfifo_rd_en <= #U_DLY 1'b1;
            lbe_rd_dat <= #U_DLY {24'd0,rxfifo_rd_data};
        end
        else
            rxfifo_rd_en <= #U_DLY 1'b0;
    end
end

assign txfifo_ready = (txfifo_data_cnt <= txfifo_trig) ? 1'b1 : 1'b0;
assign rxfifo_pfull = (rxfifo_data_cnt > rxfifo_trig) ? 1'b1 : 1'b0;


always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0) begin
        err_sack_cnt <= #U_DLY 16'd0;
        err_abt_cnt <= #U_DLY 16'd0;
    end
    else begin
        if((lbe_cs_n == 1'b0) && (lbe_rd_en == 1'b1) && (lbe_addr == 8'h40))
            err_sack_cnt <= #U_DLY 16'd0;
        else if(dgb_err_sack == 1'b1)
            err_sack_cnt <= #U_DLY err_sack_cnt + 16'd1;
        else
            ;

        if((lbe_cs_n == 1'b0) && (lbe_rd_en == 1'b1) && (lbe_addr == 8'h44))
            err_abt_cnt <= #U_DLY 16'd0;
        else if(dbg_err_abt == 1'b1)
            err_abt_cnt <= #U_DLY err_abt_cnt + 16'd1;
        else
            ;
    end
end

`ifdef _DBG_IIC_
ila_dbg u2_ila_dbg
(
    .clk                            (clk_sys                    ), // input wire clk


    .probe0                         ({lbe_cs_n,lbe_wr_en,lbe_rd_en}), 
    .probe1                         ({lbe_addr,txfifo_rst,rxfifo_rst}), 
    .probe2                         ({lbe_wr_dat,lbe_rd_dat}              ), 
    .probe3                         ({txfifo_wr_en,txfifo_wr_data,txfifo_data_cnt}              ), // input wire [31:0]  probe3 
    .probe4                         ({rxfifo_rd_en,rxfifo_rd_data,rxfifo_data_cnt}    ), // input wire [31:0]  probe4 
    .probe5                         (rxfifo_empty   ), // input wire [31:0]  probe5 
    .probe6                         (dgb_err_sack                    ), // input wire [31:0]  probe6 
    .probe7                         (dbg_err_abt) // input wire [31:0]  probe7
);
`endif

endmodule

