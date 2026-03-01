////////////////////////////////////////////////////////////////////////////////
// top_module.v
// -------------
// Top-level wrapper for the Brain Tumor Segmentation FPGA system.
//
// Block diagram:
//   MicroBlaze ──AXI──┬── BRAM Controller ── BRAM (image storage)
//                     ├── Otsu HLS IP      (accelerator)
//                     └── AXI UART Lite    (debug output)
//
// Target: Artix-7 xc7a35tcpg236-1 (Basys 3) @ 100 MHz
////////////////////////////////////////////////////////////////////////////////

module top_module (
    input  wire       clk_100mhz,    // 100 MHz system clock
    input  wire       reset_n,       // Active-low reset (button)

    // UART
    input  wire       uart_rxd,      // UART receive
    output wire       uart_txd,      // UART transmit

    // Status LEDs
    output wire [3:0] led,           // Status indicators

    // Debug / test
    output wire       done_led       // Processing-complete indicator
);

    // =========================================================================
    // Internal signals
    // =========================================================================
    wire        sys_clk;
    wire        sys_rst;
    wire        locked;

    // AXI interconnect signals (directly wired by Vivado block design)
    // These are placeholders – actual connections are made in the block design.

    // Processing status
    reg         processing_done;
    reg  [1:0]  current_mode;       // 0=FAST, 1=NORMAL, 2=CAREFUL

    // =========================================================================
    // Clock and Reset
    // =========================================================================

    // Use the 100 MHz input directly (no PLL needed for this clock rate)
    assign sys_clk = clk_100mhz;
    assign sys_rst = ~reset_n;       // Convert active-low to active-high

    // =========================================================================
    // LED Status Indicators
    // =========================================================================
    //   led[0] = system alive (heartbeat)
    //   led[1] = processing in progress
    //   led[2] = mode bit 0
    //   led[3] = mode bit 1

    reg [25:0] heartbeat_counter;
    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst)
            heartbeat_counter <= 26'd0;
        else
            heartbeat_counter <= heartbeat_counter + 1'b1;
    end

    assign led[0]   = heartbeat_counter[25];    // ~1.5 Hz blink
    assign led[1]   = ~processing_done;         // ON while processing
    assign led[2]   = current_mode[0];
    assign led[3]   = current_mode[1];
    assign done_led = processing_done;

    // =========================================================================
    // MicroBlaze System (instantiated by Vivado block design)
    // =========================================================================
    // The actual MicroBlaze + AXI interconnect + BRAM + HLS IP + UART are
    // created in the Vivado block design (build.tcl).  This top module wraps
    // the block design and connects external I/O.
    //
    // Block design instance name: microblaze_system
    //
    // Ports exposed by the block design wrapper:
    //   .clk_100mhz     (sys_clk)
    //   .reset           (sys_rst)
    //   .uart_rxd        (uart_rxd)
    //   .uart_txd        (uart_txd)
    //   .processing_done (processing_done_wire)
    //   .current_mode    (current_mode_wire)

    wire processing_done_wire;
    wire [1:0] current_mode_wire;

    // NOTE: Uncomment and adjust once block design is generated:
    // microblaze_system_wrapper u_system (
    //     .clk_100mhz         (sys_clk),
    //     .reset               (sys_rst),
    //     .uart_rxd            (uart_rxd),
    //     .uart_txd            (uart_txd),
    //     .processing_done     (processing_done_wire),
    //     .current_mode        (current_mode_wire)
    // );

    // Latch status signals from block design
    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst) begin
            processing_done <= 1'b0;
            current_mode    <= 2'b00;
        end else begin
            processing_done <= processing_done_wire;
            current_mode    <= current_mode_wire;
        end
    end

endmodule
