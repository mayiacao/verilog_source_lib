// +FHDR============================================================================/
// Author       : huangjie
// Creat Time   : 2023/06/19 10:50:03
// File Name    : iic_m_phy_timing.v
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
// iic_m_phy_timing
//    |---
// 
`timescale 1ns/1ps

module iic_m_phy_timing #
(
    parameter                           U_DLY = 1                     // 
)
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    input                               clk_sys                     ,
    input                               rst_n                       ,
// ---------------------------------------------------------------------------------
// Baud
// ---------------------------------------------------------------------------------
    input                               baud_en                     , 
// ---------------------------------------------------------------------------------
// Bit Data
// ---------------------------------------------------------------------------------
    output reg                          bit_wready                  , 
    input                               bit_wvalid                  , 
    input                        [11:0] bit_wdata                   , 

    output reg                          bit_rdata                   , 
    output reg                          bit_rvalid                  , 
// ---------------------------------------------------------------------------------
// IIC Phy
// ---------------------------------------------------------------------------------
    input                               iic_sck_i                   , 
    output reg                          iic_sck_o                   , 
    output reg                          iic_sck_t                   , 
    input                               iic_sda_i                   , 
    output reg                          iic_sda_o                   , 
    output reg                          iic_sda_t                   , 
// ---------------------------------------------------------------------------------
// Debug
// ---------------------------------------------------------------------------------
    output reg                          dbg_err_abt                   
);

reg                                     baud_en_dly                 ; 
reg                               [1:0] mstp_cnt                    ; 
reg                                     slave_pause                 ; 

reg                               [1:0] rxstp_cnt                   ; 
reg                               [2:0] rxbit_mem                   ; 

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        baud_en_dly <= #U_DLY 1'b0;
    else
        baud_en_dly <= #U_DLY baud_en;
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        mstp_cnt <= #U_DLY 2'd0;
    else
        begin
            if({slave_pause,baud_en_dly} == 2'b01)
                begin
                    if(bit_wvalid == 1'b1)
                        mstp_cnt <= #U_DLY mstp_cnt + 2'd1;
                    else
                        mstp_cnt <= #U_DLY 2'd0;
                end
            else
                ;
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        bit_wready <= #U_DLY 1'b0;
    else
        begin
            if((mstp_cnt == 2'b11) && (baud_en == 1'b1))
                bit_wready <= #U_DLY 1'b1;
            else
                bit_wready <= #U_DLY 1'b0;
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        slave_pause <= #U_DLY 1'b0;
    else
        begin
            if({iic_sck_i,iic_sck_o} == 2'b01)
                slave_pause <= #U_DLY 1'b1;
            else if(iic_sck_i == 1'b1)
                slave_pause <= #U_DLY 1'b0;
            else
                ;
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            iic_sck_o <= #U_DLY 1'b1;
            iic_sck_t <= #U_DLY 1'b0;
            iic_sda_o <= #U_DLY 1'b1;
            iic_sda_t <= #U_DLY 1'b0;
        end
    else
        begin
            if(bit_wvalid == 1'b1)
                begin
                    if(baud_en_dly == 1'b1)
                         begin
                            case(mstp_cnt)
                                2'b00   : iic_sck_o <= #U_DLY bit_wdata[7];
                                2'b01   : iic_sck_o <= #U_DLY bit_wdata[6];
                                2'b10   : iic_sck_o <= #U_DLY bit_wdata[5];
                                2'b11   : iic_sck_o <= #U_DLY bit_wdata[4];
                                default : iic_sck_o <= #U_DLY 1'b1;       
                            endcase                                       
                                                                          
                            case(mstp_cnt)                                 
                                2'b00   : iic_sck_t <= #U_DLY 1'b1;
                                2'b01   : iic_sck_t <= #U_DLY 1'b1;
                                2'b10   : iic_sck_t <= #U_DLY 1'b1;
                                2'b11   : iic_sck_t <= #U_DLY 1'b1;
                                default : iic_sck_t <= #U_DLY 1'b0;       
                            endcase                                       
                                                                          
                            case(mstp_cnt)                                 
                                2'b00   : iic_sda_o <= #U_DLY bit_wdata[3];
                                2'b01   : iic_sda_o <= #U_DLY bit_wdata[2];
                                2'b10   : iic_sda_o <= #U_DLY bit_wdata[1];
                                2'b11   : iic_sda_o <= #U_DLY bit_wdata[0];
                                default : iic_sda_o <= #U_DLY 1'b1;
                            endcase
                            
                            case(mstp_cnt)                                 
                                2'b00   : iic_sda_t <= #U_DLY bit_wdata[11];
                                2'b01   : iic_sda_t <= #U_DLY bit_wdata[10];
                                2'b10   : iic_sda_t <= #U_DLY bit_wdata[9];
                                2'b11   : iic_sda_t <= #U_DLY bit_wdata[8];
                                default : iic_sda_t <= #U_DLY 1'b0;       
                            endcase         

                                                   
                        end
                    else
                        ;
                end
            else begin
                iic_sck_o <= #U_DLY 1'b1;
                iic_sck_t <= #U_DLY 1'b0;
                iic_sda_o <= #U_DLY 1'b1;
                iic_sda_t <= #U_DLY 1'b0;
            end            
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        rxstp_cnt <= #U_DLY 2'd0;
    else
        begin
            if(({iic_sda_t,iic_sck_i,iic_sck_t} == 3'b011) || (rxstp_cnt > 2'd0))
                begin
                    if(baud_en == 1'b1)
                        rxstp_cnt <= #U_DLY rxstp_cnt + 2'd1;
                    else
                        ;
                end
            else
                rxstp_cnt <= #U_DLY 2'd0;
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        rxbit_mem <= #U_DLY 3'd0;
    else
        if(baud_en == 1'b1)
            case(rxstp_cnt)
                2'b00   : rxbit_mem[0] <= #U_DLY iic_sda_i;
                2'b01   : rxbit_mem[1] <= #U_DLY iic_sda_i;
                2'b10   : rxbit_mem[2] <= #U_DLY iic_sda_i;
                default : ;
            endcase
        else
            ;
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            bit_rdata <= #U_DLY 1'b0;
            bit_rvalid <= #U_DLY 1'b0;
        end
    else
        begin
            if(rxstp_cnt == 2'b11)
                case(rxbit_mem)
                3'b000  : bit_rdata <= #U_DLY 1'b0;
                3'b001  : bit_rdata <= #U_DLY 1'b0;
                3'b010  : bit_rdata <= #U_DLY 1'b0;
                3'b100  : bit_rdata <= #U_DLY 1'b0;
                3'b111  : bit_rdata <= #U_DLY 1'b1;
                3'b110  : bit_rdata <= #U_DLY 1'b1;
                3'b101  : bit_rdata <= #U_DLY 1'b1;
                3'b011  : bit_rdata <= #U_DLY 1'b1;
                default : bit_rdata <= #U_DLY 1'b0;
                endcase
            else
                ;

            if((rxstp_cnt == 2'b11) && (baud_en == 1'b1))
                bit_rvalid <= #U_DLY 1'b1;
            else
                bit_rvalid <= #U_DLY 1'b0;
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
       dbg_err_abt <= #U_DLY 1'b0;
    else
        begin
            if((mstp_cnt == 2'd2) && (iic_sda_t == 1'b1) && (iic_sda_o != iic_sda_i))
                dbg_err_abt <= #U_DLY 1'b1;
            else
                dbg_err_abt <= #U_DLY 1'b0;
        end
end

endmodule

