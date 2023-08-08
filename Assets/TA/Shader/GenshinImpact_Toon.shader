Shader "LY/GenshinImpact_Toon"
{
    Properties
    {
        //_BrightColor1 ("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap ("Base Map", 2D) = "white" { }

        _LightMap ("Light Map R:Mate G:AO B:", 2D) = "white" { }
        //_MetalMap ("Metal Map", 2D) = "white" { }
        // _FaceShadowMap ("FaceShadowMap", 2D) = "white"{}
        // _ShadowRampMap ("Shadow Ramp Map", 2D) = "white"{}


        [Header(Material 1)]
        [Space(10)]
        _BrightColor1 ("Bright Color1", Color) = (1, 1, 1, 1)
        _DarkColor1 ("Dark Color1", Color) = (0, 0, 0, 1)
        _DarkColor1_1 ("Dark Color1_1", Color) = (0, 0, 0, 1)
        _LightSmooth1 ("Light Smooth1", Range(0.01, 0.2)) = 0.03
        _DarkOffset1 ("Dark Offset1", Range(0, 0.2)) = 0.15
        _ColorRange1 ("Color1 Range", Range(0.0, 1)) = 0.9
        [HDR]_SpecularColor1 ("Specular Color1", Color) = (0, 0, 0, 0)
        _Shininess1 ("Shininess1", Range(0, 1)) = 1


        [Header(Material 2)]
        [Space(10)]
        _BrightColor2 ("Bright Color2", Color) = (1, 1, 1, 1)
        _DarkColor2 ("Dark Color2", Color) = (0, 0, 0, 1)
        _DarkColor2_1 ("Dark Color2_1", Color) = (0, 0, 0, 1)
        _LightSmooth2 ("Light Smooth2", Range(0.01, 0.5)) = 0.1
        _DarkOffset2 ("Dark Offset2", Range(0, 0.2)) = 0.1
        _ColorRange2 ("Color2 Range", Range(0.0, 1)) = 0.8
        //[HDR]_SpecularColor2 ("Specular Color2", Color) = (0, 0, 0, 0)
        //_Shininess2 ("Shininess2", Range(0, 1)) = 1

        [Header(Material 3)]
        [Space(10)]
        _BrightColor3 ("Bright Color3", Color) = (1, 1, 1, 1)
        _DarkColor3 ("Dark Color3", Color) = (0, 0, 0, 1)
        _DarkColor3_1 ("Dark Color3_1", Color) = (0, 0, 0, 1)
        _LightSmooth3 ("Light Smooth3", Range(0.01, 0.5)) = 0.1
        _DarkOffset3 ("Dark Offset3", Range(0, 0.5)) = 0.1
        _ColorRange3 ("Color3 Range", Range(0.0, 1)) = 0.7
        //[HDR]_SpecularColor3 ("Specular Color", Color) = (1, 1, 1, 1)
        //_Shininess3 ("Shininess3", Range(0, 1)) = 1
        

    }

        SubShader
    {

        Tags { "RenderType" = "Opaque" "RenderPipelie" = "UniversalPipelie" }
        Cull Off

        Pass
        {
            
            Tags{"LightMode" = "UniversalForward"}

            Name "Unlit"

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
            TEXTURE2D(_MetalMap);               SAMPLER(sampler_MetalMap);
            TEXTURE2D(_ShadowRampMap);          SAMPLER(sampler_ShadowRampMap);

            CBUFFER_START(UnityPerMaterial)
                half _LightSmooth1, _ColorRange1, _LightSmooth2, _ColorRange2, _LightSmooth3, _ColorRange3, _DarkOffset1, _DarkOffset2, _DarkOffset3;               
                half4 _BrightColor1, _DarkColor1, _DarkColor1_1, _BrightColor2, _DarkColor2,_DarkColor2_1, _BrightColor3, _DarkColor3,_DarkColor3_1;
                half _Shininess1,_Shininess2,_Shininess3;
                half4 _SpecularColor1,_SpecularColor2,_SpecularColor3;
                float4 _BaseMap_ST, _LightMap_ST, _MetalMap_ST, _ShadowRampMap_ST;
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

            half4 ToonDiffuse(float NdotLRaw, half4 brightColor, half4 darkColor1, half4 darkColor2, half lightSmooth, half darkOffset, half lightMap, half4 baseMap, half mask)
            {
                half4 c;
                half LambertAO = (NdotLRaw + darkOffset) * saturate(lightMap);
                half Smooth = smoothstep(0, lightSmooth, LambertAO);
                half4 Shadow = lerp(darkColor2, darkColor1, Smooth);
                half Smooth1 = smoothstep(0, lightSmooth, NdotLRaw);
                c = lerp(Shadow, brightColor, Smooth1) * baseMap * mask;
                return c;
            }
            half4 ToonSpecular (float NdotH, half4 specularColor, half shininess ,half lightSmooth,half4 baseMap, half mask)
            {
                float SpecularPow = smoothstep(0, lightSmooth, pow(NdotH, shininess * 128));
                half4 Specular = saturate(SpecularPow) * baseMap *specularColor * mask ;
                return Specular;
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
                float NdotV = max(0, dot(i.normalWS, i.viewDirWS));

                float MatellicUV = dot(i.normalWS,normalize(i.viewDirWS+LightDir));

                half4 MatellicColor =  SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, MatellicUV) *BaseMap*_Shininess3;
                //return MatellicColor; 


                half LightMapAMask1 = step(_ColorRange1, lightMap.a);
                half LightMapAMask2 = step(_ColorRange2, lightMap.a) - LightMapAMask1;
                half LightMapAMask3 = step(_ColorRange3, lightMap.a) - LightMapAMask2 - LightMapAMask1;
                //return LightMapAMask3;

                //**********Material Specular**********//
                half4 Mat1Specular = ToonSpecular(NdotH, _SpecularColor1, _Shininess1, _LightSmooth1, BaseMap, lightMap.r);
                half4 Mat2Specular = ToonSpecular(NdotH, _SpecularColor1, _Shininess1, _LightSmooth2, BaseMap, lightMap.r);
                half4 Mat3Specular = ToonSpecular(NdotH, _SpecularColor1, _Shininess1, _LightSmooth3, BaseMap, lightMap.r);

                
                

                


                //**********Material Diffuse**********//           
                half4 Mat1Diffuse = ToonDiffuse(NdotLRaw, _BrightColor1, _DarkColor1, _DarkColor1_1, _LightSmooth1, _DarkOffset1, lightMap.g, BaseMap, LightMapAMask1);
                half4 Mat2Diffuse = ToonDiffuse(NdotLRaw, _BrightColor2, _DarkColor2, _DarkColor2_1, _LightSmooth2, _DarkOffset2, lightMap.g, BaseMap, LightMapAMask2);
                half4 Mat3Diffuse = ToonDiffuse(MatellicUV, _BrightColor3, _DarkColor3, _DarkColor3_1, _LightSmooth3, _DarkOffset3, lightMap.g, BaseMap, LightMapAMask3);
                
                
                half4 Mat1Color = Mat1Diffuse +Mat1Specular;
                half4 Mat2Color = Mat2Diffuse +Mat2Specular;
                half4 Mat3Color = Mat3Diffuse +Mat3Specular;

                return (Mat1Color + Mat2Color + Mat3Color) ;


                

                

                
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
