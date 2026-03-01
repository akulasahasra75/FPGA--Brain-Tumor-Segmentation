////////////////////////////////////////////////////////////////////////////////
// bram_controller.v
// ------------------
// Dual-port BRAM controller for image storage.
//
// Port A: MicroBlaze / AXI master (read/write images)
// Port B: HLS Otsu IP (read input image, write output mask)
//
// Memory layout (64 KB BRAM = 65536 bytes):
//   0x0000 – 0xFFFF : Image buffer (256×256 = 65536 bytes)
//
// Two BRAMs are used:
//   BRAM_INPUT  – holds the input grayscale image
//   BRAM_OUTPUT – holds the output binary mask
//
// Target: Artix-7, 100 MHz
////////////////////////////////////////////////////////////////////////////////

module bram_controller #(
    parameter ADDR_WIDTH = 16,              // 2^16 = 65536 bytes
    parameter DATA_WIDTH = 8                // 8-bit pixel data
)(
    input  wire                    clk,
    input  wire                    rst,

    // === Port A: CPU / AXI side ===
    input  wire                    a_en,
    input  wire                    a_we,
    input  wire [ADDR_WIDTH-1:0]   a_addr,
    input  wire [DATA_WIDTH-1:0]   a_din,
    output reg  [DATA_WIDTH-1:0]   a_dout,

    // === Port B: HLS accelerator side ===
    input  wire                    b_en,
    input  wire                    b_we,
    input  wire [ADDR_WIDTH-1:0]   b_addr,
    input  wire [DATA_WIDTH-1:0]   b_din,
    output reg  [DATA_WIDTH-1:0]   b_dout
);

    // =========================================================================
    // Block RAM inference (dual-port, 65536 × 8-bit)
    // =========================================================================
    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];

    // Initialise to zero
    integer i;
    initial begin
        for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1)
            mem[i] = {DATA_WIDTH{1'b0}};
    end

    // =========================================================================
    // Port A (CPU side) – synchronous read/write
    // =========================================================================
    always @(posedge clk) begin
        if (a_en) begin
            if (a_we)
                mem[a_addr] <= a_din;
            a_dout <= mem[a_addr];
        end
    end

    // =========================================================================
    // Port B (HLS accelerator side) – synchronous read/write
    // =========================================================================
    always @(posedge clk) begin
        if (b_en) begin
            if (b_we)
                mem[b_addr] <= b_din;
            b_dout <= mem[b_addr];
        end
    end

endmodule
