#define TriangleRootSignature ""\
  "RootFlags(CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED | SAMPLER_HEAP_DIRECTLY_INDEXED)," \

struct Vertex {
  uint id: SV_VertexID;
};

struct Interpolator {
  float4 position: SV_Position;
  float2 uv: Texcoord;
};

struct ColorCb {
  float4 color;
};

[RootSignature(TriangleRootSignature)]
Interpolator vs(Vertex v) {

  Interpolator i;
  i.position = float4(-1.0, -1.0, 0.0, 1.0);
  i.position.x = v.id == 1 ? 3.0 : i.position.x;
  i.position.y = v.id == 2 ? 3.0 : i.position.y;
  i.uv = float2(0.0, 1.0);
  i.uv.x = v.id == 1 ? 2.0 : i.uv.x;
  i.uv.y = v.id == 2 ? -1.0 : i.uv.y;

  return i;
}

[RootSignature(TriangleRootSignature)]
float4 ps(Interpolator i) : SV_Target {
  Texture2D<float4> texture = ResourceDescriptorHeap[33];
  SamplerState default_sampler = SamplerDescriptorHeap[0];
  float4 t_color = texture.Sample(default_sampler, i.uv);
  return float4(t_color.rgb * float3(1.0, 1.0, 1.0), 1.0);
}
