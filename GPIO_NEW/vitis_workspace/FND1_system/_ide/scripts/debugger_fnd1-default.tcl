# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: C:\won\ondivce\GPIO_NEW\vitis_workspace\FND1_system\_ide\scripts\debugger_fnd1-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source C:\won\ondivce\GPIO_NEW\vitis_workspace\FND1_system\_ide\scripts\debugger_fnd1-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent Basys3 210183B31B0FA" && level==0 && jtag_device_ctx=="jsn-Basys3-210183B31B0FA-0362d093-0"}
fpga -file C:/won/ondivce/GPIO_NEW/vitis_workspace/FND1/_ide/bitstream/FND_2design_2_wrapper.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw C:/won/ondivce/GPIO_NEW/vitis_workspace/FND_2design_2_wrapper/export/FND_2design_2_wrapper/hw/FND_2design_2_wrapper.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow C:/won/ondivce/GPIO_NEW/vitis_workspace/FND1/Debug/FND1.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
con
