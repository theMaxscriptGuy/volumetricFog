uint3 resolution;
float4x4 Inverse_View_Projection;
float4x4 _View_Projection;
float4 _CameraPlane;
sampler3D _VaporFogTexture;


float ConvertLinearToViewDepth(float val) 
{
	return val * _CameraPlane.y / (1 + val * _CameraPlane.z);
}

float3 ConvertUvToViewSpace(float3 uv)
{
	float3 view;
	view.x = uv.x * 2.0f - 1.0f;
	view.y = uv.y * 2.0f - 1.0f;
	uv.z = pow(saturate(uv.z), 4.0);
	view.z = ConvertLinearToViewDepth(uv.z);

	return view;
}

float3 ConvertViewToWorld(float3 view) 
{
	float4 worldPos = mul(Inverse_View_Projection, float4(view, 1.0f));
	return worldPos.xyz / worldPos.w;
}



float VaporDeviceToLinearDepth(float device) {
	return device / (_CameraPlane.y - device * _CameraPlane.z);
}

float3 WorldToVaporDevice(float3 world) {
	float4 deviceRaw = mul(_View_Projection, float4(world, 1.0f));
	return deviceRaw.xyz / deviceRaw.w;
}

float3 VaporDeviceToUv(float3 device) {
	float3 uv;
	uv.z = VaporDeviceToLinearDepth(device.z);
	uv.z = pow(saturate(uv.z), 1.0f / 4.0);
	uv.x = (device.x + 1.0f) * 0.5f;
	uv.y = (device.y + 1.0f) * 0.5f;
	return uv;
}

float3 WorldToVaporUv(float3 world) {
	float3 device = WorldToVaporDevice(world);
	return VaporDeviceToUv(device);
}