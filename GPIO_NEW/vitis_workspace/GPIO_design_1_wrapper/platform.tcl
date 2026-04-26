# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\won\ondivce\GPIO_NEW\vitis_workspace\GPIO_design_1_wrapper\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\won\ondivce\GPIO_NEW\vitis_workspace\GPIO_design_1_wrapper\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {GPIO_design_1_wrapper}\
-hw {C:\won\ondivce\GPIO\GPIO_design_1_wrapper.xsa}\
-fsbl-target {psu_cortexa53_0} -out {C:/won/ondivce/GPIO_NEW/vitis_workspace}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {empty_application}
platform generate -domains 
platform active {GPIO_design_1_wrapper}
platform generate -quick
platform generate
