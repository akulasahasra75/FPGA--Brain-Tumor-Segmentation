// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2023.1 (64-bit)
// Tool Version Limit: 2023.05
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
#ifndef __linux__

#include "xstatus.h"
#include "xparameters.h"
#include "xotsu_threshold_top.h"

extern XOtsu_threshold_top_Config XOtsu_threshold_top_ConfigTable[];

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

