################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_SRCS += \
../MicroTBX/tbx_comp.s 

C_SRCS += \
../MicroTBX/tbx_aes256.c \
../MicroTBX/tbx_assert.c \
../MicroTBX/tbx_checksum.c \
../MicroTBX/tbx_critsect.c \
../MicroTBX/tbx_crypto.c \
../MicroTBX/tbx_heap.c \
../MicroTBX/tbx_list.c \
../MicroTBX/tbx_mempool.c \
../MicroTBX/tbx_platform.c \
../MicroTBX/tbx_port.c \
../MicroTBX/tbx_random.c 

OBJS += \
./MicroTBX/tbx_aes256.o \
./MicroTBX/tbx_assert.o \
./MicroTBX/tbx_checksum.o \
./MicroTBX/tbx_comp.o \
./MicroTBX/tbx_critsect.o \
./MicroTBX/tbx_crypto.o \
./MicroTBX/tbx_heap.o \
./MicroTBX/tbx_list.o \
./MicroTBX/tbx_mempool.o \
./MicroTBX/tbx_platform.o \
./MicroTBX/tbx_port.o \
./MicroTBX/tbx_random.o 

S_DEPS += \
./MicroTBX/tbx_comp.d 

C_DEPS += \
./MicroTBX/tbx_aes256.d \
./MicroTBX/tbx_assert.d \
./MicroTBX/tbx_checksum.d \
./MicroTBX/tbx_critsect.d \
./MicroTBX/tbx_crypto.d \
./MicroTBX/tbx_heap.d \
./MicroTBX/tbx_list.d \
./MicroTBX/tbx_mempool.d \
./MicroTBX/tbx_platform.d \
./MicroTBX/tbx_port.d \
./MicroTBX/tbx_random.d 


# Each subdirectory must supply rules for building sources it contributes
MicroTBX/%.o MicroTBX/%.su MicroTBX/%.cyclo: ../MicroTBX/%.c MicroTBX/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DDEBUG -DUSE_PWR_LDO_SUPPLY -DUSE_HAL_DRIVER -DSTM32H753xx -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Middlewares/Third_Party/FreeRTOS/Source/include -I../Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS_V2 -I../Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F -I../Drivers/CMSIS/RTOS2/Include -I../Drivers/BSP/STM32H7xx_Nucleo -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/FatFs" -I"C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/LibMicroBLT" -I"C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/MicroTBX" -I"C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/CAN_Firmware_Flashing/CAN_Firmware_Flashing_Master/App" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"
MicroTBX/%.o: ../MicroTBX/%.s MicroTBX/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m7 -g3 -DDEBUG -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Middlewares/Third_Party/FreeRTOS/Source/include -I../Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS_V2 -I../Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F -I../Drivers/CMSIS/RTOS2/Include -I../Drivers/BSP/STM32H7xx_Nucleo -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

clean: clean-MicroTBX

clean-MicroTBX:
	-$(RM) ./MicroTBX/tbx_aes256.cyclo ./MicroTBX/tbx_aes256.d ./MicroTBX/tbx_aes256.o ./MicroTBX/tbx_aes256.su ./MicroTBX/tbx_assert.cyclo ./MicroTBX/tbx_assert.d ./MicroTBX/tbx_assert.o ./MicroTBX/tbx_assert.su ./MicroTBX/tbx_checksum.cyclo ./MicroTBX/tbx_checksum.d ./MicroTBX/tbx_checksum.o ./MicroTBX/tbx_checksum.su ./MicroTBX/tbx_comp.d ./MicroTBX/tbx_comp.o ./MicroTBX/tbx_critsect.cyclo ./MicroTBX/tbx_critsect.d ./MicroTBX/tbx_critsect.o ./MicroTBX/tbx_critsect.su ./MicroTBX/tbx_crypto.cyclo ./MicroTBX/tbx_crypto.d ./MicroTBX/tbx_crypto.o ./MicroTBX/tbx_crypto.su ./MicroTBX/tbx_heap.cyclo ./MicroTBX/tbx_heap.d ./MicroTBX/tbx_heap.o ./MicroTBX/tbx_heap.su ./MicroTBX/tbx_list.cyclo ./MicroTBX/tbx_list.d ./MicroTBX/tbx_list.o ./MicroTBX/tbx_list.su ./MicroTBX/tbx_mempool.cyclo ./MicroTBX/tbx_mempool.d ./MicroTBX/tbx_mempool.o ./MicroTBX/tbx_mempool.su ./MicroTBX/tbx_platform.cyclo ./MicroTBX/tbx_platform.d ./MicroTBX/tbx_platform.o ./MicroTBX/tbx_platform.su ./MicroTBX/tbx_port.cyclo ./MicroTBX/tbx_port.d ./MicroTBX/tbx_port.o ./MicroTBX/tbx_port.su ./MicroTBX/tbx_random.cyclo ./MicroTBX/tbx_random.d ./MicroTBX/tbx_random.o ./MicroTBX/tbx_random.su

.PHONY: clean-MicroTBX

