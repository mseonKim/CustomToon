// TODO: Rim Light, Reflection, Brush Texture, Hi Color(Specular), Clipping, ForwardAdd(Point Light), Support Transparent?
// 알아볼 것: Tag의 Light Mode
Shader "CustomToon/Toon" {
    Properties {
        _MainTex ("BaseMap", 2D) = "white" {}
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
        _BaseColor_Step ("BaseColor_Step", Range(0, 1)) = 0.5
        [Enum(OFF,0,FRONT,1,BACK,2)] _CullMode("Cull Mode", int) = 2  //OFF/FRONT/BACK
        _1st_ShadeMap ("1st_ShadeMap", 2D) = "white" {}
        _1st_ShadeColor ("1st_ShadeColor", Color) = (1,1,1,1)
        [Toggle(_)] _Is_NormalMapToBase ("Is_NormalMapToBase", Float ) = 0
        _NormalMap ("NormalMap", 2D) = "bump" {}

        // Linear Step
        _LinearStepMin ("LinearStep_Min", Range(0, 1)) = 0.48
        _LinearStepMax ("LinearStep_Max", Range(0, 1)) = 0.52

        // Outline
        _Outline_Width ("Outline_Width", Float ) = 0
        _Outline_Color ("Outline_Color", Color) = (0,0,0,1)
        _Offset_Z ("Offset_Camera_Z", Float) = 0
        _Farthest_Distance ("Farthest_Distance", Float) = 10
        _Nearest_Distance ("Nearest_Distance", Float) = 0.5
        _Outline_Sampler ("Outline_Sampler", 2D) = "white" {}

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