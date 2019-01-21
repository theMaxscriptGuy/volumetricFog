Shader "Hidden/VolumetricFog"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0
			
			#include "UnityCG.cginc"
			#include "common.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD1;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.uv;
				o.uv.zw = v.uv;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D_float _CameraDepthTexture;

			float3 GetWorldPos(float2 coord, float2 view) {
				float depth = tex2Dlod(_CameraDepthTexture, float4(coord.x, coord.y, 0.0, 0.0)).x;

#if defined(UNITY_REVERSED_Z)
				depth = 1.0f - depth;
#endif


				float4 viewCoord = float4(view.x * 2.0f - 1.0f, view.y * 2.0f - 1.0f, (2 * depth - 1), 1.0);
				float4 viewSpacePosition = mul(unity_CameraInvProjection, viewCoord);
				viewSpacePosition /= viewSpacePosition.w;
				viewSpacePosition.z *= -1;

				float4x4 camWorld = unity_CameraToWorld;
				float4 wpos = mul(camWorld, viewSpacePosition);
				wpos.xyz /= wpos.w;

				return wpos;
			}

			float4 frag(v2f i) : COLOR0{
					float4 coord = UnityStereoScreenSpaceUVAdjust(i.uv, _MainTex_ST);
					float3 world = GetWorldPos(coord.xy, i.uv.xy);

					float4 color = tex2D(_MainTex, coord);

					float3 uv = ConvertWorldToViewUv(world);
					float4 fog = tex3Dlod(volumeTexture, float4(uv, 0));

					return float4(color.rgb * fog.a + fog.rgb, color.a);
			}
			ENDCG
		}
	}
}