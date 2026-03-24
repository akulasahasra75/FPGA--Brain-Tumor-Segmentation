################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
LD_SRCS += \
../src/lscript.ld 

C_SRCS += \
../src/adaptive_controller.c \
../src/energy_analyzer.c \
../src/image_loader.c \
../src/main.c \
../src/uart_debug.c \
../src/watershed.c 

OBJS += \
./src/adaptive_controller.o \
./src/energy_analyzer.o \
./src/image_loader.o \
./src/main.o \
./src/uart_debug.o \
./src/watershed.o 

C_DEPS += \
./src/adaptive_controller.d \
./src/energy_analyzer.d \
./src/image_loader.d \
./src/main.d \
./src/uart_debug.d \
./src/watershed.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -MT"$@" -IC:/Users/akula/OneDrive/Documents/FPGA-Project/FPGA--Brain-Tumor-Segmentation/04_vitis_software/vitis_workspace/brain_tumor_platform/export/brain_tumor_platform/sw/brain_tumor_platform/standalone_domain/bspinclude/include -mlittle-endian -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v11.0 -mno-xl-soft-mul -Wl,--no-relax -ffunction-sections -fdata-sections -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


