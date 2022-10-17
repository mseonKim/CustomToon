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
uniform float4 _DefaultLightColor;
uniform float4 _DefaultLightDir;
uniform float _FixLightColor;

struct VertexInput {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    // float4 tangent : TANGENT;
    float2 texcoord0 : TEXCOORD0;
};

struct VertexOutput {
    float4 pos : SV_POSITION;
    float2 uv0 : TEXCOORD0;
    float4 posWorld : TEXCOORD1;
    float3 normalDir : TEXCOORD2;
    LIGHTING_COORDS(3,4)
    UNITY_FOG_COORDS(5)
};

half LinearStep(half minValue, half maxValue, half In) {
    return saturate((In-minValue) / (maxValue-minValue));
}

VertexOutput vert(VertexInput v) {
    VertexOutput o = (VertexOutput)0;
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv0 = v.texcoord0;
    o.normalDir = UnityObjectToWorldDir(v.normal);
    o.posWorld = mul(unity_ObjectToWorld, v.vertex);
    UNITY_TRANSFER_FOG(o, o.pos);
    TRANSFER_VERTEX_TO_FRAGMENT(o)
    return o;
}

float4 frag(VertexOutput i) : SV_TARGET {
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);
    float pureAtten = attenuation;
    attenuation = LinearStep(0.49, 0.51, attenuation);

    i.uv0 = TRANSFORM_TEX(i.uv0, _MainTex);
    i.normalDir = normalize(i.normalDir);
    float3 _NormalMap_var = tex2D(_NormalMap, i.uv0);
    float3 normal = lerp(i.normalDir, _NormalMap_var, _BumpScale);

#ifdef _IS_PASS_FWDBASE
    half hasDirectionalLight = LinearStep(0, 0.01, length(_WorldSpaceLightPos0));
    float3 lightDir = lerp(_DefaultLightDir, _WorldSpaceLightPos0.xyz, hasDirectionalLight);
    float3 lightColor = lerp(max(0.1, _LightColor0.rgb), max(_LightColor0.rgb, _DefaultLightColor.rgb), _VRChat);
    lightColor = lerp(lightColor, _DefaultLightColor, _FixLightColor);
#elif _IS_PASS_FWDDELTA
// w == 0 -> Directional lights / w == 1 -> Other lights.
    float3 lightDir = normalize(lerp(_WorldSpaceLightPos0.xyz, (_WorldSpaceLightPos0.xyz - i.posWorld.xyz), _WorldSpaceLightPos0.w));
    // Set intensity as 0 if directional light
    float3 lightColor = _LightColor0.rgb * lerp(0, attenuation, _WorldSpaceLightPos0.w) * 0.1;
#endif

    float3 finalColor = 0;
    // Half Lambert
    half halfLambert = dot(lightDir, normal) * 0.5 + 0.5;
    half medTone = LinearStep(_LinearStepMin, _LinearStepMax, halfLambert);
    float3 baseColor = lerp(_ShadeColor.rgb, _BaseColor.rgb, medTone);
    finalColor = baseColor;

    // Rim Light
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.posWorld).xyz;
    half emission = LinearStep(0.25, 0.75, pow(1 - saturate(dot(viewDir, normal)), _Rim_Strength));
    half3 rimColor = (_RimLightColor * emission).rgb;
    finalColor += lerp(0, rimColor, attenuation);    // Ignore shadowed pixel

    // Texture
    finalColor *= tex2D(_MainTex, i.uv0).rgb;

    // Light
    finalColor *= lightColor;

    // Shadow
    float3 shadowColor = medTone > 0 ? lerp(_ShadeColor.rgb, 1, attenuation) / baseColor : 1;
#ifdef _IS_PASS_FWDBASE
    shadowColor = lerp(1, shadowColor, hasDirectionalLight);
#endif
    finalColor *= shadowColor;
    
    // Matcap
    float3 viewNormal = normalize(mul(UNITY_MATRIX_V, normal));
    float2 matcapUV = viewNormal.xy * 0.5 + 0.5;
    float3 _MatCap_Sampler_var = tex2Dlod(_MatCap_Sampler, float4(TRANSFORM_TEX(matcapUV, _MatCap_Sampler), 0.0, _BlurLevelMatcap));
    finalColor += _MatCap_Sampler_var * _MatCapColor.rgb;

    // Env light
    float3 decodeLightProbe = ShadeSH9(half4(normal, 1)).xyz;
    float3 envLightColor = decodeLightProbe < float3(1,1,1) ? decodeLightProbe : float3(1,1,1);
    float envLightIntensity = 0.299*envLightColor.r + 0.587*envLightColor.g + 0.114*envLightColor.b < 1 ? (0.299*envLightColor.r + 0.587*envLightColor.g + 0.114*envLightColor.b) : 1;
    finalColor = saturate(finalColor) + envLightColor * envLightIntensity * smoothstep(1, 0, envLightIntensity / 2) * 0.1;

    float4 color = 0;
#ifdef _IS_PASS_FWDBASE
    color = float4(finalColor, 1);
#elif _IS_PASS_FWDDELTA
    color = float4(finalColor, 0);
#endif

    UNITY_APPLY_FOG(i.fogCoord, color);
    return color;
}