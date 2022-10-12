struct VertexInput {
    float4 vertex : POSITION;
};
struct VertexOutput {
    V2F_SHADOW_CASTER;
};

VertexOutput vert (VertexInput v) {
    VertexOutput o = (VertexOutput)0;
    o.pos = UnityObjectToClipPos(v.vertex);
    TRANSFER_SHADOW_CASTER(o)
    return o;
}
float4 frag(VertexOutput i) : SV_TARGET {
    SHADOW_CASTER_FRAGMENT(i)
}