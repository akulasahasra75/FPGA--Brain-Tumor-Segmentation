////////////////////////////////////////////////////////////////////////////////
// axi_interface.v
// ----------------
// AXI4-Lite slave interface for custom control / status registers.
//
// Register Map (32-bit aligned):
//   Offset 0x00  [W]  CONTROL    – bit 0: start, bit 1: reset results
//   Offset 0x04  [W]  MODE       – processing mode (0/1/2)
//   Offset 0x08  [W]  IMG_ADDR   – base address of input image in BRAM
//   Offset 0x0C  [W]  OUT_ADDR   – base address of output mask in BRAM
//   Offset 0x10  [R]  STATUS     – bit 0: busy, bit 1: done
//   Offset 0x14  [R]  THRESHOLD  – computed Otsu threshold (8-bit)
//   Offset 0x18  [R]  FG_PIXELS  – foreground pixel count
//   Offset 0x1C  [R]  MODE_USED  – actual mode executed
//
// Target: Artix-7, 100 MHz AXI clock
////////////////////////////////////////////////////////////////////////////////

module axi_interface #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 5        // 32 bytes → 5-bit address
)(
    // AXI4-Lite Slave Interface
    input  wire                                s_axi_aclk,
    input  wire                                s_axi_aresetn,

    // Write address channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]       s_axi_awaddr,
    input  wire                                s_axi_awvalid,
    output reg                                 s_axi_awready,

    // Write data channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]       s_axi_wdata,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0]     s_axi_wstrb,
    input  wire                                s_axi_wvalid,
    output reg                                 s_axi_wready,

    // Write response channel
    output reg  [1:0]                          s_axi_bresp,
    output reg                                 s_axi_bvalid,
    input  wire                                s_axi_bready,

    // Read address channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]       s_axi_araddr,
    input  wire                                s_axi_arvalid,
    output reg                                 s_axi_arready,

    // Read data channel
    output reg  [C_S_AXI_DATA_WIDTH-1:0]       s_axi_rdata,
    output reg  [1:0]                          s_axi_rresp,
    output reg                                 s_axi_rvalid,
    input  wire                                s_axi_rready,

    // Control / Status ports (directly to/from logic)
    output reg                                 ctrl_start,
    output reg                                 ctrl_reset,
    output reg  [1:0]                          ctrl_mode,
    output reg  [31:0]                         ctrl_img_addr,
    output reg  [31:0]                         ctrl_out_addr,

    input  wire                                stat_busy,
    input  wire                                stat_done,
    input  wire [7:0]                          stat_threshold,
    input  wire [31:0]                         stat_fg_pixels,
    input  wire [7:0]                          stat_mode_used
);

    // =========================================================================
    // Register offsets (word-aligned)
    // =========================================================================
    localparam ADDR_CONTROL   = 5'h00;
    localparam ADDR_MODE      = 5'h04;
    localparam ADDR_IMG_ADDR  = 5'h08;
    localparam ADDR_OUT_ADDR  = 5'h0C;
    localparam ADDR_STATUS    = 5'h10;
    localparam ADDR_THRESHOLD = 5'h14;
    localparam ADDR_FG_PIXELS = 5'h18;
    localparam ADDR_MODE_USED = 5'h1C;

    // =========================================================================
    // Write logic
    // =========================================================================
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            ctrl_start     <= 1'b0;
            ctrl_reset     <= 1'b0;
            ctrl_mode      <= 2'b00;
            ctrl_img_addr  <= 32'h0;
            ctrl_out_addr  <= 32'h0;
        end else begin
            // Default: deassert start pulse after one cycle
            ctrl_start <= 1'b0;
            ctrl_reset <= 1'b0;

            // Write address & data handshake
            if (s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;

                case (s_axi_awaddr)
                    ADDR_CONTROL: begin
                        ctrl_start <= s_axi_wdata[0];
                        ctrl_reset <= s_axi_wdata[1];
                    end
                    ADDR_MODE:     ctrl_mode     <= s_axi_wdata[1:0];
                    ADDR_IMG_ADDR: ctrl_img_addr <= s_axi_wdata;
                    ADDR_OUT_ADDR: ctrl_out_addr <= s_axi_wdata;
                    default: ; // ignore writes to read-only registers
                endcase

                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;   // OKAY
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            // Write response handshake
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    // =========================================================================
    // Read logic
    // =========================================================================
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= 32'h0;
        end else begin
            // Read address handshake
            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready <= 1'b1;

                case (s_axi_araddr)
                    ADDR_CONTROL:   s_axi_rdata <= {30'b0, ctrl_reset, ctrl_start};
                    ADDR_MODE:      s_axi_rdata <= {30'b0, ctrl_mode};
                    ADDR_IMG_ADDR:  s_axi_rdata <= ctrl_img_addr;
                    ADDR_OUT_ADDR:  s_axi_rdata <= ctrl_out_addr;
                    ADDR_STATUS:    s_axi_rdata <= {30'b0, stat_done, stat_busy};
                    ADDR_THRESHOLD: s_axi_rdata <= {24'b0, stat_threshold};
                    ADDR_FG_PIXELS: s_axi_rdata <= stat_fg_pixels;
                    ADDR_MODE_USED: s_axi_rdata <= {24'b0, stat_mode_used};
                    default:        s_axi_rdata <= 32'hDEADBEEF;
                endcase

                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;   // OKAY
            end else begin
                s_axi_arready <= 1'b0;
            end

            // Read data handshake
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
        end
    end

endmodule
