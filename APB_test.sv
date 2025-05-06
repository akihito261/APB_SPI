// Testbench for apb_slave module
module tb_apb_slave;
    // Clock and reset
    logic clk, rst;
    // APB Interface
    logic psel, penable, pwrite;
    logic [31:0] paddr, pwdata, prdata;
    logic pready, pslverr;
    // Internal Interface to register_block
    logic rd_en, wr_en;
    logic [31:0] waddr, raddr, wdata, rdata;
    logic rack, wack, waddrerr, raddrerr;

    // Instantiate DUT
    apb_slave dut (
        .clk, .rst, .psel, .penable, .pwrite, .paddr, .pwdata,
        .prdata, .pready, .pslverr, .rd_en, .wr_en,
        .waddr, .raddr, .wdata, .rdata,
        .rack, .wack, .waddrerr, .raddrerr
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock (10 ns period)
    end

    // Simulate register_block responses
    always @(posedge clk) begin
        // Default responses
        rdata = 32'hDEADBEEF; // Simulated read data
        wack = 0;
        rack = 0;
        waddrerr = 0;
        raddrerr = 0;

        // Generate wack/rack for valid addresses
        if (wr_en) begin
            if (waddr == 32'h0 || waddr == 32'h8 || waddr == 32'hC)
                wack = 1;
            else
                waddrerr = 1;
        end
        if (rd_en) begin
            if (raddr == 32'h0 || raddr == 32'h4 || raddr == 32'h8 || raddr == 32'hC || raddr == 32'h10)
                rack = 1;
            else
                raddrerr = 1;
        end
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

        // Reset
        #5 rst = 1;

        // Test 1: Write to valid address (0x0)
        apb_transaction(1, 32'h0, 32'h000000A5);

        // Test 2: Write to valid address (0x8)
        apb_transaction(1, 32'h8, 32'h000001FF);

        // Test 3: Write to valid address (0xC)
        apb_transaction(1, 32'hC, 32'h00000001);

        // Test 4: Read from valid address (0x4)
        apb_transaction(0, 32'h4, 32'h0);

        // Test 5: Read from valid address (0x10)
        apb_transaction(0, 32'h10, 32'h0);

        // Test 6: Write to invalid address (0xFF)
        apb_transaction(1, 32'hFF, 32'h12345678);

        // Test 7: Read from invalid address (0xFF)
        apb_transaction(0, 32'hFF, 32'h0);

        // End simulation
        #100 $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t state=%0d psel=%b penable=%b pwrite=%b paddr=%h pwdata=%h prdata=%h pready=%b pslverr=%b wr_en=%b rd_en=%b waddr=%h raddr=%h wdata=%h",
                 $time, dut.state, psel, penable, pwrite, paddr, pwdata, prdata, pready, pslverr, wr_en, rd_en, waddr, raddr, wdata);
    end

    // Dump waveform
    initial begin
        $dumpfile("tb_apb_slave.vcd");
        $dumpvars(0, tb_apb_slave);
    end
endmodule