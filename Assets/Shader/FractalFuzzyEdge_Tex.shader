// This shader creates a stylized glow effect with a fractal fuzzy edge and a texture option.
Shader "Custom/URP/FractalFuzzyEdge_Tex"
{
    Properties
    {
        [Header(Base Material)]
        [MainColor] _BaseColor ("Base Color", Color) = (1, 0.9, 0.3, 1)
        
        [Header(Face Texture Overlay)]
        [Toggle(_USE_FACE_TEXTURE)] _UseFaceTexture ("Enable Face Texture", Float) = 0
        _FaceTexture ("Face Texture (Eyes/Mouth)", 2D) = "white" {}
        
        [Header(Emission)]
        [HDR] _EmissionColor ("Emission Color", Color) = (1, 0.95, 0.5, 1)
        _EmissionStrength ("Emission Strength", Range(0, 10)) = 3
        
        [Header(Fuzzy Edge Settings)]
        _EdgeDarkness ("Edge Darkness", Range(0, 1)) = 0.5
        _EdgePower ("Edge Softness", Range(0.1, 10)) = 3
        _EdgeWidth ("Edge Width", Range(0, 5)) = 1
        
        [Header(Fractal Noise Settings)]
        _NoiseScale ("Noise Scale", Range(0.1, 20)) = 5
        _NoiseSpeed ("Noise Speed", Range(0, 5)) = 1
        _NoiseStrength ("Noise Strength (Fuzziness)", Range(0, 1)) = 0.4
        _FractalLayers ("Fractal Layers", Range(1, 5)) = 3
        
        [Header(Animation)]
        _PulseSpeed ("Pulse Speed", Range(0, 5)) = 0.8
        _PulseAmount ("Pulse Amount", Range(0, 1)) = 0.15
        
        [Header(Material Properties)]
        _Smoothness ("Smoothness", Range(0, 1)) = 0.6
        _Metallic ("Metallic", Range(0, 1)) = 0
        
        [Header(Rendering)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", Float) = 2
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }
        
        LOD 200
        Cull [_Cull]
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // Shader feature for face texture toggle
            #pragma shader_feature_local _USE_FACE_TEXTURE
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 viewDirWS : TEXCOORD3;
            };

            // Textures and Samplers
            #ifdef _USE_FACE_TEXTURE
                TEXTURE2D(_FaceTexture);
                SAMPLER(sampler_FaceTexture);
            #endif
            
            // Properties
            CBUFFER_START(UnityPerMaterial)
                float4 _FaceTexture_ST;
                half4 _BaseColor;
                half4 _EmissionColor;
                half _EmissionStrength;
                half _EdgeDarkness;
                half _EdgePower;
                half _EdgeWidth;
                half _NoiseScale;
                half _NoiseSpeed;
                half _NoiseStrength;
                int _FractalLayers;
                half _PulseSpeed;
                half _PulseAmount;
                half _Smoothness;
                half _Metallic;
            CBUFFER_END

            // ===== NOISE FUNCTIONS =====
            float hash(float2 p)
            {
                float3 p3 = frac(float3(p.xyx) * 0.13);
                p3 += dot(p3, p3.yzx + 3.333);
                return frac((p3.x + p3.y) * p3.z);
            }

            float noise(float2 x)
            {
                float2 i = floor(x);
                float2 f = frac(x);

                float a = hash(i);
                float b = hash(i + float2(1.0, 0.0));
                float c = hash(i + float2(0.0, 1.0));
                float d = hash(i + float2(1.0, 1.0));

                float2 u = f * f * (3.0 - 2.0 * f);

                return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
            }

            float fbm(float2 x, int octaves)
            {
                float value = 0.0;
                float amplitude = 0.5;
                float frequency = 1.0;
                
                for(int i = 0; i < octaves; i++)
                {
                    value += amplitude * noise(x * frequency);
                    frequency *= 2.0;
                    amplitude *= 0.5;
                }
                
                return value;
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionHCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
                output.normalWS = normalInput.normalWS;
                
                output.viewDirWS = GetWorldSpaceNormalizeViewDir(output.positionWS);
                output.uv = input.uv;
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // ===== BASE COLOR =====
                half4 baseColor = _BaseColor;
                
                // ===== FUZZY EDGE CALCULATION =====
                float3 normalWS = normalize(input.normalWS);
                float3 viewDir = normalize(input.viewDirWS);
                
                // Fresnel effect - inverted for edge darkening
                float fresnel = 1.0 - saturate(dot(normalWS, viewDir));
                fresnel = pow(fresnel, _EdgePower);
                
                // Generate fractal noise for fuzziness
                float2 noiseUV = input.positionWS.xy * _NoiseScale;
                float time = _Time.y * _NoiseSpeed;
                noiseUV += float2(time * 0.3, time * 0.2);
                float fractalNoise = fbm(noiseUV, _FractalLayers);
                
                // Second noise layer (opposite direction for complexity)
                float2 noiseUV2 = input.positionWS.xz * _NoiseScale * 0.7;
                noiseUV2 += float2(-time * 0.2, time * 0.25);
                float fractalNoise2 = fbm(noiseUV2, _FractalLayers);
                
                // Combine noise layers
                float combinedNoise = (fractalNoise + fractalNoise2) * 0.5;
                
                // Create fuzzy edge mask
                // Noise makes the edge irregular/fuzzy instead of smooth
                float fuzzyEdge = fresnel * (1.0 + combinedNoise * _NoiseStrength);
                fuzzyEdge = saturate(fuzzyEdge * _EdgeWidth);
                
                // Add pulsing animation
                float pulse = sin(_Time.y * _PulseSpeed) * _PulseAmount + 1.0;
                fuzzyEdge *= pulse;
                
                // Apply edge darkening
                // Edges become darker, creating soft fuzzy appearance
                half3 darkenedColor = baseColor.rgb * (1.0 - fuzzyEdge * _EdgeDarkness);
                
                // ===== EMISSION =====
                // Center glows, edges are darker
                half3 emission = _EmissionColor.rgb * _EmissionStrength;
                // Reduce emission at edges for softer look
                emission *= (1.0 - fuzzyEdge * 0.5);
                
                // ===== LIGHTING SETUP =====
                InputData inputData = (InputData)0;
                inputData.positionWS = input.positionWS;
                inputData.normalWS = normalWS;
                inputData.viewDirectionWS = viewDir;
                inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = darkenedColor;
                surfaceData.alpha = 1.0;
                surfaceData.emission = emission;
                surfaceData.metallic = _Metallic;
                surfaceData.smoothness = _Smoothness;
                surfaceData.normalTS = half3(0, 0, 1);
                surfaceData.occlusion = 1;
                
                // Calculate final lit color with PBR
                half4 color = UniversalFragmentPBR(inputData, surfaceData);
                
                // ===== FACE TEXTURE OVERLAY (on top of all effects) =====
                #ifdef _USE_FACE_TEXTURE
                    float2 faceUV = TRANSFORM_TEX(input.uv, _FaceTexture);
                    half4 faceTexture = SAMPLE_TEXTURE2D(_FaceTexture, sampler_FaceTexture, faceUV);
                    
                    // Composite face texture over the fully lit/effected result
                    color.rgb = lerp(color.rgb, faceTexture.rgb, faceTexture.a);
                #endif
                
                return color;
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull [_Cull]
            
            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            
            ZWrite On
            ColorMask 0
            Cull [_Cull]
            
            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
    
    FallBack "Universal Render Pipeline/Lit"
}
