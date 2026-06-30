################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/tinyusb/src/portable/usb_board.c 

OBJS += \
./Loader/third_party/tinyusb/src/portable/usb_board.o 

C_DEPS += \
./Loader/third_party/tinyusb/src/portable/usb_board.d 


# Each subdirectory must supply rules for building sources it contributes
Loader/third_party/tinyusb/src/portable/usb_board.o: C:/Users/aragy/Documents/git_repos/BEEFBoard/1_Embedded/openblt/Target/Source/third_party/tinyusb/src/portable/usb_board.c Loader/third_party/tinyusb/src/portable/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -DSTM32H743xx -DDEBUG -DUSE_PWR_LDO_SUPPLY -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../App -I../Library/TinyUSB -I../Library/uip -I../../../../openblt/Target/Source -I../../../../openblt/Target/Source/ARMCM7_STM32H7 -I../../../../openblt/Target/Source/third_party/uip/apps/dhcpc -I../../../../openblt/Target/Source/third_party/uip/uip -I../../../../openblt/Target/Source/third_party/tinyusb/src -Og -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-Loader-2f-third_party-2f-tinyusb-2f-src-2f-portable

clean-Loader-2f-third_party-2f-tinyusb-2f-src-2f-portable:
	-$(RM) ./Loader/third_party/tinyusb/src/portable/usb_board.cyclo ./Loader/third_party/tinyusb/src/portable/usb_board.d ./Loader/third_party/tinyusb/src/portable/usb_board.o ./Loader/third_party/tinyusb/src/portable/usb_board.su

.PHONY: clean-Loader-2f-third_party-2f-tinyusb-2f-src-2f-portable

