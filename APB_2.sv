module apb_slave (
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
    output logic [31:0] waddr,    
    output logic [31:0] raddr,    
    output logic [31:0] wdata,   
    input  logic [31:0] rdata,    
    input          rack,          
    input          wack,         
    input          waddrerr,     
    input          raddrerr      
);

    localparam [1:0] IDLE = 2'b00,
                     SETUP = 2'b01,
                     ACCESS = 2'b10;
    
    
    logic [1:0] state, next_state;

    logic [31:0] wdata_next, waddr_next, raddr_next, prdata_next;
    logic        wr_en_next, rd_en_next;

    always_ff @(posedge clk or negedge rst) begin
        if (~rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM 
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (psel && !penable)
                    next_state = SETUP;
            end
            SETUP: begin
                if (psel && penable)
                    next_state = ACCESS;
                else if (!psel)
                    next_state = IDLE;
            end
            ACCESS: begin
                if (pready)
                    next_state = IDLE;
                else
                    next_state = ACCESS;
            end
            default: next_state = IDLE;
        endcase
    end


    always_comb begin
        // đặt giá trị mặc định để tránh latch
        pready = 1'b0;
        pslverr = 1'b0;
        wr_en_next = 1'b0; // wr_en cần được đặt trong ff để tránh việc psel và penable bị bật lên bất ngờ, state không ở trong access nên sẽ có thể ghi data lỗi vào.
        rd_en_next = 1'b0;
        wdata_next = wdata;
        waddr_next = waddr;
        raddr_next = raddr;
        prdata_next = prdata;

        case (state)
            IDLE: begin
                
            end
            SETUP: begin
                    if (pwrite) begin
                        wdata_next = pwdata;
                        waddr_next = paddr;
                    end else begin
                        raddr_next = paddr;
                    end 
            end
            ACCESS: begin
                    pslverr = waddrerr | raddrerr;
                    pready = wack | rack | pslverr;
                    wr_en_next = pready? 0: pwrite;
                    rd_en_next = pready? 0: ~pwrite;
                    prdata_next = pwrite ? 32'd0 : rdata;
                    
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            wdata  <= 32'd0;
            waddr  <= 32'd0;
            raddr  <= 32'd0;
            prdata <= 32'd0;
            wr_en  <= 1'b0;
            rd_en  <= 1'b0;
        end else begin
            wdata  <= wdata_next;
            waddr  <= waddr_next;
            raddr  <= raddr_next;
            prdata <= prdata_next;
            wr_en  <= wr_en_next;
            rd_en  <= rd_en_next;
        end
    end

endmodule