#define ForwardRootSignature ""\
  "RootFlags(CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED | SAMPLER_HEAP_DIRECTLY_INDEXED | ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT)," \
  "CBV(b0)," \
  "RootConstants(num32BitConstants = 2, b1)," \
  "SRV(t0)," \
  "SRV(t1)," \
  "SRV(t2)," \
  "StaticSampler(" \
    "s0," \
    "filter = FILTER_ANISOTROPIC," \
    "addressU = TEXTURE_ADDRESS_WRAP," \
    "addressV = TEXTURE_ADDRESS_WRAP," \
    "addressW = TEXTURE_ADDRESS_WRAP," \
    "maxAnisotropy = 8," \
    "visibility = SHADER_VISIBILITY_ALL)"

struct Vertex {
  float3 position: SV_Position;
  float3 normal: Normal;
  //float4 tangent: Tangent;
  float2 uv: Texcoord;
};

struct Interpolator {
  float4 position: SV_Position;
  float3 normal: Normal;
  //float4 tangent: Tangent;
  float2 uv: Texcoord;
};

struct Camera {
  float4x4 proj;
  float4x4 world_to_view;
};

struct Submesh {
  uint material_id;
};

struct Material {
  uint texture_descriptor_offset;
};

struct DrawData {
  uint submesh_id;
  uint transform_index;
};

struct Transform {
  float3x4 object_to_world;
};

ConstantBuffer<Camera> globals: register(b0);
ConstantBuffer<DrawData> draw_data: register(b1);
ByteAddressBuffer submeshes: register(t0);
ByteAddressBuffer materials: register(t1);
ByteAddressBuffer transforms: register(t2);

SamplerState material_sampler: register(s0);

[RootSignature(ForwardRootSignature)]
Interpolator vs(Vertex vertex) {
  Interpolator i;

  float3x4 object_to_world = transforms.Load<Transform>(draw_data.transform_index * sizeof(Transform)).object_to_world;
  float3 position_ws = mul(object_to_world, float4(vertex.position, 1.0));
  float3 position_vs = mul(globals.world_to_view, float4(position_ws, 1.0)).xyz;
  i.position = mul(globals.proj, float4(position_vs, 1.0));
  i.normal = vertex.normal;
  //i.tangent = vertex.tangent;
  i.uv = vertex.uv;

  return i;
}

[RootSignature(ForwardRootSignature)]
float4 ps(Interpolator i) : SV_Target {
  Submesh submesh = submeshes.Load<Submesh>(draw_data.submesh_id * sizeof(Submesh));
  Material material = materials.Load<Material>(submesh.material_id * sizeof(Material));
  Texture2D albedo_texture = ResourceDescriptorHeap[material.texture_descriptor_offset + 0];
  Texture2D normal_texture = ResourceDescriptorHeap[material.texture_descriptor_offset + 1];
  Texture2D metallic_roughness_texture = ResourceDescriptorHeap[material.texture_descriptor_offset + 2];
  float4 albedo = albedo_texture.Sample(material_sampler, i.uv);
  float4 normal = normal_texture.Sample(material_sampler, i.uv);
  float4 metallic_roughness = metallic_roughness_texture.Sample(material_sampler, i.uv);

  return metallic_roughness;
}
