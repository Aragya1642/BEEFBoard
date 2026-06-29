################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../LibMicroBLT/firmware.c \
../LibMicroBLT/microblt.c \
../LibMicroBLT/port.c \
../LibMicroBLT/session.c \
../LibMicroBLT/srecreader.c \
../LibMicroBLT/xcploader.c 

OBJS += \
./LibMicroBLT/firmware.o \
./LibMicroBLT/microblt.o \
./LibMicroBLT/port.o \
./LibMicroBLT/session.o \
./LibMicroBLT/srecreader.o \
./LibMicroBLT/xcploader.o 

C_DEPS += \
./LibMicroBLT/firmware.d \
./LibMicroBLT/microblt.d \
./LibMicroBLT/port.d \
./LibMicroBLT/session.d \
./LibMicroBLT/srecreader.d \
./LibMicroBLT/xcploader.d 


# Each subdirectory must supply rules for building sources it contributes
LibMicroBLT/%.o LibMicroBLT/%.su LibMicroBLT/%.cyclo: ../LibMicroBLT/%.c LibMicroBLT/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DDEBUG -DUSE_PWR_LDO_SUPPLY -DUSE_HAL_DRIVER -DSTM32H753xx -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Middlewares/Third_Party/FreeRTOS/Source/include -I../Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS_V2 -I../Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F -I../Drivers/CMSIS/RTOS2/Include -I../Drivers/BSP/STM32H7xx_Nucleo -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/FatFs" -I"C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/LibMicroBLT" -I"C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/MicroTBX" -I"C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/App" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-LibMicroBLT

clean-LibMicroBLT:
	-$(RM) ./LibMicroBLT/firmware.cyclo ./LibMicroBLT/firmware.d ./LibMicroBLT/firmware.o ./LibMicroBLT/firmware.su ./LibMicroBLT/microblt.cyclo ./LibMicroBLT/microblt.d ./LibMicroBLT/microblt.o ./LibMicroBLT/microblt.su ./LibMicroBLT/port.cyclo ./LibMicroBLT/port.d ./LibMicroBLT/port.o ./LibMicroBLT/port.su ./LibMicroBLT/session.cyclo ./LibMicroBLT/session.d ./LibMicroBLT/session.o ./LibMicroBLT/session.su ./LibMicroBLT/srecreader.cyclo ./LibMicroBLT/srecreader.d ./LibMicroBLT/srecreader.o ./LibMicroBLT/srecreader.su ./LibMicroBLT/xcploader.cyclo ./LibMicroBLT/xcploader.d ./LibMicroBLT/xcploader.o ./LibMicroBLT/xcploader.su

.PHONY: clean-LibMicroBLT

