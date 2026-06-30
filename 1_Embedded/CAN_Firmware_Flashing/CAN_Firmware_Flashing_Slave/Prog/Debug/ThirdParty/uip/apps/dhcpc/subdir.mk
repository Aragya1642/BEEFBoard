################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/apps/dhcpc/dhcpc.c 

OBJS += \
./ThirdParty/uip/apps/dhcpc/dhcpc.o 

C_DEPS += \
./ThirdParty/uip/apps/dhcpc/dhcpc.d 


# Each subdirectory must supply rules for building sources it contributes
ThirdParty/uip/apps/dhcpc/dhcpc.o: C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/uip/apps/dhcpc/dhcpc.c ThirdParty/uip/apps/dhcpc/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DSTM32H743xx -DDEBUG -DUSE_PWR_LDO_SUPPLY -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../App -I../Library/uip -I../../../../openblt/Target/Source/third_party/uip/apps/dhcpc -I../../../../openblt/Target/Source/third_party/uip/uip -Og -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-ThirdParty-2f-uip-2f-apps-2f-dhcpc

clean-ThirdParty-2f-uip-2f-apps-2f-dhcpc:
	-$(RM) ./ThirdParty/uip/apps/dhcpc/dhcpc.cyclo ./ThirdParty/uip/apps/dhcpc/dhcpc.d ./ThirdParty/uip/apps/dhcpc/dhcpc.o ./ThirdParty/uip/apps/dhcpc/dhcpc.su

.PHONY: clean-ThirdParty-2f-uip-2f-apps-2f-dhcpc

