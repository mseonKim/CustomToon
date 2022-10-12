uniform float _Outline_Width;
uniform float4 _Outline_Color;
uniform float _Offset_Z;
uniform float _Farthest_Distance;
uniform float _Nearest_Distance;
uniform sampler2D _Outline_Sampler; uniform float4 _Outline_Sampler_ST;

struct VertexInput {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 texcoord0 : TEXCOORD0;

};
struct VertexOutput {
    float4 pos : SV_POSITION;
};

VertexOutput vert (VertexInput v) {
    VertexOutput o = (VertexOutput)0;
    float4 objPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));

    float4 outlineSamplerVar = tex2Dlod(_Outline_Sampler, float4(v.texcoord0, 0.0, 0));
    float outlineWidth = _Outline_Width * 0.001 * smoothstep(_Farthest_Distance, _Nearest_Distance, distance(objPos, _WorldSpaceCameraPos)) * outlineSamplerVar.r;
    // float outlineWidth = _Outline_Width * 0.001;
    o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal * outlineWidth, 1));
    return o;
}
float4 frag(VertexOutput i) : SV_TARGET {
    return _Outline_Color;
}