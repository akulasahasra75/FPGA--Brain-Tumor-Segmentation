////////////////////////////////////////////////////////////////////////////////
// top_module.v
// -------------
// Top-level wrapper stub for the Brain Tumor Segmentation FPGA system.
//
// NOTE: This module is NOT the synthesis top.  The Vivado block design
//       generates microblaze_soc_wrapper.v which is set as the top
//       explicitly in build.tcl.  This file is kept as a reference /
//       documentation artifact only.
//
// Port signature intentionally matches artix7.xdc so that if this module
// were ever used as top, pin constraints would resolve without errors.
//
// Target: Artix-7 xc7a100tcsg324-1 (Nexys A7-100T) @ 100 MHz
////////////////////////////////////////////////////////////////////////////////

module top_module (
    input  wire       clk_100mhz,    // 100 MHz system clock
    input  wire       reset_n,       // Active-low reset (CPU_RESETN)

    // UART
    input  wire       uart_rxd,      // UART receive
    output wire       uart_txd,      // UART transmit

    // Status LEDs – matches led[4:0] in artix7.xdc
    //   led[0] = heartbeat
    //   led[1] = processing
    //   led[2] = mode bit 0
    //   led[3] = mode bit 1
    //   led[4] = done
    output wire [4:0] led
);

    // =========================================================================
    // The actual design is in the Vivado block design (build.tcl).
    // microblaze_soc_wrapper (auto-generated) is the synthesis top.
    // This stub is here only so Vivado can compile it without errors.
    // =========================================================================

    // Drive all outputs to safe defaults so no undriven-wire warnings arise.
    assign uart_txd = 1'b1;   // UART idle
    assign led      = 5'b0;

endmodule
