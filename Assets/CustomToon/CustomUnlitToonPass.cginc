uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
uniform float4 _BaseColor;
uniform float _BaseColor_Step;
uniform sampler2D _NormalMap; uniform float4 _NormalMap_ST;
uniform float _BumpScale;
uniform float4 _ShadeColor;
uniform float _LinearStepMin;
uniform float _LinearStepMax;
uniform float4 _RimLightColor;
uniform float _Rim_Strength;
uniform sampler2D _MatCap_Sampler; uniform float4 _MatCap_Sampler_ST;
uniform float _BlurLevelMatcap;
uniform float4 _MatCapColor;
uniform float _VRChat;
uniform float4 _DefaultLightDir;

struct VertexInput {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 texcoord0 : TEXCOORD0;
};

struct VertexOutput {
    float4 pos : SV_POSITION;
    float2 uv0 : TEXCOORD0;
    float4 posWorld : TEXCOORD1;
    float3 normalDir : TEXCOORD2;
};

half LinearStep(half minValue, half maxValue, half In) {
    return saturate((In-minValue) / (maxValue-minValue));
}

VertexOutput vert(VertexInput v) {
    VertexOutput o = (VertexOutput)0;
    // UNITY_TRANSFER_INSTANCE_ID(v, o);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv0 = TRANSFORM_TEX(v.texcoord0, _MainTex);
    o.normalDir = UnityObjectToWorldDir(v.normal);
    o.posWorld = mul(unity_ObjectToWorld, v.vertex);
    return o;
}

float4 frag(VertexOutput i) : SV_TARGET {
    float4 color = 0;

    i.normalDir = normalize(i.normalDir);
    float3 _NormalMap_var = tex2D(_NormalMap, i.uv0);
    float3 normal = lerp(i.normalDir, _NormalMap_var, _BumpScale);

    half hasDirectionalLight = LinearStep(0, 0.01, length(_WorldSpaceLightPos0));
    float3 lightDir = lerp(_DefaultLightDir, _WorldSpaceLightPos0.xyz, hasDirectionalLight);

    // Half Lambert
    half halfLambert = dot(lightDir, normal) * 0.5 + 0.5;
    half medTone = LinearStep(_LinearStepMin, _LinearStepMax, halfLambert);
    color = lerp(_ShadeColor, _BaseColor, medTone);

    // Rim Light
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.posWorld).xyz;
    half emission = LinearStep(0.25, 0.75, pow(1 - saturate(dot(viewDir, normal)), _Rim_Strength));
    half4 rimColor = half4((_RimLightColor * emission).rgb, 1);
    color += rimColor;

    color *= tex2D(_MainTex, i.uv0);

    // Apply Matcap
    float3 viewNormal = normalize(mul(UNITY_MATRIX_V, normal));
    float2 matcapUV = viewNormal.xy * 0.5 + 0.5;
    float3 _MatCap_Sampler_var = tex2Dlod(_MatCap_Sampler, float4(TRANSFORM_TEX(matcapUV, _MatCap_Sampler), 0.0, _BlurLevelMatcap));
    color.rgb += _MatCap_Sampler_var * _MatCapColor;

    return color;
}