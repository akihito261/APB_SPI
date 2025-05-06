// Testbench for apb_register_top module
module tb_apb_register_top;
    // Clock and reset
    logic clk, rst;
    // APB Interface
    logic psel, penable, pwrite;
    logic [31:0] paddr, pwdata, prdata;
    logic pready, pslverr;
    // SPI Interface
    logic [31:0] tx_data;
    logic ctrl_cpol, ctrl_cpha, ctrl_order;
    logic [3:0] ctrl_slave_en;
    logic ctrl_rd;
    logic [1:0] ctrl_scks;
    logic start_op;
    logic [31:0] rx_data;
    logic busy;

    // Instantiate DUT
    apb_register_top dut (
        .clk, .rst, .psel, .penable, .pwrite, .paddr, .pwdata,
        .prdata, .pready, .pslverr,
        .tx_data, .ctrl_cpol, .ctrl_cpha, .ctrl_order,
        .ctrl_slave_en, .ctrl_rd, .ctrl_scks, .start_op,
        .rx_data, .busy
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock (10 ns period)
    end

    // Simulate SPI responses
    initial begin
        rx_data = 32'h00000000;
        busy = 1;
        // Simulate busy signal when start_op is asserted
        
    end

    // Task to perform APB transaction
    task apb_transaction(input logic write, input [31:0] addr, input [31:0] data);
        // Wait for previous transaction to complete (pready = 0)
        @(posedge clk);
        while (pready) @(posedge clk); // Wait until pready = 0
        @(posedge clk); // Ensure clean start

        // SETUP phase
        psel = 1;
        pwrite = write;
        paddr = addr;
        pwdata = data;
        penable = 0;

        // ACCESS phase
        @(posedge clk);
        penable = 1;

        // Wait for pready
        while (!pready) @(posedge clk);

        // End transaction
        @(posedge clk);
        psel = 0;
        penable = 0;
        @(posedge clk); // Idle cycle
    endtask

    // Test stimulus
    initial begin
        // Initialize signals
        rst = 0;
        psel = 0;
        penable = 0;
        pwrite = 0;
        paddr = 0;
        pwdata = 0;
        rx_data = 32'h00000000;
        

        // Reset
        #5 rst = 1;

        // Test 1: Write to TX_DATA (0x0)
        apb_transaction(1, 32'h0, 32'h000000A5);
        apb_transaction(1, 32'h0, 32'h00000033);
        // Test 2: Write to CFG (0x8)
        apb_transaction(1, 32'h8, 32'h000001FF); // cpol=1, cpha=1, order=1, scks=3
        apb_transaction(1, 32'h0, 32'h000000A5);

        // Test 3: Write to CTRL (0xC)
        apb_transaction(1, 32'hC, 32'h00000011); // slave_en=1, rd=0, start_op=1
        apb_transaction(1, 32'h0, 32'h00000044);

        apb_transaction(1, 32'h10, 32'h000000A5);

        
        // Test 4: Read from RX_DATA (0x4)
        #50; // Wait for SPI operation to complete
        apb_transaction(0, 32'h0, 32'h0); // Expect rx_data = 0xAABBCCDD
        apb_transaction(0, 32'h4, 32'h0); // Expect rx_data = 0xAABBCCDD

        // Test 5: Read from STT (0x10)
        apb_transaction(0, 32'h10, 32'h0); // Expect busy = 0

        // Test 6: Write to invalid address (0xFF)
        apb_transaction(1, 32'hFF, 32'h12345678);

        // Test 7: Read from invalid address (0xFF)
        apb_transaction(0, 32'hFF, 32'h0);

        // End simulation
        #100 $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t state=%0d psel=%b penable=%b pwrite=%b paddr=%h pwdata=%h prdata=%h pready=%b pslverr=%b start_op=%b busy=%b rx_data=%h tx_data=%h",
                 $time, dut.u_apb_slave.state, psel, penable, pwrite, paddr, pwdata, prdata, pready, pslverr, start_op, busy, rx_data, tx_data);
    end

    // Dump waveform
    initial begin
        $dumpfile("tb_apb_register_top.vcd");
        $dumpvars(0, tb_apb_register_top);
    end
endmodule