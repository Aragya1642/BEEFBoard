/************************************************************************************//**
* \file         blt_port.c
* \brief        LibMicroBLT port for XCP over FDCAN (classic frames) on STM32H7.
* \details      Maps the four LibMicroBLT port functions onto the HAL FDCAN driver.
*               Transmits classic CAN frames (FDFormat = FDCAN_CLASSIC_CAN) so it talks
*               to a stock OpenBLT target, even though the peripheral is FD-capable.
*               IDs are OpenBLT defaults: 0x667 master->target, 0x7E1 target->master.
****************************************************************************************/

/****************************************************************************************
* Include files
****************************************************************************************/
#include <microtbx.h>                       /* MicroTBX (TBX_OK/ERROR/ASSERT)          */
#include <microblt.h>                       /* LibMicroBLT (tPort, BltPortInit)        */
#include <FreeRTOS.h>                        /* FreeRTOS                                */
#include <queue.h>                           /* FreeRTOS queues                         */
#include "main.h"                            /* HAL types + hfdcan1                     */
#include "blt_port.h"                        /* This module                            */

/****************************************************************************************
* Macro definitions
****************************************************************************************/
/** \brief CAN identifier for master->target XCP commands (OpenBLT default). */
#define BLT_XCP_CAN_TX_ID      (0x667U)
/** \brief CAN identifier for target->master XCP responses (OpenBLT default). */
#define BLT_XCP_CAN_RX_ID      (0x7E1U)
/** \brief Maximum classic-CAN payload length. */
#define BLT_XCP_CAN_MAX_LEN    (8U)

/****************************************************************************************
* Type definitions
****************************************************************************************/
/** \brief Compact storage for one received XCP-on-CAN response. */
typedef struct
{
  uint8_t data[BLT_XCP_CAN_MAX_LEN];
  uint8_t len;
} tBltXcpCanMsg;

/****************************************************************************************
* External data
****************************************************************************************/
extern FDCAN_HandleTypeDef hfdcan1;          /* Defined in main.c                       */

/****************************************************************************************
* Function prototypes
****************************************************************************************/
static uint32_t BltPortSystemGetTime(void);
static uint8_t  BltPortXcpTransmitPacket(tPortXcpPacket const * txPacket);
static uint8_t  BltPortXcpReceivePacket(tPortXcpPacket * rxPacket);
static uint8_t  BltPortXcpComputeKeyFromSeed(uint8_t seedLen, uint8_t const * seedPtr,
                                             uint8_t * keyLenPtr, uint8_t * keyPtr);

/****************************************************************************************
* Local data declarations
****************************************************************************************/
/** \brief Queue holding one received XCP CAN response (ISR -> port). */
static QueueHandle_t bltXcpRxQueue = NULL;

/** \brief Port interface passed to LibMicroBLT. */
static tPort const bltPortInterface =
{
  .SystemGetTime         = BltPortSystemGetTime,
  .XcpTransmitPacket     = BltPortXcpTransmitPacket,
  .XcpReceivePacket      = BltPortXcpReceivePacket,
  .XcpComputeKeyFromSeed = BltPortXcpComputeKeyFromSeed
};

/************************************************************************************//**
** \brief     Configures FDCAN1 RX filtering for 0x7E1, starts CAN, enables the RX
**            FIFO0 interrupt, and registers the port with LibMicroBLT.
****************************************************************************************/
void BltPortFdcanInit(void)
{
  FDCAN_FilterTypeDef filter;

  /* One-deep queue for received XCP responses. */
  bltXcpRxQueue = xQueueCreate(1U, sizeof(tBltXcpCanMsg));

  /* Accept only standard ID 0x7E1 into RX FIFO0. */
  filter.IdType       = FDCAN_STANDARD_ID;
  filter.FilterIndex  = 0U;
  filter.FilterType   = FDCAN_FILTER_MASK;
  filter.FilterConfig = FDCAN_FILTER_TO_RXFIFO0;
  filter.FilterID1    = BLT_XCP_CAN_RX_ID;
  filter.FilterID2    = 0x7FFU;              /* mask: all 11 bits must match */
  (void)HAL_FDCAN_ConfigFilter(&hfdcan1, &filter);

  /* Reject everything that does not match the filter. */
  (void)HAL_FDCAN_ConfigGlobalFilter(&hfdcan1, FDCAN_REJECT, FDCAN_REJECT,
                                     FDCAN_FILTER_REMOTE, FDCAN_FILTER_REMOTE);

  /* Start CAN and enable the RX FIFO0 new-message notification (routed to IT0). */
  (void)HAL_FDCAN_Start(&hfdcan1);
  (void)HAL_FDCAN_ActivateNotification(&hfdcan1, FDCAN_IT_RX_FIFO0_NEW_MESSAGE, 0U);

  /* Register the port with LibMicroBLT. */
  BltPortInit(&bltPortInterface);
} /*** end of BltPortFdcanInit ***/

/************************************************************************************//**
** \brief     Obtains the current system time in milliseconds.
****************************************************************************************/
static uint32_t BltPortSystemGetTime(void)
{
  return HAL_GetTick();
} /*** end of BltPortSystemGetTime ***/

/************************************************************************************//**
** \brief     Transmits an XCP packet as a classic CAN frame on 0x667.
****************************************************************************************/
static uint8_t BltPortXcpTransmitPacket(tPortXcpPacket const * txPacket)
{
  static const uint32_t dlcLookup[BLT_XCP_CAN_MAX_LEN + 1U] =
  {
    FDCAN_DLC_BYTES_0, FDCAN_DLC_BYTES_1, FDCAN_DLC_BYTES_2, FDCAN_DLC_BYTES_3,
    FDCAN_DLC_BYTES_4, FDCAN_DLC_BYTES_5, FDCAN_DLC_BYTES_6, FDCAN_DLC_BYTES_7,
    FDCAN_DLC_BYTES_8
  };
  uint8_t               result = TBX_ERROR;
  FDCAN_TxHeaderTypeDef txHeader;
  uint8_t               txData[BLT_XCP_CAN_MAX_LEN] = { 0 };
  uint8_t               idx;

  TBX_ASSERT(txPacket != NULL);

  if ((txPacket != NULL) && (txPacket->len <= BLT_XCP_CAN_MAX_LEN))
  {
    for (idx = 0U; idx < txPacket->len; idx++)
    {
      txData[idx] = txPacket->data[idx];
    }
    txHeader.Identifier          = BLT_XCP_CAN_TX_ID;
    txHeader.IdType              = FDCAN_STANDARD_ID;
    txHeader.TxFrameType         = FDCAN_DATA_FRAME;
    txHeader.DataLength          = dlcLookup[txPacket->len];
    txHeader.ErrorStateIndicator = FDCAN_ESI_ACTIVE;
    txHeader.BitRateSwitch       = FDCAN_BRS_OFF;
    txHeader.FDFormat            = FDCAN_CLASSIC_CAN;   /* classic frame for OpenBLT */
    txHeader.TxEventFifoControl  = FDCAN_NO_TX_EVENTS;
    txHeader.MessageMarker       = 0U;

    if (HAL_FDCAN_AddMessageToTxFifoQ(&hfdcan1, &txHeader, txData) == HAL_OK)
    {
      result = TBX_OK;
    }
  }
  return result;
} /*** end of BltPortXcpTransmitPacket ***/

/************************************************************************************//**
** \brief     Non-blocking attempt to dequeue a received XCP packet.
****************************************************************************************/
static uint8_t BltPortXcpReceivePacket(tPortXcpPacket * rxPacket)
{
  uint8_t       result = TBX_FALSE;
  tBltXcpCanMsg rxMsg;
  uint8_t       idx;

  TBX_ASSERT(rxPacket != NULL);

  if ((rxPacket != NULL) && (bltXcpRxQueue != NULL))
  {
    if (xQueueReceive(bltXcpRxQueue, &rxMsg, 0U) == pdPASS)
    {
      for (idx = 0U; idx < rxMsg.len; idx++)
      {
        rxPacket->data[idx] = rxMsg.data[idx];
      }
      rxPacket->len = rxMsg.len;
      result = TBX_TRUE;
    }
  }
  return result;
} /*** end of BltPortXcpReceivePacket ***/

/************************************************************************************//**
** \brief     Computes the key from a seed. Unused while seed/key protection is disabled
**            on the target; kept matching OpenBLT's default hook (seed - 1).
****************************************************************************************/
static uint8_t BltPortXcpComputeKeyFromSeed(uint8_t seedLen, uint8_t const * seedPtr,
                                            uint8_t * keyLenPtr, uint8_t * keyPtr)
{
  uint8_t result = TBX_ERROR;
  uint8_t cnt;

  TBX_ASSERT((seedLen > 0U) && (seedPtr != NULL) && (keyLenPtr != NULL) &&
             (keyPtr != NULL));

  if ((seedLen > 0U) && (seedPtr != NULL) && (keyLenPtr != NULL) && (keyPtr != NULL))
  {
    for (cnt = 0U; cnt < seedLen; cnt++)
    {
      keyPtr[cnt] = seedPtr[cnt] - 1U;
    }
    *keyLenPtr = seedLen;
    result = TBX_OK;
  }
  return result;
} /*** end of BltPortXcpComputeKeyFromSeed ***/

/************************************************************************************//**
** \brief     FDCAN RX FIFO0 callback. Queues XCP responses (id 0x7E1) for the port.
** \attention Runs at interrupt level.
****************************************************************************************/
void HAL_FDCAN_RxFifo0Callback(FDCAN_HandleTypeDef * hfdcan, uint32_t RxFifo0ITs)
{
  FDCAN_RxHeaderTypeDef rxHeader;
  uint8_t               rxData[64];          /* sized for any FD frame, just in case */
  tBltXcpCanMsg         rxMsg;
  BaseType_t            woken = pdFALSE;
  uint8_t               len;
  uint8_t               idx;

  if ((hfdcan->Instance == FDCAN1) &&
      ((RxFifo0ITs & FDCAN_IT_RX_FIFO0_NEW_MESSAGE) != 0U))
  {
    if (HAL_FDCAN_GetRxMessage(hfdcan, FDCAN_RX_FIFO0, &rxHeader, rxData) == HAL_OK)
    {
      if ((rxHeader.IdType == FDCAN_STANDARD_ID) &&
          (rxHeader.Identifier == BLT_XCP_CAN_RX_ID))
      {
        /* Convert DLC code to a byte count (classic frames are <= 8). */
        len = (uint8_t)rxHeader.DataLength;
        if (len > BLT_XCP_CAN_MAX_LEN)
        {
          len = BLT_XCP_CAN_MAX_LEN;
        }
        for (idx = 0U; idx < len; idx++)
        {
          rxMsg.data[idx] = rxData[idx];
        }
        rxMsg.len = len;
        (void)xQueueSendFromISR(bltXcpRxQueue, &rxMsg, &woken);
        portYIELD_FROM_ISR(woken);
      }
    }
  }
} /*** end of HAL_FDCAN_RxFifo0Callback ***/

/*********************************** end of blt_port.c *********************************/
