# Connect to JTAG
connect

# List available targets
targets

# Program FPGA with bitstream
targets -set -filter {name =~ "xc7a*"}
fpga C:/Users/anees/Documents/Projects/FPGA--Brain-Tumor-Segmentation/03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/top_module.bit
after 2000

# Download application to MicroBlaze
targets -set -filter {name =~ "*MicroBlaze*"}
rst -processor
dow C:/Users/anees/Documents/Projects/FPGA--Brain-Tumor-Segmentation/04_vitis_software/vitis_workspace/brain_tumor_app/Debug/brain_tumor_app.elf

# Run application
con

puts ""
puts "=========================================="
puts "  Application running on MicroBlaze!"
puts "  Open serial terminal at 115200 baud"
puts "  Check LED0 for 1Hz heartbeat"
puts "=========================================="

# Keep connection open for debugging
# Use 'disconnect' and 'exit' when done
