set SCRIPT_DIR [file dirname [file normalize [info script]]]
cd $SCRIPT_DIR

set PROJECT_NAME "brain_tumor_soc"
set PART "xc7a100tcsg324-1"
set CONSTRAINT_FILE "constraints/artix7.xdc"
set IP_REPO_DIR "ip_repo"

puts "--------------------------------------------------------"
puts "  Vivado Build Flow - Brain Tumor Segmentation          "
puts "--------------------------------------------------------"

# 1. Fail-Fast Validations
if {![file exists $CONSTRAINT_FILE]} {
    puts "FATAL ERROR: Constraint file not found at $CONSTRAINT_FILE"
    exit 1
}

if {![file exists $IP_REPO_DIR/component.xml]} {
    puts "FATAL ERROR: HLS IP not found in $IP_REPO_DIR! Run HLS build first."
    exit 1
}

# 2. Cleanup & Create Project
if {[file exists vivado_project]} {
    file delete -force vivado_project
}
create_project $PROJECT_NAME ./vivado_project -part $PART

# 3. Setup IP Repository
set_property ip_repo_paths [file normalize $IP_REPO_DIR] [current_project]
update_ip_catalog

# 4. Add Constraints & Valid Verilog RTL Sources
add_files -norecurse [glob -nocomplain srcs/verilog/*.v]
add_files -fileset constrs_1 -norecurse $CONSTRAINT_FILE
update_compile_order -fileset sources_1

# 5. Create Block Design (if any)
if {[file exists "bd.tcl"]} {
    source bd.tcl 
    generate_target all [get_files *.bd]
    make_wrapper -files [get_files *.bd] -top
    add_files -norecurse [get_files *.v]
    set_property top [lindex [get_files *.bd] 0]_wrapper [current_fileset]
} else {
    set_property top top_module [current_fileset]
}

puts "INFO: Routing & Synthesis setup complete."
launch_runs synth_1 -jobs 8
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "FATAL ERROR: Synthesis failed."
    exit 1
}

launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "FATAL ERROR: Implementation/Bitstream generation failed."
    exit 1
}

# Export Hardware (XSA) for Vitis
write_hw_platform -fixed -include_bit -force -file ./vivado_project/${PROJECT_NAME}.xsa
puts "INFO: Hardware platform exported to vivado_project/${PROJECT_NAME}.xsa"

puts "Vivado Build Completed Successfully."
exit 0
