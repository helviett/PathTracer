#define TriangleRootSignature ""\
  "RootFlags(CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED | SAMPLER_HEAP_DIRECTLY_INDEXED)," \

struct Vertex {
  uint id: SV_VertexID;
};

struct PixelData {
  float4 position: SV_Position;
  float3 color: Color;
};

struct ColorCb {
  float4 color;
};

[RootSignature(TriangleRootSignature)]
PixelData vs(Vertex v) {
  float4 positions[3] = {
    float4(-1.0, -1.0, 0.0, 1.0),
    float4( 1.0, -1.0, 0.0, 1.0),
    float4( 0.0,  1.0, 0.0, 1.0),
  };

  ByteAddressBuffer bab = ResourceDescriptorHeap[0];

  PixelData pixel;
  pixel.position = positions[v.id];
  pixel.color = bab.Load<float3>(0);

  return pixel;
}

[RootSignature(TriangleRootSignature)]
float4 ps(PixelData v) : SV_Target {
  Texture2D<float4> texture = ResourceDescriptorHeap[1];
  SamplerState default_sampler = SamplerDescriptorHeap[0];
  uint w, h;
  texture.GetDimensions(w, h);
  float2 uv = v.position.xy / float2(w, h);
  float4 t_color = texture.Sample(default_sampler, uv * 2);
  return float4(t_color.rgb * v.color, 1.0);
}
