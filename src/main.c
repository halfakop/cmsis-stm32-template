#include <stm32f10x.h>
/* Подключаем функции управления генератором частоты и GPIO */
#include <stm32f10x_rcc.h>
#include <stm32f10x_gpio.h>

const uint16_t
  LED1 = GPIO_Pin_8, // PC8
  LED2 = GPIO_Pin_9, // PC9
  BUTTON = GPIO_Pin_0; // PA0

void init_button();
void init_leds();

int main()
{
  init_button();
  init_leds();
  GPIO_ResetBits(GPIOC, LED1 | LED2);

  /* Конфигурируем таймер SysTick на срабатывание 100 раз в секунду */
  SysTick_Config(SystemCoreClock / 100);

  do ; while (1);
}

/* Обработчик прерывания по переполнению таймера SysTick */
void SysTick_Handler()
{
  /* Обработка кнопки */
  static uint8_t btn_old_state = 0;
  uint8_t btn_state = GPIO_ReadInputDataBit(GPIOA, BUTTON);

  if (btn_old_state == 0 && btn_state == 1)
    GPIO_WriteBit(GPIOC, LED1, !GPIO_ReadOutputDataBit(GPIOC, LED1));

  btn_old_state = btn_state;

  /* Мигание светодиодом */
  static uint8_t counter = 0;

  if (counter == 0)
  {
    GPIO_WriteBit(GPIOC, LED2, !GPIO_ReadOutputDataBit(GPIOC, LED2));
    counter = 10;
  }
  else
    --counter;
}

void init_button()
{
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
  GPIO_InitTypeDef gpio;
  GPIO_StructInit(&gpio);
  gpio.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  gpio.GPIO_Pin = BUTTON;
  gpio.GPIO_Speed = GPIO_Speed_2MHz;
  GPIO_Init(GPIOA, &gpio);
}

void init_leds()
{
  /* Включаем тактирование порта C */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOC, ENABLE);

  /* Заполняем структуру gpio данными для инициализации:
   * - Режим: вывод, Push-Pull
   * - Пины: 8 и 9
   * - Частота обновления: 2 МГц
   */
  GPIO_InitTypeDef gpio;
  GPIO_StructInit(&gpio);
  gpio.GPIO_Mode = GPIO_Mode_Out_PP;
  gpio.GPIO_Pin = LED1 | LED2;
  gpio.GPIO_Speed = GPIO_Speed_2MHz;

  /* Инициализируем GPIO на порту C */
  GPIO_Init(GPIOC, &gpio);

  /* Устанавливаем единички на выводах 8 и 9 */
  GPIO_SetBits(GPIOC, GPIO_Pin_8 | GPIO_Pin_9);
}
