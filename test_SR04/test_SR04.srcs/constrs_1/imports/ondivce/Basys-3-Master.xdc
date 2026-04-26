## Basys3 Rev B - SR04 + 7seg (for top_sr04_fnd / top with fnd_data,fnd_digit, echo, trigger)
## ------------------------------------------------------------

## Clock signal (100MHz)
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset button (Basys3 btnC = U18)  *네 top이 rst 입력일 때*
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports rst]

## ------------------------------------------------------------
## 7 Segment Display
## Basys3 uses: seg[6:0], dp, an[3:0]
## 네 top 포트: fnd_data[7:0] (a,b,c,d,e,f,g,dp), fnd_digit[3:0] (an[0..3])
## ------------------------------------------------------------

## seg[0] = a
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[0]}]
## seg[1] = b
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[1]}]
## seg[2] = c
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[2]}]
## seg[3] = d
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[3]}]
## seg[4] = e
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[4]}]
## seg[5] = f
set_property -dict { PACKAGE_PIN V5   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[5]}]
## seg[6] = g
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[6]}]
## dp
set_property -dict { PACKAGE_PIN V7   IOSTANDARD LVCMOS33 } [get_ports {fnd_data[7]}]

## an[0..3] (digit enable)
set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS33 } [get_ports {fnd_digit[0]}]
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports {fnd_digit[1]}]
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports {fnd_digit[2]}]
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS33 } [get_ports {fnd_digit[3]}]

## ------------------------------------------------------------
## Pmod Header JA (SR04)
## 추천 배선:
##  - JA1(JA[0]) : TRIG (FPGA -> SR04 TRIG)
##  - JA2(JA[1]) : ECHO (SR04 ECHO -> FPGA)  **반드시 5V->3.3V 분압**
##  - JA GND, VCC(5V)도 같이 연결
## ------------------------------------------------------------

## JA1 = J1
set_property -dict { PACKAGE_PIN J1   IOSTANDARD LVCMOS33 } [get_ports trigger]
## JA2 = L2
set_property -dict { PACKAGE_PIN L2   IOSTANDARD LVCMOS33 } [get_ports echo]

## (옵션) ECHO 입력이 떠서 노이즈 타면 풀다운/풀업을 줄 수 있음
## 보통은 센서가 달려있으면 필요 없지만, 테스트 중이면 PULLDOWN 권장
## set_property PULLDOWN true [get_ports echo]

## ------------------------------------------------------------
## Config
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
