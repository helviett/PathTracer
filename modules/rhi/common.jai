Texture        :: #type, isa Handle;
Buffer         :: #type, isa Handle;
Pipeline       :: #type, isa Handle;
Shader         :: #type, isa Handle;
RootSignature  :: #type, isa Handle;
MemoryHeap     :: #type, isa Handle;
DescriptorHeap :: #type, isa Handle;

Format :: enum {
  unknown;
  r8g8b8a8_unorm;
  r8g8b8a8_unorm_srgb;
}

TextureLayout :: enum {
  Undefined;
  RenderTarget;
  CopySource;
  CopyTarget;
  Present;
}

SyncStage :: enum {
  None :: 0;
  Vertex :: 1 << 0;
  Pixel :: 1 << 1;
  Raster :: 1 << 2;
  Copy :: 1 << 3;
  Present :: 1 << 4;
}

Viewport :: struct {
  x: float;
  y: float;
  width: float;
  height: float;
  min_depth: float = 0;
  max_depth: float = 1;
}

Scissor :: struct {
  x: u32;
  y: u32;
  width: u32;
  height: u32;
}

ClearColor :: struct {
  r: float;
  g: float;
  b: float;
  a: float;
}

SwapchainDesc :: struct {
  hwnd: HWND;
  width: u32;
  height: u32;
};

TextureDesc :: struct {
  format: Format;
  width: u32;
  height: u32;
  usage: D3D12_RESOURCE_FLAGS;
}

BufferDesc :: struct {
  size: u64;
  usage: D3D12_RESOURCE_FLAGS;
}

ShaderDesc :: struct {
  code: string;
}

ComputePipelineDesc :: struct {
  cs: Shader = xx null_handle;
}

GraphicsPipelineDesc :: struct {
  root_siganture: RootSignature;
  vs: Shader = xx null_handle;
  ps: Shader = xx null_handle;
  render_target_formats: []Format;
}

MemoryHeapDesc :: struct {
  heap_type: D3D12_HEAP_TYPE;
  size: u64;
}

AllocationRequirements :: struct {
  alignment: u64;
  size: u64;
}

Memory :: struct {
  heap: MemoryHeap;
  offset: u64;
}

BufferCopy :: struct {
  dst: Buffer;
  dst_offset: u64;
  src: Buffer;
  src_offset: u64;
  size: u64;
}

TextureCopy :: struct {
  dst: Texture;
  dst_subresource: TextureSubresource;
  dst_x: u32;
  dst_y: u32;
  src: Texture;
  src_subresource: TextureSubresource;
  src_x: u32;
  src_y: u32;
  width: u32;
  height: u32;
}

BufferToTextureCopy :: struct {
  buffer: Buffer;
  buffer_offset: u64;
  texture: Texture;
  texture_subresource: TextureSubresource;
  texture_x: u32;
  texture_y: u32;
  width: u32;
  height: u32;
}

TextureToBufferCopy :: #type, distinct BufferToTextureCopy;

TextureSubresource :: struct {
  mip_index: u16;
  array_index: u16;
}

FormatDesc :: struct {
  bytes_per_block: u32;
}

get_format_desc :: inline (format: Format) -> FormatDesc {
  if #complete format == {
    case .unknown;
      return .{};
    case .r8g8b8a8_unorm; #through;
    case .r8g8b8a8_unorm_srgb;
      return .{ bytes_per_block = 4 };
  }
}

format_to_dxgi :: inline (format: Format) -> DXGI_FORMAT {
  if #complete format == {
    case .unknown; return .UNKNOWN;
    case .r8g8b8a8_unorm; return .R8G8B8A8_UNORM;
    case .r8g8b8a8_unorm_srgb; return .R8G8B8A8_UNORM_SRGB;
  }
}

dxgi_to_format :: inline (dxgi: DXGI_FORMAT) -> Format {
  if dxgi == {
    case .UNKNOWN; return .unknown;
    case .R8G8B8A8_UNORM; return .r8g8b8a8_unorm;
    case .R8G8B8A8_UNORM_SRGB; return .r8g8b8a8_unorm_srgb;
  }

  assert(false);
  return .unknown;
}
