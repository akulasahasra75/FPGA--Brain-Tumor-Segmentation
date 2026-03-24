# 2026-03-02T21:31:50.743008700
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis_workspace")

platform = client.create_platform_component(name = "brain_tumor_platform",hw_design = "$COMPONENT_LOCATION/../../03_vivado_hardware/vivado_project/brain_tumor_soc.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",generate_dtb = True)

vitis.dispose()

