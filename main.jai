#import "Basic";
#import "Windows";
#import "dxgi";
#import "d3d12"()(INCLUDE_DEBUG_BINDINGS = true);
#import "File";
#import "String";
#import "object-pool";
#import "allocators";

Window :: #import "Window_Creation";
Input  :: #import "Input";

width :: 1920;
height :: 1080;

main :: () {
  hwnd := Window.create_window(width, height, "PathTracing");
  device: Device;
  swapchain: Swapchain;
  result: bool;

  device, result = create_device();

  if !result {
    return;
  }

  swapchain, result = create_swapchain(*device, SwapchainDesc.{ hwnd = hwnd, width = width, height = height, });

  if !result {
    return;
  }

  compute_shader := load_shader_binary(*device, "compute.dxil");
  compute_pipeline := create_compute_pipeline(*device, .{ cs = compute_shader, });

  triangle_vs := load_shader_binary(*device, "triangle_vs.dxil");
  triangle_ps := load_shader_binary(*device, "triangle_ps.dxil");

  triangle_root_signature := create_root_signature(*device, triangle_vs);

  triangle_pipeline := create_graphics_pipeline(*device, .{
    root_siganture = triangle_root_signature,
    vs = triangle_vs,
    ps = triangle_ps,
    render_target_formats = .[ .r8g8b8a8_unorm_srgb, ],
  });

  heap_size: u64 = 1024 * 1024 * 1024;
  heap := create_memory_heap(*device, .{ heap_type = .DEFAULT, size = heap_size, });
  resource_allocator: ResourceAllocator;
  init(*resource_allocator, *device, heap, heap_size);

  color_target := create_texture(*resource_allocator, .{
    format = .r8g8b8a8_unorm_srgb,
    width = width,
    height = height,
    usage = .ALLOW_RENDER_TARGET,
  });

  cpu_frame := CpuFrame.{
    fence = create_fence(*device),
  };

  for 0..gpu_frame_count - 1 {
    cpu_frame.gpu_frames[it] = .{
      cmd = create_cmd(*device),
      fence_value = 0,
    };
  }

  quit := false;
  while !quit {
      reset_temporary_storage();
      Input.update_window_events();
      for Input.events_this_frame {
          if it.type == .QUIT then quit = true;
      }

      using cpu_frame;
      gpu_frame := *gpu_frames[gpu_frame_index];
      using gpu_frame;
      wait_for_fence(*device, *fence, fence_value);
      swapchain_texture := get_next_texture(*swapchain);
      begin(*cmd);

      barrier(*cmd, .Present, .Raster | .Copy, .[
        .{ texture = swapchain_texture, before = .Present, after = .CopyTarget, },
        .{ texture = color_target, before = .Undefined, after = .RenderTarget, },
        ]
      );

      set_viewport(*cmd, .{ width = width, height = height });
      set_scissor(*cmd, .{ width = width, height = height });
      clear_rtv(*cmd, color_target, .{ });

      set_render_targets(*cmd, .[color_target], xx null_handle);

      set_root_signature(*cmd, triangle_root_signature);
      set_pipeline(*cmd, triangle_pipeline);
      draw(*cmd, 3, 1, 0, 0);

      barrier(*cmd, .Raster, .Copy, .[.{ texture = color_target, before = .RenderTarget, after = .CopySource, }]);

      copy(*cmd, TextureCopy.{
        dst = swapchain_texture,
        src =  color_target,
        width = width,
        height = height,
      });

      barrier(*cmd, .Copy, .Present, .[.{ texture = swapchain_texture, before = .CopyTarget, after = .Present, }]);

      end(*cmd);
      submit(*device, *cmd);
      fence_value = next_value(*fence);
      signal(*device, *fence, fence_value);
      present(*swapchain);
      gpu_frame_index = (gpu_frame_index + 1) % gpu_frame_count;
  }

  for 0..gpu_frame_count - 1 {
    gpu_frame := *cpu_frame.gpu_frames[it];
    wait_for_fence(*device, *cpu_frame.fence, gpu_frame.fence_value);
    destroy(*device, *gpu_frame.cmd);
  }

  destroy(*device, *cpu_frame.fence);

  destroy(*swapchain);
  destroy(*device);
}

// Renderer

gpu_frame_count : u32 : 2;

GpuFrame :: struct
{
  cmd : Cmd;
  fence_value: u64;
}

CpuFrame :: struct
{
  gpu_frames: [gpu_frame_count]GpuFrame;
  fence: Fence;
  gpu_frame_index: u32;
}

load_shader_binary :: (device: *Device, path: string) -> Shader, bool {
  auto_release_temp();
  compiled_shader_dir :: "compiled-shaders";
  bytecode, success := read_entire_file(path_join(compiled_shader_dir, path,, allocator=temp));

  if !success {
    print("Unable to load shader binary %", path);
    return xx null_handle, false;
  }

  shader: Shader;
  shader, success = create_shader(device, .{ code = bytecode, });

  return shader, success;
}

ResourceAllocator :: struct {
  offset_allocator: LinearAllocator;
  memory_heap: MemoryHeap;
  device: *Device;
}

init :: (allocator: *ResourceAllocator, device: *Device, heap: MemoryHeap, size: u64) {
  init(*allocator.offset_allocator, size);
  allocator.device = device;
  allocator.memory_heap = heap;
}

create_texture :: (using allocator: *ResourceAllocator, texture_desc: TextureDesc) -> Texture, bool {
  requirements := get_texture_allocation_requirements(device, texture_desc);
  allocation := alloc(*offset_allocator, requirements.size, requirements.alignment);
  texture, success := create_texture(device, .{ heap = memory_heap, offset = allocation.offset }, texture_desc);

  return texture, success;
}

create_buffer :: (using allocator: *ResourceAllocator, buffer_desc: BufferDesc) -> Buffer, bool {
  requirements := get_buffer_allocation_requirements(device, buffer_desc);
  allocation := alloc(*offset_allocator, requirements.size, requirements.alignment);
  buffer, success := create_buffer(device, .{ heap = memory_heap, offset = allocation.offset }, buffer_desc);

  return buffer, success;
}

// TODO: proper deallocation once any allocator with free implementation arrives.

// RHI

Texture       :: #type, isa Handle;
Buffer        :: #type, isa Handle;
Pipeline      :: #type, isa Handle;
Shader        :: #type, isa Handle;
RootSignature :: #type, isa Handle;
MemoryHeap    :: #type, isa Handle;

Device :: struct {
  factory: *IDXGIFactory6;
  debug: *ID3D12Debug1;
  adapter: *IDXGIAdapter2;
  queue: *ID3D12CommandQueue;
  info_queue: *ID3D12InfoQueue1;
  device: *ID3D12Device10;
  cookie: u32;
  rtv_descriptor_size: u32;
  dsv_descriptor_size: u32;
  cbv_srv_uav_descriptor_size: u32;
  sampler_descriptor_size: u32;
  textures: ObjectPool(TextureD3D12, Texture);
  buffers: ObjectPool(BufferD3D12, Buffer);
  pipelines: ObjectPool(PipelineD3D12, Pipeline);
  shaders: ObjectPool(ShaderD3D12, Shader);
  root_sigantures: ObjectPool(RootSignatureD3D12, RootSignature);
  memory_heaps: ObjectPool(MemoryHeapD3D12, MemoryHeap);
}

SwapchainDesc :: struct {
  hwnd: HWND;
  width: u32;
  height: u32;
};

Swapchain :: struct {
  handle: *IDXGISwapChain3;
  textures: [3]Texture;
  device: *Device;
}

Cmd :: struct {
  cmd: *ID3D12GraphicsCommandList7;
  device: *Device;
  allocator: *ID3D12CommandAllocator;
  rtv_heap: *ID3D12DescriptorHeap;
  dsv_heap: *ID3D12DescriptorHeap;
}

Fence :: struct {
  value: u64;
  fence: *ID3D12Fence;
  event: HANDLE;
}

SyncStage :: enum {
  None :: 0;
  Vertex :: 1 << 0;
  Pixel :: 1 << 1;
  Raster :: 1 << 2;
  Copy :: 1 << 3;
  Present :: 1 << 4;
}

TextureLayout :: enum {
  Undefined;
  RenderTarget;
  CopySource;
  CopyTarget;
  Present;
}

LayoutTransition :: struct {
  texture: Texture;
  before: TextureLayout;
  after: TextureLayout;
}

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

TextureD3D12 :: struct {
  format: Format;
  mip_count: u16 = 1;
  array_count: u16 = 1;
  width: u32;
  height: u32;
  memory: Memory;
  handle: *ID3D12Resource;
}

BufferD3D12 :: struct {
  memory: Memory;
  handle: *ID3D12Resource;
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

ShaderDesc :: struct {
  code: string;
}

ShaderD3D12 :: struct {
  code: D3D12_SHADER_BYTECODE;
}

RootSignatureD3D12 :: struct {
  handle: *ID3D12RootSignature;
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

PipelineD3D12 :: struct {
  handle: *ID3D12PipelineState;
}

MemoryHeapDesc :: struct {
  heap_type: D3D12_HEAP_TYPE;
  size: u64;
}

MemoryHeapD3D12 :: struct {
  handle: *ID3D12Heap;
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

Format :: enum {
  unknown;
  r8g8b8a8_unorm;
  r8g8b8a8_unorm_srgb;
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

rif :: (res: HRESULT, msg: string) #expand {
  if FAILED(res) {
    print("Error 0x%: %", FormatInt.{value = cast, no_check(u32) res, base = 16}, msg);
    `return .{}, true;
  }
}

rif_handle :: (res: HRESULT, msg: string) #expand {
  if FAILED(res) {
    print("Error 0x%: %", FormatInt.{value = cast, no_check(u32) res, base = 16}, msg);
    `return xx null_handle, true;
  }
}

release :: (u: *IUnknown) #expand {
  if u { IUnknown_Release(u); }
}

debug_callback :: (Category: D3D12_MESSAGE_CATEGORY, Severity: D3D12_MESSAGE_SEVERITY, ID: D3D12_MESSAGE_ID, pDescription: *u8, pContext: *void) #c_call {
  push_context {
    str := to_string(pDescription);
    print(str);

    if Severity == .ERROR {
      DebugBreak();
    }
  }
}

create_device :: () -> Device, bool {
  debug: *ID3D12Debug1;

  dxgi_factory_flags: u32;

  if SUCCEEDED(D3D12GetDebugInterface(*uid(ID3D12Debug1_UUID), xx *debug)) {
    ID3D12Debug1_EnableDebugLayer(debug);

    dxgi_factory_flags |= DXGI_CREATE_FACTORY_DEBUG;
  }

  factory2 : *IDXGIFactory2;
  result := CreateDXGIFactory2(dxgi_factory_flags, *uid(IDXGIFactory2_UUID), xx *factory2);

  rif(result, "Failed to create IDXGIFactory2");

  factory6 : *IDXGIFactory6;

  result = IUnknown_QueryInterface(factory2, *uid(IDXGIFactory6_UUID), xx *factory6);

  rif(result, "Factory doesn't support IDXGIFactory6 interface");

  adapter_index: u32;
  adapter: *IDXGIAdapter2;

  while true {
    if SUCCEEDED(IDXGIFactory6_EnumAdapterByGpuPreference(factory6, adapter_index, .HIGH_PERFORMANCE, *uid(IDXGIAdapter2_UUID), xx *adapter)) {
      desc: DXGI_ADAPTER_DESC2;
      if SUCCEEDED(IDXGIAdapter2_GetDesc2(adapter, *desc)) && !(desc.Flags && DXGI_ADAPTER_FLAG.SOFTWARE) {
        break;
      }
    } else {
      adapter = null;
      break;
    }

    adapter_index += 1;
  }

  device: *ID3D12Device10;

  result = D3D12CreateDevice(adapter, .D3D_FEATURE_LEVEL_12_2, *uid(ID3D12Device10_UUID), xx *device);

  rif(result, "Failed to create ID3D12Device10");

  options12: D3D12_FEATURE_DATA_D3D12_OPTIONS12;

  ID3D12Device_CheckFeatureSupport(device, .D3D12_OPTIONS12, *options12, size_of(D3D12_FEATURE_DATA_D3D12_OPTIONS12));

  if !options12.EnhancedBarriersSupported {
    print("Enhanced barriers unsupported");
    return .{}, false;
  }

  queue_desc := D3D12_COMMAND_QUEUE_DESC.{
    Type = .DIRECT,
  };

  queue: *ID3D12CommandQueue;
  cookie: u32;

  result = ID3D12Device_CreateCommandQueue(device, *queue_desc, *uid(ID3D12CommandQueue_UUID), xx *queue);

  rif(result, "Failed to reate ID3D12CommandQueue");

  info_queue: *ID3D12InfoQueue1;

  if dxgi_factory_flags & DXGI_CREATE_FACTORY_DEBUG {
    result = IUnknown_QueryInterface(device, *uid(ID3D12InfoQueue1_UUID), xx *info_queue);

    rif(result, "Failed to acquire ID3D12InfoQueue1");

    result = ID3D12InfoQueue1_RegisterMessageCallback(info_queue, debug_callback, .FLAG_NONE, null, *cookie);
  }

  return .{
    factory = factory6,
    debug = debug,
    adapter = adapter,
    queue = queue,
    info_queue = info_queue,
    cookie = cookie,
    device = device,
    rtv_descriptor_size = ID3D12Device_GetDescriptorHandleIncrementSize(device, .RTV),
    dsv_descriptor_size = ID3D12Device_GetDescriptorHandleIncrementSize(device, .DSV),
    cbv_srv_uav_descriptor_size = ID3D12Device_GetDescriptorHandleIncrementSize(device, .CBV_SRV_UAV),
    sampler_descriptor_size = ID3D12Device_GetDescriptorHandleIncrementSize(device, .SAMPLER),
  }, true;
}

destroy :: (device: *Device) -> () {
  release(device.queue);
  release(device.device);
  release(device.adapter);
  release(device.factory);
  release(device.debug);

  assert(device.textures.objects.count == 0);
  reset(*device.textures);
}

create_swapchain :: (device: *Device, desc: SwapchainDesc) -> Swapchain, bool {
  format :: Format.r8g8b8a8_unorm;
  dxgi_desc := DXGI_SWAP_CHAIN_DESC1.{
    Width = desc.width,
    Height = desc.height,
    Format = format_to_dxgi(format),
    SampleDesc.Count = 1,
    BufferUsage = .RENDER_TARGET_OUTPUT,
    BufferCount = 3,
    Scaling = .NONE,
    SwapEffect = .FLIP_DISCARD,
    AlphaMode = .IGNORE,
  };

  dxgi_swapchain: *IDXGISwapChain1;
  result := IDXGIFactory2_CreateSwapChainForHwnd(
    device.factory,
    device.queue,
    desc.hwnd,
    *dxgi_desc,
    null,
    null,
    *dxgi_swapchain
  );

  rif(result, "Unable to create IDXGISwapChain1");

  dxgi_swapchain3: *IDXGISwapChain3;
  result = IUnknown_QueryInterface(dxgi_swapchain, *uid(IDXGISwapChain1_UUID), xx *dxgi_swapchain3);

  rif(result, "Unable to query ID3D12SwapChain3 interface");

  flags : DXGI_MWA : .NO_WINDOW_CHANGES | .NO_ALT_ENTER;
  result = IDXGIFactory_MakeWindowAssociation(device.factory, desc.hwnd, xx flags);

  rif(result, "Unable to associate window with swapchain");

  swapchain := Swapchain.{
    device = device,
    handle = dxgi_swapchain3,
  };

  for 0..2 {
    texture := TextureD3D12.{
      width = desc.width,
      height = desc.height,
    };
    IDXGISwapChain_GetBuffer(dxgi_swapchain, xx it, *uid(ID3D12Resource_UUID), xx *texture.handle);
    swapchain.textures[it] = add_object(*device.textures, texture);
  }

  return swapchain, true;
}

destroy :: (using swapchain: *Swapchain) {
  for textures {
    remove_object(*device.textures, it);
  }

  release(handle);
}

present :: (using swapchain: *Swapchain) {
  IDXGISwapChain_Present(handle, 1, 0);
}

get_next_texture :: (using swapchain: *Swapchain) -> Texture {
  idx := IDXGISwapChain3_GetCurrentBackBufferIndex(handle);
  return textures[idx];
}

create_cmd :: (device: *Device) -> Cmd, bool {
  allocator: *ID3D12CommandAllocator;
  result := ID3D12Device_CreateCommandAllocator(device.device, .DIRECT, *uid(ID3D12CommandAllocator_UUID), xx *allocator);

  rif(result, "Unable to create ID3D12CommandAllocator");

  cmd_list: *ID3D12GraphicsCommandList7;
  result = ID3D12Device4_CreateCommandList1(device.device, 0, .DIRECT, 0, *uid(ID3D12GraphicsCommandList7_UUID), xx *cmd_list);

  rtv_heap_desc := D3D12_DESCRIPTOR_HEAP_DESC.{
    Type = .RTV,
    NumDescriptors = 8,
    Flags = .NONE,
    NodeMask = 0,
  };
  rtv_heap: *ID3D12DescriptorHeap;
  result = ID3D12Device_CreateDescriptorHeap(device.device, *rtv_heap_desc, *uid(ID3D12DescriptorHeap_UUID), xx *rtv_heap);

  rif(result, "Failed to create RTV ID3D12DescriptorHeap");


  dsv_heap_desc := D3D12_DESCRIPTOR_HEAP_DESC.{
    Type = .DSV,
    NumDescriptors = 1,
    Flags = .NONE,
    NodeMask = 0,
  };
  dsv_heap: *ID3D12DescriptorHeap;
  result = ID3D12Device_CreateDescriptorHeap(device.device, *dsv_heap_desc, *uid(ID3D12DescriptorHeap_UUID), xx *dsv_heap);

  return .{
    cmd = cmd_list,
    device = device,
    allocator = allocator,
    rtv_heap = rtv_heap,
    dsv_heap = dsv_heap,
  }, true;
}

destroy :: (device: *Device, cmd: *Cmd) {
  release(cmd.cmd);
  release(cmd.allocator);
}

begin :: (cmd: *Cmd) {
  ID3D12CommandAllocator_Reset(cmd.allocator);
  ID3D12GraphicsCommandList_Reset(cmd.cmd, cmd.allocator, null);
  ID3D12GraphicsCommandList_IASetPrimitiveTopology(cmd.cmd, .TRIANGLELIST);
}

end :: (cmd: *Cmd) {
  ID3D12GraphicsCommandList_Close(cmd.cmd);
}

set_viewport :: (cmd: *Cmd, viewport: Viewport) {
  d3d12_viewport := D3D12_VIEWPORT.{
    TopLeftX = viewport.x,
    TopLeftY = viewport.y,
    Width = viewport.width,
    Height = viewport.height,
    MinDepth = viewport.min_depth,
    MaxDepth = viewport.max_depth,
  };
  ID3D12GraphicsCommandList_RSSetViewports(cmd.cmd, 1, *d3d12_viewport);
}

set_scissor :: (cmd: *Cmd, scissor: Scissor) {
  d3d12_scissor := RECT.{
    left = cast(s32)scissor.x,
    top = cast(s32)scissor.y,
    right = cast(s32)(scissor.x + scissor.width),
    bottom = cast(s32)(scissor.y + scissor.height),
  };

  ID3D12GraphicsCommandList_RSSetScissorRects(cmd.cmd, 1, *d3d12_scissor);
}

sync_stage_to_d3d12_sync_and_access :: (stage: SyncStage) -> D3D12_BARRIER_SYNC, D3D12_BARRIER_ACCESS {
  if stage == .None {
    return .NONE, .NO_ACCESS;
  }

  sync: D3D12_BARRIER_SYNC;
  access: D3D12_BARRIER_ACCESS;

  any_l0_l1_l2_access : D3D12_BARRIER_ACCESS : .VERTEX_BUFFER | .INDEX_BUFFER | .CONSTANT_BUFFER | .SHADER_RESOURCE | .UNORDERED_ACCESS;

  if stage & .Vertex {
    sync |= .VERTEX_SHADING | .INDEX_INPUT;
    access |= any_l0_l1_l2_access;
  }

  if stage & .Pixel {
    sync |= .PIXEL_SHADING;
    access |= any_l0_l1_l2_access;
  }

  if stage & .Raster {
    sync |= .RENDER_TARGET;
    access |= .RENDER_TARGET;
  }

  if stage & .Copy {
    sync |= .COPY;
    access |= .COPY_SOURCE | .COPY_DEST;
  }

  if stage & .Present {
    access = .NO_ACCESS;
  }

  assert(access != .COMMON);

  return sync, access;
}

layout_to_d3d12_layout :: (layout: TextureLayout) -> D3D12_BARRIER_LAYOUT {
  if #complete layout == {
    case .Undefined; return .UNDEFINED;
    case .RenderTarget; return .RENDER_TARGET;
    case .CopySource; return .COPY_SOURCE;
    case .CopyTarget; return .COPY_DEST;
    case .Present; return .PRESENT;
  }
}

keep_compatible_access :: inline (layout: D3D12_BARRIER_LAYOUT, access: D3D12_BARRIER_ACCESS) -> D3D12_BARRIER_ACCESS {
  if layout == {
    case .UNDEFINED; return access;
    case .PRESENT; return .NO_ACCESS;
    case .RENDER_TARGET; return access & .RENDER_TARGET;
    case .UNORDERED_ACCESS; return access & .UNORDERED_ACCESS;
    case .DEPTH_STENCIL_WRITE; return access & (.DEPTH_STENCIL_READ | .DEPTH_STENCIL_WRITE);
    case .DEPTH_STENCIL_READ; return access & .DEPTH_STENCIL_READ;
    case .SHADER_RESOURCE; return access & .SHADER_RESOURCE;
    case .COPY_SOURCE; return access & .COPY_SOURCE;
    case .COPY_DEST; return access & .COPY_DEST;
  }

  return access;
}

keep_compatible_sync :: inline(sync: D3D12_BARRIER_SYNC, access: D3D12_BARRIER_ACCESS) -> D3D12_BARRIER_SYNC {
  compatible: D3D12_BARRIER_SYNC;

  if access & .VERTEX_BUFFER {
    compatible |= (.ALL | .VERTEX_SHADING | .DRAW | .ALL_SHADING);
  }

  if access & .CONSTANT_BUFFER {
    compatible |= (.ALL | .VERTEX_SHADING | .PIXEL_SHADING | .COMPUTE_SHADING | .DRAW | .ALL_SHADING);
  }

  if access & .INDEX_BUFFER {
    compatible |= (.ALL | .INDEX_INPUT | .DRAW);
  }

  if access & .RENDER_TARGET {
    compatible |= (.ALL | .DRAW | .RENDER_TARGET);
  }

  if access & .UNORDERED_ACCESS {
    compatible |= (.ALL | .VERTEX_SHADING | .PIXEL_SHADING | .COMPUTE_SHADING | .DRAW | .ALL_SHADING | .EMIT_RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO | .RAYTRACING);
  }

  if access & (.DEPTH_STENCIL_WRITE | .DEPTH_STENCIL_READ) {
    compatible |= (.ALL | .DRAW | .DEPTH_STENCIL);
  }

  if access & .SHADER_RESOURCE {
    compatible |= (.ALL | .VERTEX_SHADING | .PIXEL_SHADING | .COMPUTE_SHADING | .DRAW | .ALL_SHADING | .BUILD_RAYTRACING_ACCELERATION_STRUCTURE | .RAYTRACING);
  }

  if access & .INDIRECT_ARGUMENT {
    compatible |= (.ALL | .EXECUTE_INDIRECT);
  }

  if access & (.COPY_DEST | .COPY_SOURCE) {
    compatible |= (.ALL | .COPY);
  }

  return sync & compatible;
}

keep_compatible_bits :: inline (layout: D3D12_BARRIER_LAYOUT, sync: D3D12_BARRIER_SYNC, access: D3D12_BARRIER_ACCESS) -> D3D12_BARRIER_SYNC, D3D12_BARRIER_ACCESS {
  compatible_access := keep_compatible_access(layout, access);
  compatible_sync := keep_compatible_sync(sync, compatible_access);

  return compatible_sync, compatible_access;
}

barrier :: (cmd: *Cmd, before: SyncStage, after: SyncStage, layout_transitions: []LayoutTransition) {
  auto_release_temp();
  group_count : u32 = 0;
  groups := D3D12_BARRIER_GROUP.[.{}, .{}];

  global := *groups[group_count];
  global.Type = .GLOBAL;
  global.NumBarriers = 1;
  group_count += 1;

  global_barrier: D3D12_GLOBAL_BARRIER;
  global_barrier.SyncBefore, global_barrier.AccessBefore = sync_stage_to_d3d12_sync_and_access(before);
  global_barrier.SyncAfter, global_barrier.AccessAfter = sync_stage_to_d3d12_sync_and_access(after);
  global.pGlobalBarriers = *global_barrier;

  if layout_transitions.count > 0 {
    texture := *groups[group_count];
    texture.Type = .TEXTURE;
    texture.NumBarriers = cast(u32) layout_transitions.count;
    group_count += 1;;

    barriers := NewArray(layout_transitions.count, D3D12_TEXTURE_BARRIER,, allocator=temp);
    texture.pTextureBarriers = *barriers[0];

    for 0..layout_transitions.count - 1 {
      t := *layout_transitions[it];
      b := *barriers[it];

      b.LayoutBefore = layout_to_d3d12_layout(t.before);
      b.LayoutAfter = layout_to_d3d12_layout(t.after);
      b.SyncBefore, b.AccessBefore = keep_compatible_bits(b.LayoutBefore, global_barrier.SyncBefore, global_barrier.AccessBefore);
      b.SyncAfter, b.AccessAfter = keep_compatible_bits(b.LayoutAfter, global_barrier.SyncAfter, global_barrier.AccessAfter);
      b.pResource = get_object(cmd.device.textures, t.texture).handle;
      b.Subresources.IndexOrFirstMipLevel = 0xFFFFFFFF;
    }
  }

  ID3D12GraphicsCommandList7_Barrier(cmd.cmd, group_count, *groups[0]);
}

clear_rtv :: (cmd: *Cmd, rtv: Texture, clear_color: ClearColor) {
  d3d12_rtv := get_object(cmd.device.textures, rtv);

  handle := ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(cmd.rtv_heap);
  ID3D12Device_CreateRenderTargetView(cmd.device.device, d3d12_rtv.handle, null, handle);
  d3d12_clear_color := float.[clear_color.r, clear_color.g, clear_color.b, clear_color.a];

  ID3D12GraphicsCommandList_ClearRenderTargetView(cmd.cmd, handle, *d3d12_clear_color, 0, null);
}

set_render_targets :: (cmd: *Cmd, color_targets: []Texture, depth_target: Texture) {
  rtv_head := ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(cmd.rtv_heap);
  rtv_handle_ptr :*D3D12_CPU_DESCRIPTOR_HANDLE;

  if color_targets {
    rtv_handle_ptr = *rtv_head;

    for color_targets {
      handle := D3D12_CPU_DESCRIPTOR_HANDLE.{ ptr = rtv_head.ptr + cast(u64) it_index * cmd.device.rtv_descriptor_size };
      d3d12_color_target := get_object(cmd.device.textures, it);
      ID3D12Device_CreateRenderTargetView(cmd.device.device, d3d12_color_target.handle, null, handle);
    }
  }

  dsv_handle_ptr :*D3D12_CPU_DESCRIPTOR_HANDLE;

  if depth_target != xx null_handle {
    handle := ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(cmd.dsv_heap);
    d3d12_depth_target := get_object(cmd.device.textures, depth_target);
    ID3D12Device_CreateDepthStencilView(cmd.device.device, d3d12_depth_target.handle, null, handle);
    dsv_handle_ptr = *handle;
  }

  ID3D12GraphicsCommandList_OMSetRenderTargets(cmd.cmd, xx color_targets.count, rtv_handle_ptr, .TRUE, dsv_handle_ptr);
}

set_root_signature :: (cmd: *Cmd, root_siganture: RootSignature) {
  handle: *ID3D12RootSignature = get_object(cmd.device.root_sigantures, root_siganture).handle;
  ID3D12GraphicsCommandList_SetGraphicsRootSignature(cmd.cmd, handle);
  ID3D12GraphicsCommandList_SetComputeRootSignature(cmd.cmd, handle);
}

set_pipeline :: (cmd: *Cmd, pipeline: Pipeline) {
  ID3D12GraphicsCommandList_SetPipelineState(cmd.cmd, get_object(cmd.device.pipelines, pipeline).handle);
}

draw :: (cmd: *Cmd, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) {
  ID3D12GraphicsCommandList_DrawInstanced(cmd.cmd, vertex_count, instance_count, first_vertex, first_instance);
}

draw_indexed :: (cmd: *Cmd, index_count: u32, instance_count: u32, first_index: u32, vertex_offset: s32, first_instance: u32) {
  ID3D12GraphicsCommandList_DrawIndexedInstanced(cmd.cmd, index_count, instance_count, first_index, vertex_offset, first_instance);
}

copy :: (cmd: *Cmd, copy: BufferCopy) {
  d3d12_dst := get_object(cmd.device.buffers, copy.dst).handle;
  d3d12_src := get_object(cmd.device.buffers, copy.src).handle;

  ID3D12GraphicsCommandList_CopyBufferRegion(cmd.cmd, d3d12_dst, copy.dst_offset, d3d12_src, copy.src_offset, copy.size);
}

copy :: (cmd: *Cmd, copy: TextureCopy) {
  d3d12_dst := get_object(cmd.device.textures, copy.dst).handle;
  d3d12_src := get_object(cmd.device.textures, copy.src).handle;
  dst_location := D3D12_TEXTURE_COPY_LOCATION.{
    pResource = d3d12_dst,
    Type = .SUBRESOURCE_INDEX,
    SubresourceIndex = subresource_index(copy.dst_subresource, 1),
  };
  src_location := D3D12_TEXTURE_COPY_LOCATION.{
    pResource = d3d12_src,
    Type = .SUBRESOURCE_INDEX,
    SubresourceIndex = subresource_index(copy.src_subresource, 1),
  };
  src_box := D3D12_BOX.{
    left = copy.src_x,
    top = copy.src_y,
    front = 0,
    right = copy.src_x + copy.width,
    bottom = copy.src_y + copy.height,
    back = 1,
  };

  ID3D12GraphicsCommandList_CopyTextureRegion(
    cmd.cmd, *dst_location, copy.dst_x, copy.dst_y, 0, *src_location, *src_box);
}

copy :: (cmd: *Cmd, copy: BufferToTextureCopy) {
  d3d12_dst := get_object(cmd.device.textures, copy.texture);
  d3d12_src := get_object(cmd.device.buffers, copy.buffer);
  dst_location := D3D12_TEXTURE_COPY_LOCATION.{
    pResource = d3d12_dst.handle,
    Type = .SUBRESOURCE_INDEX,
    SubresourceIndex = subresource_index(copy.texture_subresource, 1),
  };

  src_footprint := D3D12_PLACED_SUBRESOURCE_FOOTPRINT.{
    Offset = copy.buffer_offset,
    Footprint = .{
      Format = format_to_dxgi(d3d12_dst.format),
      Width = copy.width,
      Height = copy.height,
      Depth = 1,
      RowPitch = align_pot(d3d12_dst.width * get_format_desc(d3d12_dst.format).bytes_per_block, D3D12_TEXTURE_DATA_PITCH_ALIGNMENT),
    },
  };
  src_location := D3D12_TEXTURE_COPY_LOCATION.{
    pResource = d3d12_src.handle,
    Type = .PLACED_FOOTPRINT,
    PlacedFootprint = src_footprint,
  };

  ID3D12GraphicsCommandList_CopyTextureRegion(
    cmd.cmd, *dst_location, copy.texture_x, copy.texture_y, 0, *src_location, null);
}

copy :: (cmd: *Cmd, copy: TextureToBufferCopy) {
  assert(false);
}

submit :: (device: *Device, cmd: *Cmd) {
  ID3D12CommandQueue_ExecuteCommandLists(device.queue, 1, xx *cmd.cmd);
}

wait_for_fence :: (device: *Device, fence: *Fence, value: u64) {
  last_completed_value: u64 = ID3D12Fence_GetCompletedValue(fence.fence);

  if (last_completed_value < value) {
    ID3D12Fence_SetEventOnCompletion(fence.fence, value, fence.event);
    WaitForSingleObject(fence.event, WIN_TIMEOUT_INFINITE);
  }
}

signal :: (device: *Device, fence: *Fence, value: u64) {
  ID3D12CommandQueue_Signal(device.queue, fence.fence, value);
}

create_fence :: (device: *Device) -> Fence, bool {
  fence: *ID3D12Fence;
  result := ID3D12Device_CreateFence(device.device, 0, .NONE, *uid(ID3D12Fence_UUID), xx *fence);

  rif(result, "Failed to create ID3D12Fence");

  event := CreateEventW(null, 0, 0, null);

  if event == null {
    return .{}, false;
  }

  return .{
    value = 0,
    fence = fence,
    event = event,
  }, true;
}

destroy :: (device: *Device, fence: *Fence) {
  release(fence.fence);
}

next_value :: (fence: *Fence) -> u64 {
  fence.value = fence.value + 1;

  return fence.value;
}

create_shader :: (device: *Device, using desc: ShaderDesc) -> Shader, bool {
  return add_object(*device.shaders, .{ code = .{ code.data, xx code.count } }), true;
}

create_root_signature :: (device: *Device, shader: Shader) -> RootSignature, bool {
  root_siganture: *ID3D12RootSignature;
  d3d12_shader := get_object(device.shaders, shader);
  result := ID3D12Device_CreateRootSignature(device.device, 0, d3d12_shader.code.pShaderBytecode, d3d12_shader.code.BytecodeLength, *uid(ID3D12RootSignature_UUID), xx *root_siganture);
  rif_handle(result, "Unable to create root signature");

  return add_object(*device.root_sigantures, .{ handle = root_siganture, }), true;
}

create_compute_pipeline :: (device: *Device, using desc: ComputePipelineDesc) -> Pipeline, bool {
  d3d12_shader := get_object(device.shaders, cs);
  d3d12_desc := D3D12_COMPUTE_PIPELINE_STATE_DESC.{ CS = d3d12_shader.code, };
  pipeline: *ID3D12PipelineState;
  ID3D12Device_CreateComputePipelineState(device.device, *d3d12_desc, *uid(ID3D12PipelineState_UUID), xx *pipeline);

  return add_object(*device.pipelines, .{ handle = pipeline }), true;
}

MAX_PIPELINE_STATE_STREAM_SIZE :: #run
  align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(*ID3D12RootSignature), size_of(*void))
  // 2 Shaders at most.
  + align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(D3D12_SHADER_BYTECODE), size_of(*void))
  + align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(D3D12_SHADER_BYTECODE), size_of(*void))
  + align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(D3D12_BLEND_DESC), size_of(*void))
  + align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(u32), size_of(*void))
  + align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(D3D12_RASTERIZER_DESC2), size_of(*void))
  + align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(D3D12_DEPTH_STENCIL_DESC2), size_of(*void))
  + align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(D3D12_INPUT_LAYOUT_DESC), size_of(*void))
  + align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(D3D12_RT_FORMAT_ARRAY), size_of(*void))
  + align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(DXGI_FORMAT), size_of(*void))
  + align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(DXGI_SAMPLE_DESC), size_of(*void))
  + align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(D3D12_PRIMITIVE_TOPOLOGY_TYPE), size_of(*void))
  + align_pot(size_of(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE) + size_of(u32), size_of(*void));

create_graphics_pipeline :: (device: *Device, using desc: GraphicsPipelineDesc) -> Pipeline, bool {
  auto_release_temp();
  stream_head : *u8 = alloc(MAX_PIPELINE_STATE_STREAM_SIZE,, allocator=temp);
  stream_tail := stream_head;

  write_stream :: (subobject: $T) #expand {
    (cast(*T) stream_tail).* = subobject;
    stream_tail += align_pot(size_of(T), size_of(*void));
    assert((stream_tail - stream_head) <= MAX_PIPELINE_STATE_STREAM_SIZE);
  }

  if root_siganture != xx null_handle {
    d3d12_root_signature := get_object(device.root_sigantures, root_siganture);
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.ROOT_SIGNATURE; root_signature: *ID3D12RootSignature; };
    so.root_signature = d3d12_root_signature.handle;

    write_stream(so);
  }

  if vs != xx null_handle {
    d3d12_vs := get_object(device.shaders, vs);
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.VS; vs: D3D12_SHADER_BYTECODE; };
    so.vs = d3d12_vs.code;

    write_stream(so);
  }

  if ps != xx null_handle {
    d3d12_ps := get_object(device.shaders, ps);
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.PS; ps: D3D12_SHADER_BYTECODE; };
    so.ps = d3d12_ps.code;

    write_stream(so);
  }

  if render_target_formats {
    assert(render_target_formats.count <= 8);
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.RENDER_TARGET_FORMATS; rtv_formats: D3D12_RT_FORMAT_ARRAY; };
    so.rtv_formats.NumRenderTargets = xx render_target_formats.count;

    for render_target_formats {
      so.rtv_formats.RTFormats[it_index] = format_to_dxgi(it);
    }

    write_stream(so);
  }

  {
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.PRIMITIVE_TOPOLOGY; topology: D3D12_PRIMITIVE_TOPOLOGY_TYPE; };
    so.topology = .TRIANGLE;

    write_stream(so);
  }

  {
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.RASTERIZER2; rasterizer: D3D12_RASTERIZER_DESC2; };
    so.rasterizer = .{
      FillMode = .SOLID,
      CullMode = .BACK,
      FrontCounterClockwise = .TRUE,
      DepthClipEnable = .TRUE,
    };


    write_stream(so);
  }

  pipeline_stream := D3D12_PIPELINE_STATE_STREAM_DESC.{
    SizeInBytes = xx (stream_tail - stream_head),
    pPipelineStateSubobjectStream = stream_head,
  };

  pipeline: *ID3D12PipelineState;


  result := ID3D12Device2_CreatePipelineState(device.device, *pipeline_stream, *uid(ID3D12PipelineState_UUID), xx *pipeline);
  rif_handle(result, "Unable to create pipeline");

  return add_object(*device.pipelines, .{ handle = pipeline, }), true;
}

destroy :: (device: *Device, pipeline: Pipeline) {
  d3d12_pipeline, removed := remove_object(*device.pipelines, pipeline);
  assert(removed);

  release(d3d12_pipeline.handle);
}

create_memory_heap :: (device: *Device, memory_heap_desc: MemoryHeapDesc) -> MemoryHeap, bool {
  handle: *ID3D12Heap;

  d3d12_desc := D3D12_HEAP_DESC.{
    SizeInBytes = memory_heap_desc.size,
    Properties = .{ Type = memory_heap_desc.heap_type, },
    // MSAA needs higher alignment value.
    Alignment = D3D12_DEFAULT_RESOURCE_PLACEMENT_ALIGNMENT,
    Flags = .ALLOW_ALL_BUFFERS_AND_TEXTURES,
  };

  result := ID3D12Device_CreateHeap(device.device, *d3d12_desc, *uid(ID3D12Heap_UUID), xx *handle);
  rif_handle(result, "Unable to create memory heap");

  return add_object(*device.memory_heaps, .{ handle = handle }), true;
}

destroy :: (device: *Device, memory_heap: MemoryHeap) {
  d3d12_memory_heap, removed := remove_object(*device.memory_heaps, memory_heap);
  assert(removed);

  release(d3d12_memory_heap.handle);
}

get_texture_allocation_requirements :: (device: *Device, texture_desc: TextureDesc) -> AllocationRequirements {
  resource_desc := D3D12_RESOURCE_DESC1.{
    Dimension = .TEXTURE2D,
    Width = texture_desc.width,
    Height = texture_desc.height,
    DepthOrArraySize = 1,
    MipLevels = 1,
    Format = format_to_dxgi(texture_desc.format),
    SampleDesc = .{ Count = 1, Quality = 0 },
    Layout = .UNKNOWN,
    Flags = .NONE,
  };

  allocation_info: D3D12_RESOURCE_ALLOCATION_INFO1;
  ID3D12Device8_GetResourceAllocationInfo2(device.device, 0, 1, *resource_desc, *allocation_info);

  return .{ alignment = allocation_info.Alignment, size = allocation_info.SizeInBytes };
}

get_buffer_allocation_requirements :: (device: *Device, buffer_desc: BufferDesc) -> AllocationRequirements {
  resource_desc := D3D12_RESOURCE_DESC1.{
    Dimension = .BUFFER,
    Width = buffer_desc.size,
    Height = 1,
    Format = .UNKNOWN,
    Layout = .ROW_MAJOR,
    Flags = buffer_desc.usage,
  };

  allocation_info: D3D12_RESOURCE_ALLOCATION_INFO1;
  ID3D12Device8_GetResourceAllocationInfo2(device.device, 0, 1, *resource_desc, *allocation_info);

  return .{ alignment = allocation_info.Alignment, size = allocation_info.SizeInBytes };
}

create_texture :: (device: *Device, memory: Memory, texture_desc: TextureDesc) -> Texture, bool {
  resource_desc := D3D12_RESOURCE_DESC1.{
    Dimension = .TEXTURE2D,
    Width = texture_desc.width,
    Height = texture_desc.height,
    DepthOrArraySize = 1,
    MipLevels = 1,
    Format = format_to_dxgi(texture_desc.format),
    SampleDesc = .{ Count = 1, Quality = 0 },
    Layout = .UNKNOWN,
    Flags = texture_desc.usage,
  };
  clear_value := D3D12_CLEAR_VALUE.{
    Format = format_to_dxgi(texture_desc.format),
  };
  d3d12_heap := get_object(device.memory_heaps, memory.heap).handle;

  resource: *ID3D12Resource;
  result := ID3D12Device10_CreatePlacedResource2(
    device.device,
    d3d12_heap,
    memory.offset,
    *resource_desc,
    .UNDEFINED,
    *clear_value,
    0,
    null,
    *uid(ID3D12Resource_UUID),
    xx *resource
  );
  rif_handle(result, "Unable to create texture.");

  return add_object(*device.textures, .{
    format = texture_desc.format,
    mip_count = 1,
    array_count = 1,
    width = texture_desc.width,
    height = texture_desc.height,
    memory = memory,
    handle = resource,
  }), true;
}

destroy :: (device: *Device, texture: Texture) {
  d3d12_texture, removed := remove_object(*device.textures, texture);
  assert(removed);

  release(d3d12_texture.handle);
}

create_buffer :: (device: *Device, memory: Memory, buffer_desc: BufferDesc) -> Buffer, bool {
  resource_desc := D3D12_RESOURCE_DESC1.{
    Dimension = .BUFFER,
    Width = buffer_desc.size,
    Height = 1,
    DepthOrArraySize = 1,
    MipLevels = 1,
    Format = .UNKNOWN,
    Layout = .UNKNOWN,
    Flags = buffer_desc.usage,
  };
  clear_value := D3D12_CLEAR_VALUE.{};
  d3d12_heap := get_object(device.memory_heaps, memory.heap).handle;

  resource: *ID3D12Resource;
  result := ID3D12Device10_CreatePlacedResource2(
    device.device,
    d3d12_heap,
    memory.offset,
    *resource_desc,
    .UNDEFINED,
    *clear_value,
    0,
    null,
    *uid(ID3D12Resource_UUID),
    xx *resource
  );
  rif_handle(result, "Unable to create buffer.");

  return add_object(*device.buffers, .{ memory = memory, handle = resource, }), true;
}

destroy :: (device: *Device, buffer: Buffer) {
  d3d12_buffer, removed := remove_object(*device.buffers, buffer);
  assert(removed);

  release(d3d12_buffer.handle);
}

subresource_index :: inline (using subresource: TextureSubresource, mip_count: u16) -> u32 {
  return mip_index + (array_index * mip_count);
}
