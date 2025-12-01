// +FHDR============================================================================/
// Author       : mayia
// Creat Time   : 2022/07/21 14:58:55
// File Name    : axi2fifo.v
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
// axi2fifo
//    |---
// 
`timescale 1ns/1ps

module axi2fifo #
(
    parameter                       DW = 8                      ,
    parameter                       UDW = 10                    ,
    parameter                       U_DLY = 1                   ,
    parameter                       DEW = DW/8                  ,
    parameter                       FW = DW+DEW+UDW+1           
)
(
// ---------------------------------------------------------------------------------
// Clock & Reset
// ---------------------------------------------------------------------------------
    input                           clk_sys                     , 
    input                           rst_n                       ,  
// ---------------------------------------------------------------------------------
// AXI
// --------------------------------------------------------------------------------- 
    output reg                      axi_ready                   , 
    input                           axi_valid                   , 
    input                  [DW-1:0] axi_data                    , 
    input                           axi_last                    , 
    input                 [DEW-1:0] axi_keep                    , 
    input                 [UDW-1:0] axi_user                    , 
// ---------------------------------------------------------------------------------
// FIFO Read
// --------------------------------------------------------------------------------- 
    input                           fifo_rd_en                  , 
    output                 [FW-1:0] fifo_rd_data                , 
    output                          fifo_empty                  , 
    output                          fifo_eflag                    
);

wire                                fifo_wr_en                  ; 
wire                       [FW-1:0] fifo_wr_data                ; 

reg                           [3:0] fifo_ptr                    ; 
reg                        [FW-1:0] mem_data [7:0]              ; 

assign fifo_wr_en = axi_valid & axi_ready;
assign fifo_wr_data = {axi_user,axi_keep,axi_last,axi_data};
assign fifo_rd_data = mem_data[0];
assign fifo_empty = (|fifo_ptr == 1'b0) ? 1'b1 : 1'b0;
assign fifo_eflag = ((fifo_ptr == 4'd1) && (fifo_rd_en == 1'b1)) ? 1'b1 : 1'b0;

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        fifo_ptr <= #U_DLY 4'd0;
    else
        case({fifo_wr_en,fifo_rd_en})
            2'b10: fifo_ptr <= #U_DLY fifo_ptr + 4'd1;
            2'b01: fifo_ptr <= #U_DLY (|fifo_ptr == 1'b1) ? (fifo_ptr - 4'd1) : 4'd0;
            default: ;
        endcase
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        axi_ready <= #U_DLY 1'b0;
    else
        begin
            if(fifo_ptr < 4'd5)
                axi_ready <= #U_DLY 1'b1;
            else
                axi_ready <= #U_DLY 1'b0;
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            mem_data[0] <= #U_DLY {FW{1'b0}};
            mem_data[1] <= #U_DLY {FW{1'b0}};
            mem_data[2] <= #U_DLY {FW{1'b0}};
            mem_data[3] <= #U_DLY {FW{1'b0}};
            mem_data[4] <= #U_DLY {FW{1'b0}};
            mem_data[5] <= #U_DLY {FW{1'b0}};
            mem_data[6] <= #U_DLY {FW{1'b0}};
            mem_data[7] <= #U_DLY {FW{1'b0}};
        end
    else
        begin
            case({fifo_wr_en,fifo_rd_en})
                2'b01   : mem_data[0] <= #U_DLY mem_data[1];
                2'b10   : mem_data[0] <= #U_DLY (fifo_ptr == 4'd0) ? fifo_wr_data : mem_data[0];
                2'b11   : mem_data[0] <= #U_DLY (fifo_ptr == 4'd1) ? fifo_wr_data : mem_data[1];
                default :;
            endcase

            case({fifo_wr_en,fifo_rd_en})
                2'b01   : mem_data[1] <= #U_DLY mem_data[2];
                2'b10   : mem_data[1] <= #U_DLY (fifo_ptr == 4'd1) ? fifo_wr_data : mem_data[1];
                2'b11   : mem_data[1] <= #U_DLY (fifo_ptr == 4'd2) ? fifo_wr_data : mem_data[2];
                default :;
            endcase

            case({fifo_wr_en,fifo_rd_en})
                2'b01   : mem_data[2] <= #U_DLY mem_data[3];
                2'b10   : mem_data[2] <= #U_DLY (fifo_ptr == 4'd2) ? fifo_wr_data : mem_data[2];
                2'b11   : mem_data[2] <= #U_DLY (fifo_ptr == 4'd3) ? fifo_wr_data : mem_data[3];
                default :;
            endcase

            case({fifo_wr_en,fifo_rd_en})
                2'b01   : mem_data[3] <= #U_DLY mem_data[4];
                2'b10   : mem_data[3] <= #U_DLY (fifo_ptr == 4'd3) ? fifo_wr_data : mem_data[3];
                2'b11   : mem_data[3] <= #U_DLY (fifo_ptr == 4'd4) ? fifo_wr_data : mem_data[4];
                default :;
            endcase

            case({fifo_wr_en,fifo_rd_en})
                2'b01   : mem_data[4] <= #U_DLY mem_data[5];
                2'b10   : mem_data[4] <= #U_DLY (fifo_ptr == 4'd4) ? fifo_wr_data : mem_data[4];
                2'b11   : mem_data[4] <= #U_DLY (fifo_ptr == 4'd5) ? fifo_wr_data : mem_data[5];
                default :;
            endcase    

            case({fifo_wr_en,fifo_rd_en})
                2'b01   : mem_data[5] <= #U_DLY mem_data[6];
                2'b10   : mem_data[5] <= #U_DLY (fifo_ptr == 4'd5) ? fifo_wr_data : mem_data[5];
                2'b11   : mem_data[5] <= #U_DLY (fifo_ptr == 4'd6) ? fifo_wr_data : mem_data[6];
                default :;
            endcase

            case({fifo_wr_en,fifo_rd_en})
                2'b01   : mem_data[6] <= #U_DLY mem_data[7];
                2'b10   : mem_data[6] <= #U_DLY (fifo_ptr == 4'd6) ? fifo_wr_data : mem_data[6];
                2'b11   : mem_data[6] <= #U_DLY (fifo_ptr == 4'd7) ? fifo_wr_data : mem_data[7];
                default :;
            endcase

            case({fifo_wr_en,fifo_rd_en})
                2'b01   : mem_data[7] <= #U_DLY {FW{1'b0}};
                2'b10   : mem_data[7] <= #U_DLY (fifo_ptr == 4'd7) ? fifo_wr_data : mem_data[7];
                2'b11   : mem_data[7] <= #U_DLY {FW{1'b0}}; 
                default :;
            endcase            
        end
end

endmodule




