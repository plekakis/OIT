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

Shader "Hidden/OITComposite"
{
	Properties
	{
		_MainTex("Main tex", 2D) = "white"
		_OITSortedTex("OIT Sorted", 2D) = "black"
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0
			
			#include "UnityCG.cginc"
			#include "OITCommon.cginc"

			sampler2D _MainTex;
			sampler2D _OITSortedTex;

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata_base v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}

			// Sort the nodes based on depth
			void Sort(inout OITNode io_nodes[MAX_OIT_PIXEL_NODES], uint i_count)
			{
				for (uint i = 1; i < i_count; i++)
				{
					OITNode toInsert = io_nodes[i];
					uint j = i;
#if UNITY_REVERSED_Z
					while (j > 0 && toInsert.depth < io_nodes[j - 1].depth)
#else
					while (j > 0 && toInsert.depth > io_nodes[j - 1].depth)
#endif // UNITY_REVERSED_Z
					{
						io_nodes[j] = io_nodes[j - 1];
						j--;
					}
					io_nodes[j] = toInsert;
				}
			}
			
			// Calculate the final pixel color and composite it with the scene
			float4 frag (v2f i) : SV_Target
			{
				// Calculate viewport position [(0,0)..(width,height)] and find the current nodeCoord
				const uint2 screenSize = (uint2)_ScreenParams.xy;
				const float2 uv = float2(i.uv.x, 1.0 - i.uv.y);
				const float2 viewportPos = ceil(uv * screenSize);

				const uint nodeCoord = viewportPos.y * screenSize.x + viewportPos.x;
				
				// These are the nodes that we'll sort for this pixel
				OITNode nodes[MAX_OIT_PIXEL_NODES];

				// Go through the headPointers for this pixel and update the local array until we run out of elements
				uint count = 0;
				uint next = _OITHeadPointers[nodeCoord];
				while ( (next != ~0u) && (count < MAX_OIT_PIXEL_NODES) )
				{
					nodes[count] = _OITNodes[next];
					next = nodes[count].next;
					++count;
				}

				// Sort the nodes based on depth
				Sort(nodes, count);

				// Colors are sorted, lerp from one to another based on the alpha
				float4 color = 0.0;
				for (uint c = 0; c < count; c++)
				{
					color.rgb = lerp(color.rgb, nodes[c].color.rgb, nodes[c].color.a);
				}
				
				// Add it in the scene
				const float4 scene = tex2D(_MainTex, i.uv);

				return float4(scene.rgb + color.bbb, 1.0);
			}
			ENDCG
		}
	}
}
