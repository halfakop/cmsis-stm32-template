# Имя проекта
#-------------------------------------------------------------------------------
TARGET  = template

# Используемые модули библиотеки периферии
#-------------------------------------------------------------------------------
# PERIPHDRIVERS += stm32f10x_adc
# PERIPHDRIVERS += stm32f10x_bkp
# PERIPHDRIVERS += stm32f10x_can
# PERIPHDRIVERS += stm32f10x_cec
# PERIPHDRIVERS += stm32f10x_crc
# PERIPHDRIVERS += stm32f10x_dbgmcu
# PERIPHDRIVERS += stm32f10x_exti
# PERIPHDRIVERS += stm32f10x_flash
# PERIPHDRIVERS += stm32f10x_fsmc
PERIPHDRIVERS += stm32f10x_gpio
# PERIPHDRIVERS += stm32f10x_i2c
# PERIPHDRIVERS += stm32f10x_iwdg
# PERIPHDRIVERS += stm32f10x_pwr
PERIPHDRIVERS += stm32f10x_rcc
# PERIPHDRIVERS += stm32f10x_rtc
# PERIPHDRIVERS += stm32f10x_sdio
# PERIPHDRIVERS += stm32f10x_spi
# PERIPHDRIVERS += stm32f10x_tim
# PERIPHDRIVERS += stm32f10x_usart
# PERIPHDRIVERS += stm32f10x_wwdg
# PERIPHDRIVERS += misc.c

# Дефайны
#-------------------------------------------------------------------------------
DEFINES += USE_STDPERIPH_DRIVER  # использование SPL
DEFINES += STM32F10X_MD_VL       # SystemCoreClock = SYSCLK_FREQ_24MHz
DEFINES += GCC_ARMCM3
DEFINES += VECT_TAB_FLASH

# Инструменты
#-------------------------------------------------------------------------------
TOOLCHAIN=~/devel/arm/toolchain/current/bin
AS = $(TOOLCHAIN)/arm-none-eabi-gcc
CC = $(TOOLCHAIN)/arm-none-eabi-gcc
LD = $(TOOLCHAIN)/arm-none-eabi-gcc
CP = $(TOOLCHAIN)/arm-none-eabi-objcopy
SZ = $(TOOLCHAIN)/arm-none-eabi-size
OD = $(TOOLCHAIN)/arm-none-eabi-objdump
RM = rm

# Пути к CMSIS, StdPeriph Lib
#-------------------------------------------------------------------------------
CMSIS_PATH         = cmsis
STDPERIPH_INC_PATH = stdperiph/inc
STDPERIPH_SRC_PATH = stdperiph/src

# Путь к файлу инициализации
#-------------------------------------------------------------------------------
STARTUP = startup/stm32f10x_md_vl.s

# Пути поиска исходных файлов
#-------------------------------------------------------------------------------
SOURCEDIRS := src
SOURCEDIRS += $(CMSIS_PATH)
SOURCEDIRS += $(STDPERIPH_SRC_PATH)

# Пути поиска заголовочных файлов
#-------------------------------------------------------------------------------
INCLUDES += .
INCLUDES += $(SOURCEDIRS)
INCLUDES += $(CMSIS_PATH)
INCLUDES += $(STDPERIPH_INC_PATH)

# Библиотеки
#-------------------------------------------------------------------------------
LIBPATH +=
LIBS    +=

# Настройки компилятора
#-------------------------------------------------------------------------------
CFLAGS += -mthumb -mcpu=cortex-m3 # архитектура и система комманд
CFLAGS += -std=gnu99              # стандарт языка С
CFLAGS += -Wall -pedantic         # выводить все предупреждения
CFLAGS += -Os                     # оптимизация
CFLAGS += -ggdb                   # генерировать отладочную информацию для gdb
CFLAGS += -fno-builtin

CFLAGS += $(addprefix -I, $(INCLUDES))
CFLAGS += $(addprefix -D, $(DEFINES))

# Скрипт линкера
#-------------------------------------------------------------------------------
LDSCR_PATH = ld-scripts
LDSCRIPT   = stm32f100rb.ld

# Настройки линкера
#-------------------------------------------------------------------------------
LDFLAGS += -nostartfiles -nostdlib -mthumb
LDFLAGS += -L$(LDSCR_PATH)
LDFLAGS += -T$(LDSCR_PATH)/$(LDSCRIPT)
LDFLAGS += $(addprefix -L, $(LIBPATH))
LDFLAGS += $(LIBS)

# Настройки ассемблера
#-------------------------------------------------------------------------------
# AFLAGS += -ahls -mapcs-32

# Список объектных файлов
#-------------------------------------------------------------------------------
OBJS += $(patsubst %.c, %.o, $(wildcard  $(addsuffix /*.c, $(SOURCEDIRS))))
OBJS += $(addprefix $(STDPERIPH_SRC_PATH)/, $(addsuffix .o, $(PERIPHDRIVERS)))
OBJS += $(patsubst %.s, %.o, $(STARTUP))

# Пути поиска make
#-------------------------------------------------------------------------------
VPATH := $(SOURCEDIRS)

# Список файлов к удалению командой "make clean"
#-------------------------------------------------------------------------------
TOREMOVE += *.elf *.hex a.out *~
TOREMOVE += $(addsuffix /*.o, $(SOURCEDIRS))
TOREMOVE += $(addsuffix /*.d, $(SOURCEDIRS))
TOREMOVE += $(addsuffix /*~, $(SOURCEDIRS))
TOREMOVE += $(STDPERIPH_SRC_PATH)/*.o
TOREMOVE += $(patsubst %.s, %.o, $(STARTUP))
TOREMOVE += $(TARGET)

# Собрать всё
#-------------------------------------------------------------------------------
all: $(TARGET).hex size

# Очистка
#-------------------------------------------------------------------------------
clean:
	@$(RM) -f $(TOREMOVE)

# Создание .hex файла
#-------------------------------------------------------------------------------
$(TARGET).hex: $(TARGET).elf
	@echo "Create HEX =>" $(CP) -Oihex $(TARGET).elf $(TARGET).hex
	@$(CP) -Oihex $(TARGET).elf $(TARGET).hex

$(TARGET).lst: $(TARGET).elf
	@echo "Create LST =>" $(OD) -h -S $(TARGET).elf > $(TARGET).lst
	@$(OD) -h -S $< > $@

# Показываем размер
#-------------------------------------------------------------------------------
size:
	@echo "---------------------------------------------------"
	@$(SZ) $(TARGET).elf

# Линковка
#-------------------------------------------------------------------------------
$(TARGET).elf: $(OBJS)
	@echo "Linking =>" $^
	@$(LD) $(LDFLAGS) $^ -o $@

# Компиляция
#-------------------------------------------------------------------------------
%.o: %.c
	@echo "Compilling C source =>" $<
	@$(CC) $(CFLAGS) -MD -c $< -o $@

%.o: %.s
	@echo "Compilling ASM source =>" $<
	@$(AS) $(AFLAGS) -c $< -o $@

# Сгенерированные gcc зависимости
#-------------------------------------------------------------------------------
include $(wildcart *.d)
