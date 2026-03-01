################################################################################
# build.tcl
# ----------
# Vivado non-project-mode TCL script for the Brain Tumor Segmentation SoC.
#
# What it does
#   1. Creates a Vivado project targeting Nexys A7-100T (xc7a100tcsg324-1)
#   2. Imports the HLS Otsu IP from ip_repo/
#   3. Creates a MicroBlaze block design with:
#        – MicroBlaze (area-optimised)
#        – Local memory (64 KB BRAM)
#        – AXI interconnect
#        – AXI UART Lite (115200 baud)
#        – HLS accelerator
#        – AXI GPIO (LEDs)
#   4. Adds RTL sources & constraints
#   5. Runs synthesis, implementation, and bitstream generation
#
# Usage
#   vivado -mode batch -source build.tcl
#
# Prerequisites
#   – Copy the HLS IP zip into ip_repo/ before running.
################################################################################

# ==============================================================================
# User-configurable parameters
# ==============================================================================
set project_name   "brain_tumor_soc"
set project_dir    "./vivado_project"
set part           "xc7a100tcsg324-1"
set board_part     "digilentinc.com:nexys-a7-100t:part0:1.3"
set ip_repo_path   "./ip_repo"
set rtl_dir        "./srcs/verilog"
set xdc_file       "./constraints/artix7.xdc"

# ==============================================================================
# Step 0 – Clean previous build
# ==============================================================================
if { [file exists $project_dir] } {
    puts "INFO: Removing previous project directory..."
    file delete -force $project_dir
}

# ==============================================================================
# Step 1 – Create project
# ==============================================================================
create_project $project_name $project_dir -part $part -force
set_property board_part $board_part [current_project]

# Add IP repository (contains HLS Otsu IP)
if { [file exists $ip_repo_path] } {
    set_property ip_repo_paths [list $ip_repo_path] [current_project]
    update_ip_catalog
    puts "INFO: IP repository added from $ip_repo_path"
} else {
    puts "WARNING: IP repository not found at $ip_repo_path – skipping."
}

# ==============================================================================
# Step 2 – Add RTL sources
# ==============================================================================
if { [file exists $rtl_dir] } {
    add_files -norecurse [glob -nocomplain $rtl_dir/*.v]
    puts "INFO: Added Verilog sources from $rtl_dir"
}

# ==============================================================================
# Step 3 – Add constraints
# ==============================================================================
if { [file exists $xdc_file] } {
    add_files -fileset constrs_1 -norecurse $xdc_file
    puts "INFO: Added constraints from $xdc_file"
}

# ==============================================================================
# Step 4 – Create Block Design (MicroBlaze SoC)
# ==============================================================================
set bd_name "microblaze_soc"
create_bd_design $bd_name

# ---- Clock wizard (100 MHz in → 100 MHz + reset out) ----
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
set_property -dict [list \
    CONFIG.PRIM_IN_FREQ      {100.000} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
    CONFIG.USE_LOCKED         {true} \
    CONFIG.USE_RESET          {true} \
    CONFIG.RESET_TYPE         {ACTIVE_LOW} \
] [get_bd_cells clk_wiz_0]

# ---- Processor System Reset ----
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

# ---- MicroBlaze (area-optimised) ----
create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 microblaze_0
set_property -dict [list \
    CONFIG.C_USE_BARREL        {1} \
    CONFIG.C_USE_HW_MUL        {1} \
    CONFIG.C_DEBUG_ENABLED     {1} \
    CONFIG.C_ICACHE_BASEADDR   {0x00000000} \
    CONFIG.C_ICACHE_HIGHADDR   {0x3FFFFFFF} \
    CONFIG.C_DCACHE_BASEADDR   {0x00000000} \
    CONFIG.C_DCACHE_HIGHADDR   {0x3FFFFFFF} \
] [get_bd_cells microblaze_0]

# ---- Local Memory (64 KB for code+data) ----
create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr
create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr
create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10
create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram
set_property -dict [list \
    CONFIG.Memory_Type          {True_Dual_Port_RAM} \
    CONFIG.use_bram_block       {BRAM_Controller} \
    CONFIG.Assume_Synchronous_Clk {true} \
] [get_bd_cells lmb_bram]

# ---- AXI Interconnect (MicroBlaze peripherals) ----
#   6 master ports: UART, GPIO, Timer, HLS control, HLS control_r, Image BRAM
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property CONFIG.NUM_MI {6} [get_bd_cells axi_interconnect_0]

# ---- AXI UART Lite (115200 baud) ----
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0
set_property CONFIG.C_BAUDRATE {115200} [get_bd_cells axi_uartlite_0]

# ---- AXI GPIO (5 LEDs: heartbeat, processing, mode[1:0], done) ----
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
set_property -dict [list \
    CONFIG.C_GPIO_WIDTH  {5} \
    CONFIG.C_ALL_OUTPUTS {1} \
] [get_bd_cells axi_gpio_0]

# ---- AXI Timer (for performance measurement) ----
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 axi_timer_0

# ---- HLS Otsu IP (added only if present in repo) ----
set hls_ip_vlnv [get_ipdefs -filter {NAME =~ *otsu*}]
if { $hls_ip_vlnv ne "" } {
    create_bd_cell -type ip -vlnv $hls_ip_vlnv hls_otsu_0
    puts "INFO: HLS Otsu IP instantiated: $hls_ip_vlnv"
} else {
    puts "WARNING: HLS Otsu IP not found in catalog – add it to ip_repo/ and re-run."
}

# ---- AXI SmartConnect (merges HLS m_axi_gmem0 + gmem1 → BRAM) ----
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smartconnect_0
set_property -dict [list \
    CONFIG.NUM_SI {2} \
    CONFIG.NUM_MI {1} \
] [get_bd_cells axi_smartconnect_0]

# ---- AXI BRAM Controller A (MicroBlaze → shared image BRAM, port A) ----
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
set_property -dict [list \
    CONFIG.SINGLE_PORT_BRAM {1} \
    CONFIG.DATA_WIDTH       {32} \
] [get_bd_cells axi_bram_ctrl_0]

# ---- AXI BRAM Controller B (HLS → shared image BRAM, port B) ----
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_1
set_property -dict [list \
    CONFIG.SINGLE_PORT_BRAM {1} \
    CONFIG.DATA_WIDTH       {32} \
] [get_bd_cells axi_bram_ctrl_1]

# ---- Shared Image BRAM (True Dual Port – 128 KB for input+output images) ----
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 image_bram
set_property -dict [list \
    CONFIG.Memory_Type          {True_Dual_Port_RAM} \
    CONFIG.use_bram_block       {BRAM_Controller} \
    CONFIG.Assume_Synchronous_Clk {true} \
] [get_bd_cells image_bram]

# ==============================================================================
# Step 4b – Connections
# ==============================================================================

# ---- External ports ----
create_bd_port -dir I -type clk clk_100mhz
create_bd_port -dir I -type rst reset_n
create_bd_port -dir I uart_rxd
create_bd_port -dir O uart_txd
create_bd_port -dir O -from 4 -to 0 led

# ---- Clock & reset infrastructure ----
connect_bd_net [get_bd_ports clk_100mhz] [get_bd_pins clk_wiz_0/clk_in1]
connect_bd_net [get_bd_ports reset_n]     [get_bd_pins clk_wiz_0/resetn]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1]  [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins clk_wiz_0/locked]     [get_bd_pins proc_sys_reset_0/dcm_locked]
connect_bd_net [get_bd_ports reset_n]              [get_bd_pins proc_sys_reset_0/ext_reset_in]

# Convenience variables
set sys_clk    [get_bd_pins clk_wiz_0/clk_out1]
set sys_rst    [get_bd_pins proc_sys_reset_0/mb_reset]
set periph_rst [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
set ic_rst     [get_bd_pins proc_sys_reset_0/interconnect_aresetn]

# ---- MicroBlaze clock & reset ----
connect_bd_net $sys_clk [get_bd_pins microblaze_0/Clk]
connect_bd_net $sys_rst [get_bd_pins microblaze_0/Reset]

# ---- LMB connections (instruction bus) ----
connect_bd_intf_net [get_bd_intf_pins microblaze_0/ILMB] \
                    [get_bd_intf_pins ilmb_v10/LMB_M]
connect_bd_intf_net [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] \
                    [get_bd_intf_pins ilmb_v10/LMB_Sl_0]
connect_bd_intf_net [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] \
                    [get_bd_intf_pins lmb_bram/BRAM_PORTA]
connect_bd_net $sys_clk [get_bd_pins ilmb_v10/LMB_Clk]
connect_bd_net $sys_rst [get_bd_pins ilmb_v10/SYS_Rst]
connect_bd_net $sys_clk [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk]
connect_bd_net $sys_rst [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst]

# ---- LMB connections (data bus) ----
connect_bd_intf_net [get_bd_intf_pins microblaze_0/DLMB] \
                    [get_bd_intf_pins dlmb_v10/LMB_M]
connect_bd_intf_net [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] \
                    [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
connect_bd_intf_net [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] \
                    [get_bd_intf_pins lmb_bram/BRAM_PORTB]
connect_bd_net $sys_clk [get_bd_pins dlmb_v10/LMB_Clk]
connect_bd_net $sys_rst [get_bd_pins dlmb_v10/SYS_Rst]
connect_bd_net $sys_clk [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk]
connect_bd_net $sys_rst [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst]

# ---- MicroBlaze AXI data port → Peripheral Interconnect ----
connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_DP] \
                    [get_bd_intf_pins axi_interconnect_0/S00_AXI]

# ---- Peripheral Interconnect → Peripherals ----
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] \
                    [get_bd_intf_pins axi_uartlite_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M01_AXI] \
                    [get_bd_intf_pins axi_gpio_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M02_AXI] \
                    [get_bd_intf_pins axi_timer_0/S_AXI]

# ---- HLS IP connections (control + memory) ----
if { $hls_ip_vlnv ne "" } {
    # AXI-Lite slave: control (mode, result, ap_ctrl)
    connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M03_AXI] \
                        [get_bd_intf_pins hls_otsu_0/s_axi_control]
    # AXI-Lite slave: control_r (img_in, img_out pointers)
    connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M04_AXI] \
                        [get_bd_intf_pins hls_otsu_0/s_axi_control_r]
    # AXI4 masters: image memory access → SmartConnect → BRAM
    connect_bd_intf_net [get_bd_intf_pins hls_otsu_0/m_axi_gmem0] \
                        [get_bd_intf_pins axi_smartconnect_0/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins hls_otsu_0/m_axi_gmem1] \
                        [get_bd_intf_pins axi_smartconnect_0/S01_AXI]
    # Clock & reset for HLS IP
    connect_bd_net $sys_clk [get_bd_pins hls_otsu_0/ap_clk]
    connect_bd_net $periph_rst [get_bd_pins hls_otsu_0/ap_rst_n]
}

# ---- Peripheral Interconnect M05 → Image BRAM Controller A (MicroBlaze side) ----
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M05_AXI] \
                    [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

# ---- SmartConnect → Image BRAM Controller B (HLS side) ----
connect_bd_intf_net [get_bd_intf_pins axi_smartconnect_0/M00_AXI] \
                    [get_bd_intf_pins axi_bram_ctrl_1/S_AXI]

# ---- BRAM Controllers → Shared Image BRAM ----
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] \
                    [get_bd_intf_pins image_bram/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] \
                    [get_bd_intf_pins image_bram/BRAM_PORTB]

# ---- Clock & reset for all AXI infrastructure ----
# AXI Interconnect
connect_bd_net $sys_clk    [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net $ic_rst     [get_bd_pins axi_interconnect_0/ARESETN]
# Interconnect slave/master port clocks
foreach port {S00_ACLK M00_ACLK M01_ACLK M02_ACLK M03_ACLK M04_ACLK M05_ACLK} {
    connect_bd_net $sys_clk [get_bd_pins axi_interconnect_0/$port]
}
foreach port {S00_ARESETN M00_ARESETN M01_ARESETN M02_ARESETN M03_ARESETN M04_ARESETN M05_ARESETN} {
    connect_bd_net $periph_rst [get_bd_pins axi_interconnect_0/$port]
}
# AXI peripherals
foreach cell {axi_uartlite_0 axi_gpio_0 axi_timer_0 axi_bram_ctrl_0 axi_bram_ctrl_1} {
    connect_bd_net $sys_clk    [get_bd_pins $cell/s_axi_aclk]
    connect_bd_net $periph_rst [get_bd_pins $cell/s_axi_aresetn]
}
# SmartConnect
connect_bd_net $sys_clk    [get_bd_pins axi_smartconnect_0/aclk]
connect_bd_net $periph_rst [get_bd_pins axi_smartconnect_0/aresetn]

# ---- UART external ports ----
connect_bd_net [get_bd_ports uart_rxd] [get_bd_pins axi_uartlite_0/rx]
connect_bd_net [get_bd_ports uart_txd] [get_bd_pins axi_uartlite_0/tx]

# ---- GPIO external ports (LEDs) ----
connect_bd_net [get_bd_ports led] [get_bd_pins axi_gpio_0/gpio_io_o]

# ==============================================================================
# Step 5 – Address map
# ==============================================================================
# MicroBlaze peripheral address map
assign_bd_address -target_address_space /microblaze_0/Data \
    [get_bd_addr_segs {axi_uartlite_0/S_AXI/Reg}] -range 64K -offset 0x40600000
assign_bd_address -target_address_space /microblaze_0/Data \
    [get_bd_addr_segs {axi_gpio_0/S_AXI/Reg}]     -range 64K -offset 0x40000000
assign_bd_address -target_address_space /microblaze_0/Data \
    [get_bd_addr_segs {axi_timer_0/S_AXI/Reg}]    -range 64K -offset 0x41C00000
# MicroBlaze → image BRAM (via BRAM Controller A)
assign_bd_address -target_address_space /microblaze_0/Data \
    [get_bd_addr_segs {axi_bram_ctrl_0/S_AXI/Mem0}] -range 128K -offset 0x80000000
if { $hls_ip_vlnv ne "" } {
    # MicroBlaze → HLS control registers
    assign_bd_address -target_address_space /microblaze_0/Data \
        [get_bd_addr_segs {hls_otsu_0/s_axi_control/Reg}] -range 64K -offset 0x44A00000
    assign_bd_address -target_address_space /microblaze_0/Data \
        [get_bd_addr_segs {hls_otsu_0/s_axi_control_r/Reg}] -range 64K -offset 0x44A10000
    # HLS gmem0 → image BRAM (via BRAM Controller B)
    assign_bd_address -target_address_space /hls_otsu_0/Data_m_axi_gmem0 \
        [get_bd_addr_segs {axi_bram_ctrl_1/S_AXI/Mem0}] -range 128K -offset 0x80000000
    # HLS gmem1 → image BRAM (via BRAM Controller B)
    assign_bd_address -target_address_space /hls_otsu_0/Data_m_axi_gmem1 \
        [get_bd_addr_segs {axi_bram_ctrl_1/S_AXI/Mem0}] -range 128K -offset 0x80000000
}

# ==============================================================================
# Step 6 – Validate & generate
# ==============================================================================
validate_bd_design
save_bd_design
generate_target all [get_files $project_dir/$project_name.srcs/sources_1/bd/$bd_name/$bd_name.bd]
make_wrapper -files [get_files $project_dir/$project_name.srcs/sources_1/bd/$bd_name/$bd_name.bd] -top
add_files -norecurse $project_dir/$project_name.gen/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v

# ==============================================================================
# Step 7 – Synthesis
# ==============================================================================
puts "INFO: Starting synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if { [get_property STATUS [get_runs synth_1]] ne "synth_design Complete!" } {
    puts "ERROR: Synthesis failed."
    exit 1
}
puts "INFO: Synthesis complete."

# ==============================================================================
# Step 8 – Implementation
# ==============================================================================
puts "INFO: Starting implementation..."
launch_runs impl_1 -jobs 4
wait_on_run impl_1
if { [get_property STATUS [get_runs impl_1]] ne "route_design Complete!" } {
    puts "ERROR: Implementation failed."
    exit 1
}
puts "INFO: Implementation complete."

# ==============================================================================
# Step 9 – Bitstream
# ==============================================================================
puts "INFO: Generating bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "INFO: Bitstream generated at:"
puts "  $project_dir/$project_name.runs/impl_1/${bd_name}_wrapper.bit"

# ==============================================================================
# Step 10 – Export hardware (for Vitis)
# ==============================================================================
write_hw_platform -fixed -include_bit \
    -file $project_dir/${project_name}.xsa
puts "INFO: Hardware platform exported: $project_dir/${project_name}.xsa"
puts "INFO: Build complete!"
