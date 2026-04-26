#include <stdint.h>
#include "xparameters.h"
#include "sleep.h"
#include "xil_printf.h"

#define GPIOA_CR  (*(uint32_t *) (XPAR_GPIO_0_S00_AXI_BASEADDR + 0x00))
#define GPIOA_IDR  (*(uint32_t *) (XPAR_GPIO_0_S00_AXI_BASEADDR + 0x04))
#define GPIOA_ODR  (*(uint32_t *) (XPAR_GPIO_0_S00_AXI_BASEADDR + 0x08))

#define GPIOB_CR    (*(uint32_t *) (XPAR_GPIO_1_S00_AXI_BASEADDR + 0x00))
#define GPIOB_IDR   (*(uint32_t *) (XPAR_GPIO_1_S00_AXI_BASEADDR + 0x04))
#define GPIOB_ODR   (*(uint32_t *) (XPAR_GPIO_1_S00_AXI_BASEADDR + 0x08))


int main(){

int counter =0;
GPIOA_CR = 0xff;
GPIOB_CR = 0x00;

while(1){

   if(!(GPIOB_IDR & (1<<0))) {
      xil_printf("hello xilinx : %d\n", counter++);

   }
   else {
   GPIOA_ODR ^= 0xff;
   }
   usleep(100000);
}


   return 0;
}



