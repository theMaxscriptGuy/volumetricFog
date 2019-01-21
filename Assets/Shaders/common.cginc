uint3 resolution;
float4x4 Inverse_View_Projection;
float4x4 _View_Projection;
float4 _CameraPlane;
sampler3D volumeTexture;


#define depthSaturation 2.0

float ConvertLinearToViewDepth(float val) 
{
	return val * _CameraPlane.y / (1 + val * _CameraPlane.z);
}

float3 ConvertUvToView(float3 uv) 
{
	//standard way to convert from uv 0-1 to -1 to 1
	float3 view;
	view.x = uv.x * 2.0f - 1.0f;
	view.y = uv.y * 2.0f - 1.0f;
	//as we go in the depth/z-dir saturate to get the volumetric fog depth effect
	uv.z = pow(saturate(uv.z), depthSaturation);
	view.z = ConvertLinearToViewDepth(uv.z);
	return view;
}

float3 ConvertViewToWorld(float3 view) 
{
	float4 worldPos = mul(Inverse_View_Projection, float4(view, 1.0f));
	return worldPos.xyz / worldPos.w;
}

float ConvertViewToLinearDepth(float view) 
{
	return view / (_CameraPlane.y - view * _CameraPlane.z);
}

float3 WorldToViewSpace(float3 world) 
{
	float4 viewRaw = mul(_View_Projection, float4(world, 1.0f));
	return viewRaw.xyz / viewRaw.w;
}

float3 ConvertViewToUv(float3 view) 
{
	float3 uv;
	uv.z = ConvertViewToLinearDepth(view.z);
	uv.z = pow(saturate(uv.z), 1.0f / depthSaturation);
	uv.x = (view.x + 1.0f) * 0.5f;
	uv.y = (view.y + 1.0f) * 0.5f;
	return uv;
}

float3 ConvertWorldToViewUv(float3 worldPos) 
{
	float3 view = WorldToViewSpace(worldPos);
	return ConvertViewToUv(view);
}