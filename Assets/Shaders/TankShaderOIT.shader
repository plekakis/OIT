/*
MIT License

Copyright (c) 2018 Pantelis Lekakis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

Shader "Custom/Tank OIT"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100

		Pass
		{
			// OIT version doesn't write anything
			ColorMask 0
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0
			
			#include "UnityCG.cginc"
			#include "OITCommon.cginc"
		
			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 screenPos : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata_base v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				// export post-projection vertex, we'll calculate screen position with this
				o.screenPos.xyz = o.vertex.xyw;

				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}
			
			// OIT pixel shader
			void frag (v2f i)
			{				
				// This is the same as the non-oit version
				float4 diffuse = tex2D(_MainTex, i.uv);
				diffuse.a = 0.5;

				// Calculate post-projection depth
				const float z = i.vertex.z / i.vertex.w;

				// Bring the screen position into viewport position coordinates [ (0,0)..(1,1)] -> [ (0,0)..(width,height)]
				// This is used to calculate the offset in the headPointer buffer
				const uint2 screenSize = (uint2)_ScreenParams.xy;
				const float2 screenPos = (i.screenPos.xy / i.screenPos.z) * 0.5 + 0.5;
				const float2 viewportPos = ceil(screenPos.xy * screenSize);

				// Increment the counter of the headPointers
				const uint nodeIndex = _OITHeadPointers.IncrementCounter();
				
				// Calculate the flat index to access the headPointer buffer
				const uint nodeCoord = viewportPos.y * screenSize.x + viewportPos.x;

				// Get the previous head index for this nodeCoord and put the new one in
				// The previous one will be our next link in the list
				uint prevHead;
				InterlockedExchange(_OITHeadPointers[nodeCoord], nodeIndex, prevHead);

				// Finally, update the node with the colour, depth and the next link in the list
				_OITNodes[nodeIndex].color = diffuse;
				_OITNodes[nodeIndex].depth = z;
				_OITNodes[nodeIndex].next = prevHead;
			}
			ENDCG
		}
	}
}
