// This shader implements a toon shading effect, with support for outlines, rim lighting, and specular highlights. 
Shader "Custom/ToonBoom"
{
    Properties
    {
        [Header(Base)]
        [Toggle(_USE_BASE_TEXTURE)] _UseBaseTexture ("Enable Base Texture", Float) = 0
        _BaseMap ("Base Texture", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _AmbientColor ("Ambient Color", Color) = (0.3, 0.3, 0.3, 1)
        
        [Header(Toon Shading)]
        _ToonSteps ("Toon Steps", Range(2, 10)) = 3
        _ToonRampSmoothness ("Ramp Smoothness", Range(0.001, 0.1)) = 0.01
        
        [Header(Specular)]
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _SpecularGloss ("Specular Gloss", Range(0, 1)) = 0.5
        _SpecularStrength ("Specular Strength", Range(0, 1)) = 0.5
        
        [Header(Rim Lighting)]
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimAmount ("Rim Amount", Range(0, 1)) = 0.5
        _RimThreshold ("Rim Threshold", Range(0, 1)) = 0.1
        
        [Header(Outline)]
        _OutlineWidth ("Outline Width", Range(0, 0.1)) = 0.005
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        // ===== OUTLINE PASS =====
        Pass
        {
            Name "Outline"
            Tags { "LightMode" = "SRPDefaultUnlit" }
            
            Cull Front
            
            HLSLPROGRAM
            #pragma vertex OutlineVertex
            #pragma fragment OutlineFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                float4 _OutlineColor;
                float _OutlineWidth;
                // Declare all other properties to keep SRP Batcher compatibility
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float4 _AmbientColor;
                float _ToonSteps;
                float _ToonRampSmoothness;
                float4 _SpecularColor;
                float _SpecularGloss;
                float _SpecularStrength;
                float4 _RimColor;
                float _RimAmount;
                float _RimThreshold;
            CBUFFER_END
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };
            
            Varyings OutlineVertex(Attributes input)
            {
                Varyings output;
                float3 positionOS = input.positionOS.xyz + input.normalOS * _OutlineWidth;
                output.positionCS = TransformObjectToHClip(positionOS);
                return output;
            }
            
            half4 OutlineFragment(Varyings input) : SV_Target
            {
                return _OutlineColor;
            }
            ENDHLSL
        }

        // ===== MAIN TOON SHADING PASS =====
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex ToonVertex
            #pragma fragment ToonFragment
            
            // Texture toggle
            #pragma shader_feature_local _USE_BASE_TEXTURE
            
            // URP keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #ifdef _USE_BASE_TEXTURE
                TEXTURE2D(_BaseMap);
                SAMPLER(sampler_BaseMap);
            #endif
            
            CBUFFER_START(UnityPerMaterial)
                float4 _OutlineColor;
                float _OutlineWidth;
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float4 _AmbientColor;
                float _ToonSteps;
                float _ToonRampSmoothness;
                float4 _SpecularColor;
                float _SpecularGloss;
                float _SpecularStrength;
                float4 _RimColor;
                float _RimAmount;
                float _RimThreshold;
            CBUFFER_END
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 viewDirWS : TEXCOORD3;
            };
            
            Varyings ToonVertex(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.normalWS = normalInputs.normalWS;
                output.viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                
                return output;
            }
            
            half4 ToonFragment(Varyings input) : SV_Target
            {
                // ===== BASE COLOR =====
                float4 baseColor = _BaseColor;
                
                #ifdef _USE_BASE_TEXTURE
                    float4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                    baseColor *= texColor;
                #endif
                
                // ===== LIGHTING SETUP =====
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                float3 normalWS = normalize(input.normalWS);
                float3 viewDir = normalize(input.viewDirWS);
                
                // ===== TOON DIFFUSE =====
                float NdotL = saturate(dot(normalWS, lightDir));
                
                // Stepped toon bands
                float toonRamp = smoothstep(0.0, _ToonRampSmoothness, NdotL);
                float stepped = floor(toonRamp * _ToonSteps) / _ToonSteps;
                
                float3 diffuse = baseColor.rgb * stepped * mainLight.color.rgb;
                
                // Ambient contribution
                float3 ambient = baseColor.rgb * _AmbientColor.rgb;
                
                // ===== SPECULAR (Blinn-Phong, toon stepped) =====
                float3 halfVector = normalize(lightDir + viewDir);
                float NdotH = saturate(dot(normalWS, halfVector));
                float specularIntensity = pow(NdotH, _SpecularGloss * 128.0);
                float toonSpecular = smoothstep(0.005, 0.01, specularIntensity);
                float3 specular = _SpecularColor.rgb * toonSpecular * _SpecularStrength;
                
                // ===== RIM LIGHTING =====
                float rimDot = 1 - dot(viewDir, normalWS);
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
                float3 rim = _RimColor.rgb * rimIntensity;
                
                // ===== COMBINE =====
                float3 finalColor = ambient + diffuse + specular + rim;
                
                return float4(finalColor, baseColor.a);
            }
            ENDHLSL
        }
        
        // ===== SHADOW CASTER PASS =====
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex ShadowVertex
            #pragma fragment ShadowFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            float3 _LightDirection;
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };
            
            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                
                return positionCS;
            }
            
            Varyings ShadowVertex(Attributes input)
            {
                Varyings output;
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }
            
            half4 ShadowFragment(Varyings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
