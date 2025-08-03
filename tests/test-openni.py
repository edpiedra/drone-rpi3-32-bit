from openni import openni2
openni2.initialize()
dev = openni2.Device.open_any()
print("Device:", dev.get_device_info())
openni2.unload()