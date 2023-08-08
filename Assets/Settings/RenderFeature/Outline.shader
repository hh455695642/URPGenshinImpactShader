Shader "LY/Outline"
{
    Properties
    {
        _OutlineColor ("Outline Color", Color) = (0, 1, 1, 1)
        _OutlineWidth ("Outline Width", Range(0,1)) = 0.1
        _UnifromWidth("Unifrom Width", Range(0,1)) = 1
    }

    SubShader
    {
        
        Tags { "RenderType" = "Opaque" "RenderPipelie" = "UniversalPipelie" }

        Pass
        {
            Tags { "LightMode" ="UniversalForward" }
            
            Name "Outline"
            Cull Front
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyigs
            {
                float4 positionHCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                float _OutlineWidth,_UnifromWidth;
                half4 _OutlineColor;

            CBUFFER_END

            
            Varyigs vert(Attributes v)
            {             
                Varyigs o;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                float3 positionWS = vertexInput.positionWS;
                float3 positionOS = v.positionOS;
                
                //相机与顶点距离
                float distance = length(_WorldSpaceCameraPos - positionWS);
                distance = lerp(1, distance, _UnifromWidth);
                float3 width = normalize(v.normalOS) * _OutlineWidth * 0.01;
                width *= distance;
                positionOS += width;

                o.positionHCS = TransformObjectToHClip(positionOS);

                return o;
            }

            half4 frag(Varyigs i) : SV_Target
            {

                half4 color = _OutlineColor;
                return color;
            }
            ENDHLSL
        }
    }
}