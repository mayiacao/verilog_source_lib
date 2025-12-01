// +FHDR============================================================================/
// Author       : hjie
// Creat Time   : 2024/10/24 16:15:01
// File Name    : asfifo_v02.v
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
// asfifo_v02
//    |---
// 
`timescale 1ns/1ps

module asfifo_v02 #
(
    parameter                           PA_DW = 8                   , // It must be a multiple of 8.
    parameter                           PA_AW = 8                   , // Must not be less than log2(PB_DW/PA_DW).
    parameter                           PB_DW = 16                  , // It must be a multiple of PA_DW.
    parameter                           RD_AS_ACK = "TRUE"          , // "TRUE" OR "FALSE"
    parameter                           PIPLI_STAGE = 2             , //Must be >= 2  
    parameter                           PA_DEPTH = 2**PA_AW         ,
    parameter                           PB_AW = LOG2(PA_DW*PA_DEPTH/PB_DW-1),  
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
// Write Control & Status
// ---------------------------------------------------------------------------------
    input                               wr_en                       , 
    input                   [PA_DW-1:0] wr_data                     , 
    input                   [PA_AW-1:0] prog_data                   , 
    output reg              [PA_AW-1:0] wr_cnt                      , 
    output reg                          full                        , 
    output reg                          pfull                       , 
// ---------------------------------------------------------------------------------
// Read Control & Status
// ---------------------------------------------------------------------------------
    input                               rd_en                       , 
    output reg              [PB_DW-1:0] rd_data                     , 
    output reg              [PB_AW-1:0] rd_cnt                      , 
    output reg                          empty                       , 
    output reg                          aempty                
);

localparam SUBAB_AW = (PA_DW > PB_DW) ? (LOG2(PA_DW/PB_DW)-1) : (LOG2(PB_DW/PA_DW)-1);

localparam MEM_DW = (PA_DW > PB_DW) ? PA_DW : PB_DW;
localparam PTRW_MEM = (PA_DW > PB_DW) ? PA_AW : PB_AW;

localparam PIPLE = (PIPLI_STAGE >= 2) ? PIPLI_STAGE : 2;

localparam DEPTH_MEM = 2 ** PTRW_MEM;

(* ram_style="block" *)reg                         [MEM_DW-1:0] mem [DEPTH_MEM-1:0]    /* syn_ramstyle = “usram” */    ; 

reg                           [PA_AW:0] wrptr                       ; 
reg                           [PA_AW:0] wrptr_next                  ; 
wire                          [PA_AW:0] wrptr_gray                  ; 

reg                           [PB_AW:0] rdptr_dly [PIPLE-1:0]       ;     
wire                          [PB_AW:0] rdptr_bin                   ; 

wire                          [PA_AW:0] wrcnt_next                  ; 

reg                           [PB_AW:0] rdptr                       ; 
reg                           [PB_AW:0] rdptr_next                  ; 
wire                          [PB_AW:0] rdptr_gray                  ; 

reg                           [PA_AW:0] wrptr_dly [PIPLE-1:0]       ; 
wire                          [PA_AW:0] wrptr_bin                   ; 

wire                          [PB_AW:0] rdcnt_next                  ; 


genvar                                  i                           ;
//  ******************************************************************* //
//  ******************************************************************* //
//  FIFO write address process.
//  ******************************************************************* //
//  ******************************************************************* //
always @ (*) begin
    if(~full && wr_en)
        wrptr_next = wrptr + {{PA_AW{1'b0}},1'b1};
    else
        wrptr_next = wrptr;
end

always @ (posedge clk_wr or negedge rst_n) begin
    if(~rst_n)
        wrptr <= #U_DLY {(PA_AW+1){1'b0}};
    else 
        wrptr <= #U_DLY wrptr_next;
end

always @ (posedge clk_wr or negedge rst_n) begin
    if(~rst_n)
        rdptr_dly[PIPLE-1] <= #U_DLY 'd0;
    else
        rdptr_dly[PIPLE-1] <= #U_DLY rdptr_gray;
end

generate
for(i=0;i<PIPLE-1;i=i+1) begin:rdpiple_loop

always @ (posedge clk_wr or negedge rst_n) begin
    if(~rst_n)
        rdptr_dly[i] <= #U_DLY 'd0;
    else
        rdptr_dly[i] <= #U_DLY rdptr_dly[i+1];
end

end
endgenerate

//  ******************************************************************* //
//  ******************************************************************* //
//  FIFO write data & Status process.
//  ******************************************************************* //
//  ******************************************************************* //
generate
if(PA_DW >= PB_DW)
begin:wrmax2min_if

always @(posedge clk_wr)
begin
    if(~full && wr_en)
        mem[wrptr[PA_AW-1:0]] <= #U_DLY wr_data;
    else
        ;
end

assign wrcnt_next = wrptr_next - rdptr_bin[PB_AW:SUBAB_AW];

end
else
begin:wrmin2max_if

always @(posedge clk_wr)
begin
    if(~full && wr_en)
        mem[wrptr[PA_AW-1:SUBAB_AW]][wrptr[SUBAB_AW-1:0]*PA_DW+:PA_DW] <= #U_DLY wr_data;
    else
        ;
end

assign wrcnt_next = wrptr_next - {rdptr_bin,{SUBAB_AW{1'b0}}};

end
endgenerate

always @ (posedge clk_wr or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        full <= #U_DLY 1'b0;
        pfull <= #U_DLY 1'b0;
        wr_cnt <= #U_DLY {PA_AW{1'b0}};
    end
    else begin
        if(wrcnt_next >= {1'b0,{PA_AW{1'b1}}})
            full <= #U_DLY 1'b1;
        else
            full <= #U_DLY 1'b0;

        if(wrcnt_next >= {1'b0,prog_data})
            pfull <= #U_DLY 1'b1;
        else
            pfull <= #U_DLY 1'b0;

        wr_cnt <= #U_DLY wrcnt_next;
    end
end

//  ******************************************************************* //
//  ******************************************************************* //
//  FIFO Read process.
//  ******************************************************************* //
//  ******************************************************************* //
always @ (*) begin
    if(~empty && rd_en)
        rdptr_next = rdptr + {{PB_AW{1'b0}},1'b1};
    else
        rdptr_next = rdptr;
end

always @ (posedge clk_rd or negedge rst_n) begin
    if(rst_n == 1'b0) 
        rdptr <= #U_DLY {(PB_AW+1){1'b0}};
    else 
        rdptr <= #U_DLY rdptr_next;
end

always @ (posedge clk_rd or negedge rst_n) begin
    if(~rst_n)
        wrptr_dly[PIPLE-1] <= #U_DLY 'd0;
    else
        wrptr_dly[PIPLE-1] <= #U_DLY wrptr_gray;
end

generate
for(i=0;i<PIPLE-1;i=i+1) begin:wrpiple_loop

always @ (posedge clk_rd or negedge rst_n) begin
    if(~rst_n)
        wrptr_dly[i] <= #U_DLY 'd0;
    else
        wrptr_dly[i] <= #U_DLY wrptr_dly[i+1];
end

end
endgenerate


generate
if(PA_DW > PB_DW)
begin:rdwrmax2min_if
if(RD_AS_ACK == "FALSE")
begin:rdreq_if

always @(posedge clk_rd or negedge rst_n)
begin
    if(rst_n == 1'b0)
        rd_data <= #U_DLY {PB_DW{1'b0}};
    else begin
        if(~empty && rd_en)
            rd_data <= #U_DLY mem[rdptr[PB_AW-1:SUBAB_AW]][rdptr[SUBAB_AW-1:0]*PB_DW+:PB_DW];
        else
            ;        
    end
end

end
else
begin:rdack_if

always @(posedge clk_rd or negedge rst_n)
begin
    if(rst_n == 1'b0)
        rd_data <= #U_DLY {PB_DW{1'b0}};
    else begin
        rd_data <= #U_DLY mem[rdptr_next[PB_AW-1:SUBAB_AW]][rdptr_next[SUBAB_AW-1:0]*PB_DW+:PB_DW];
    end
end

end

assign rdcnt_next = {wrptr_bin,{SUBAB_AW{1'b0}}} - rdptr_next;

end
else
begin:rdmin2max_if

if(RD_AS_ACK == "FALSE")
begin:rdreq_if

always @(posedge clk_rd or negedge rst_n)
begin
    if(rst_n == 1'b0)
        rd_data <= #U_DLY {PB_DW{1'b0}};
    else begin
        if(~empty && rd_en)
            rd_data <= #U_DLY mem[rdptr[PB_AW-1:0]];
        else
            ;        
    end
end

end
else
begin:rdack_if

always @(posedge clk_rd or negedge rst_n)
begin
    if(rst_n == 1'b0)
        rd_data <= #U_DLY {PB_DW{1'b0}};
    else begin
        rd_data <= #U_DLY mem[rdptr_next[PB_AW-1:0]];
    end
end

end

assign rdcnt_next = wrptr_bin[PA_AW:SUBAB_AW] - rdptr_next;

end
endgenerate

always @ (posedge clk_rd or negedge rst_n)
begin
    if(rst_n == 1'b0) begin
        empty <= #U_DLY 1'b1;
        aempty <= #U_DLY 1'b1;
        rd_cnt <= #U_DLY {PB_AW{1'b0}};
    end
    else begin
        if(rdcnt_next <= {{(PB_AW+1){1'b0}}})
            empty <= #U_DLY 1'b1;
        else
            empty <= #U_DLY 1'b0;

        if(rdcnt_next <= {{PB_AW{1'b0}},1'b1})
            aempty <= #U_DLY 1'b1;
        else
            aempty <= #U_DLY 1'b0;

        rd_cnt <= #U_DLY rdcnt_next;
    end
end

asfifo_dec2gray #
(
    .PIPLE_LINE                     (1                          ), // 
    .DW                             (PA_AW+1                    ), 
    .U_DLY                          (U_DLY                      )  // 
)
u0_asfifo_dec2gray
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_sys                        (clk_wr                     ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Dec In
// ---------------------------------------------------------------------------------
    .idata                          (wrptr                      ), // (input )
// ---------------------------------------------------------------------------------
// Gray Out
// ---------------------------------------------------------------------------------
    .odata                          (wrptr_gray                 )  // (output)
); 

asfifo_dec2gray #
(
    .PIPLE_LINE                     (1                          ), // 
    .DW                             (PB_AW+1                    ), 
    .U_DLY                          (U_DLY                      )  // 
)
u1_asfifo_dec2gray
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_sys                        (clk_rd                     ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Dec In
// ---------------------------------------------------------------------------------
    .idata                          (rdptr                      ), // (input )
// ---------------------------------------------------------------------------------
// Gray Out
// ---------------------------------------------------------------------------------
    .odata                          (rdptr_gray                 )  // (output)
); 

asfifo_gray2dec #
(
    .PIPLE_LINE                     (1                          ), // 
    .DW                             (PB_AW+1                    ), 
    .U_DLY                          (U_DLY                      )  // 
)
u0_asfifo_gray2dec
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_sys                        (clk_wr                     ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Gray In
// ---------------------------------------------------------------------------------
    .idata                          (rdptr_dly[0]               ), // (input )
// ---------------------------------------------------------------------------------
// Dec Out
// ---------------------------------------------------------------------------------
    .odata                          (rdptr_bin                  )  // (output)
);

asfifo_gray2dec #
(
    .PIPLE_LINE                     (1                          ), // 
    .DW                             (PA_AW+1                    ), 
    .U_DLY                          (U_DLY                      )  // 
)
u1_asfifo_gray2dec
(
// ---------------------------------------------------------------------------------
// CLock & Reset
// ---------------------------------------------------------------------------------
    .clk_sys                        (clk_wr                     ), // (input )
    .rst_n                          (rst_n                      ), // (input )
// ---------------------------------------------------------------------------------
// Gray In
// ---------------------------------------------------------------------------------
    .idata                          (wrptr_dly[0]               ), // (input )
// ---------------------------------------------------------------------------------
// Dec Out
// ---------------------------------------------------------------------------------
    .odata                          (wrptr_bin                  )  // (output)
);


function integer LOG2 ;
input integer d;
begin
    LOG2 = 1;
    while((2**LOG2-1) < d)
        LOG2 = LOG2 + 1;
end
endfunction

endmodule


