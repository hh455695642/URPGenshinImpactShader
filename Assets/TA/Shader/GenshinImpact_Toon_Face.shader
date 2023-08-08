Shader "LY/GenshinImpact_Toon_Face"
{
    Properties
    {

        _BaseMap ("Base Map", 2D) = "white" { }
        _FaceShadowMap ("Face Shadow Map", 2D) = "white"{}

        _BrightColor ("Bright Color1", Color) = (1, 1, 1, 1)
        _DarkColor ("Dark Color1", Color) = (0, 0, 0, 1)

        [HideInInspector]_HeadForward("Head Forward",vector)=(0,0,1,0)
        [HideInInspector]_HeadRight("Head Right",vector)=(1,0,0,0)
    }

        SubShader
    {

        Tags { "RenderType" = "Opaque" "RenderPipelie" = "UniversalPipelie" }

        Pass
        {

            Name "ForwardUnlit"
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM

            #pragma vertex vert            
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Varyigs
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);                SAMPLER(sampler_BaseMap);
            TEXTURE2D(_FaceShadowMap);          SAMPLER(sampler_FaceShadowMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BrightColor, _DarkColor;
                float4 _BaseMap_ST, _FaceShadowRampMap_ST;
            CBUFFER_END

            float3 _HeadForward, _HeadRight;

            Varyigs vert(Attributes v)
            {
                Varyigs o;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = vertexInput.positionCS;

                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);

                // o.normalWS = TransformObjectToWorldNormal(v.normal);
                // o.viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
                return o;
            }



            half4 frag(Varyigs i) : SV_Target
            {
                //主光源
                Light mainLight = GetMainLight();
                float4 mainLightColor = float4(mainLight.color, 1); //获取主光源颜色
                float3 LightDir = normalize(mainLight.direction); //主光源方向

                //基础色
                half4 BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);

                half4 faceShadowMap = SAMPLE_TEXTURE2D(_FaceShadowMap, sampler_FaceShadowMap, i.uv);
                half4 inversionFaceShadowMap = SAMPLE_TEXTURE2D(_FaceShadowMap, sampler_FaceShadowMap, float2(1 - i.uv.x, i.uv.y));

                // float3 Front = unity_ObjectToWorld._12_22_32;
                // float3 Right = unity_ObjectToWorld._13_23_33;
                float3 Front = _HeadForward.xyz;
                float3 Right = _HeadRight.xyz;
                // float3 Front = float3(0,0,1);
                // float3 Right = float3(1,0,0);
                float FrontL = dot(normalize(Front.xz), normalize(LightDir.xz));
                float RightL = dot(normalize(Right.xz), normalize(LightDir.xz));
                float Angle = (acos(RightL) / PI) * 2;
                float texShadowDir = (RightL > 0) ? inversionFaceShadowMap : faceShadowMap ;
                float lightAngle = (RightL > 0) ? 1 - Angle : Angle - 1;
                float lightAttenuation = step(lightAngle, texShadowDir) * step(0, FrontL);
                
                half4 c = lerp( _DarkColor * BaseMap, _BrightColor * BaseMap, lightAttenuation);


                return c;
                return half4(_HeadForward.xyz,1);





                


                //**********AO 常暗区域**********//

                

                

                
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormalsOnly"
            Tags{"LightMode" = "DepthNormalsOnly"}

            ZWrite On

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT // forward-only variant
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
}
