module apb_slave2 (
    // APB Interface
    input clk,
    input rst,
    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    input  logic [31:0] paddr,
    input  logic [31:0] pwdata,
    output logic [31:0] prdata,
    output logic        pready,
    output logic        pslverr,
    output logic  rd_en,
    // Internal Bus Interface
    output logic [31:0] waddr,
    output logic [31:0] raddr,
    output logic [31:0] wdata,
    output logic        wr_en,
    input  logic [31:0] rdata,
    input  logic        rack,
    input  logic        wack,
    input  logic        waddrerr,
    input  logic        raddrerr
);

localparam IDLE_STATE = 2'b00;
localparam SETUP_STATE = 2'b01;
localparam ACCESS_STATE= 2'b10;

logic [1:0] state;
logic [1:0] next_state;
logic transfer;
assign rd_en = pesl & ~pwrite & penable;
assign pready = wack | rack;
assign pslverr = waddrerr | raddrerr; 
always_comb begin
    if(state == SETUP_STATE) begin 
        if(pwrite) begin
            waddr = paddr;
        end
        else begin
            raddr = paddr;
        end 
            
    end
    else if(state == ACCESS_STATE) begin 

        if(pwrite) begin
            wdata = pwdata;
            wr_en = 1;
        end
        else begin
            prdata = rdata;
            rd_en = 1;
    end
    else(state) begin
    end
end
end
always_comb begin
    if(state == IDLE_STATE )begin
        if(psel == 0 && penable ==0 && transfer == 0) begin
            next_state = IDLE_STATE;
        end
        else if(psel == 1 && penable ==0 && transfer == 1)begin
            next_state = SETUP_STATE;
        end
        else begin
            pslverr = 1;
        end
    end
    else if(state == SETUP_STATE) begin
         if (psel == 1 && penable == 0) begin
            next_state = SETUP_STATE;
        end
        else if (psel == 1 && penable == 1) begin
            next_state = ACCESS_STATE;
        end
        else begin
            pslverr = 1;
        end
    end
    else if(state == ACCESS_STATE) begin
         if (psel == 1 && penable == 1 && pready ==0) begin
            next_state = ACCESS_STATE;
        end
        else if (psel == 1 && penable == 1 && pready ==1 && transfer == 1) begin
            next_state = SETUP_STATE;
        end
        else if (psel == 1 && penable == 1 && pready ==1 && transfer == 0) begin
            next_state = IDLE_STATE;
        end
        else begin
            pslverr = 1;
        end
    end
end

always_comb begin 
    if(state == SETUP_STATE) begin 
        if(pwrite == 0) begin 
            ptrb
        end
    end
end

always_ff @(posedge clk or negedge rst) begin
    if(~rst) begin
        state <= IDLE_STATE;
    end
    else begin 
        state <= next_state;
    end

end
endmodule