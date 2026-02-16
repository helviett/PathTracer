#define TriangleRootSignature ""\
  "RootFlags(CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED | SAMPLER_HEAP_DIRECTLY_INDEXED),"\
  "CBV(b0),"\
  "SRV(t0)"

struct Vertex {
  uint id: SV_VertexID;
};

struct PixelData {
  float4 position: SV_Position;
  float3 color: Color;
};

struct RootConstants {
  float3 color;
};

ConstantBuffer<RootConstants> rc: register(b0);
ByteAddressBuffer colors: register(t0);

[RootSignature(TriangleRootSignature)]
PixelData vs(Vertex v) {
  float4 positions[3] = {
    float4(-1.0, -1.0, 0.0, 1.0),
    float4( 1.0, -1.0, 0.0, 1.0),
    float4( 0.0,  1.0, 0.0, 1.0),
  };

  PixelData pixel;
  pixel.position = positions[v.id];
  pixel.color = colors.Load<float3>(0);

  return pixel;
}

[RootSignature(TriangleRootSignature)]
float4 ps(PixelData v) : SV_Target {
  return float4(v.color, 1.0);
}
