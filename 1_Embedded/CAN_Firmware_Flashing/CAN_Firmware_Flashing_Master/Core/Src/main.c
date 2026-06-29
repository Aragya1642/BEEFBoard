/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "FreeRTOS.h"
#include "cmsis_os2.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "ff.h"
#include "stream_buffer.h"
#include <string.h>
#include <stdio.h>
#include <microtbx.h>
#include <microblt.h>
#include "update.h"
#include "blt_port.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define UART_RX_CHUNK        (256U)         /* ISR idle-reception buffer size      */
#define SREC_STREAM_SIZE     (4096U)        /* ISR->task byte FIFO (slack for f_write) */
#define WRITE_CHUNK          (512U)         /* batch size for f_write              */
#define SREC_MAX_FILE_SIZE   (440U * 1024U) /* reject lengths the RAM disk can't hold */
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

FDCAN_HandleTypeDef hfdcan1;

UART_HandleTypeDef huart3;

/* Definitions for FwUpdateTask */
osThreadId_t FwUpdateTaskHandle;
const osThreadAttr_t FwUpdateTask_attributes = {
  .name = "FwUpdateTask",
  .stack_size = 2048 * 4,
  .priority = (osPriority_t) osPriorityNormal,
};
/* USER CODE BEGIN PV */
static StreamBufferHandle_t srecStream;
static uint8_t              uartRxChunk[UART_RX_CHUNK];
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_FDCAN1_Init(void);
static void MX_USART3_UART_Init(void);
void FwUpdateTaskFunc(void *argument);

/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
static void VcpPrint(const char *s)
{
  HAL_UART_Transmit(&huart3, (uint8_t *)s, (uint16_t)strlen(s), HAL_MAX_DELAY);
}

/* MicroTBX assertion handler: report file/line over the VCP instead of hanging silently. */
static void AppAssertHandler(const char * const file, uint32_t line)
{
  char buf[96];
  snprintf(buf, sizeof(buf), "ASSERT %s:%lu\r\n", file, (unsigned long)line);
  VcpPrint(buf);
  for (;;) { /* halt for debugger inspection */ }
}


/* Idle-line / buffer-full RX event: push received bytes to the task, then re-arm. */
void HAL_UARTEx_RxEventCallback(UART_HandleTypeDef *huart, uint16_t Size)
{
  if (huart->Instance == USART3)
  {
    BaseType_t woken = pdFALSE;
    if (Size > 0U)
    {
      (void)xStreamBufferSendFromISR(srecStream, uartRxChunk, Size, &woken);
    }
    (void)HAL_UARTEx_ReceiveToIdle_IT(huart, uartRxChunk, UART_RX_CHUNK);
    portYIELD_FROM_ISR(woken);
  }
}

/* Recover from overrun/framing errors by re-arming reception. */
void HAL_UART_ErrorCallback(UART_HandleTypeDef *huart)
{
  if (huart->Instance == USART3)
  {
    (void)HAL_UARTEx_ReceiveToIdle_IT(huart, uartRxChunk, UART_RX_CHUNK);
  }
}
/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_FDCAN1_Init();
  MX_USART3_UART_Init();
  /* USER CODE BEGIN 2 */

  /* USER CODE END 2 */

  /* Init scheduler */
  osKernelInitialize();

  /* USER CODE BEGIN RTOS_MUTEX */
  /* add mutexes, ... */
  /* USER CODE END RTOS_MUTEX */

  /* USER CODE BEGIN RTOS_SEMAPHORES */
  /* add semaphores, ... */
  /* USER CODE END RTOS_SEMAPHORES */

  /* USER CODE BEGIN RTOS_TIMERS */
  /* start timers, add new ones, ... */
  /* USER CODE END RTOS_TIMERS */

  /* USER CODE BEGIN RTOS_QUEUES */
  /* add queues, ... */
  /* USER CODE END RTOS_QUEUES */

  /* Create the thread(s) */
  /* creation of FwUpdateTask */
  FwUpdateTaskHandle = osThreadNew(FwUpdateTaskFunc, NULL, &FwUpdateTask_attributes);

  /* USER CODE BEGIN RTOS_THREADS */
  /* add threads, ... */
  /* USER CODE END RTOS_THREADS */

  /* USER CODE BEGIN RTOS_EVENTS */
  /* add events, ... */
  /* USER CODE END RTOS_EVENTS */

  /* Initialize leds */
  BSP_LED_Init(LED_GREEN);
  BSP_LED_Init(LED_YELLOW);
  BSP_LED_Init(LED_RED);

  /* Start scheduler */
  osKernelStart();

  /* We should never get here as control is now taken by the scheduler */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {

    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Supply configuration update enable
  */
  HAL_PWREx_ConfigSupply(PWR_LDO_SUPPLY);

  /** Configure the main internal regulator output voltage
  */
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE2);

  while(!__HAL_PWR_GET_FLAG(PWR_FLAG_VOSRDY)) {}

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_DIV1;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 4;
  RCC_OscInitStruct.PLL.PLLN = 9;
  RCC_OscInitStruct.PLL.PLLP = 2;
  RCC_OscInitStruct.PLL.PLLQ = 3;
  RCC_OscInitStruct.PLL.PLLR = 2;
  RCC_OscInitStruct.PLL.PLLRGE = RCC_PLL1VCIRANGE_3;
  RCC_OscInitStruct.PLL.PLLVCOSEL = RCC_PLL1VCOMEDIUM;
  RCC_OscInitStruct.PLL.PLLFRACN = 3072;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2
                              |RCC_CLOCKTYPE_D3PCLK1|RCC_CLOCKTYPE_D1PCLK1;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_HSI;
  RCC_ClkInitStruct.SYSCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB3CLKDivider = RCC_APB3_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_APB1_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_APB2_DIV1;
  RCC_ClkInitStruct.APB4CLKDivider = RCC_APB4_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_1) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief FDCAN1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_FDCAN1_Init(void)
{

  /* USER CODE BEGIN FDCAN1_Init 0 */

  /* USER CODE END FDCAN1_Init 0 */

  /* USER CODE BEGIN FDCAN1_Init 1 */

  /* USER CODE END FDCAN1_Init 1 */
  hfdcan1.Instance = FDCAN1;
  hfdcan1.Init.FrameFormat = FDCAN_FRAME_FD_NO_BRS;
  hfdcan1.Init.Mode = FDCAN_MODE_NORMAL;
  hfdcan1.Init.AutoRetransmission = ENABLE;
  hfdcan1.Init.TransmitPause = DISABLE;
  hfdcan1.Init.ProtocolException = DISABLE;
  hfdcan1.Init.NominalPrescaler = 1;
  hfdcan1.Init.NominalSyncJumpWidth = 13;
  hfdcan1.Init.NominalTimeSeg1 = 86;
  hfdcan1.Init.NominalTimeSeg2 = 13;
  hfdcan1.Init.DataPrescaler = 25;
  hfdcan1.Init.DataSyncJumpWidth = 1;
  hfdcan1.Init.DataTimeSeg1 = 2;
  hfdcan1.Init.DataTimeSeg2 = 1;
  hfdcan1.Init.MessageRAMOffset = 0;
  hfdcan1.Init.StdFiltersNbr = 1;
  hfdcan1.Init.ExtFiltersNbr = 0;
  hfdcan1.Init.RxFifo0ElmtsNbr = 1;
  hfdcan1.Init.RxFifo0ElmtSize = FDCAN_DATA_BYTES_12;
  hfdcan1.Init.RxFifo1ElmtsNbr = 0;
  hfdcan1.Init.RxFifo1ElmtSize = FDCAN_DATA_BYTES_8;
  hfdcan1.Init.RxBuffersNbr = 0;
  hfdcan1.Init.RxBufferSize = FDCAN_DATA_BYTES_8;
  hfdcan1.Init.TxEventsNbr = 0;
  hfdcan1.Init.TxBuffersNbr = 0;
  hfdcan1.Init.TxFifoQueueElmtsNbr = 1;
  hfdcan1.Init.TxFifoQueueMode = FDCAN_TX_FIFO_OPERATION;
  hfdcan1.Init.TxElmtSize = FDCAN_DATA_BYTES_12;
  if (HAL_FDCAN_Init(&hfdcan1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN FDCAN1_Init 2 */

  /* USER CODE END FDCAN1_Init 2 */

}

/**
  * @brief USART3 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART3_UART_Init(void)
{

  /* USER CODE BEGIN USART3_Init 0 */

  /* USER CODE END USART3_Init 0 */

  /* USER CODE BEGIN USART3_Init 1 */

  /* USER CODE END USART3_Init 1 */
  huart3.Instance = USART3;
  huart3.Init.BaudRate = 115200;
  huart3.Init.WordLength = UART_WORDLENGTH_8B;
  huart3.Init.StopBits = UART_STOPBITS_1;
  huart3.Init.Parity = UART_PARITY_NONE;
  huart3.Init.Mode = UART_MODE_TX_RX;
  huart3.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart3.Init.OverSampling = UART_OVERSAMPLING_16;
  huart3.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
  huart3.Init.ClockPrescaler = UART_PRESCALER_DIV1;
  huart3.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
  if (HAL_UART_Init(&huart3) != HAL_OK)
  {
    Error_Handler();
  }
  if (HAL_UARTEx_SetTxFifoThreshold(&huart3, UART_TXFIFO_THRESHOLD_1_8) != HAL_OK)
  {
    Error_Handler();
  }
  if (HAL_UARTEx_SetRxFifoThreshold(&huart3, UART_RXFIFO_THRESHOLD_1_8) != HAL_OK)
  {
    Error_Handler();
  }
  if (HAL_UARTEx_DisableFifoMode(&huart3) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART3_Init 2 */

  /* USER CODE END USART3_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  /* USER CODE BEGIN MX_GPIO_Init_1 */

  /* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();

  /* USER CODE BEGIN MX_GPIO_Init_2 */

  /* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/* USER CODE BEGIN Header_FwUpdateTaskFunc */
/**
  * @brief  Function implementing the FwUpdateTask thread.
  * @param  argument: Not used
  * @retval None
  */
/* USER CODE END Header_FwUpdateTaskFunc */
void FwUpdateTaskFunc(void *argument)
{
  /* USER CODE BEGIN 5 */
  FATFS    fs;
  FIL      fil;
  BYTE     work[_MAX_SS];
  FRESULT  fr;
  uint8_t  hdr[4];
  uint8_t  writeBuf[WRITE_CHUNK];
  uint32_t fileLen, remaining, totalWritten, hdrGot;
  size_t   got;
  UINT     bw;
  char     line[72];

  TbxAssertSetHandler(AppAssertHandler);

  /* ---- One-time init: stream buffer, format + mount, arm reception ---- */
  srecStream = xStreamBufferCreate(SREC_STREAM_SIZE, 1);

  fr = f_mkfs("", FM_FAT, 0, work, sizeof(work));
  if (fr == FR_OK) { fr = f_mount(&fs, "", 1); }
  if ((srecStream == NULL) || (fr != FR_OK))
  {
	VcpPrint("INIT FAIL\r\n");
	for (;;) { osDelay(1000); }
  }

  (void)HAL_UARTEx_ReceiveToIdle_IT(&huart3, uartRxChunk, UART_RX_CHUNK);
  
  /* Configure FDCAN, register the LibMicroBLT port. */
  BltPortFdcanInit();
  
  /* ---- Per-transfer loop: accept a new app.srec on each iteration ---- */
  for (;;)
  {
	/* Discard any stray bytes so a fresh upload starts clean. */
	(void)xStreamBufferReset(srecStream);
	totalWritten = 0U;
	hdrGot       = 0U;

	VcpPrint("READY: send 4-byte LE length, then app.srec\r\n");

	/* 1) 4-byte little-endian length header (wait indefinitely for upload). */
	while (hdrGot < sizeof(hdr))
	{
	  got = xStreamBufferReceive(srecStream, &hdr[hdrGot], sizeof(hdr) - hdrGot, portMAX_DELAY);
	  hdrGot += (uint32_t)got;
	}
	fileLen = (uint32_t)hdr[0]         | ((uint32_t)hdr[1] << 8) |
			  ((uint32_t)hdr[2] << 16) | ((uint32_t)hdr[3] << 24);

	if ((fileLen == 0U) || (fileLen > SREC_MAX_FILE_SIZE))
	{
	  snprintf(line, sizeof(line), "BAD LENGTH: %lu\r\n", (unsigned long)fileLen);
	  VcpPrint(line);
	  continue;                       /* back to READY for the next attempt */
	}

	/* 2) Stream the body into app.srec (CREATE_ALWAYS truncates any prior file). */
	fr = f_open(&fil, "app.srec", FA_CREATE_ALWAYS | FA_WRITE);
	if (fr != FR_OK)
	{
	  VcpPrint("OPEN FAIL\r\n");
	  continue;
	}

	remaining = fileLen;
	while (remaining > 0U)
	{
	  uint32_t want = (remaining < WRITE_CHUNK) ? remaining : WRITE_CHUNK;
	  got = xStreamBufferReceive(srecStream, writeBuf, want, pdMS_TO_TICKS(5000));
	  if (got == 0U)
	  {
		VcpPrint("RX TIMEOUT (incomplete)\r\n");
		break;
	  }
	  fr = f_write(&fil, writeBuf, (UINT)got, &bw);
	  if ((fr != FR_OK) || (bw < (UINT)got))
	  {
		VcpPrint("WRITE FAIL (disk full?)\r\n");
		break;
	  }
	  totalWritten += (uint32_t)got;
	  remaining    -= (uint32_t)got;
	}
	f_close(&fil);

	/* 3) Report + verify. */
	snprintf(line, sizeof(line), "RECEIVED %lu / %lu bytes\r\n",
			 (unsigned long)totalWritten, (unsigned long)fileLen);
	VcpPrint(line);

	if (f_open(&fil, "app.srec", FA_READ) == FR_OK)
	{
	  snprintf(line, sizeof(line), "VERIFY app.srec = %lu bytes %s\r\n",
			   (unsigned long)f_size(&fil),
			   (f_size(&fil) == fileLen) ? "OK" : "MISMATCH");
	  VcpPrint(line);
	  f_close(&fil);
	}

	/* If the file arrived intact, attempt to flash the target. */
  if (totalWritten == fileLen)
  {
    uint8_t updRes = UpdateFirmware("app.srec", 0U);
    snprintf(line, sizeof(line), "UPDATE %s\r\n",
              (updRes == TBX_OK) ? "OK" : "FAILED (connect timeout?)");
    VcpPrint(line);
  }
  
  }
  /* USER CODE END 5 */
}

/**
  * @brief  Period elapsed callback in non blocking mode
  * @note   This function is called  when TIM6 interrupt took place, inside
  * HAL_TIM_IRQHandler(). It makes a direct call to HAL_IncTick() to increment
  * a global variable "uwTick" used as application time base.
  * @param  htim : TIM handle
  * @retval None
  */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
  /* USER CODE BEGIN Callback 0 */

  /* USER CODE END Callback 0 */
  if (htim->Instance == TIM6)
  {
    HAL_IncTick();
  }
  /* USER CODE BEGIN Callback 1 */

  /* USER CODE END Callback 1 */
}

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}
#ifdef USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
