// This shader creates a volumetric light shaft (god ray) effect with customisable parameters  
// It uses a procedural noise function to create an animated dust-like appearance 
Shader "Custom/LightShaft"
{
    Properties
    {
        _ShaftColor ("Shaft Color", Color) = (1, 0.83, 0.63, 0.3)
        _Intensity ("Intensity", Range(0, 3)) = 1.0
        _NoiseScale ("Noise Scale", Range(0.1, 20)) = 4.0
        _NoiseSpeed ("Noise Scroll Speed", Range(0, 1)) = 0.05
        _NoiseStrength ("Noise Strength", Range(0, 1)) = 0.4
        _EdgeSoftness ("Edge Softness", Range(0.01, 1)) = 0.4
        _DepthFadeDistance ("Depth Fade Distance", Range(0.1, 10)) = 2.0
        _FresnelPower ("Fresnel Fade Power", Range(0.1, 5)) = 2.0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "LightShaft"
            Tags { "LightMode" = "UniversalForward" }

            Blend One One          // Additive blending - light adds to scene
            ZWrite Off             // Don't write to depth buffer
            Cull Off               // Render both sides of the quad

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 positionWS  : TEXCOORD1;
                float3 normalWS    : TEXCOORD2;
                float3 viewDirWS   : TEXCOORD3;
                float4 screenPos   : TEXCOORD4;
            };

            CBUFFER_START(UnityPerMaterial)
                half4  _ShaftColor;
                half   _Intensity;
                half   _NoiseScale;
                half   _NoiseSpeed;
                half   _NoiseStrength;
                half   _EdgeSoftness;
                half   _DepthFadeDistance;
                half   _FresnelPower;
            CBUFFER_END

            // -------------------------------------------------------
            // Simple 2D hash and value noise
            // Based on standard GPU noise techniques from
            // "The Book of Shaders" (Gonzalez Vivo & Lowe)
            // -------------------------------------------------------
            float hash(float2 p)
            {
                float3 p3 = frac(float3(p.xyx) * 0.1031);
                p3 += dot(p3, p3.yzx + 33.33);
                return frac((p3.x + p3.y) * p3.z);
            }

            float valueNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);

                // Smooth interpolation curve
                float2 u = f * f * (3.0 - 2.0 * f);

                // Four corners
                float a = hash(i);
                float b = hash(i + float2(1.0, 0.0));
                float c = hash(i + float2(0.0, 1.0));
                float d = hash(i + float2(1.0, 1.0));

                return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
            }

            // Fractal Brownian Motion - layered noise for organic look
            float fbm(float2 p)
            {
                float value = 0.0;
                float amplitude = 0.5;
                float frequency = 1.0;

                // 3 octaves - enough detail without GPU cost
                for (int i = 0; i < 3; i++)
                {
                    value += amplitude * valueNoise(p * frequency);
                    frequency *= 2.0;
                    amplitude *= 0.5;
                }
                return value;
            }

            // -------------------------------------------------------
            // Vertex shader
            // -------------------------------------------------------
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs posInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                VertexNormalInputs normInputs = GetVertexNormalInputs(IN.normalOS);

                OUT.positionHCS = posInputs.positionCS;
                OUT.positionWS  = posInputs.positionWS;
                OUT.normalWS    = normInputs.normalWS;
                OUT.viewDirWS   = GetWorldSpaceNormalizeViewDir(posInputs.positionWS);
                OUT.screenPos   = ComputeScreenPos(posInputs.positionCS);
                OUT.uv          = IN.uv;

                return OUT;
            }

            // -------------------------------------------------------
            // Fragment shader
            // -------------------------------------------------------
            half4 frag(Varyings IN) : SV_Target
            {
                // --- 1. UV-based edge softness ---
                // Fade out towards the edges of the quad so the
                // light shaft doesn't have hard rectangular borders.
                float2 centeredUV = IN.uv - 0.5;           // Remap 0..1 to -0.5..0.5
                float edgeMask = 1.0 - saturate(length(centeredUV * 2.0));
                edgeMask = smoothstep(0.0, _EdgeSoftness, edgeMask);

                // Also fade along V axis (length of the shaft)
                // so it fades out towards the far end
                float lengthFade = smoothstep(0.0, 0.3, IN.uv.y)
                                 * smoothstep(1.0, 0.7, IN.uv.y);

                // --- 2. Fresnel fade ---
                // Fade based on view angle so the shaft looks
                // more transparent when viewed head-on and more
                // visible at grazing angles. This adds depth.
                float3 normalWS = normalize(IN.normalWS);
                float3 viewDirWS = normalize(IN.viewDirWS);
                float NdotV = abs(dot(normalWS, viewDirWS));
                float fresnel = pow(1.0 - NdotV, _FresnelPower);
                // Blend: mostly visible at glancing angles,
                // but never fully invisible head-on
                float fresnelMask = lerp(0.3, 1.0, fresnel);

                // --- 3. Scrolling noise ---
                // Creates the animated dust / atmospheric scatter
                // look within the light shaft.
                float2 noiseUV = IN.uv * _NoiseScale;
                noiseUV.y += _Time.y * _NoiseSpeed;    // Scroll along shaft
                noiseUV.x += _Time.y * _NoiseSpeed * 0.3; // Slight horizontal drift
                float noise = fbm(noiseUV);
                // Remap noise to modulate around 1.0
                float noiseMask = lerp(1.0, noise, _NoiseStrength);

                // --- 4. Depth fade (soft intersection) ---
                // Prevents hard edges where the shaft quad
                // intersects scene geometry (floor, walls, etc.)
                float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
                float sceneDepth = LinearEyeDepth(
                    SampleSceneDepth(screenUV),
                    _ZBufferParams
                );
                float fragDepth = IN.screenPos.w; // Linear depth of this fragment
                float depthDiff = sceneDepth - fragDepth;
                float depthFade = saturate(depthDiff / _DepthFadeDistance);

                // --- 5. Combine all masks ---
                float alpha = edgeMask
                            * lengthFade
                            * fresnelMask
                            * noiseMask
                            * depthFade
                            * _Intensity;

                // Output: additive blend (RGB * alpha, no separate alpha needed)
                half3 color = _ShaftColor.rgb * alpha;
                return half4(color, 0.0); // Alpha irrelevant for additive blend
            }
            ENDHLSL
        }
    }

    FallBack Off
}
