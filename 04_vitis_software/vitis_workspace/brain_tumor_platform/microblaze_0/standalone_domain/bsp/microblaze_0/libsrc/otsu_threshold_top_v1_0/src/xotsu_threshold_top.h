// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2023.1 (64-bit)
// Tool Version Limit: 2023.05
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
#ifndef XOTSU_THRESHOLD_TOP_H
#define XOTSU_THRESHOLD_TOP_H

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/
#ifndef __linux__
#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"
#include "xil_io.h"
#else
#include <stdint.h>
#include <assert.h>
#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stddef.h>
#endif
#include "xotsu_threshold_top_hw.h"

/**************************** Type Definitions ******************************/
#ifdef __linux__
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
#else
typedef struct {
    u16 DeviceId;
    u64 Control_BaseAddress;
    u64 Control_r_BaseAddress;
} XOtsu_threshold_top_Config;
#endif

typedef struct {
    u64 Control_BaseAddress;
    u64 Control_r_BaseAddress;
    u32 IsReady;
} XOtsu_threshold_top;

typedef u32 word_type;

typedef struct {
    u32 word_0;
    u32 word_1;
    u32 word_2;
} XOtsu_threshold_top_Result_i;

typedef struct {
    u32 word_0;
    u32 word_1;
    u32 word_2;
} XOtsu_threshold_top_Result_o;

/***************** Macros (Inline Functions) Definitions *********************/
#ifndef __linux__
#define XOtsu_threshold_top_WriteReg(BaseAddress, RegOffset, Data) \
    Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))
#define XOtsu_threshold_top_ReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))
#else
#define XOtsu_threshold_top_WriteReg(BaseAddress, RegOffset, Data) \
    *(volatile u32*)((BaseAddress) + (RegOffset)) = (u32)(Data)
#define XOtsu_threshold_top_ReadReg(BaseAddress, RegOffset) \
    *(volatile u32*)((BaseAddress) + (RegOffset))

#define Xil_AssertVoid(expr)    assert(expr)
#define Xil_AssertNonvoid(expr) assert(expr)

#define XST_SUCCESS             0
#define XST_DEVICE_NOT_FOUND    2
#define XST_OPEN_DEVICE_FAILED  3
#define XIL_COMPONENT_IS_READY  1
#endif

/************************** Function Prototypes *****************************/
#ifndef __linux__
int XOtsu_threshold_top_Initialize(XOtsu_threshold_top *InstancePtr, u16 DeviceId);
XOtsu_threshold_top_Config* XOtsu_threshold_top_LookupConfig(u16 DeviceId);
int XOtsu_threshold_top_CfgInitialize(XOtsu_threshold_top *InstancePtr, XOtsu_threshold_top_Config *ConfigPtr);
#else
int XOtsu_threshold_top_Initialize(XOtsu_threshold_top *InstancePtr, const char* InstanceName);
int XOtsu_threshold_top_Release(XOtsu_threshold_top *InstancePtr);
#endif

void XOtsu_threshold_top_Start(XOtsu_threshold_top *InstancePtr);
u32 XOtsu_threshold_top_IsDone(XOtsu_threshold_top *InstancePtr);
u32 XOtsu_threshold_top_IsIdle(XOtsu_threshold_top *InstancePtr);
u32 XOtsu_threshold_top_IsReady(XOtsu_threshold_top *InstancePtr);
void XOtsu_threshold_top_EnableAutoRestart(XOtsu_threshold_top *InstancePtr);
void XOtsu_threshold_top_DisableAutoRestart(XOtsu_threshold_top *InstancePtr);

void XOtsu_threshold_top_Set_mode(XOtsu_threshold_top *InstancePtr, u32 Data);
u32 XOtsu_threshold_top_Get_mode(XOtsu_threshold_top *InstancePtr);
void XOtsu_threshold_top_Set_result_i(XOtsu_threshold_top *InstancePtr, XOtsu_threshold_top_Result_i Data);
XOtsu_threshold_top_Result_i XOtsu_threshold_top_Get_result_i(XOtsu_threshold_top *InstancePtr);
XOtsu_threshold_top_Result_o XOtsu_threshold_top_Get_result_o(XOtsu_threshold_top *InstancePtr);
u32 XOtsu_threshold_top_Get_result_o_vld(XOtsu_threshold_top *InstancePtr);
void XOtsu_threshold_top_Set_img_in(XOtsu_threshold_top *InstancePtr, u64 Data);
u64 XOtsu_threshold_top_Get_img_in(XOtsu_threshold_top *InstancePtr);
void XOtsu_threshold_top_Set_img_out(XOtsu_threshold_top *InstancePtr, u64 Data);
u64 XOtsu_threshold_top_Get_img_out(XOtsu_threshold_top *InstancePtr);

void XOtsu_threshold_top_InterruptGlobalEnable(XOtsu_threshold_top *InstancePtr);
void XOtsu_threshold_top_InterruptGlobalDisable(XOtsu_threshold_top *InstancePtr);
void XOtsu_threshold_top_InterruptEnable(XOtsu_threshold_top *InstancePtr, u32 Mask);
void XOtsu_threshold_top_InterruptDisable(XOtsu_threshold_top *InstancePtr, u32 Mask);
void XOtsu_threshold_top_InterruptClear(XOtsu_threshold_top *InstancePtr, u32 Mask);
u32 XOtsu_threshold_top_InterruptGetEnabled(XOtsu_threshold_top *InstancePtr);
u32 XOtsu_threshold_top_InterruptGetStatus(XOtsu_threshold_top *InstancePtr);

#ifdef __cplusplus
}
#endif

#endif
