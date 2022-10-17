// TODO: GI, Clipping, Support Transparent?
Shader "CustomToon/Toon" {
    Properties {
        [Enum(OFF,0,FRONT,1,BACK,2)] _CullMode("Cull Mode", int) = 2  //OFF/FRONT/BACK
        _MainTex ("BaseMap", 2D) = "white" {}
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
        _BaseColor_Step ("BaseColor_Step", Range(0, 1)) = 0.5
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _BumpScale ("Normal_Scale", Range(0, 1)) = 0
        _ShadeColor ("ShadeColor", Color) = (1,1,1,1)

        // Linear Step
        _LinearStepMin ("LinearStep_Min", Range(0, 1)) = 0.48
        _LinearStepMax ("LinearStep_Max", Range(0, 1)) = 0.52

        // Rim Light
        _RimLightColor ("RimLightColor", Color) = (1,1,1,1)
        _Rim_Strength ("Rim_Strength", Float) = 4

        // MatCap
        _MatCap_Sampler ("MatCap_Sampler", 2D) = "black" {}
        _BlurLevelMatcap ("Blur Level of MatCap_Sampler", Range(0, 10)) = 0
        _MatCapColor ("MatCapColor", Color) = (1,1,1,1)

        // Outline
        _Outline_Width ("Outline_Width", Float ) = 0
        _Outline_Color ("Outline_Color", Color) = (0,0,0,1)
        _Offset_Z ("Offset_Camera_Z", Float) = 0
        _Farthest_Distance ("Farthest_Distance", Float) = 10
        _Nearest_Distance ("Nearest_Distance", Float) = 0.5
        _Outline_Sampler ("Outline_Sampler", 2D) = "white" {}

        // VRChat
        [Toggle(_)] _VRChat ("VRChat", Float) = 0
        _DefaultLightColor ("DefaultLightColor", Color) = (0.8,0.8,0.8,1)
        _DefaultLightDir ("Default_Light_Direction", Vector) = (0,0,0,0)
        [Toggle(_)] _FixLightColor ("_FixLightColor", Float) = 0

    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        Pass {
            Name "Outline"
            Tags {
                "LightMode"="ForwardBase"
            }
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            #include "CustomToonOutline.cginc"
            ENDCG
        }
        Pass {
            Name "Forward"
            Tags {
                "LightMode"="ForwardBase"
            }
            Cull[_CullMode]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            // Shadow
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile_fog
            #pragma multi_compile _IS_PASS_FWDBASE

            #include "CustomToonPass.cginc"
            ENDCG
        }
        Pass {
            Name "Forward_Delta"
            Tags {
                "LightMode"="ForwardAdd"
            }
            Blend One One
            Cull[_CullMode]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            // Shadow
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile_fog
            #pragma multi_compile _IS_PASS_FWDDELTA

            #include "CustomToonPass.cginc"
            ENDCG
        }
        Pass {
            Name "ShadowCaster"
            Tags {
                "LightMode"="ShadowCaster"
            }
            Offset 1, 1
            Cull Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // Shadow
            #pragma multi_compile_shadowcaster
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_fog

            #include "CustomToonShadowCaster.cginc"
            ENDCG
        }
    }
}