/************************************************************************************//**
* \file         blt_port.h
* \brief        LibMicroBLT FDCAN port header file.
****************************************************************************************/
#ifndef BLT_PORT_H
#define BLT_PORT_H

#ifdef __cplusplus
extern "C" {
#endif

/** \brief Configure FDCAN1 for XCP, register the LibMicroBLT port, and start CAN.
 *         Call once after the RTOS scheduler is running and before UpdateFirmware().
 */
void BltPortFdcanInit(void);

#ifdef __cplusplus
}
#endif

#endif /* BLT_PORT_H */
