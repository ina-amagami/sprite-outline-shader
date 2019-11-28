/*
Sprites/Outline

Copyright (c) 2019 ina-amagami (ina@amagamina.jp)

This software is released under the MIT License.
https://opensource.org/licenses/mit-license.php
*/
Shader "Sprites/Outline"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		[MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
		_OutLineSpread ("Outline Spread", Range(0, 0.1)) = 0
		_OutLineColor ("Outline Color", Color) = (1, 1, 1, 1)
		_Smoothness ("Outline Smoothness", Range(0, 0.5)) = 0.1
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Fog { Mode Off }
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile DUMMY PIXELSNAP_ON
			#include "UnityCG.cginc"
			
			struct appdata
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex	: SV_POSITION;
				fixed4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};
			
			sampler2D _MainTex;
			half _OutLineSpread;
			fixed4 _OutLineColor;
			fixed _Smoothness;

			v2f vert(appdata IN)
			{
				fixed scale = 1 + _OutLineSpread * 2;

				float2 tex = IN.texcoord * scale;
				tex -= (scale - 1) / 2;

				v2f OUT;
				OUT.vertex = mul(UNITY_MATRIX_MVP, IN.vertex);
				OUT.texcoord = tex;
				OUT.color = IN.color;
				#ifdef PIXELSNAP_ON
				OUT.vertex = UnityPixelSnap (OUT.vertex);
				#endif

				return OUT;
			}

			sampler2D _AlphaTex;
			float _AlphaSplitEnabled;

			fixed4 SampleSpriteTexture (float2 uv)
			{
				fixed4 color = tex2D (_MainTex, uv);

#if UNITY_TEXTURE_ALPHASPLIT_ALLOWED
				if (_AlphaSplitEnabled)
				{
					color.a = tex2D (_AlphaTex, uv).r;
				}
#endif

				return color;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 base = SampleSpriteTexture(IN.texcoord) * IN.color;

				fixed4 out_col = _OutLineColor;
				out_col.a = 1;
				half2 line_w = half2(_OutLineSpread, 0);
				fixed4 line_col = SampleSpriteTexture(IN.texcoord + line_w.xy)
							    + SampleSpriteTexture(IN.texcoord - line_w.xy)
								+ SampleSpriteTexture(IN.texcoord + line_w.yx)
								+ SampleSpriteTexture(IN.texcoord - line_w.yx);
				out_col *= line_col.a;
				out_col.rgb = _OutLineColor.rgb;
				out_col = lerp(base, out_col, max(0, sign(_OutLineSpread)));

				fixed4 main_col = base;
				main_col = lerp(main_col, out_col, (1 - main_col.a));
				main_col.a = IN.color.a * max(0, sign(main_col.a - _Smoothness));
				return main_col;
			}
		ENDCG
		}
	}
}