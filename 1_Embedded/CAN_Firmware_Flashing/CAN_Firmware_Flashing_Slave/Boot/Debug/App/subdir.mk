################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../App/app.c \
../App/hooks.c \
../App/led.c \
../App/shared_params.c 

OBJS += \
./App/app.o \
./App/hooks.o \
./App/led.o \
./App/shared_params.o 

C_DEPS += \
./App/app.d \
./App/hooks.d \
./App/led.d \
./App/shared_params.d 


# Each subdirectory must supply rules for building sources it contributes
App/%.o App/%.su App/%.cyclo: ../App/%.c App/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -DSTM32H743xx -DDEBUG -DUSE_PWR_LDO_SUPPLY -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../App -I../Library/TinyUSB -I../Library/uip -I../../../../openblt/Target/Source -I../../../../openblt/Target/Source/ARMCM7_STM32H7 -I../../../../openblt/Target/Source/third_party/uip/apps/dhcpc -I../../../../openblt/Target/Source/third_party/uip/uip -I../../../../openblt/Target/Source/third_party/tinyusb/src -Og -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-App

clean-App:
	-$(RM) ./App/app.cyclo ./App/app.d ./App/app.o ./App/app.su ./App/hooks.cyclo ./App/hooks.d ./App/hooks.o ./App/hooks.su ./App/led.cyclo ./App/led.d ./App/led.o ./App/led.su ./App/shared_params.cyclo ./App/shared_params.d ./App/shared_params.o ./App/shared_params.su

.PHONY: clean-App

