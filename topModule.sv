// Top module: Integrates apb_slave and register_block
module apb_register_top (
    // APB Interface
    input          clk,          // System clock
    input          rst,          // Active-low reset
    input          psel,         // Peripheral select
    input          penable,      // Enable signal for ACCESS phase
    input          pwrite,       // Write (1) or read (0)
    input  logic [31:0] paddr,   // Address
    input  logic [31:0] pwdata,  // Write data
    output logic [31:0] prdata,  // Read data
    output logic        pready,   // Ready signal
    output logic        pslverr,  // Slave error signal
    // SPI Interface (from register_block)
    output logic [31:0] tx_data,          // Transmit data
    output logic        ctrl_cpol,        // Clock polarity
    output logic        ctrl_cpha,        // Clock phase
    output logic        ctrl_order,       // Data order
    output logic [3:0]  ctrl_slave_en,    // Slave enable
    output logic        ctrl_rd,          // Read enable
    output logic [1:0]  ctrl_scks,        // Clock speed select
    output logic        start_op,         // Start operation
    input  logic [31:0] rx_data,          // Receive data
    input  logic        busy              // Busy signal from SPI peripheral
);

    // Internal signals between apb_slave and register_block
    logic [31:0] waddr, raddr, wdata, rdata;
    logic        rd_en, wr_en, rack, wack, waddrerr, raddrerr;

    // Instantiate apb_slave
    apb_slave u_apb_slave (
        .clk, .rst, .psel, .penable, .pwrite, .paddr, .pwdata,
        .prdata, .pready, .pslverr, .rd_en, .wr_en,
        .waddr, .raddr, .wdata, .rdata,
        .rack, .wack, .waddrerr, .raddrerr
    );

    // Instantiate register_block
    register_block u_register_block (
        .clk, .reset(rst), .waddr, .raddr, .wdata, .wr_en, .rd_en,
        .rdata, .rack, .wack, .waddrerr, .raddrerr,
        .tx_data, .ctrl_cpol, .ctrl_cpha, .ctrl_order,
        .ctrl_slave_en, .ctrl_rd, .ctrl_scks, .start_op,
        .rx_data, .busy
    );

endmodule