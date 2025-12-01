// +FHDR============================================================================/
// Author       : huangjie
// Creat Time   : 2023/06/07 09:18:19
// File Name    : iic_sfifo_fwft.v
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
// iic_sfifo_fwft
//    |---
// 
`timescale 1ns/1ps

module iic_sfifo_fwft #
(
    parameter                       DW = 8                      ,
    parameter                       U_DLY = 1                   
)
(
// ---------------------------------------------------------------------------------
// Clock & Reset
// ---------------------------------------------------------------------------------
    input                           clk_sys                     , 
    input                           rst_n                       , 
// ---------------------------------------------------------------------------------
// Write & Read
// ---------------------------------------------------------------------------------
    input                           wr_en                       , 
    input                  [DW-1:0] wr_data                     , 
    input                           rd_en                       , 
    output                 [DW-1:0] rd_data                     , 
// ---------------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------------
    output reg                      wr_ready                    , 
    output                          empty                       , 
    output                          eflag                         
);

reg                           [3:0] ptr                         ; 
reg                        [DW-1:0] mem_data[7:0]               ; 

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        ptr <= #U_DLY 4'd0;
    else
        case({wr_en,rd_en})
            2'b10: ptr <= #U_DLY ptr + 4'd1;
            2'b01: ptr <= #U_DLY (|ptr == 1'b1) ? (ptr - 4'd1) : 4'd0;
            default: ;
        endcase
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        wr_ready <= #U_DLY 1'b0;
    else
        begin
            if(ptr < 4'd5)
                wr_ready <= #U_DLY 1'b1;
            else
                wr_ready <= #U_DLY 1'b0;
        end
end

always @ (posedge clk_sys or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            mem_data[0] <= #U_DLY {DW{1'b0}};
            mem_data[1] <= #U_DLY {DW{1'b0}};
            mem_data[2] <= #U_DLY {DW{1'b0}};
            mem_data[3] <= #U_DLY {DW{1'b0}};
            mem_data[4] <= #U_DLY {DW{1'b0}};
            mem_data[5] <= #U_DLY {DW{1'b0}};
            mem_data[6] <= #U_DLY {DW{1'b0}};
            mem_data[7] <= #U_DLY {DW{1'b0}};
        end
    else
        begin
            case({wr_en,rd_en})
                2'b01   : mem_data[0] <= #U_DLY mem_data[1];
                2'b10   : mem_data[0] <= #U_DLY (ptr == 4'd0) ? wr_data : mem_data[0];
                2'b11   : mem_data[0] <= #U_DLY (ptr == 4'd1) ? wr_data : mem_data[1];
                default :;
            endcase

            case({wr_en,rd_en})
                2'b01   : mem_data[1] <= #U_DLY mem_data[2];
                2'b10   : mem_data[1] <= #U_DLY (ptr == 4'd1) ? wr_data : mem_data[1];
                2'b11   : mem_data[1] <= #U_DLY (ptr == 4'd2) ? wr_data : mem_data[2];
                default :;
            endcase

            case({wr_en,rd_en})
                2'b01   : mem_data[2] <= #U_DLY mem_data[3];
                2'b10   : mem_data[2] <= #U_DLY (ptr == 4'd2) ? wr_data : mem_data[2];
                2'b11   : mem_data[2] <= #U_DLY (ptr == 4'd3) ? wr_data : mem_data[3];
                default :;
            endcase

            case({wr_en,rd_en})
                2'b01   : mem_data[3] <= #U_DLY mem_data[4];
                2'b10   : mem_data[3] <= #U_DLY (ptr == 4'd3) ? wr_data : mem_data[3];
                2'b11   : mem_data[3] <= #U_DLY (ptr == 4'd4) ? wr_data : mem_data[4];
                default :;
            endcase

            case({wr_en,rd_en})
                2'b01   : mem_data[4] <= #U_DLY mem_data[5];
                2'b10   : mem_data[4] <= #U_DLY (ptr == 4'd4) ? wr_data : mem_data[4];
                2'b11   : mem_data[4] <= #U_DLY (ptr == 4'd5) ? wr_data : mem_data[5];
                default :;
            endcase    

            case({wr_en,rd_en})
                2'b01   : mem_data[5] <= #U_DLY mem_data[6];
                2'b10   : mem_data[5] <= #U_DLY (ptr == 4'd5) ? wr_data : mem_data[5];
                2'b11   : mem_data[5] <= #U_DLY (ptr == 4'd6) ? wr_data : mem_data[6];
                default :;
            endcase

            case({wr_en,rd_en})
                2'b01   : mem_data[6] <= #U_DLY mem_data[7];
                2'b10   : mem_data[6] <= #U_DLY (ptr == 4'd6) ? wr_data : mem_data[6];
                2'b11   : mem_data[6] <= #U_DLY (ptr == 4'd7) ? wr_data : mem_data[7];
                default :;
            endcase

            case({wr_en,rd_en})
                2'b01   : mem_data[7] <= #U_DLY {DW{1'b0}};
                2'b10   : mem_data[7] <= #U_DLY (ptr == 4'd7) ? wr_data : mem_data[7];
                2'b11   : mem_data[7] <= #U_DLY {DW{1'b0}}; 
                default :;
            endcase            
        end
end

assign rd_data = mem_data[0];
assign empty = (|ptr == 1'b0) ? 1'b1 : 1'b0;
assign eflag = ((ptr == 4'd1) && (rd_en == 1'b1)) ? 1'b1 : 1'b0;


endmodule





