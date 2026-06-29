/****************************************************************************************
* MicroTBX configuration for the BEEFBoard CAN firmware-update master.
****************************************************************************************/
#ifndef TBX_CONF_H
#define TBX_CONF_H

#ifdef __cplusplus
extern "C" {
#endif

/** \brief Enable/disable run-time assertions. */
#define TBX_CONF_ASSERTIONS_ENABLE               (1U)

/** \brief Heap size in bytes. Used by LibMicroBLT's S-record reader for per-segment
 *         metadata. Raise this if srecreader asserts on a fragmented image. */
#define TBX_CONF_HEAP_SIZE                       (16U * 1024U)

#ifdef __cplusplus
}
#endif

#endif /* TBX_CONF_H */
