// +FHDR============================================================================/
// Author       : huangjie
// Creat Time   : 2023/06/06 16:42:38
// File Name    : iic_m_phy_bitgen.v
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
// iic_m_phy_bitgen
//    |---
// 
`define START           {4'b1111,4'b1110,4'b1000}
`define END             {4'b1111,4'b0111,4'b0011}
`define READ            {4'b0000,4'b0110,4'b0000}
`define MACK_ERR        {4'b1111,4'b0110,4'b1111}
`define MACK_OK         {4'b1111,4'b0110,4'b0000}
`define IDLE            {4'b0000,4'b1111,4'b1111}

`timescale 1ns/1ps

module iic_m_phy_bitgen #
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
// User Data
// ---------------------------------------------------------------------------------
    output reg                          usr_wready                  , 
    input                               usr_wvalid                  , 
    input                         [3:0] usr_wcmd                    , // bit3 -> master ack status,bit2 -> rd/wrn,bit1 -> end,bit0->start.
    input                         [7:0] usr_wdata                   , 

    output reg                    [7:0] usr_rdata                   , 
    output reg                          usr_rvalid                  , 
// ---------------------------------------------------------------------------------
// Bit Data
// ---------------------------------------------------------------------------------
    input                               bit_wready                  , 
    output                              bit_wvalid                  , 
    output                       [11:0] bit_wdata                   , 

    input                         [1:0] bit_rdata                   , 
    input                               bit_rvalid                  , 
// ---------------------------------------------------------------------------------
// Debug
// ---------------------------------------------------------------------------------
    output reg                          dgb_err_sack                  
);

wire                                    usr_wready_mask             ; 
reg                               [3:0] usr_wcmd_reg                ; 
reg                               [7:0] usr_wdata_reg               ; 

reg                                     stpen                       ; 
reg                               [3:0] stp_cnt                     ; 

reg                                     wr_en                       ; 
reg                              [11:0] wr_data                     ; 
wire                                    rd_en                       ; 
wire                                    wr_ready                    ; 
wire                                    empty                       ; 

wire                                    wr_mode                     ; 
reg                               [3:0] rxstp_cnt                   ; 

assign usr_wready_mask = usr_wready & usr_wvalid;

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        usr_wready <= #U_DLY 1'b0;
    else begin
        if((stpen == 1'b0) && (usr_wready_mask == 1'b0))
            usr_wready <= #U_DLY 1'b1;
        else if(usr_wvalid == 1'b1)
            usr_wready <= #U_DLY 1'b0;
        else
            ;
    end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0) begin
        usr_wcmd_reg <= #U_DLY 3'd0;
        usr_wdata_reg <= #U_DLY 8'd0;
    end
    else begin
        if(usr_wvalid & usr_wready) begin
            usr_wcmd_reg <= #U_DLY usr_wcmd;
            usr_wdata_reg <= #U_DLY usr_wdata;
        end
        else 
            ;
    end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0) 
        stpen <= #U_DLY 1'b0;
    else begin
        if(usr_wvalid & usr_wready)
            stpen <= #U_DLY 1'b1;
        else if((stp_cnt >= 4'd10) && (wr_ready == 1'b1))
            stpen <= #U_DLY 1'b0;
        else
            ;
    end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        stp_cnt <= #U_DLY 4'd0;
    else
        begin
            if(stpen == 1'b1)
                begin
                    if((wr_ready == 1'b1) && (stp_cnt < 4'd10))
                        stp_cnt <= #U_DLY stp_cnt + 4'd1;
                    else
                        ;
                end
            else
                stp_cnt <= #U_DLY 4'd0;
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        wr_en <= #U_DLY 1'b0;
    else begin
        if((wr_ready == 1'b1) && (stpen == 1'b1))
            case({usr_wcmd_reg[1:0],stp_cnt})
                {2'd0,4'd0}     : wr_en <= #U_DLY 1'b0;
                {2'd2,4'd0}     : wr_en <= #U_DLY 1'b0;
                {2'd0,4'd10}    : wr_en <= #U_DLY 1'b0;
                {2'd1,4'd10}    : wr_en <= #U_DLY 1'b0;
                default         : wr_en <= #U_DLY 1'b1;
            endcase
        else
            wr_en <= #U_DLY 1'b0;
    end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        wr_data <= #U_DLY `IDLE;
    else
        begin
            if((wr_ready == 1'b1) && (stpen == 1'b1))
                begin
                    if(usr_wcmd_reg[2] == 1'b1)
                        case(stp_cnt)
                            4'd0    : wr_data <= #U_DLY `START;
                            4'd1    : wr_data <= #U_DLY `READ;
                            4'd2    : wr_data <= #U_DLY `READ;
                            4'd3    : wr_data <= #U_DLY `READ;
                            4'd4    : wr_data <= #U_DLY `READ;
                            4'd5    : wr_data <= #U_DLY `READ;
                            4'd6    : wr_data <= #U_DLY `READ;
                            4'd7    : wr_data <= #U_DLY `READ;
                            4'd8    : wr_data <= #U_DLY `READ;
                            4'd9    : wr_data <= #U_DLY {4'b1111,4'b0110,{4{usr_wcmd_reg[3]}}};
                            4'd10   : wr_data <= #U_DLY `END;
                            default : ;
                        endcase
                    else
                        case(stp_cnt)
                            4'd0    : wr_data <= #U_DLY `START;
                            4'd1    : wr_data <= #U_DLY {4'b1111,4'b0110,{4{usr_wdata_reg[7]}}};
                            4'd2    : wr_data <= #U_DLY {4'b1111,4'b0110,{4{usr_wdata_reg[6]}}};
                            4'd3    : wr_data <= #U_DLY {4'b1111,4'b0110,{4{usr_wdata_reg[5]}}};
                            4'd4    : wr_data <= #U_DLY {4'b1111,4'b0110,{4{usr_wdata_reg[4]}}};
                            4'd5    : wr_data <= #U_DLY {4'b1111,4'b0110,{4{usr_wdata_reg[3]}}};
                            4'd6    : wr_data <= #U_DLY {4'b1111,4'b0110,{4{usr_wdata_reg[2]}}};
                            4'd7    : wr_data <= #U_DLY {4'b1111,4'b0110,{4{usr_wdata_reg[1]}}};
                            4'd8    : wr_data <= #U_DLY {4'b1111,4'b0110,{4{usr_wdata_reg[0]}}};
                            4'd9    : wr_data <= #U_DLY `READ;
                            4'd10   : wr_data <= #U_DLY `END;
                            default : ;
                        endcase
                end
            else
                ;
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        rxstp_cnt <= #U_DLY 4'd0;
    else
        begin
            if(wr_mode == 1'b1)
                begin
                    if({bit_wvalid,bit_wready} == 2'b11) begin
                        if(rxstp_cnt < 4'd8) begin
                            rxstp_cnt <= #U_DLY rxstp_cnt + 4'd1;
                        end
                        else
                            rxstp_cnt <= #U_DLY 4'd0;
                    end
                    else
                        ;
                end
            else
                rxstp_cnt <= #U_DLY 4'd0;
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            usr_rdata <= #U_DLY 8'd0;
            usr_rvalid <= #U_DLY 1'b0;
        end
    else
        begin
            if(wr_mode == 1'b1)
                case(rxstp_cnt)
                    4'd1    : usr_rdata[7] <= #U_DLY bit_rdata;
                    4'd2    : usr_rdata[6] <= #U_DLY bit_rdata;
                    4'd3    : usr_rdata[5] <= #U_DLY bit_rdata;
                    4'd4    : usr_rdata[4] <= #U_DLY bit_rdata;
                    4'd5    : usr_rdata[3] <= #U_DLY bit_rdata;
                    4'd6    : usr_rdata[2] <= #U_DLY bit_rdata;
                    4'd7    : usr_rdata[1] <= #U_DLY bit_rdata;
                    4'd8    : usr_rdata[0] <= #U_DLY bit_rdata;
                    default : ;
                endcase
            else
                ;
            
            if((wr_mode == 1'b1) && (rxstp_cnt == 4'd8) && (bit_rvalid == 1'b1))
                usr_rvalid <= #U_DLY 1'b1;
            else
                usr_rvalid <= #U_DLY 1'b0;
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        dgb_err_sack <= #U_DLY 1'b0;
    else
        begin
            if((rxstp_cnt == 4'b0) && ({bit_rdata,bit_rvalid} ==2'b11))
                dgb_err_sack <= #U_DLY 1'b1;
            else
                dgb_err_sack <= #U_DLY 1'b0;
        end
end

iic_sfifo_fwft #
(
    .DW                             (13                         ), 
    .U_DLY                          (U_DLY                      )  
)
u_iic_sfifo_fwft
(
// ---------------------------------------------------------------------------------
// Clock & Reset
// ---------------------------------------------------------------------------------
    .clk_sys                        (clk_sys                    ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Write & Read
// ---------------------------------------------------------------------------------
    .wr_en                          (wr_en                      ), // (input )
    .wr_data                        ({usr_wcmd_reg[2],wr_data[11:0]}), // (input )
    .rd_en                          (rd_en                      ), // (input )
    .rd_data                        ({wr_mode,bit_wdata[11:0]}  ), // (output)
// ---------------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------------
    .wr_ready                       (wr_ready                   ), // (output)
    .empty                          (empty                      ), // (output)
    .eflag                          (                           )  // (output)
);

assign rd_en = bit_wvalid & bit_wready;
assign bit_wvalid = ~empty;

endmodule

