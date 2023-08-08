Shader "Fog"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        ZWrite Off Cull Off
        Pass
        {
            Name "FogBlitPass"

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // The Blit.hlsl file provides the vertex shader (Vert), Blit.hlsl�ļ��ṩ������ɫ����Vert��������ṹ�����ԣ�������ṹ��������
            // input structure (Attributes) and output strucutre (Varyings)
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #pragma vertex Vert
            #pragma fragment frag

            TEXTURE2D_X(_CameraOpaqueTexture);      SAMPLER(sampler_CameraOpaqueTexture);
            TEXTURE2D_X(_CameraDepthTexture);       SAMPLER(sampler_CameraDepthTexture);

            float _Intensity;
            float4x4 _InverseView;
            half4 _FogColor;
            float _FogDensity;
            float3 _NoiseSpeed;
            float _NoiseCellSize, _NoiseRoughness, _NoisePersistance, _NoiseScale;

            #define OCTAVES 4 

            float rand3dTo1d(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719))
            {
                //make value smaller to avoid artefacts
                float3 smallValue = cos(value);
                //get scalar value from 3d vector
                float random = dot(smallValue, dotDir);
                //make value more random by making it bigger and then taking the factional part
                random = frac(sin(random) * 143758.5453);
                return random;
            }

            float3 rand3dTo3d(float3 value)
            {
                return float3(
                    rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
                    rand3dTo1d(value, float3(39.346, 11.135, 83.155)),
                    rand3dTo1d(value, float3(73.156, 52.235, 09.151))
                );
            }

            float easeIn(float interpolator)
            {
                return interpolator * interpolator;
            }

            float easeOut(float interpolator)
            {
                return 1 - easeIn(1 - interpolator);
            }

            float easeInOut(float interpolator)
            {
                float easeInValue = easeIn(interpolator);
                float easeOutValue = easeOut(interpolator);
                return lerp(easeInValue, easeOutValue, interpolator);
            }

            float perlinNoise(float3 value)
            {
                float3 fraction = frac(value);

                float interpolatorX = easeInOut(fraction.x);
                float interpolatorY = easeInOut(fraction.y);
                float interpolatorZ = easeInOut(fraction.z);

                float cellNoiseZ[2];
                [unroll]
                for (int z = 0; z <= 1; z++)
                {
                    float cellNoiseY[2];
                    [unroll]
                    for (int y = 0; y <= 1; y++)
                    {
                        float cellNoiseX[2];
                        [unroll]
                        for (int x = 0; x <= 1; x++)
                        {
                            float3 cell = floor(value) + float3(x, y, z);
                            float3 cellDirection = rand3dTo3d(cell) * 2 - 1;
                            float3 compareVector = fraction - float3(x, y, z);
                            cellNoiseX[x] = dot(cellDirection, compareVector);
                        }
                        cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
                    }
                    cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
                }
                float noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
                return noise;
            }

            float sampleLayeredNoise(float3 value)
            {
                float noise = 0;
                float frequency = 1;
                float factor = 1;

                [unroll]
                for (int i = 0; i < OCTAVES; i++)
                {
                    noise = noise + perlinNoise(value * frequency + i * 0.72354) * factor;
                    factor *= _NoisePersistance;
                    frequency *= _NoiseRoughness;
                }

                return noise;
            }



            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float4 color = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, input.texcoord);
                float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, input.texcoord).r;
                depth = Linear01Depth(depth, _ZBufferParams);

                //从深度重建世界空间位置
                float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
                float3 viewPos = float3((input.texcoord * 2 - 1) / p11_22, -1) * depth * _ProjectionParams.z;
                float4 wposVP = mul(_InverseView, float4(viewPos, 1)); //_ViewToWorld
                
                
                float noise = sampleLayeredNoise((wposVP.xyz + _NoiseSpeed * _Time.y) * _NoiseCellSize);

                if (depth < 1)
                {
                    depth += depth * noise * _NoiseScale;
                }
                
                //float dis = distance(_WorldSpaceCameraPos,wposVP.xyz)/_ProjectionParams.z;
                float fog = saturate(depth * pow(2, _FogDensity));


                return lerp(color, _FogColor, fog);
                return color * float4(0, _Intensity, 0, 1);
            }
            ENDHLSL
        }
    }
}