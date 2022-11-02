###########################################
## Pin Mapping
## LED0: AT32, LED1: AV34, LED2: AY30
###########################################
set_property PACKAGE_PIN AT32 [get_ports {led[0]}]
set_property PACKAGE_PIN AV34 [get_ports {led[1]}]
set_property PACKAGE_PIN AY30 [get_ports {led[2]}]

set_property IOSTANDARD LVCMOS12 [get_ports {led[*]}]


###########################################
## Timing Constraints
###########################################
set_false_path -from [get_ports pcie_perstn]
set_false_path -through [get_pins u_shell_wrapper/usr_rtl_rstn]
