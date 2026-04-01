// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2025.1 (64-bit)
// Tool Version Limit: 2025.05
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
#ifndef __linux__

#include "xstatus.h"
#ifdef SDT
#include "xparameters.h"
#endif
#include "xotsu_threshold_top.h"

extern XOtsu_threshold_top_Config XOtsu_threshold_top_ConfigTable[];

#ifdef SDT
XOtsu_threshold_top_Config *XOtsu_threshold_top_LookupConfig(UINTPTR BaseAddress) {
	XOtsu_threshold_top_Config *ConfigPtr = NULL;

	int Index;

	for (Index = (u32)0x0; XOtsu_threshold_top_ConfigTable[Index].Name != NULL; Index++) {
		if (!BaseAddress || XOtsu_threshold_top_ConfigTable[Index].Control_BaseAddress == BaseAddress) {
			ConfigPtr = &XOtsu_threshold_top_ConfigTable[Index];
			break;
		}
	}

	return ConfigPtr;
}

int XOtsu_threshold_top_Initialize(XOtsu_threshold_top *InstancePtr, UINTPTR BaseAddress) {
	XOtsu_threshold_top_Config *ConfigPtr;

	Xil_AssertNonvoid(InstancePtr != NULL);

	ConfigPtr = XOtsu_threshold_top_LookupConfig(BaseAddress);
	if (ConfigPtr == NULL) {
		InstancePtr->IsReady = 0;
		return (XST_DEVICE_NOT_FOUND);
	}

	return XOtsu_threshold_top_CfgInitialize(InstancePtr, ConfigPtr);
}
#else
XOtsu_threshold_top_Config *XOtsu_threshold_top_LookupConfig(u16 DeviceId) {
	XOtsu_threshold_top_Config *ConfigPtr = NULL;

	int Index;

	for (Index = 0; Index < XPAR_XOTSU_THRESHOLD_TOP_NUM_INSTANCES; Index++) {
		if (XOtsu_threshold_top_ConfigTable[Index].DeviceId == DeviceId) {
			ConfigPtr = &XOtsu_threshold_top_ConfigTable[Index];
			break;
		}
	}

	return ConfigPtr;
}

int XOtsu_threshold_top_Initialize(XOtsu_threshold_top *InstancePtr, u16 DeviceId) {
	XOtsu_threshold_top_Config *ConfigPtr;

	Xil_AssertNonvoid(InstancePtr != NULL);

	ConfigPtr = XOtsu_threshold_top_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {
		InstancePtr->IsReady = 0;
		return (XST_DEVICE_NOT_FOUND);
	}

	return XOtsu_threshold_top_CfgInitialize(InstancePtr, ConfigPtr);
}
#endif

#endif

