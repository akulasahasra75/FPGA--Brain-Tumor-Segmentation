// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2025.1 (64-bit)
// Tool Version Limit: 2025.05
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
/***************************** Include Files *********************************/
#include "xotsu_threshold_top.h"

/************************** Function Implementation *************************/
#ifndef __linux__
int XOtsu_threshold_top_CfgInitialize(XOtsu_threshold_top *InstancePtr, XOtsu_threshold_top_Config *ConfigPtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(ConfigPtr != NULL);

    InstancePtr->Control_BaseAddress = ConfigPtr->Control_BaseAddress;
    InstancePtr->Control_r_BaseAddress = ConfigPtr->Control_r_BaseAddress;
    InstancePtr->IsReady = XIL_COMPONENT_IS_READY;

    return XST_SUCCESS;
}
#endif

void XOtsu_threshold_top_Start(XOtsu_threshold_top *InstancePtr) {
    u32 Data;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XOtsu_threshold_top_ReadReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_AP_CTRL) & 0x80;
    XOtsu_threshold_top_WriteReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_AP_CTRL, Data | 0x01);
}

u32 XOtsu_threshold_top_IsDone(XOtsu_threshold_top *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XOtsu_threshold_top_ReadReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_AP_CTRL);
    return (Data >> 1) & 0x1;
}

u32 XOtsu_threshold_top_IsIdle(XOtsu_threshold_top *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XOtsu_threshold_top_ReadReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_AP_CTRL);
    return (Data >> 2) & 0x1;
}

u32 XOtsu_threshold_top_IsReady(XOtsu_threshold_top *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XOtsu_threshold_top_ReadReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_AP_CTRL);
    // check ap_start to see if the pcore is ready for next input
    return !(Data & 0x1);
}

void XOtsu_threshold_top_EnableAutoRestart(XOtsu_threshold_top *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XOtsu_threshold_top_WriteReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_AP_CTRL, 0x80);
}

void XOtsu_threshold_top_DisableAutoRestart(XOtsu_threshold_top *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XOtsu_threshold_top_WriteReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_AP_CTRL, 0);
}

void XOtsu_threshold_top_Set_mode(XOtsu_threshold_top *InstancePtr, u32 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XOtsu_threshold_top_WriteReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_MODE_DATA, Data);
}

u32 XOtsu_threshold_top_Get_mode(XOtsu_threshold_top *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XOtsu_threshold_top_ReadReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_MODE_DATA);
    return Data;
}

u64 XOtsu_threshold_top_Get_result(XOtsu_threshold_top *InstancePtr) {
    u64 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XOtsu_threshold_top_ReadReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_RESULT_DATA);
    Data += (u64)XOtsu_threshold_top_ReadReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_RESULT_DATA + 4) << 32;
    return Data;
}

u32 XOtsu_threshold_top_Get_result_vld(XOtsu_threshold_top *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XOtsu_threshold_top_ReadReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_RESULT_CTRL);
    return Data & 0x1;
}

void XOtsu_threshold_top_Set_img_in(XOtsu_threshold_top *InstancePtr, u64 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XOtsu_threshold_top_WriteReg(InstancePtr->Control_r_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_R_ADDR_IMG_IN_DATA, (u32)(Data));
    XOtsu_threshold_top_WriteReg(InstancePtr->Control_r_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_R_ADDR_IMG_IN_DATA + 4, (u32)(Data >> 32));
}

u64 XOtsu_threshold_top_Get_img_in(XOtsu_threshold_top *InstancePtr) {
    u64 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XOtsu_threshold_top_ReadReg(InstancePtr->Control_r_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_R_ADDR_IMG_IN_DATA);
    Data += (u64)XOtsu_threshold_top_ReadReg(InstancePtr->Control_r_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_R_ADDR_IMG_IN_DATA + 4) << 32;
    return Data;
}

void XOtsu_threshold_top_Set_img_out(XOtsu_threshold_top *InstancePtr, u64 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XOtsu_threshold_top_WriteReg(InstancePtr->Control_r_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_R_ADDR_IMG_OUT_DATA, (u32)(Data));
    XOtsu_threshold_top_WriteReg(InstancePtr->Control_r_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_R_ADDR_IMG_OUT_DATA + 4, (u32)(Data >> 32));
}

u64 XOtsu_threshold_top_Get_img_out(XOtsu_threshold_top *InstancePtr) {
    u64 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XOtsu_threshold_top_ReadReg(InstancePtr->Control_r_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_R_ADDR_IMG_OUT_DATA);
    Data += (u64)XOtsu_threshold_top_ReadReg(InstancePtr->Control_r_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_R_ADDR_IMG_OUT_DATA + 4) << 32;
    return Data;
}

void XOtsu_threshold_top_InterruptGlobalEnable(XOtsu_threshold_top *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XOtsu_threshold_top_WriteReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_GIE, 1);
}

void XOtsu_threshold_top_InterruptGlobalDisable(XOtsu_threshold_top *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XOtsu_threshold_top_WriteReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_GIE, 0);
}

void XOtsu_threshold_top_InterruptEnable(XOtsu_threshold_top *InstancePtr, u32 Mask) {
    u32 Register;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Register =  XOtsu_threshold_top_ReadReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_IER);
    XOtsu_threshold_top_WriteReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_IER, Register | Mask);
}

void XOtsu_threshold_top_InterruptDisable(XOtsu_threshold_top *InstancePtr, u32 Mask) {
    u32 Register;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Register =  XOtsu_threshold_top_ReadReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_IER);
    XOtsu_threshold_top_WriteReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_IER, Register & (~Mask));
}

void XOtsu_threshold_top_InterruptClear(XOtsu_threshold_top *InstancePtr, u32 Mask) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XOtsu_threshold_top_WriteReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_ISR, Mask);
}

u32 XOtsu_threshold_top_InterruptGetEnabled(XOtsu_threshold_top *InstancePtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    return XOtsu_threshold_top_ReadReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_IER);
}

u32 XOtsu_threshold_top_InterruptGetStatus(XOtsu_threshold_top *InstancePtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    return XOtsu_threshold_top_ReadReg(InstancePtr->Control_BaseAddress, XOTSU_THRESHOLD_TOP_CONTROL_ADDR_ISR);
}

