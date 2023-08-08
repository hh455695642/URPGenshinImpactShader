Shader "LY/GenshinImpact_Toon_Hair"
{
    Properties
    {

        _BaseMap ("Base Map", 2D) = "white" { }
        _LightMap ("Light Map", 2D) = "white" { }
        

        _BrightColor ("Bright Color", Color) = (1, 1, 1, 1)
        _DarkColor ("Dark Color", Color) = (0, 0, 0, 1)
        _DarkColor_1 ("Dark Color_1", Color) = (0, 0, 0, 1)
        _LightSmooth ("Light Smooth", Range(0.01, 0.2)) = 0.03
        _DarkOffset ("Dark Offset", Range(0, 0.2)) = 0.15



        _AnisoHairFresnelPow("Aniso Hair Fresnel Pow",float) =1
        _AnisoHairFresnelIntensity("Aniso Hair Fresnel Intensity",float) =1.5
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
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);                SAMPLER(sampler_BaseMap);
            TEXTURE2D(_LightMap);               SAMPLER(sampler_LightMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BrightColor, _DarkColor, _DarkColor_1;
                float4 _BaseMap_ST,_LightMap_ST, _FaceShadowRampMap_ST;
                float _AnisoHairFresnelPow, _AnisoHairFresnelIntensity, _LightSmooth, _DarkOffset;
            CBUFFER_END

            Varyigs vert(Attributes v)
            {
                Varyigs o;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = vertexInput.positionCS;

                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);

                o.normalWS = TransformObjectToWorldNormal(v.normal);
                o.viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
                return o;
            }

            half4 ToonDiffuse(float NdotLRaw, half4 brightColor, half4 darkColor1, half4 darkColor2, half lightSmooth, half darkOffset, half lightMap, half4 baseMap)
            {
                half4 c;
                half LambertAO = (NdotLRaw + darkOffset) * saturate(lightMap);
                half Smooth = smoothstep(0, lightSmooth, LambertAO);
                half4 Shadow = lerp(darkColor2, darkColor1, Smooth);
                half Smooth1 = smoothstep(0, lightSmooth, NdotLRaw);
                c = lerp(Shadow, brightColor, Smooth1) * baseMap;
                return c;
            }


            half4 frag(Varyigs i) : SV_Target
            {
                //主光源
                Light mainLight = GetMainLight();
                float4 mainLightColor = float4(mainLight.color, 1); //获取主光源颜色
                float3 LightDir = normalize(mainLight.direction); //主光源方向

                //基础色
                half4 BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);

                //通道图
                //R:高光类型分层;白色是金属，灰色是非金属，黑色无高光
                //G:区分AO区域，AO就是常暗区域，有光照也是暗
                //B:高光的强度分层，材料的roughness，越暗越粗糙，黑色非高光
                //A:材质分层，如皮肤，衣服的不同布料类型等
                float4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.uv);

                float NdotLRaw = dot(i.normalWS, LightDir);
                float NdotH = dot(i.normalWS, normalize(i.viewDirWS + LightDir));
                float NdotL = max(0, NdotLRaw);



                //**********Material Diffuse**********//           
                half4 Mat1Diffuse = ToonDiffuse(NdotLRaw, _BrightColor, _DarkColor, _DarkColor_1, _LightSmooth, _DarkOffset, lightMap.g, BaseMap );

                float anisoHairFresnel = pow(1-saturate(dot(i.normalWS,i.viewDirWS)) ,_AnisoHairFresnelPow)*_AnisoHairFresnelIntensity; 
                float anisoHair = saturate(1-anisoHairFresnel)*lightMap.b *NdotL;

                //return saturate(1-anisoHairFresnel);
                return Mat1Diffuse + anisoHair;
                





                


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
