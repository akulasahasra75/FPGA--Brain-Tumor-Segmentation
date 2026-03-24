# 2026-03-02T21:34:09.719873900
import vitis

client = vitis.create_client()
client.set_workspace(path="Z:/vitis_ws")

platform = client.create_platform_component(name = "brain_tumor_platform",hw_design = "Z:\03_vivado_hardware\vivado_project\brain_tumor_soc.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",generate_dtb = True)

vitis.dispose()

