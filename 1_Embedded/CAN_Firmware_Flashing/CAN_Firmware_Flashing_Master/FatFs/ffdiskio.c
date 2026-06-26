#include "diskio.h"
#include <string.h>

/****************************************************************************************
* Macro definitions
****************************************************************************************/

#define RAMDISK_SECTOR_SIZE     (512U)
#define RAMDISK_SECTOR_COUNT    (896U)
#define RAMDISK_SIZE_BYTES      (RAMDISK_SECTOR_SIZE * RAMDISK_SECTOR_COUNT)

/****************************************************************************************
* Local data declarations
****************************************************************************************/

__attribute__((section(".ramdisk"), aligned(4)))
static uint8_t ramDiskBuffer[RAMDISK_SIZE_BYTES];

/************************************************************************************//**
** \brief     Initializes the disk drive.
** \param     pdrv Physical drive number.
** \return    Disk status.
****************************************************************************************/
DSTATUS disk_initialize(BYTE pdrv)
{
  (void)pdrv;
  return 0;
} /*** end of disk_initialize ***/

/************************************************************************************//**
** \brief     Obtains the disk drive status.
** \param     pdrv Physical drive number.
** \return    Disk status.
****************************************************************************************/
DSTATUS disk_status(BYTE pdrv)
{
  (void)pdrv;
  return 0;
} /*** end of disk_status ***/

/************************************************************************************//**
** \brief     Reads sector(s) from the RAM disk.
** \param     pdrv   Physical drive number.
** \param     buff   Pointer to the destination buffer.
** \param     sector Start sector number.
** \param     count  Number of sectors to read.
** \return    Result of the operation.
****************************************************************************************/
DRESULT disk_read(BYTE pdrv, BYTE *buff, DWORD sector, UINT count)
{
  (void)pdrv;
  if ((sector + count) > RAMDISK_SECTOR_COUNT)
  {
    return RES_PARERR;
  }
  memcpy(buff, &ramDiskBuffer[sector * RAMDISK_SECTOR_SIZE],
         (size_t)count * RAMDISK_SECTOR_SIZE);
  return RES_OK;
} /*** end of disk_read ***/

/************************************************************************************//**
** \brief     Writes sector(s) to the RAM disk.
** \param     pdrv   Physical drive number.
** \param     buff   Pointer to the source data.
** \param     sector Start sector number.
** \param     count  Number of sectors to write.
** \return    Result of the operation.
****************************************************************************************/
DRESULT disk_write(BYTE pdrv, const BYTE *buff, DWORD sector, UINT count)
{
  (void)pdrv;
  if ((sector + count) > RAMDISK_SECTOR_COUNT)
  {
    return RES_PARERR;
  }
  memcpy(&ramDiskBuffer[sector * RAMDISK_SECTOR_SIZE], buff,
         (size_t)count * RAMDISK_SECTOR_SIZE);
  return RES_OK;
} /*** end of disk_write ***/

/************************************************************************************//**
** \brief     Controls device-specific features and miscellaneous functions.
** \param     pdrv Physical drive number.
** \param     cmd  Control command code.
** \param     buff Pointer to the parameter buffer (command dependent).
** \return    Result of the operation.
****************************************************************************************/
DRESULT disk_ioctl(BYTE pdrv, BYTE cmd, void *buff)
{
  (void)pdrv;
  switch (cmd)
  {
    case CTRL_SYNC:
      /* Nothing to flush; RAM writes are immediate. */
      return RES_OK;

    case GET_SECTOR_COUNT:
      *(DWORD *)buff = RAMDISK_SECTOR_COUNT;
      return RES_OK;

    case GET_SECTOR_SIZE:
      *(WORD *)buff = RAMDISK_SECTOR_SIZE;
      return RES_OK;

    case GET_BLOCK_SIZE:
      /* Erase block size in sectors; 1 for RAM. */
      *(DWORD *)buff = 1;
      return RES_OK;

    default:
      return RES_PARERR;
  }
} /*** end of disk_ioctl ***/