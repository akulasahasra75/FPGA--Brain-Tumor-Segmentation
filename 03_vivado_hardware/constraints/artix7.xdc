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
# Reset – active-low CPU_RESETN (dedicated reset button on Nexys A7)
# ==============================================================================
set_property -dict { PACKAGE_PIN C12  IOSTANDARD LVCMOS33 } [get_ports reset_n]

# ==============================================================================
# UART over USB (directly connected to FTDI chip)
# ==============================================================================
set_property -dict { PACKAGE_PIN C4   IOSTANDARD LVCMOS33 } [get_ports uart_rxd]
set_property -dict { PACKAGE_PIN D4   IOSTANDARD LVCMOS33 } [get_ports uart_txd]

# ==============================================================================
# Status LEDs (active-high)
# ==============================================================================
#   led[0] = LD0 = heartbeat
#   led[1] = LD1 = processing
#   led[2] = LD2 = mode bit 0
#   led[3] = LD3 = mode bit 1
set_property -dict { PACKAGE_PIN H17  IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN K15  IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN J13  IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN N14  IOSTANDARD LVCMOS33 } [get_ports {led[3]}]

# Done LED = LD4 (active-high)
set_property -dict { PACKAGE_PIN R18  IOSTANDARD LVCMOS33 } [get_ports {led[4]}]

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
