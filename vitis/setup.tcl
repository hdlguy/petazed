# run at linux command line 
#       xsct setup.tcl
#       vitis --classic --workspace ./workspace
#
file delete -force ./workspace

set hw ../implement/results/top.xsa
set proc "ps7_cortexa9_0"
#set proc "psu_cortexr5_0"
#set proc "psu_cortexa53_0"
#set proc "microblaze_0"

setws ./workspace

platform create -name "standalone_plat" -hw $hw -proc $proc -os standalone

app create -name hello1 -platform standalone_plat -domain standalone_domain -template "Empty Application(C)"
file link -symbolic ./workspace/hello1/src/test.c             ../../../src/hello1/test.c
file link -symbolic ./workspace/hello1/src/fpga.h               ../../../src/fpga.h

app build all


