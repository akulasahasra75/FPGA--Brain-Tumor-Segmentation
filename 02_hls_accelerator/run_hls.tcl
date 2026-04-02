set SCRIPT_DIR [file dirname [file normalize [info script]]]
cd $SCRIPT_DIR

set PROJECT_NAME "otsu_hls"
set SOLUTION_NAME "solution1"
set TOP_FUNCTION "otsu_threshold_top"
set PART "xc7a100tcsg324-1"
set CLOCK_PERIOD 10

set IP_REPO_DIR "../03_vivado_hardware/ip_repo"

puts "INFO: Creating HLS project: ${PROJECT_NAME}"
open_project -reset ${PROJECT_NAME}

add_files otsu_threshold.cpp
add_files otsu_threshold.h
add_files image_stats.cpp
add_files image_stats.h
add_files -tb test_otsu.cpp

set_top ${TOP_FUNCTION}
open_solution -reset ${SOLUTION_NAME}

set_part ${PART}
create_clock -period ${CLOCK_PERIOD} -name default
set_clock_uncertainty 1.25

# Performance configurations
config_compile -pipeline_loops 1
config_array_partition -complete_threshold 256

puts "===> Running C Simulation..."
csim_design -clean

puts "===> Running C Synthesis..."
csynth_design

puts "===> Exporting IP..."
# File copy approach requires ensuring dir exists
file mkdir $IP_REPO_DIR

export_design -format ip_catalog -display_name "otsu_threshold_v2" -description "Otsu Threshold Accelerator" -vendor "custom" -version "2.0" -output $IP_REPO_DIR

if {![file exists "$IP_REPO_DIR/component.xml"]} {
    puts "ERROR: IP Export failed! component.xml not found in $IP_REPO_DIR"
    exit 1
}

puts "INFO: HLS Build and IP Export Successful."
exit 0
