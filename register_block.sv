module register_block (
    input clk,
    input reset,
    input  [31:0] waddr,
    input  [31:0] raddr,
    input  [31:0] wdata,
    input  wr_en,
    input  rd_en,
    output logic [31:0] rdata,
    output logic rack,
    output logic wack,
    output logic waddrerr,
    output logic raddrerr,

    output logic [31:0] tx_data,         
    output logic ctrl_cpol,
    output logic ctrl_cpha,
    output logic ctrl_order,
    output logic [3:0] ctrl_slave_en,
    output logic ctrl_rd,
    output logic [1:0] ctrl_scks,
    output logic start_op,
    
    input logic [31:0] rx_data,                       
    input busy
);

    localparam TX_ADDR = 32'h0;
    localparam RX_ADDR = 32'h4;
    localparam CFG_ADDR = 32'h8;
    localparam CTRL_ADDR = 32'hC;
    localparam STT_ADDR = 32'h10;

    logic [31:0] rdata_next;                
    logic [31:0] tx_data_next;               
    logic [31:0] cfg_data, cfg_data_next;    
    logic [31:0] ctrl_data, ctrl_data_next;  
    logic [31:0] stt_data, stt_data_next;                  

    logic tx_data_wen;
    logic cfg_wen;
    logic ctrl_wen;

    logic tx_data_ren;
    logic rx_data_ren;
    logic cfg_ren;
    logic ctrl_ren;
    logic stt_ren;

    // config
    assign ctrl_cpol = cfg_data[0];
    assign ctrl_cpha = cfg_data[1];
    assign ctrl_order = cfg_data[2];
    assign ctrl_slave_en = cfg_data[6:3];
    assign ctrl_rd = cfg_data[7];
    assign ctrl_scks = cfg_data[9:8];

    assign start_op = ctrl_data[0];

    assign stt_data_next = {31'b0 ,busy};
    // tín hiệu ghi 
    assign tx_data_wen = (wr_en == 1 && waddr == TX_ADDR);
    assign cfg_wen = (wr_en == 1 && waddr == CFG_ADDR);
    assign ctrl_wen = (wr_en == 1 && waddr == CTRL_ADDR);
    assign waddrerr = (wr_en == 1 && !(waddr inside {TX_ADDR, CFG_ADDR, CTRL_ADDR}));
     
    // tisn hiệu đọc
    assign tx_data_ren = (rd_en == 1 && raddr == TX_ADDR);
    assign rx_data_ren = (rd_en == 1 && raddr == RX_ADDR);
    assign cfg_ren = (rd_en == 1 && raddr == CFG_ADDR);
    assign ctrl_ren = (rd_en == 1 && raddr == CTRL_ADDR);
    assign stt_ren = (rd_en == 1 && raddr == STT_ADDR);
    assign raddrerr = (rd_en == 1 && !(raddr inside {TX_ADDR, RX_ADDR, CFG_ADDR, CTRL_ADDR, STT_ADDR}));
     

    // ff 
    assign tx_data_next = tx_data_wen ? wdata : tx_data; 
    assign cfg_data_next = cfg_wen ? {22'b0, wdata[9:0]} : cfg_data; 
    assign ctrl_data_next = ctrl_wen ? {31'b0, wdata[0]} : ctrl_data; 

    always_comb begin
        if (rd_en && ~raddrerr) begin
            unique case (raddr)
                TX_ADDR: rdata_next = tx_data;
                RX_ADDR: rdata_next = rx_data;
                CFG_ADDR: rdata_next = cfg_data;
                CTRL_ADDR: rdata_next = ctrl_data;
                STT_ADDR: rdata_next = stt_data;
                default: rdata_next = 0;
            endcase
        end else begin
            rdata_next = rdata;
        end
    end

    always_ff @(posedge clk, negedge reset) begin
        if (!reset) begin
            tx_data <= 0;
            cfg_data <= 0;
            ctrl_data <= 0;
            rdata <= 0;
            stt_data <= 0;
        end else begin
            tx_data <= tx_data_next;
            cfg_data <= cfg_data_next;
            ctrl_data <= ctrl_data_next;
            rdata <= rdata_next;
            stt_data <= stt_data_next;
            rack <= rd_en && !raddrerr;
            wack <= wr_en && !waddrerr;
        end
    end

endmodule