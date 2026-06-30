################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Library/uip/clock-arch.c \
../Library/uip/lan8742.c \
../Library/uip/netdev.c 

OBJS += \
./Library/uip/clock-arch.o \
./Library/uip/lan8742.o \
./Library/uip/netdev.o 

C_DEPS += \
./Library/uip/clock-arch.d \
./Library/uip/lan8742.d \
./Library/uip/netdev.d 


# Each subdirectory must supply rules for building sources it contributes
Library/uip/%.o Library/uip/%.su Library/uip/%.cyclo: ../Library/uip/%.c Library/uip/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DSTM32H743xx -DDEBUG -DUSE_PWR_LDO_SUPPLY -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I../App -I../Library/uip -I../../../../openblt/Target/Source/third_party/uip/apps/dhcpc -I../../../../openblt/Target/Source/third_party/uip/uip -Og -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-Library-2f-uip

clean-Library-2f-uip:
	-$(RM) ./Library/uip/clock-arch.cyclo ./Library/uip/clock-arch.d ./Library/uip/clock-arch.o ./Library/uip/clock-arch.su ./Library/uip/lan8742.cyclo ./Library/uip/lan8742.d ./Library/uip/lan8742.o ./Library/uip/lan8742.su ./Library/uip/netdev.cyclo ./Library/uip/netdev.d ./Library/uip/netdev.o ./Library/uip/netdev.su

.PHONY: clean-Library-2f-uip

