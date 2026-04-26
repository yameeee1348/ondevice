## =========================================================
## Basys3 최소 XDC (dht11_controller용)
## =========================================================

## Clock 100 MHz
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk]

## Reset (예: btnC 사용)  -- 포트명이 rst라면 아래처럼
set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## Start 버튼 (예: btnU 사용) -- 포트명이 start라면
set_property PACKAGE_PIN T18 [get_ports start]
set_property IOSTANDARD LVCMOS33 [get_ports start]

## DHT11 Data (예: Pmod JA1에 연결했다고 가정)
## Basys3 Pmod JA: JA1=J1, JA2=L2, JA3=J2, JA4=G2, JA7=H1, JA8=K2, JA9=H2, JA10=G3
set_property PACKAGE_PIN J1 [get_ports dhtio]        ;# 또는 DHT11_data 포트명에 맞게
set_property IOSTANDARD LVCMOS33 [get_ports dhtio]
set_property PULLUP true [get_ports dhtio]

## (선택) debug[2:0]을 LED에 연결 (LED0~2 예시)
set_property PACKAGE_PIN U16 [get_ports {debug[0]}]
set_property PACKAGE_PIN E19 [get_ports {debug[1]}]
set_property PACKAGE_PIN U19 [get_ports {debug[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {debug[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {debug[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {debug[2]}]

## (선택) DHT11_valid를 LED3에 연결
set_property PACKAGE_PIN V19 [get_ports DHT11_valid]
set_property IOSTANDARD LVCMOS33 [get_ports DHT11_valid]
