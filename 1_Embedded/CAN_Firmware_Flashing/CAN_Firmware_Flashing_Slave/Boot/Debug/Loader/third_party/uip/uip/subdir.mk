################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/uip/uip.c \
C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/uip/uip_arp.c \
C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/uip/uip_timer.c \
C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/uip/uiplib.c 

OBJS += \
./Loader/third_party/uip/uip/uip.o \
./Loader/third_party/uip/uip/uip_arp.o \
./Loader/third_party/uip/uip/uip_timer.o \
./Loader/third_party/uip/uip/uiplib.o 

C_DEPS += \
./Loader/third_party/uip/uip/uip.d \
./Loader/third_party/uip/uip/uip_arp.d \
./Loader/third_party/uip/uip/uip_timer.d \
./Loader/third_party/uip/uip/uiplib.d 


# Each subdirectory must supply rules for building sources it contributes
Loader/third_party/uip/uip/uip.o: C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/uip/uip.c Loader/third_party/uip/uip/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -DSTM32H743xx -DDEBUG -DUSE_PWR_LDO_SUPPLY -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../App -I../Library/TinyUSB -I../Library/uip -I../../../../openblt/Target/Source -I../../../../openblt/Target/Source/ARMCM7_STM32H7 -I../../../../openblt/Target/Source/third_party/uip/apps/dhcpc -I../../../../openblt/Target/Source/third_party/uip/uip -I../../../../openblt/Target/Source/third_party/tinyusb/src -Og -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"
Loader/third_party/uip/uip/uip_arp.o: C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/uip/uip_arp.c Loader/third_party/uip/uip/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -DSTM32H743xx -DDEBUG -DUSE_PWR_LDO_SUPPLY -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../App -I../Library/TinyUSB -I../Library/uip -I../../../../openblt/Target/Source -I../../../../openblt/Target/Source/ARMCM7_STM32H7 -I../../../../openblt/Target/Source/third_party/uip/apps/dhcpc -I../../../../openblt/Target/Source/third_party/uip/uip -I../../../../openblt/Target/Source/third_party/tinyusb/src -Og -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"
Loader/third_party/uip/uip/uip_timer.o: C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/uip/uip_timer.c Loader/third_party/uip/uip/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -DSTM32H743xx -DDEBUG -DUSE_PWR_LDO_SUPPLY -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../App -I../Library/TinyUSB -I../Library/uip -I../../../../openblt/Target/Source -I../../../../openblt/Target/Source/ARMCM7_STM32H7 -I../../../../openblt/Target/Source/third_party/uip/apps/dhcpc -I../../../../openblt/Target/Source/third_party/uip/uip -I../../../../openblt/Target/Source/third_party/tinyusb/src -Og -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"
Loader/third_party/uip/uip/uiplib.o: C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/uip/uiplib.c Loader/third_party/uip/uip/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -DSTM32H743xx -DDEBUG -DUSE_PWR_LDO_SUPPLY -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../App -I../Library/TinyUSB -I../Library/uip -I../../../../openblt/Target/Source -I../../../../openblt/Target/Source/ARMCM7_STM32H7 -I../../../../openblt/Target/Source/third_party/uip/apps/dhcpc -I../../../../openblt/Target/Source/third_party/uip/uip -I../../../../openblt/Target/Source/third_party/tinyusb/src -Og -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-Loader-2f-third_party-2f-uip-2f-uip

clean-Loader-2f-third_party-2f-uip-2f-uip:
	-$(RM) ./Loader/third_party/uip/uip/uip.cyclo ./Loader/third_party/uip/uip/uip.d ./Loader/third_party/uip/uip/uip.o ./Loader/third_party/uip/uip/uip.su ./Loader/third_party/uip/uip/uip_arp.cyclo ./Loader/third_party/uip/uip/uip_arp.d ./Loader/third_party/uip/uip/uip_arp.o ./Loader/third_party/uip/uip/uip_arp.su ./Loader/third_party/uip/uip/uip_timer.cyclo ./Loader/third_party/uip/uip/uip_timer.d ./Loader/third_party/uip/uip/uip_timer.o ./Loader/third_party/uip/uip/uip_timer.su ./Loader/third_party/uip/uip/uiplib.cyclo ./Loader/third_party/uip/uip/uiplib.d ./Loader/third_party/uip/uip/uiplib.o ./Loader/third_party/uip/uip/uiplib.su

.PHONY: clean-Loader-2f-third_party-2f-uip-2f-uip

