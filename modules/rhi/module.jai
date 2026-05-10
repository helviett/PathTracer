DeviceD3D12 :: struct {
  factory: *IDXGIFactory6;
  debug: *ID3D12Debug1;
  adapter: *IDXGIAdapter2;
  queue: *ID3D12CommandQueue;
  info_queue: *ID3D12InfoQueue1;
  device: *ID3D12Device10;
  wait_idle_fence: Fence;
  cookie: u32;
  rtv_descriptor_size: u64;
  dsv_descriptor_size: u64;
  cbv_srv_uav_descriptor_size: u64;
  sampler_descriptor_size: u64;
  samplers: ObjectPool(SamplerD3D12, Sampler);
  textures: ObjectPool(TextureD3D12, Texture);
  buffers: ObjectPool(BufferD3D12, Buffer);
  pipelines: ObjectPool(PipelineD3D12, Pipeline);
  shaders: ObjectPool(ShaderD3D12, Shader);
  root_sigantures: ObjectPool(RootSignatureD3D12, RootSignature);
  memory_heaps: ObjectPool(MemoryHeapD3D12, MemoryHeap);
  descriptor_heaps: ObjectPool(DescriptorHeapD3D12, DescriptorHeap);
  // TODO: resizable array that is backed by large preallocated virtual address space
  cmds: [128]CmdD3D12;
  free_cmd_index: s64;
}

Swapchain :: struct {
  handle: *IDXGISwapChain3;
  textures: [3]Texture;
  device: Device;
}

CmdD3D12 :: struct {
  cmd: *ID3D12GraphicsCommandList7;
  device: Device;
  allocator: *ID3D12CommandAllocator;
  rtv_heap: *ID3D12DescriptorHeap;
  dsv_heap: *ID3D12DescriptorHeap;
}

Fence :: struct {
  value: u64;
  fence: *ID3D12Fence;
  event: HANDLE;
}

LayoutTransition :: struct {
  texture: Texture;
  before: TextureLayout;
  after: TextureLayout;
}

SamplerD3D12 :: struct {
  desc: D3D12_SAMPLER_DESC;
}

TextureD3D12 :: struct {
  format: Format;
  mip_count: u16 = 1;
  layer_count: u16 = 1;
  width: u32;
  height: u32;
  memory: Memory;
  handle: *ID3D12Resource;
}

BufferD3D12 :: struct {
  memory: Memory;
  mapped_ptr: *void;
  size: u64;
  handle: *ID3D12Resource;
}

ShaderD3D12 :: struct {
  code: D3D12_SHADER_BYTECODE;
}

RootSignatureD3D12 :: struct {
  handle: *ID3D12RootSignature;
}

PipelineD3D12 :: struct {
  handle: *ID3D12PipelineState;
}

MemoryHeapD3D12 :: struct {
  handle: *ID3D12Heap;
}

DescriptorHeapD3D12 :: struct {
  handle: *ID3D12DescriptorHeap;
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

  rif_handle(result, "Failed to create IDXGIFactory2");

  factory6 : *IDXGIFactory6;

  result = IUnknown_QueryInterface(factory2, *uid(IDXGIFactory6_UUID), xx *factory6);

  rif_handle(result, "Factory doesn't support IDXGIFactory6 interface");

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

  rif_handle(result, "Failed to create ID3D12Device10");

  options12: D3D12_FEATURE_DATA_D3D12_OPTIONS12;

  ID3D12Device_CheckFeatureSupport(device, .D3D12_OPTIONS12, *options12, size_of(D3D12_FEATURE_DATA_D3D12_OPTIONS12));

  if !options12.EnhancedBarriersSupported {
    print("Enhanced barriers unsupported");
    return xx null_handle, false;
  }

  queue_desc := D3D12_COMMAND_QUEUE_DESC.{
    Type = .DIRECT,
  };

  queue: *ID3D12CommandQueue;
  cookie: u32;

  result = ID3D12Device_CreateCommandQueue(device, *queue_desc, *uid(ID3D12CommandQueue_UUID), xx *queue);

  rif_handle(result, "Failed to reate ID3D12CommandQueue");

  info_queue: *ID3D12InfoQueue1;

  if dxgi_factory_flags & DXGI_CREATE_FACTORY_DEBUG {
    result = IUnknown_QueryInterface(device, *uid(ID3D12InfoQueue1_UUID), xx *info_queue);

    rif_handle(result, "Failed to acquire ID3D12InfoQueue1");

    result = ID3D12InfoQueue1_RegisterMessageCallback(info_queue, debug_callback, .FLAG_NONE, null, *cookie);
  }

  result_device : =New(DeviceD3D12);
  result_device.* = DeviceD3D12.{
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
  };

  is_created: bool;
  result_device.wait_idle_fence, is_created = create_fence(xx result_device);

  return xx result_device, is_created;
}

destroy :: (device: Device) -> () {
  d3d12_device: *DeviceD3D12 = xx device;
  release(d3d12_device.queue);
  release(d3d12_device.device);
  release(d3d12_device.adapter);
  release(d3d12_device.factory);
  release(d3d12_device.debug);

  assert(d3d12_device.textures.objects.count == 0);
  reset(*d3d12_device.textures);
}

create_swapchain :: (device: Device, desc: SwapchainDesc) -> Swapchain, bool {
  d3d12_device: *DeviceD3D12 = xx device;
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
    d3d12_device.factory,
    d3d12_device.queue,
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
  result = IDXGIFactory_MakeWindowAssociation(d3d12_device.factory, desc.hwnd, xx flags);

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
    swapchain.textures[it] = add_object(*d3d12_device.textures, texture);
  }

  return swapchain, true;
}

destroy :: (using swapchain: *Swapchain) {
  d3d12_device: *DeviceD3D12 = xx device;
  for textures {
    remove_object(*d3d12_device.textures, it);
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

create_cmd :: (device: Device) -> Cmd, bool {
  d3d12_device: *DeviceD3D12 = xx device;
  assert(d3d12_device.free_cmd_index < d3d12_device.cmds.count);
  allocator: *ID3D12CommandAllocator;
  result := ID3D12Device_CreateCommandAllocator(d3d12_device.device, .DIRECT, *uid(ID3D12CommandAllocator_UUID), xx *allocator);

  rif_handle(result, "Unable to create ID3D12CommandAllocator");

  cmd_list: *ID3D12GraphicsCommandList7;
  result = ID3D12Device4_CreateCommandList1(d3d12_device.device, 0, .DIRECT, 0, *uid(ID3D12GraphicsCommandList7_UUID), xx *cmd_list);

  rtv_heap_desc := D3D12_DESCRIPTOR_HEAP_DESC.{
    Type = .RTV,
    NumDescriptors = 8,
    Flags = .NONE,
    NodeMask = 0,
  };
  rtv_heap: *ID3D12DescriptorHeap;
  result = ID3D12Device_CreateDescriptorHeap(d3d12_device.device, *rtv_heap_desc, *uid(ID3D12DescriptorHeap_UUID), xx *rtv_heap);

  rif_handle(result, "Failed to create RTV ID3D12DescriptorHeap");


  dsv_heap_desc := D3D12_DESCRIPTOR_HEAP_DESC.{
    Type = .DSV,
    NumDescriptors = 1,
    Flags = .NONE,
    NodeMask = 0,
  };
  dsv_heap: *ID3D12DescriptorHeap;
  result = ID3D12Device_CreateDescriptorHeap(d3d12_device.device, *dsv_heap_desc, *uid(ID3D12DescriptorHeap_UUID), xx *dsv_heap);

  d3d12_device.cmds[d3d12_device.free_cmd_index] =  .{
    cmd = cmd_list,
    device = device,
    allocator = allocator,
    rtv_heap = rtv_heap,
    dsv_heap = dsv_heap,
  };

  d3d12_device.free_cmd_index += 1;

  return xx *d3d12_device.cmds[d3d12_device.free_cmd_index - 1], true;
}

destroy :: (device: Device, cmd: Cmd) {
  d3d12_device: *DeviceD3D12 = xx device;
  d3d12_cmd: *CmdD3D12 = xx cmd;
  release(d3d12_cmd.cmd);
  release(d3d12_cmd.allocator);
}

begin :: (cmd: Cmd) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  ID3D12CommandAllocator_Reset(d3d12_cmd.allocator);
  ID3D12GraphicsCommandList_Reset(d3d12_cmd.cmd, d3d12_cmd.allocator, null);
  ID3D12GraphicsCommandList_IASetPrimitiveTopology(d3d12_cmd.cmd, .TRIANGLELIST);
}

end :: (cmd: Cmd) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  ID3D12GraphicsCommandList_Close(d3d12_cmd.cmd);
}

set_viewport :: (cmd: Cmd, viewport: Viewport) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_viewport := D3D12_VIEWPORT.{
    TopLeftX = viewport.x,
    TopLeftY = viewport.y,
    Width = viewport.width,
    Height = viewport.height,
    MinDepth = viewport.min_depth,
    MaxDepth = viewport.max_depth,
  };
  ID3D12GraphicsCommandList_RSSetViewports(d3d12_cmd.cmd, 1, *d3d12_viewport);
}

set_scissor :: (cmd: Cmd, scissor: Scissor) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_scissor := RECT.{
    left = cast(s32)scissor.x,
    top = cast(s32)scissor.y,
    right = cast(s32)(scissor.x + scissor.width),
    bottom = cast(s32)(scissor.y + scissor.height),
  };

  ID3D12GraphicsCommandList_RSSetScissorRects(d3d12_cmd.cmd, 1, *d3d12_scissor);
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

  if stage & .Compute {
    sync |= .COMPUTE_SHADING;
    access |= any_l0_l1_l2_access;
  }

  if stage & .Raster {
    sync |= .RENDER_TARGET | .DEPTH_STENCIL;
    access |= .RENDER_TARGET | .DEPTH_STENCIL_WRITE | .DEPTH_STENCIL_READ;
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
    case .ShaderResource; return .SHADER_RESOURCE;
    case .RenderTarget; return .RENDER_TARGET;
    case .DepthStencilTarget; return .DEPTH_STENCIL_WRITE;
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
    // Spec says it's .DEPTH_STENCIL_READ | .DEPTH_STENCIL_WRITE but validation layers complain.
    case .DEPTH_STENCIL_WRITE; return access & .DEPTH_STENCIL_WRITE;
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

  if access & (.DEPTH_STENCIL_WRITE | .DEPTH_STENCIL_WRITE) {
    compatible |= (.ALL | .DRAW | .DEPTH_STENCIL);
  }

  return sync & compatible;
}

keep_compatible_bits :: inline (layout: D3D12_BARRIER_LAYOUT, sync: D3D12_BARRIER_SYNC, access: D3D12_BARRIER_ACCESS) -> D3D12_BARRIER_SYNC, D3D12_BARRIER_ACCESS {
  compatible_access := keep_compatible_access(layout, access);
  compatible_sync := keep_compatible_sync(sync, compatible_access);

  return compatible_sync, compatible_access;
}

barrier :: (cmd: Cmd, before: SyncStage, after: SyncStage, layout_transitions: []LayoutTransition) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
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
    all_sync_before, all_sync_after: D3D12_BARRIER_SYNC; 
    all_access_before, all_access_after: D3D12_BARRIER_ACCESS; 

    for 0..layout_transitions.count - 1 {
      t := *layout_transitions[it];
      b := *barriers[it];

      b.LayoutBefore = layout_to_d3d12_layout(t.before);
      b.LayoutAfter = layout_to_d3d12_layout(t.after);
      b.SyncBefore, b.AccessBefore = keep_compatible_bits(b.LayoutBefore, global_barrier.SyncBefore, global_barrier.AccessBefore);
      b.SyncAfter, b.AccessAfter = keep_compatible_bits(b.LayoutAfter, global_barrier.SyncAfter, global_barrier.AccessAfter);
      b.pResource = get_object(d3d12_device.textures, t.texture).handle;
      b.Subresources.IndexOrFirstMipLevel = 0xFFFFFFFF;

      all_sync_before |= b.SyncBefore;
      all_sync_after |= b.SyncAfter;
      all_access_before |= b.AccessBefore;
      all_access_after |= b.AccessAfter;
    }

    // Remove target bits from global barrier to avoid false positives that
    // .Raster turned into -> .RENDER_TARGET & .DEPTH_WRITE, but there was no depth layout transition.
    all_sync_before &= .RENDER_TARGET | .DEPTH_STENCIL;
    all_sync_after &= .RENDER_TARGET | .DEPTH_STENCIL;
    all_access_before &= .RENDER_TARGET | .DEPTH_STENCIL_WRITE | .DEPTH_STENCIL_READ;
    all_access_after &= .RENDER_TARGET | .DEPTH_STENCIL_WRITE | .DEPTH_STENCIL_READ;

    global_barrier.SyncBefore &= ~all_sync_before;
    global_barrier.SyncAfter &= ~all_sync_after;
    global_barrier.AccessBefore &= ~all_access_before;
    global_barrier.AccessAfter &= ~all_access_after;

    global_barrier.SyncBefore &= ~(.RENDER_TARGET | .DEPTH_STENCIL);
    global_barrier.SyncAfter &= ~(.RENDER_TARGET | .DEPTH_STENCIL);
    global_barrier.AccessBefore &= ~(.RENDER_TARGET | .DEPTH_STENCIL_WRITE | .DEPTH_STENCIL_READ);
    global_barrier.AccessAfter &= ~(.RENDER_TARGET | .DEPTH_STENCIL_WRITE | .DEPTH_STENCIL_READ);

    if global_barrier.AccessBefore == .COMMON {
      global_barrier.AccessBefore = .NO_ACCESS;
    }
    if global_barrier.AccessAfter == .COMMON {
      global_barrier.AccessAfter = .NO_ACCESS;
    }
  }

  ID3D12GraphicsCommandList7_Barrier(d3d12_cmd.cmd, group_count, *groups[0]);
}

clear_render_target :: (cmd: Cmd, rt: Texture, clear_color: ClearColor) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  d3d12_rt := get_object(d3d12_device.textures, rt);

  handle := ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(d3d12_cmd.rtv_heap);
  ID3D12Device_CreateRenderTargetView(d3d12_device.device, d3d12_rt.handle, null, handle);
  d3d12_clear_color := float.[clear_color.r, clear_color.g, clear_color.b, clear_color.a];

  ID3D12GraphicsCommandList_ClearRenderTargetView(d3d12_cmd.cmd, handle, *d3d12_clear_color, 0, null);
}

clear_depth_stencil_target :: (cmd: Cmd, ds: Texture, clear_value: ClearDepthStencil) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  d3d12_ds := get_object(d3d12_device.textures, ds);

  handle := ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(d3d12_cmd.dsv_heap);
  ID3D12Device_CreateDepthStencilView(d3d12_device.device, d3d12_ds.handle, null, handle);

  ID3D12GraphicsCommandList_ClearDepthStencilView(d3d12_cmd.cmd, handle, .DEPTH | .STENCIL, clear_value.depth, clear_value.stencil, 0, null);
}

set_targets :: (cmd: Cmd, color_targets: []Texture, depth_target: Texture) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  rtv_head := ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(d3d12_cmd.rtv_heap);
  rtv_handle_ptr :*D3D12_CPU_DESCRIPTOR_HANDLE;

  if color_targets {
    rtv_handle_ptr = *rtv_head;

    for color_targets {
      handle := D3D12_CPU_DESCRIPTOR_HANDLE.{ ptr = rtv_head.ptr + cast(u64) it_index * d3d12_device.rtv_descriptor_size };
      d3d12_color_target := get_object(d3d12_device.textures, it);
      ID3D12Device_CreateRenderTargetView(d3d12_device.device, d3d12_color_target.handle, null, handle);
    }
  }

  dsv_handle_ptr :*D3D12_CPU_DESCRIPTOR_HANDLE;

  if depth_target != xx null_handle {
    handle := ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(d3d12_cmd.dsv_heap);
    d3d12_depth_target := get_object(d3d12_device.textures, depth_target);
    ID3D12Device_CreateDepthStencilView(d3d12_device.device, d3d12_depth_target.handle, null, handle);
    dsv_handle_ptr = *handle;
  }

  ID3D12GraphicsCommandList_OMSetRenderTargets(d3d12_cmd.cmd, xx color_targets.count, rtv_handle_ptr, .TRUE, dsv_handle_ptr);
}

set_root_signature :: (cmd: Cmd, root_siganture: RootSignature) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  handle: *ID3D12RootSignature = get_object(d3d12_device.root_sigantures, root_siganture).handle;
  ID3D12GraphicsCommandList_SetGraphicsRootSignature(d3d12_cmd.cmd, handle);
  ID3D12GraphicsCommandList_SetComputeRootSignature(d3d12_cmd.cmd, handle);
}

set_pipeline :: (cmd: Cmd, pipeline: Pipeline) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  ID3D12GraphicsCommandList_SetPipelineState(d3d12_cmd.cmd, get_object(d3d12_device.pipelines, pipeline).handle);
}

set_index_buffer :: (cmd: Cmd, buffer: Buffer, index_type: IndexType, offset: u64) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  d3d12_buffer := get_object(d3d12_device.buffers, buffer);
  view := D3D12_INDEX_BUFFER_VIEW.{
    BufferLocation = ID3D12Resource_GetGPUVirtualAddress(d3d12_buffer.handle) + offset,
    SizeInBytes = xx d3d12_buffer.size,
    Format = ifx index_type == .r16_uint then .R16_UINT else .R32_UINT,
  };
  ID3D12GraphicsCommandList_IASetIndexBuffer(d3d12_cmd.cmd, *view);
}

set_vertex_buffers :: (cmd: Cmd, first_binding: u32, bindings: []VertexBufferBinding) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  auto_release_temp();
  views := NewArray(bindings.count, D3D12_VERTEX_BUFFER_VIEW, initialized = false);

  for bindings {
    d3d12_buffer := get_object(d3d12_device.buffers, it.buffer);
    views[it_index] = D3D12_VERTEX_BUFFER_VIEW.{
      BufferLocation = ID3D12Resource_GetGPUVirtualAddress(d3d12_buffer.handle) + it.offset,
      SizeInBytes = xx d3d12_buffer.size,
      StrideInBytes = it.stride,
    };
  }

  ID3D12GraphicsCommandList_IASetVertexBuffers(d3d12_cmd.cmd, first_binding, xx views.count, views.data);
}

draw :: (cmd: Cmd, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  ID3D12GraphicsCommandList_DrawInstanced(d3d12_cmd.cmd, vertex_count, instance_count, first_vertex, first_instance);
}

draw_indexed :: (cmd: Cmd, index_count: u32, instance_count: u32, first_index: u32, vertex_offset: s32, first_instance: u32) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  ID3D12GraphicsCommandList_DrawIndexedInstanced(d3d12_cmd.cmd, index_count, instance_count, first_index, vertex_offset, first_instance);
}

copy :: (cmd: Cmd, copy: BufferCopy) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  d3d12_dst := get_object(d3d12_device.buffers, copy.dst).handle;
  d3d12_src := get_object(d3d12_device.buffers, copy.src).handle;

  ID3D12GraphicsCommandList_CopyBufferRegion(d3d12_cmd.cmd, d3d12_dst, copy.dst_offset, d3d12_src, copy.src_offset, copy.size);
}

copy :: (cmd: Cmd, copy: TextureCopy) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  d3d12_dst := get_object(d3d12_device.textures, copy.dst).handle;
  d3d12_src := get_object(d3d12_device.textures, copy.src).handle;
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
    d3d12_cmd.cmd, *dst_location, copy.dst_x, copy.dst_y, 0, *src_location, *src_box);
}

copy :: (cmd: Cmd, copy: BufferToTextureCopy) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  d3d12_dst := get_object(d3d12_device.textures, copy.texture);
  d3d12_src := get_object(d3d12_device.buffers, copy.buffer);
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
    d3d12_cmd.cmd, *dst_location, copy.texture_x, copy.texture_y, 0, *src_location, null);
}

copy :: (cmd: Cmd, copy: TextureToBufferCopy) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  assert(false);
}

set_descriptor_heaps :: (cmd: Cmd, heaps: []DescriptorHeap) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  auto_release_temp();
  d3d12_heaps := NewArray(heaps.count, *ID3D12DescriptorHeap,, allocator=temp);

  for heaps {
    d3d12_heaps[it_index] = get_object(d3d12_device.descriptor_heaps, it).handle;
  }

  ID3D12GraphicsCommandList_SetDescriptorHeaps(d3d12_cmd.cmd, xx heaps.count, d3d12_heaps.data);
}

set_root_constants :: (cmd: Cmd, root_index: u32, constants: *void, size: u64) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  assert(size % size_of(u32) == 0);
  ID3D12GraphicsCommandList_SetGraphicsRoot32BitConstants(d3d12_cmd.cmd, root_index, xx (size / size_of(u32)), constants, 0);
  ID3D12GraphicsCommandList_SetComputeRoot32BitConstants(d3d12_cmd.cmd, root_index, xx (size / size_of(u32)), constants, 0);
}

set_root_constants :: (cmd: Cmd, root_index: u32, constants: $T) #expand {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  set_root_constants(cmd, root_index, *constants, size_of(T));
}

set_root_cbv :: (cmd: Cmd, root_index: u32, buffer: Buffer, offset: u64 = 0) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  addr := ID3D12Resource_GetGPUVirtualAddress(get_object(d3d12_device.buffers, buffer).handle);
  addr += offset;
  ID3D12GraphicsCommandList_SetGraphicsRootConstantBufferView(d3d12_cmd.cmd, root_index, addr);
  ID3D12GraphicsCommandList_SetComputeRootConstantBufferView(d3d12_cmd.cmd, root_index, addr);
}

set_root_srv :: (cmd: Cmd, root_index: u32, buffer: Buffer, offset: u64 = 0) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  addr := ID3D12Resource_GetGPUVirtualAddress(get_object(d3d12_device.buffers, buffer).handle);
  addr += offset;
  ID3D12GraphicsCommandList_SetGraphicsRootShaderResourceView(d3d12_cmd.cmd, root_index, addr);
  ID3D12GraphicsCommandList_SetComputeRootShaderResourceView(d3d12_cmd.cmd, root_index, addr);
}

set_root_uav :: (cmd: Cmd, root_index: u32, buffer: Buffer, offset: u64 = 0) {
  d3d12_cmd: *CmdD3D12 = xx cmd;
  d3d12_device: *DeviceD3D12 = xx d3d12_cmd.device;
  addr := ID3D12Resource_GetGPUVirtualAddress(get_object(d3d12_device.buffers, buffer).handle);
  addr += offset;
  ID3D12GraphicsCommandList_SetGraphicsRootUnorderedAccessView(d3d12_cmd.cmd, root_index, addr);
  ID3D12GraphicsCommandList_SetComputeRootUnorderedAccessView(d3d12_cmd.cmd, root_index, addr);
}

submit :: (device: Device, cmd: Cmd) {
  d3d12_device: *DeviceD3D12 = xx device;
  d3d12_cmd: *CmdD3D12 = xx cmd;
  ID3D12CommandQueue_ExecuteCommandLists(d3d12_device.queue, 1, xx *d3d12_cmd.cmd);
}

wait_for_completion :: (device: Device) {
  d3d12_device: *DeviceD3D12 = xx device;
  value := next_value(*d3d12_device.wait_idle_fence);
  signal(device, *d3d12_device.wait_idle_fence, value);
  wait_for_fence(device, *d3d12_device.wait_idle_fence, value);
}

wait_for_fence :: (device: Device, fence: *Fence, value: u64) {
  d3d12_device: *DeviceD3D12 = xx device;
  last_completed_value: u64 = ID3D12Fence_GetCompletedValue(fence.fence);

  if (last_completed_value < value) {
    ID3D12Fence_SetEventOnCompletion(fence.fence, value, fence.event);
    WaitForSingleObject(fence.event, WIN_TIMEOUT_INFINITE);
  }
}

signal :: (device: Device, fence: *Fence, value: u64) {
  d3d12_device: *DeviceD3D12 = xx device;
  ID3D12CommandQueue_Signal(d3d12_device.queue, fence.fence, value);
}

create_fence :: (device: Device) -> Fence, bool {
  d3d12_device: *DeviceD3D12 = xx device;
  fence: *ID3D12Fence;
  result := ID3D12Device_CreateFence(d3d12_device.device, 0, .NONE, *uid(ID3D12Fence_UUID), xx *fence);

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

destroy :: (device: Device, fence: *Fence) {
  d3d12_device: *DeviceD3D12 = xx device;
  release(fence.fence);
}

next_value :: (fence: *Fence) -> u64 {
  fence.value = fence.value + 1;

  return fence.value;
}

create_shader :: (device: Device, using desc: ShaderDesc) -> Shader, bool {
  d3d12_device: *DeviceD3D12 = xx device;
  return add_object(*d3d12_device.shaders, .{ code = .{ code.data, xx code.count } }), true;
}

create_root_signature :: (device: Device, shader: Shader) -> RootSignature, bool {
  d3d12_device: *DeviceD3D12 = xx device;
  root_siganture: *ID3D12RootSignature;
  d3d12_shader := get_object(d3d12_device.shaders, shader);
  result := ID3D12Device_CreateRootSignature(d3d12_device.device, 0, d3d12_shader.code.pShaderBytecode, d3d12_shader.code.BytecodeLength, *uid(ID3D12RootSignature_UUID), xx *root_siganture);
  rif_handle(result, "Unable to create root signature");

  return add_object(*d3d12_device.root_sigantures, .{ handle = root_siganture, }), true;
}

create_compute_pipeline :: (device: Device, using desc: ComputePipelineDesc) -> Pipeline, bool {
  d3d12_device: *DeviceD3D12 = xx device;
  d3d12_shader := get_object(d3d12_device.shaders, cs);
  d3d12_desc := D3D12_COMPUTE_PIPELINE_STATE_DESC.{ CS = d3d12_shader.code, };
  pipeline: *ID3D12PipelineState;
  ID3D12Device_CreateComputePipelineState(d3d12_device.device, *d3d12_desc, *uid(ID3D12PipelineState_UUID), xx *pipeline);

  return add_object(*d3d12_device.pipelines, .{ handle = pipeline }), true;
}

semantic_to_wide_string :: inline (semantic: Semantic) -> *u8 {
  // TODO: Use #insert #run to generate and insert []u8 literal?
  if #complete semantic == {
    case .Position;
      return "SV_Position";
    case .Normal;
      return "Normal";
    case .Tangent;
      return "Tangent";
    case .Texcoord0; #through;
    case .Texcoord1; #through;
    case .Texcoord2; #through;
    case .Texcoord3; #through;
    case .Texcoord4; #through;
    case .Texcoord5; #through;
    case .Texcoord6; #through;
    case .Texcoord7;
      return "Texcoord";
    case .Color0; #through;
    case .Color1; #through;
    case .Color2; #through;
    case .Color3;
      return "Color";
    case .Attribute0;
      return "Attribute";
  }

  return "Attribute";
}

semantic_to_index :: inline (semantic: Semantic) -> u32 {
  if #complete semantic == {
    case .Position; #through;
    case .Normal; #through;
    case .Tangent; #through;
    case .Attribute0;
      return 0;
    case .Texcoord0; #through;
    case .Texcoord1; #through;
    case .Texcoord2; #through;
    case .Texcoord3; #through;
    case .Texcoord4; #through;
    case .Texcoord5; #through;
    case .Texcoord6; #through;
    case .Texcoord7;
      return xx (semantic - .Texcoord0);
    case .Color0; #through;
    case .Color1; #through;
    case .Color2; #through;
    case .Color3;
      return xx (semantic - .Color0);
  }

  return xx (semantic - .Attribute0);
}

comparison_func_to_dx12 :: inline (func: ComparisonFunc) -> D3D12_COMPARISON_FUNC {
  if #complete func == {
    case .None; return .NONE;
    case .Never; return .NEVER;
    case .Less; return .LESS;
    case .Equal; return .EQUAL;
    case .LessEqual; return .LESS_EQUAL;
    case .Greater; return .GREATER;
    case .NotEqual; return .NOT_EQUAL;
    case .GreaterEqual; return .GREATER_EQUAL;
    case .Always; return .ALWAYS;
  }
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

create_graphics_pipeline :: (device: Device, using desc: GraphicsPipelineDesc) -> Pipeline, bool {
  d3d12_device: *DeviceD3D12 = xx device;
  auto_release_temp();
  stream_head : *u8 = alloc(MAX_PIPELINE_STATE_STREAM_SIZE,, allocator=temp);
  stream_tail := stream_head;

  write_stream :: (subobject: $T) #expand {
    (cast(*T) stream_tail).* = subobject;
    stream_tail += align_pot(size_of(T), size_of(*void));
    assert((stream_tail - stream_head) <= MAX_PIPELINE_STATE_STREAM_SIZE);
  }

  if root_siganture != xx null_handle {
    d3d12_root_signature := get_object(d3d12_device.root_sigantures, root_siganture);
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.ROOT_SIGNATURE; root_signature: *ID3D12RootSignature; };
    so.root_signature = d3d12_root_signature.handle;

    write_stream(so);
  }

  if vs != xx null_handle {
    d3d12_vs := get_object(d3d12_device.shaders, vs);
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.VS; vs: D3D12_SHADER_BYTECODE; };
    so.vs = d3d12_vs.code;

    write_stream(so);
  }

  if ps != xx null_handle {
    d3d12_ps := get_object(d3d12_device.shaders, ps);
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

  if depth_stencil_target_format {
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.DEPTH_STENCIL_FORMAT; format: DXGI_FORMAT; };
    so.format = format_to_dxgi(depth_stencil_target_format);

    write_stream(so);
  }

  {
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.PRIMITIVE_TOPOLOGY; topology: D3D12_PRIMITIVE_TOPOLOGY_TYPE; };
    so.topology = .TRIANGLE;

    write_stream(so);
  }

  if vertex_desc
  {
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.INPUT_LAYOUT; input_layout: D3D12_INPUT_LAYOUT_DESC; };
    input_elements := NewArray(vertex_desc.count, D3D12_INPUT_ELEMENT_DESC,, temp);

    for vertex_desc {
      input_elements[it_index] = .{
        SemanticName = semantic_to_wide_string(it.semantic),
        SemanticIndex = semantic_to_index(it.semantic),
        Format = format_to_dxgi(it.format),
        AlignedByteOffset = ifx it.offset == AppendAttribute then D3D12_APPEND_ALIGNED_ELEMENT else it.offset,
        InputSlot = it.binding,
      };
    }

    so.input_layout = .{
      pInputElementDescs = input_elements.data,
      NumElements = xx vertex_desc.count,
    };

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

  {
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.DEPTH_STENCIL2; depth_stencil: D3D12_DEPTH_STENCIL_DESC2; };
    so.depth_stencil = .{
      DepthEnable = xx depth_stencil_desc.enable,
      DepthWriteMask = .ALL,
      DepthFunc = comparison_func_to_dx12(depth_stencil_desc.func),
    };

    write_stream(so);
  }

  pipeline_stream := D3D12_PIPELINE_STATE_STREAM_DESC.{
    SizeInBytes = xx (stream_tail - stream_head),
    pPipelineStateSubobjectStream = stream_head,
  };

  pipeline: *ID3D12PipelineState;


  result := ID3D12Device2_CreatePipelineState(d3d12_device.device, *pipeline_stream, *uid(ID3D12PipelineState_UUID), xx *pipeline);
  rif_handle(result, "Unable to create pipeline");

  return add_object(*d3d12_device.pipelines, .{ handle = pipeline, }), true;
}

destroy :: (device: Device, pipeline: Pipeline) {
  d3d12_device: *DeviceD3D12 = xx device;
  d3d12_pipeline, removed := remove_object(*d3d12_device.pipelines, pipeline);
  assert(removed);

  release(d3d12_pipeline.handle);
}

create_memory_heap :: (device: Device, memory_heap_desc: MemoryHeapDesc) -> MemoryHeap, bool {
  d3d12_device: *DeviceD3D12 = xx device;
  handle: *ID3D12Heap;

  d3d12_desc := D3D12_HEAP_DESC.{
    SizeInBytes = memory_heap_desc.size,
    Properties = .{ Type = memory_heap_desc.heap_type, },
    // MSAA needs higher alignment value.
    Alignment = D3D12_DEFAULT_RESOURCE_PLACEMENT_ALIGNMENT,
    Flags = .ALLOW_ALL_BUFFERS_AND_TEXTURES,
  };

  result := ID3D12Device_CreateHeap(d3d12_device.device, *d3d12_desc, *uid(ID3D12Heap_UUID), xx *handle);
  rif_handle(result, "Unable to create memory heap");

  return add_object(*d3d12_device.memory_heaps, .{ handle = handle }), true;
}

destroy :: (device: Device, memory_heap: MemoryHeap) {
  d3d12_device: *DeviceD3D12 = xx device;
  d3d12_memory_heap, removed := remove_object(*d3d12_device.memory_heaps, memory_heap);
  assert(removed);

  release(d3d12_memory_heap.handle);
}

get_texture_allocation_requirements :: (device: Device, texture_desc: TextureDesc) -> AllocationRequirements {
  d3d12_device: *DeviceD3D12 = xx device;
  resource_desc := texture_desc_to_d3d12(texture_desc);

  allocation_info: D3D12_RESOURCE_ALLOCATION_INFO1;
  ID3D12Device8_GetResourceAllocationInfo2(d3d12_device.device, 0, 1, *resource_desc, *allocation_info);

  return .{ alignment = allocation_info.Alignment, size = allocation_info.SizeInBytes };
}

get_buffer_allocation_requirements :: (device: Device, buffer_desc: BufferDesc) -> AllocationRequirements {
  d3d12_device: *DeviceD3D12 = xx device;
  resource_desc := buffer_desc_to_d3d12(buffer_desc);

  allocation_info: D3D12_RESOURCE_ALLOCATION_INFO1;
  ID3D12Device8_GetResourceAllocationInfo2(d3d12_device.device, 0, 1, *resource_desc, *allocation_info);

  return .{ alignment = allocation_info.Alignment, size = allocation_info.SizeInBytes };
}

texture_desc_to_d3d12 :: inline (texture_desc: TextureDesc) -> D3D12_RESOURCE_DESC1 {
  usage := texture_usage_to_d3d12(texture_desc.usage);
  resource_desc := D3D12_RESOURCE_DESC1.{
    Dimension = .TEXTURE2D,
    Width = texture_desc.width,
    Height = texture_desc.height,
    DepthOrArraySize = 1,
    MipLevels = 1,
    Format = format_to_dxgi(texture_desc.format),
    SampleDesc = .{ Count = 1, Quality = 0 },
    Layout = .UNKNOWN,
    Flags = usage,
  };

  return resource_desc;
}

texture_usage_to_d3d12 :: inline (usage: TextureUsage) -> D3D12_RESOURCE_FLAGS {
  flags: D3D12_RESOURCE_FLAGS;

  if usage & .UnorderedAccess {
    flags |= .ALLOW_UNORDERED_ACCESS;
  }

  if usage & .RenderTarget {
    flags |= .ALLOW_RENDER_TARGET;
  }

  if usage & .DepthStencil {
    flags |= .ALLOW_DEPTH_STENCIL;
  }

  return flags;
}

create_texture :: (device: Device, memory: Memory, texture_desc: TextureDesc) -> Texture, bool {
  d3d12_device: *DeviceD3D12 = xx device;
  resource_desc := texture_desc_to_d3d12(texture_desc);
  clear_value := D3D12_CLEAR_VALUE.{
    Format = format_to_dxgi(texture_desc.format),
  };

  if resource_desc.Flags & .ALLOW_RENDER_TARGET {
    clear_value.Color.data[0] = texture_desc.clear_color.r;
    clear_value.Color.data[1] = texture_desc.clear_color.g;
    clear_value.Color.data[2] = texture_desc.clear_color.b;
    clear_value.Color.data[3] = texture_desc.clear_color.a;
  } else if resource_desc.Flags & .ALLOW_DEPTH_STENCIL {
    clear_value.DepthStencil.Depth = texture_desc.clear_depth_stencil.depth;
    clear_value.DepthStencil.Stencil = texture_desc.clear_depth_stencil.stencil;
  }
  need_clear_value := resource_desc.Flags & (.ALLOW_RENDER_TARGET | .ALLOW_DEPTH_STENCIL);
  d3d12_heap := get_object(d3d12_device.memory_heaps, memory.heap).handle;

  resource: *ID3D12Resource;
  result := ID3D12Device10_CreatePlacedResource2(
    d3d12_device.device,
    d3d12_heap,
    memory.offset,
    *resource_desc,
    .UNDEFINED,
    ifx need_clear_value then *clear_value else null,
    0,
    null,
    *uid(ID3D12Resource_UUID),
    xx *resource
  );
  rif_handle(result, "Unable to create texture.");

  name_object(resource, texture_desc.name);

  return add_object(*d3d12_device.textures, .{
    format = texture_desc.format,
    mip_count = 1,
    layer_count = 1,
    width = texture_desc.width,
    height = texture_desc.height,
    memory = memory,
    handle = resource,
  }), true;
}

destroy :: (device: Device, texture: Texture) {
  d3d12_device: *DeviceD3D12 = xx device;
  d3d12_texture, removed := remove_object(*d3d12_device.textures, texture);
  assert(removed);

  release(d3d12_texture.handle);
}

buffer_desc_to_d3d12 :: (buffer_desc: BufferDesc) -> D3D12_RESOURCE_DESC1 {
  resource_desc := D3D12_RESOURCE_DESC1.{
    Dimension = .BUFFER,
    Width = buffer_desc.size,
    Height = 1,
    DepthOrArraySize = 1,
    MipLevels = 1,
    SampleDesc = .{ Count = 1, Quality = 0 },
    Format = .UNKNOWN,
    Layout = .ROW_MAJOR,
    Flags = buffer_usage_to_d3d12(buffer_desc.usage),
  };

  return resource_desc;
}

// TODO: move all helpers under #scope_file
buffer_usage_to_d3d12 :: inline (usage: BufferUsage) -> D3D12_RESOURCE_FLAGS {
  flags: D3D12_RESOURCE_FLAGS;

  if !(usage & .ShaderResource) {
    flags |= .DENY_SHADER_RESOURCE;
  }

  if usage & .UnorderedAccess {
    flags |= .ALLOW_UNORDERED_ACCESS;
  }

  return flags;
}

create_buffer :: (device: Device, memory: Memory, buffer_desc: BufferDesc) -> Buffer, bool {
  d3d12_device: *DeviceD3D12 = xx device;
  resource_desc := buffer_desc_to_d3d12(buffer_desc);
  d3d12_heap := get_object(d3d12_device.memory_heaps, memory.heap).handle;

  resource: *ID3D12Resource;
  result := ID3D12Device10_CreatePlacedResource2(
    d3d12_device.device,
    d3d12_heap,
    memory.offset,
    *resource_desc,
    .UNDEFINED,
    null,
    0,
    null,
    *uid(ID3D12Resource_UUID),
    xx *resource
  );
  rif_handle(result, "Unable to create buffer.");

  name_object(resource, buffer_desc.name);

  return add_object(*d3d12_device.buffers, .{ memory = memory, size = buffer_desc.size, handle = resource, }), true;
}

map :: (device: Device, buffer: Buffer) -> *void {
  d3d12_device: *DeviceD3D12 = xx device;
  d3d12_buffer := get_object(d3d12_device.buffers, buffer);
  ID3D12Resource_Map(d3d12_buffer.handle, 0, null, *d3d12_buffer.mapped_ptr);
  set_object(d3d12_device.buffers, buffer, d3d12_buffer);

  return d3d12_buffer.mapped_ptr;
}

unmap :: (device: Device, buffer: Buffer) -> *void {
  d3d12_device: *DeviceD3D12 = xx device;
  d3d12_buffer := get_object(d3d12_device.buffers, buffer);
  ID3D12Resource_Unmap(d3d12_buffer.handle, 0, null);
  d3d12_buffer.mapped_ptr = null;
  set_object(d3d12_device.d3d12_device.buffers, buffer, d3d12_buffer);
}

get_mapped_ptr :: (device: Device, buffer: Buffer) -> *void {
  d3d12_device: *DeviceD3D12 = xx device;
  d3d12_buffer := get_object(d3d12_device.buffers, buffer);

  return d3d12_buffer.mapped_ptr;
}

destroy :: (device: Device, buffer: Buffer) {
  d3d12_device: *DeviceD3D12 = xx device;
  d3d12_buffer, removed := remove_object(*d3d12_device.buffers, buffer);
  assert(removed);

  release(d3d12_buffer.handle);
}

create_descriptor_heap :: (device: Device, descriptor_heap_desc: DescriptorHeapDesc) -> DescriptorHeap, bool {
  d3d12_device: *DeviceD3D12 = xx device;
  heap_desc := D3D12_DESCRIPTOR_HEAP_DESC.{
    Type = descriptor_heap_type_to_d3d12(descriptor_heap_desc.type),
    NumDescriptors = descriptor_heap_desc.descriptor_count,
    Flags = .SHADER_VISIBLE,
    NodeMask = 0,
  };
  heap: *ID3D12DescriptorHeap;
  result := ID3D12Device_CreateDescriptorHeap(d3d12_device.device, *heap_desc, *uid(ID3D12DescriptorHeap_UUID), xx *heap);
  rif_handle(result, "Unable to create descriptor heap");

  return add_object(*d3d12_device.descriptor_heaps, .{ handle = heap, }), false;
}

destroy :: (device: Device, descriptor_heap: DescriptorHeap) {
  d3d12_device: *DeviceD3D12 = xx device;
  d3d12_heap, removed := remove_object(*d3d12_device.descriptor_heaps, descriptor_heap);
  assert(removed);

  release(d3d12_heap.handle);
}

descriptor_heap_type_to_d3d12 :: (descriptor_heap_type: DescriptorHeapType) -> D3D12_DESCRIPTOR_HEAP_TYPE {
  if #complete descriptor_heap_type == {
    case .Resource; return .CBV_SRV_UAV;
    case .Sampler; return .SAMPLER;
  }
}

swizzle_shift :: D3D12_SHADER_COMPONENT_MAPPING_SHIFT;
swizzle_channels :: (r: u32, g: u32, b: u32, a: u32) -> u32 #expand {
  return (r << (swizzle_shift * 0)) | (g << (swizzle_shift * 1)) | (b << (swizzle_shift * 2)) | (a << (swizzle_shift * 3)) | D3D12_SHADER_COMPONENT_MAPPING_ALWAYS_SET_BIT_AVOIDING_ZEROMEM_MISTAKES;
}

ConstantBufferAlignment :: D3D12_CONSTANT_BUFFER_DATA_PLACEMENT_ALIGNMENT;

update_descriptors :: (device: Device, heap: DescriptorHeap, descriptors: []Descriptor) {
  d3d12_device: *DeviceD3D12 = xx device;
  d3d12_heap := get_object(d3d12_device.descriptor_heaps, heap);
  heap_start := ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(d3d12_heap.handle);

  for d: descriptors {
    using d;
    descriptor_handle := D3D12_CPU_DESCRIPTOR_HANDLE.{ ptr = heap_start.ptr + d3d12_device.cbv_srv_uav_descriptor_size * heap_offset };

    if #complete type == {
      case .Undefined; assert(false);
      case .ConstantBuffer; #through;
      case .ShaderResourceBuffer; #through;
      case .UnorderedAccessBuffer;
        d3d12_buffer := get_object(d3d12_device.buffers, xx handle);
        addr := ID3D12Resource_GetGPUVirtualAddress(d3d12_buffer.handle) + buffer.offset;
        size := ifx buffer.size == RemainingSize then d3d12_buffer.size - buffer.offset else buffer.size;

        if type == {
          case .ConstantBuffer;
            size = align_pot(size, ConstantBufferAlignment);
            view := D3D12_CONSTANT_BUFFER_VIEW_DESC.{ BufferLocation = addr, SizeInBytes = xx size, };
            ID3D12Device_CreateConstantBufferView(d3d12_device.device, *view, descriptor_handle);
          case .ShaderResourceBuffer;
            view := D3D12_SHADER_RESOURCE_VIEW_DESC.{
              Format = .R32_TYPELESS,
              ViewDimension = .BUFFER,
              Shader4ComponentMapping = swizzle_channels(0, 1, 2, 3),
              Buffer = .{ NumElements = xx (size / size_of(u32)), Flags = .RAW, },
            };
            ID3D12Device_CreateShaderResourceView(d3d12_device.device, d3d12_buffer.handle, *view, descriptor_handle);
          case .UnorderedAccessBuffer;
            view := D3D12_UNORDERED_ACCESS_VIEW_DESC.{
              Format = .R32_TYPELESS,
              ViewDimension = .BUFFER,
              Buffer = .{ NumElements = xx (size / size_of(u32)), Flags = .RAW, },
            };
            ID3D12Device_CreateUnorderedAccessView(d3d12_device.device, d3d12_buffer.handle, null, *view, descriptor_handle);
        }
      case .ShaderResourceTexture; #through;
      case .UnorderedAccessTexture;
        d3d12_texture := get_object(d3d12_device.textures, xx handle);

        if type == {
          case .ShaderResourceTexture;
            view := D3D12_SHADER_RESOURCE_VIEW_DESC.{
              Format = format_to_dxgi(d3d12_texture.format),
              ViewDimension = .TEXTURE2D,
              Shader4ComponentMapping = swizzle_channels(0, 1, 2, 3),
              Texture2D = .{
                MostDetailedMip = texture.mip_index,
                MipLevels = ifx texture.mip_count == RemainingMips then cast(u32) 0xFFFFFFFF else texture.mip_count,
              },
            };
            ID3D12Device_CreateShaderResourceView(d3d12_device.device, d3d12_texture.handle, *view, descriptor_handle);
          case .UnorderedAccessTexture;
            view := D3D12_UNORDERED_ACCESS_VIEW_DESC.{
              Format = format_to_dxgi(d3d12_texture.format),
              ViewDimension = .TEXTURE2D,
              Texture2D = .{ MipSlice = texture.mip_index, },
            };
            ID3D12Device_CreateUnorderedAccessView(d3d12_device.device, d3d12_texture.handle, null, *view, descriptor_handle);
        }
      case .Sampler;
        descriptor_handle = D3D12_CPU_DESCRIPTOR_HANDLE.{ ptr = heap_start.ptr + d3d12_device.sampler_descriptor_size * heap_offset };
        d3d12_sampler := get_object(d3d12_device.samplers, xx handle);
        ID3D12Device_CreateSampler(d3d12_device.device, *d3d12_sampler.desc, descriptor_handle);
    }
  }
}

subresource_index :: inline (using subresource: TextureSubresource, mip_count: u16) -> u32 {
  return mip_index + (array_index * mip_count);
}

sampler_addressing_to_d3d12 :: inline (address: SamplerAddressMode, address_u: D3D12_TEXTURE_ADDRESS_MODE) -> D3D12_TEXTURE_ADDRESS_MODE {
  if #complete address == {
    case .SameAsUOrRepeat; return address_u;
    case .Repeat; return .WRAP;
    case .MirroredRepeat; return .MIRROR;
    case .Clamp; return .CLAMP;
    case .Border; return .BORDER;
    case .MirroredClamp; return .MIRROR_ONCE;
  }
}

create_sampler :: (device: Device, desc: SamplerDesc) -> Sampler, bool {
  d3d12_device: *DeviceD3D12 = xx device;
  u := sampler_addressing_to_d3d12(desc.address_u, .WRAP);
  d3d12_desc := D3D12_SAMPLER_DESC.{
    Filter = filters_to_d3d12(desc.min_filter, desc.mag_filter, desc.mip_filter, desc.max_anisotropy),
    AddressU = u,
    AddressV = sampler_addressing_to_d3d12(desc.address_v, u),
    AddressW = sampler_addressing_to_d3d12(desc.address_w, u),
    MaxAnisotropy = desc.max_anisotropy,
  };
  return add_object(*d3d12_device.samplers, .{ desc = d3d12_desc }), true;
}

name_object :: inline (obj: *ID3D12Object, name: string) {
  auto_release_temp();
  if (name) {
    wide_name := utf8_to_wide(name,, temp);
    ID3D12Object_SetName(obj, xx wide_name);
  }
}

filters_to_d3d12 :: inline (min: Filter, mag: Filter, mip: Filter, max_anisotropy: u32) -> D3D12_FILTER {
  if max_anisotropy > 1 {
    assert(min == .Linear && mag == .Linear);
    return ifx mip == .Linear then .ANISOTROPIC else .MIN_MAG_ANISOTROPIC_MIP_POINT;
  }

  if #complete min == {
    case .Linear;
      if #complete mag == {
        case .Linear;
          if #complete mip == {
            case .Linear; return .MIN_MAG_MIP_LINEAR;
            case .Nearest; return .MIN_MAG_LINEAR_MIP_POINT;
          }
        case .Nearest;
          if #complete mip == {
            case .Linear; return .MIN_LINEAR_MAG_POINT_MIP_LINEAR;
            case .Nearest; return .MIN_LINEAR_MAG_MIP_POINT;
          }
      }
    case .Nearest;
      if #complete mag == {
        case .Linear;
          if #complete mip == {
            case .Linear; return .MIN_POINT_MAG_MIP_LINEAR;
            case .Nearest; return .MIN_POINT_MAG_LINEAR_MIP_POINT;
          }
        case .Nearest;
          if #complete mip == {
            case .Linear; return .MIN_MAG_POINT_MIP_LINEAR;
            case .Nearest; return .MIN_MAG_MIP_POINT;
          }
      }
  }
}

// TODO: replace d3d12 enum and flags with own.
//#scope_module
// TODO: replace d3d12 bindins with own bindings generated from agility sdk headers
// and use module parameters insteadf of program parameters
//#import "d3d12"()(INCLUDE_DEBUG_BINDINGS = true);

#import "dxgi";
#import "d3d12";
#import "Windows";
#import "object-pool";
#import "allocators";
#import "Basic";
#import "Windows_Utf8";

#load "common.jai";
