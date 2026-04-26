# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: C:\won\ondivce\GPIO_NEW\vitis_workspace\FNDre_system\_ide\scripts\debugger_fndre-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source C:\won\ondivce\GPIO_NEW\vitis_workspace\FNDre_system\_ide\scripts\debugger_fndre-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent Basys3 210183B31B0FA" && level==0 && jtag_device_ctx=="jsn-Basys3-210183B31B0FA-0362d093-0"}
fpga -file C:/won/ondivce/GPIO_NEW/vitis_workspace/FNDre/_ide/bitstream/FNDredesign_1_wrapper.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw C:/won/ondivce/GPIO_NEW/vitis_workspace/FNDredesign_1_wrapper/export/FNDredesign_1_wrapper/hw/FNDredesign_1_wrapper.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
