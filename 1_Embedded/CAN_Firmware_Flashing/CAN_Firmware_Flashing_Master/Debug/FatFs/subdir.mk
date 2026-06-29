################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../FatFs/ccsbcs.c \
../FatFs/ff.c \
../FatFs/ffdiskio.c 

OBJS += \
./FatFs/ccsbcs.o \
./FatFs/ff.o \
./FatFs/ffdiskio.o 

C_DEPS += \
./FatFs/ccsbcs.d \
./FatFs/ff.d \
./FatFs/ffdiskio.d 


# Each subdirectory must supply rules for building sources it contributes
FatFs/%.o FatFs/%.su FatFs/%.cyclo: ../FatFs/%.c FatFs/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DDEBUG -DUSE_PWR_LDO_SUPPLY -DUSE_HAL_DRIVER -DSTM32H753xx -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Middlewares/Third_Party/FreeRTOS/Source/include -I../Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS_V2 -I../Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F -I../Drivers/CMSIS/RTOS2/Include -I../Drivers/BSP/STM32H7xx_Nucleo -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/FatFs" -I"C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/LibMicroBLT" -I"C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/MicroTBX" -I"C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/App" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-FatFs

clean-FatFs:
	-$(RM) ./FatFs/ccsbcs.cyclo ./FatFs/ccsbcs.d ./FatFs/ccsbcs.o ./FatFs/ccsbcs.su ./FatFs/ff.cyclo ./FatFs/ff.d ./FatFs/ff.o ./FatFs/ff.su ./FatFs/ffdiskio.cyclo ./FatFs/ffdiskio.d ./FatFs/ffdiskio.o ./FatFs/ffdiskio.su

.PHONY: clean-FatFs

