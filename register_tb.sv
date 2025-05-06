// Testbench for register_block module
module tb_register_block;
    // Clock and reset
    logic clk, reset;
    // Input signals
    logic [31:0] waddr, raddr, wdata;
    logic wr_en, rd_en;
    logic [31:0] rx_data;
    logic busy;
    // Output signals
    logic [31:0] rdata;
    logic rack, wack, waddrerr, raddrerr;
    logic [31:0] tx_data;
    logic ctrl_cpol, ctrl_cpha, ctrl_order;
    logic [3:0] ctrl_slave_en;
    logic ctrl_rd;
    logic [1:0] ctrl_scks;
    logic start_op;

    // Instantiate DUT
    register_block dut (
        .clk, .reset, .waddr, .raddr, .wdata, .wr_en, .rd_en,
        .rdata, .rack, .wack, .waddrerr, .raddrerr,
        .tx_data, .ctrl_cpol, .ctrl_cpha, .ctrl_order,
        .ctrl_slave_en, .ctrl_rd, .ctrl_scks, .start_op,
        .rx_data, .busy
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Test stimulus
    initial begin
        // Initialize signals
        reset = 0;
        waddr = 0;
        raddr = 0;
        wdata = 0;
        wr_en = 0;
        rd_en = 0;
        rx_data = 32'hDEADBEEF;
        busy = 0;

        // Reset
        #10 reset = 1;

        // Test 1: Write to TX_DATA (0x0)
        #10 waddr = 32'h0; wdata = 32'h000000A5; wr_en = 1; // Write 8-bit data 0xA5
        #10 wr_en = 0;
        #10; // Wait for register update

        // Test 2: Write to CFG (0x8)
        #10 waddr = 32'h8; wdata = 32'h000001FF; wr_en = 1; // Set config bits
        #10 wr_en = 0;
        #10;

        // Test 3: Write to CTRL (0xC)
        #10 waddr = 32'hC; wdata = 32'h00000001; wr_en = 1; // Start operation
        #10 wr_en = 0;
        #10;

        // Test 4: Read from TX_DATA (0x0)
        #10 raddr = 32'h0; rd_en = 1;
        #10 rd_en = 0;
        #10;

        // Test 5: Read from RX_DATA (0x4)
        #10 raddr = 32'h4; rd_en = 1;
        #10 rd_en = 0;
        #10;

        // Test 6: Read from CFG (0x8)
        #10 raddr = 32'h8; rd_en = 1;
        #10 rd_en = 0;
        #10;

        // Test 7: Read from CTRL (0xC)
        #10 raddr = 32'hC; rd_en = 1;
        #10 rd_en = 0;
        #10;

        // Test 8: Read from STT (0x10) with busy = 1
        #10 raddr = 32'h10; rd_en = 1; busy = 1;
        #10 rd_en = 0; busy = 0;
        #10;

        // Test 9: Write to invalid address (0xFF)
        #10 waddr = 32'hFF; wdata = 32'h12345678; wr_en = 1;
        #10 wr_en = 0;
        #10;

        // Test 10: Read from invalid address (0xFF)
        #10 raddr = 32'hFF; rd_en = 1;
        #10 rd_en = 0;
        #10;

        // End simulation
        #50 $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t reset=%b wr_en=%b rd_en=%b waddr=%h raddr=%h wdata=%h rdata=%h wack=%b rack=%b waddrerr=%b raddrerr=%b tx_data=%h start_op=%b busy=%b",
                 $time, reset, wr_en, rd_en, waddr, raddr, wdata, rdata, wack, rack, waddrerr, raddrerr, tx_data, start_op, busy);
    end

    // Dump waveform
    initial begin
        $dumpfile("tb_register_block.vcd");
        $dumpvars(0, tb_register_block);
    end
endmodule