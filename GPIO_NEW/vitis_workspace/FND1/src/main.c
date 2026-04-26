#include <stdint.h>
#include "xparameters.h"
#include "sleep.h"
#include "xil_printf.h"

#define FND_BASEADDR  XPAR_FND2_0_S00_AXI_BASEADDR

// 레지스터 포인터 매크로 설정
#define FND_CTRL_REG   (*(volatile uint32_t *) (FND_BASEADDR + 0x00)) // 제어 (Start/Stop)
#define FND_STAT_REG   (*(volatile uint32_t *) (FND_BASEADDR + 0x04)) // 상태 (Running)
#define FND_SPEED_REG  (*(volatile uint32_t *) (FND_BASEADDR + 0x08)) // 속도 조절 (새로 추가!)

// 비트 마스크
#define CMD_START  (1 << 0)
#define CMD_STOP   (1 << 1)
#define CMD_RESET  (1 << 2)

int main() {
    xil_printf("--- Dynamic Speed Control Test ---\n");

    // 기본 1배속 (1초마다 증가)로 카운트 시작
    FND_SPEED_REG = 99999999;
    FND_CTRL_REG = CMD_START;
    usleep(10000);
    FND_CTRL_REG = 0x00;

    xil_printf("Running at Normal Speed (1Hz)...\n");
    sleep(5); // 5초 대기 (이 동안 FND는 1초마다 올라감)

    // 소프트웨어에서 즉시 4배속으로 속도 변경!
    xil_printf("Changing to 4x Speed (4Hz)...\n");
    FND_SPEED_REG = 24999999; // 100,000,000 / 4 - 1
    sleep(5); // 5초 대기 (이 동안 FND는 0.25초마다 다다닥 올라감)

    // 소프트웨어에서 즉시 10배속으로 속도 변경!
    xil_printf("Changing to 10x Speed (10Hz)...\n");
    FND_SPEED_REG = 9999999;  // 100,000,000 / 10 - 1
    sleep(5);

    // 정지
    FND_CTRL_REG = CMD_STOP;
    usleep(10000);
    FND_CTRL_REG = 0x00;

    return 0;
}
