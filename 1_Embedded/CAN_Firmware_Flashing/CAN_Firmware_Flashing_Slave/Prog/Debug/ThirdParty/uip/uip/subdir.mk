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
./ThirdParty/uip/uip/uip.o \
./ThirdParty/uip/uip/uip_arp.o \
./ThirdParty/uip/uip/uip_timer.o \
./ThirdParty/uip/uip/uiplib.o 

C_DEPS += \
./ThirdParty/uip/uip/uip.d \
./ThirdParty/uip/uip/uip_arp.d \
./ThirdParty/uip/uip/uip_timer.d \
./ThirdParty/uip/uip/uiplib.d 


# Each subdirectory must supply rules for building sources it contributes
ThirdParty/uip/uip/uip.o: C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/uip/uip.c ThirdParty/uip/uip/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DSTM32H743xx -DDEBUG -DUSE_PWR_LDO_SUPPLY -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../App -I../Library/uip -I../../../../openblt/Target/Source/third_party/uip/apps/dhcpc -I../../../../openblt/Target/Source/third_party/uip/uip -Og -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"
ThirdParty/uip/uip/uip_arp.o: C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/uip/uip_arp.c ThirdParty/uip/uip/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DSTM32H743xx -DDEBUG -DUSE_PWR_LDO_SUPPLY -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../App -I../Library/uip -I../../../../openblt/Target/Source/third_party/uip/apps/dhcpc -I../../../../openblt/Target/Source/third_party/uip/uip -Og -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"
ThirdParty/uip/uip/uip_timer.o: C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/uip/uip_timer.c ThirdParty/uip/uip/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DSTM32H743xx -DDEBUG -DUSE_PWR_LDO_SUPPLY -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../App -I../Library/uip -I../../../../openblt/Target/Source/third_party/uip/apps/dhcpc -I../../../../openblt/Target/Source/third_party/uip/uip -Og -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"
ThirdParty/uip/uip/uiplib.o: C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/uip/uiplib.c ThirdParty/uip/uip/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DSTM32H743xx -DDEBUG -DUSE_PWR_LDO_SUPPLY -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../App -I../Library/uip -I../../../../openblt/Target/Source/third_party/uip/apps/dhcpc -I../../../../openblt/Target/Source/third_party/uip/uip -Og -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-ThirdParty-2f-uip-2f-uip

clean-ThirdParty-2f-uip-2f-uip:
	-$(RM) ./ThirdParty/uip/uip/uip.cyclo ./ThirdParty/uip/uip/uip.d ./ThirdParty/uip/uip/uip.o ./ThirdParty/uip/uip/uip.su ./ThirdParty/uip/uip/uip_arp.cyclo ./ThirdParty/uip/uip/uip_arp.d ./ThirdParty/uip/uip/uip_arp.o ./ThirdParty/uip/uip/uip_arp.su ./ThirdParty/uip/uip/uip_timer.cyclo ./ThirdParty/uip/uip/uip_timer.d ./ThirdParty/uip/uip/uip_timer.o ./ThirdParty/uip/uip/uip_timer.su ./ThirdParty/uip/uip/uiplib.cyclo ./ThirdParty/uip/uip/uiplib.d ./ThirdParty/uip/uip/uiplib.o ./ThirdParty/uip/uip/uiplib.su

.PHONY: clean-ThirdParty-2f-uip-2f-uip

