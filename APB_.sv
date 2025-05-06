module apb_slave1 (
    // APB Interface
    input          clk,
    input          rst,
    input          psel,
    input          penable,
    input          pwrite,
    input  logic [31:0] paddr,
    input  logic [31:0] pwdata,
    output logic [31:0] prdata,
    output logic        pready,
    output logic        pslverr,
    output logic        rd_en,
    output logic        wr_en,
    // Internal Bus Interface
    output logic [31:0] waddr,
    output logic [31:0] raddr,
    output logic [31:0] wdata,
    
    input  logic [31:0] rdata,
    input          rack,
    input          wack,
    input          waddrerr,
    input          raddrerr
);

    // Signals for next-state logic
    logic [31:0] wdata_next, waddr_next, raddr_next, prdata_next;
    logic        wr_en_next;

    // Write logic
    assign wdata_next = (psel && pwrite && penable)? pwdata : (wr_en ? 0 : wdata);
    assign waddr_next = (psel && pwrite && penable)? paddr : (wr_en ? 0 : waddr);
    assign wr_en_next = (psel && pwrite && penable)? 1 : (wr_en ? 0 : wr_en);

    assign prdata_next = (psel && ~pwrite && penable)? rdata : (rd_en ? 0 : prdata);
    assign raddr_next = (psel && ~write && penable)? paddr : (rd_en ? 0 : raddr);

    assign rd_en = psel && ~pwrite && penable
    assign pslverr = waddrerr | raddrerr;
    assign pready  = wack | rack;  // assume transaction completes in 1 cycle if ack asserted

    // Sequential logic
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            wdata  <= 32'd0;
            waddr  <= 32'd0;
            wr_en  <= 1'b0;
            raddr  <= 32'd0;
            prdata <= 32'd0;
        end else begin
            wdata  <= wdata_next;
            waddr  <= waddr_next;
            wr_en  <= wr_en_next;
            raddr  <= raddr_next;
            prdata <= prdata_next;
        end
    end

endmodule
