#include <stdint.h>
#include "xparameters.h"
#include "sleep.h"
#include "xil_printf.h"

// ===================================================================
// BASE ADDRESS 설정 (xparameters.h에서 실제 정의된 이름으로 꼭 변경하세요!)
// 예: XPAR_FND2_0_S00_AXI_BASEADDR 또는 XPAR_FND2_V1_0_0_BASEADDR
// ===================================================================
#define FND_BASEADDR  XPAR_FND4_0_S00_AXI_BASEADDR

// ===================================================================
// 레지스터 포인터 매크로 (하드웨어 접근 시 volatile 키워드 사용을 권장합니다)
// ===================================================================
#define FND_CTRL_REG  (*(volatile uint32_t *) (FND_BASEADDR + 0x00))
#define FND_STAT_REG  (*(volatile uint32_t *) (FND_BASEADDR + 0x04))

// 비트 마스크 정의
#define CMD_START     (1 << 0) // 0x01
#define CMD_STOP      (1 << 1) // 0x02
#define CMD_RESET     (1 << 2) // 0x04

int main() {
    xil_printf("--- FND Counter AXI Control Test ---\n");

    // 1. 하드웨어 초기화 (Reset 펄스 발생)
    xil_printf("1. Resetting FND...\n");
    FND_CTRL_REG = CMD_RESET;  // Reset 비트 1 (스위치 누름)
    usleep(10000);             // 10ms 대기
    FND_CTRL_REG = 0x00;       // Reset 비트 0 (스위치 뗌)

    usleep(500000); // 0.5초 대기

    // 2. 카운터 시작 (Start 펄스 발생)
    xil_printf("2. Starting FND...\n");
    FND_CTRL_REG = CMD_START;  // Start 비트 1
    usleep(10000);
    FND_CTRL_REG = 0x00;       // Start 비트 0으로 원상복구

    // 3. 5초 동안 상태 레지스터를 읽으며 카운트 진행 확인
    for (int i = 0; i < 5; i++) {
        // Status 레지스터의 0번 비트(is_running) 읽기
        uint32_t status = FND_STAT_REG & 0x01;
        xil_printf("   Running time: %d sec | is_running status: %d\n", i+1, status);
        sleep(1); // 1초 대기 (이 동안 보드의 FND는 하드웨어 타이머에 의해 계속 올라감)
    }

    // 4. 카운터 정지 (Stop 펄스 발생)
    xil_printf("3. Stopping FND...\n");
    FND_CTRL_REG = CMD_STOP;   // Stop 비트 1
    usleep(10000);
    FND_CTRL_REG = 0x00;       // Stop 비트 0

    xil_printf("Test Finished. Now you can use physical buttons.\n");

    // 무한 루프 유지 (보드의 물리 버튼으로도 직접 제어가 되는지 테스트 해보세요)
    while(1) {
        usleep(1000000);
    }

    return 0;
}
