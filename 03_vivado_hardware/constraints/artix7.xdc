################################################################################
# artix7.xdc
# -----------
# Constraints for Nexys A7-100T board (Artix-7 xc7a100tcsg324-1)
#
# Active pins:
#   - 100 MHz oscillator
#   - CPU_RESETN (active-low dedicated reset)
#   - UART over USB
#   - 4 status LEDs + 1 done LED
################################################################################

# ==============================================================================
# Clock – 100 MHz oscillator
# ==============================================================================
set_property -dict { PACKAGE_PIN E3   IOSTANDARD LVCMOS33 } [get_ports clk_100mhz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100mhz]

# ==============================================================================
# Reset – active-low
# ==============================================================================
set_property -dict { PACKAGE_PIN U11  IOSTANDARD LVCMOS33 } [get_ports reset_n]

# ==============================================================================
# UART
# ==============================================================================
set_property -dict { PACKAGE_PIN C4   IOSTANDARD LVCMOS33 } [get_ports uart_rxd]
set_property -dict { PACKAGE_PIN D4   IOSTANDARD LVCMOS33 } [get_ports uart_txd]

# ==============================================================================
# Status LEDs (active-high)
# ==============================================================================
#   led[0] = heartbeat
#   led[1] = processing
#   led[2] = mode bit 0
#   led[3] = mode bit 1
#   led[4] = done
set_property -dict { PACKAGE_PIN V12  IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN V14  IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN V15  IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN T16  IOSTANDARD LVCMOS33 } [get_ports {led[3]}]
set_property -dict { PACKAGE_PIN U14  IOSTANDARD LVCMOS33 } [get_ports {led[4]}]

# ==============================================================================
# Spare pins (active design does not use these – uncomment as needed)
# ==============================================================================
# Inputs:  H6, T13, R16, U8, T8, R13
# Outputs: T15, V16

# ==============================================================================
# Configuration
# ==============================================================================
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# ==============================================================================
# Bitstream settings
# ==============================================================================
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33  [current_design]

# ==============================================================================
# I/O Timing Constraints (for timing closure)
# ==============================================================================
# Input delays (external routing ~2-3ns)
set_input_delay -clock sys_clk_pin -max 3.0 [get_ports reset_n]
set_input_delay -clock sys_clk_pin -min 0.5 [get_ports reset_n]
set_input_delay -clock sys_clk_pin -max 3.0 [get_ports uart_rxd]
set_input_delay -clock sys_clk_pin -min 0.5 [get_ports uart_rxd]

# Output delays (external routing ~2-3ns)
set_output_delay -clock sys_clk_pin -max 3.0 [get_ports uart_txd]
set_output_delay -clock sys_clk_pin -min 0.5 [get_ports uart_txd]
set_output_delay -clock sys_clk_pin -max 3.0 [get_ports {led[*]}]
set_output_delay -clock sys_clk_pin -min 0.5 [get_ports {led[*]}]

# Reset is asynchronous - add false path to help timing closure
set_false_path -from [get_ports reset_n]
