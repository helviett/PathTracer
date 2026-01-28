#import "Basic";
#import "Windows";
#import "dxgi";
#import "d3d12"()(INCLUDE_DEBUG_BINDINGS = true);
#import "File";
#import "String";

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

  compute_shader := load_shader_binary("compute.dxil");
  compute_pipeline := create_compute_pipeline(*device, .{ cs = *compute_shader, });

  triangle_vs := load_shader_binary("triangle_vs.dxil");
  triangle_ps := load_shader_binary("triangle_ps.dxil");

  triangle_root_signature := create_root_signature(*device, *triangle_vs);

  triangle_pipeline := create_graphics_pipeline(*device, .{
    root_siganture = *triangle_root_signature,
    vs = *triangle_vs,
    ps = *triangle_ps,
    render_target_formats = .[ .R8G8B8A8_UNORM, ],
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

      barrier(*cmd, .Present, .Raster, .[.{ texture = swapchain_texture, before = .Present, after = .RenderTarget, }]);

      set_viewport(*cmd, .{ width = width, height = height });
      set_scissor(*cmd, .{ width = width, height = height });
      clear_rtv(*cmd, swapchain_texture, .{ });

      set_render_targets(*cmd, .[swapchain_texture], null);

      set_root_signature(*cmd, *triangle_root_signature);
      set_pipeline(*cmd, *triangle_pipeline);
      draw(*cmd, 3, 1, 0, 0);

      barrier(*cmd, .Raster, .Present, .[.{ texture = swapchain_texture, before = .RenderTarget, after = .Present, }]);

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


align_pot :: inline (value: $T, alignment: T) -> T {
  return (value + alignment - 1) & ~(alignment - 1);
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

load_shader_binary :: (path: string) -> Shader, bool {
  auto_release_temp();
  compiled_shader_dir :: "compiled-shaders";
  bytecode, success := read_entire_file(path_join(compiled_shader_dir, path,, allocator=temp));

  if !success {
    print("Unable to load shader binary %", path);
    return .{}, false;
  }

  shader: Shader;
  shader, success = create_shader(.{ code = bytecode, });

  return shader, success;
}

// RHI

Device :: struct {
  factory: *IDXGIFactory6;
  debug: *ID3D12Debug1;
  adapter: *IDXGIAdapter2;
  queue: *ID3D12CommandQueue;
  info_queue: *ID3D12InfoQueue1;
  device: *ID3D12Device5;
  cookie: u32;
  rtv_descriptor_size: u32;
  dsv_descriptor_size: u32;
  cbv_srv_uav_descriptor_size: u32;
  sampler_descriptor_size: u32;
}

SwapchainDesc :: struct {
  hwnd: HWND;
  width: u32;
  height: u32;
};

Swapchain :: struct {
  swapchain: *IDXGISwapChain3;
  textures: [3]Texture;
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
  Present :: 1 << 3;
}

TextureLayout :: enum {
  Undefined;
  RenderTarget;
  Present;
}

LayoutTransition :: struct {
  texture: *Texture;
  before: TextureLayout;
  after: TextureLayout;
}

Texture :: struct {
  rsc: *ID3D12Resource;
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

Shader :: struct {
  code: D3D12_SHADER_BYTECODE;
}

RootSignature :: struct {
  handle: *ID3D12RootSignature;
}

ComputePipelineDesc :: struct {
  cs: *Shader;
}

GraphicsPipelineDesc :: struct {
  root_siganture: *RootSignature;
  vs: *Shader;
  ps: *Shader;
  render_target_formats: []DXGI_FORMAT;
}

Pipeline :: struct {
  handle: *ID3D12PipelineState;
}

rif :: (res: HRESULT, msg: string) #expand {
  if FAILED(res) {
    print("Error 0x%: %", FormatInt.{value = cast, no_check(u32) res, base = 16}, msg);
    `return .{}, true;
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

  device: *ID3D12Device5;

  result = D3D12CreateDevice(adapter, .D3D_FEATURE_LEVEL_12_2, *uid(ID3D12Device5_UUID), xx *device);

  rif(result, "Failed to create ID3D12Device5");

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
}

create_swapchain :: (device: *Device, desc: SwapchainDesc) -> Swapchain, bool {
  dxgi_desc := DXGI_SWAP_CHAIN_DESC1.{
    Width = desc.width,
    Height = desc.height,
    Format = .R8G8B8A8_UNORM,
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
    swapchain = dxgi_swapchain3,
  };

  for 0..2 {
    IDXGISwapChain_GetBuffer(dxgi_swapchain, xx it, *uid(ID3D12Resource_UUID), xx *swapchain.textures[it].rsc);
  }

  return swapchain, true;
}

destroy :: (swapchain: *Swapchain) {
  release(swapchain.swapchain);
}

present :: (swapchain: *Swapchain) {
  IDXGISwapChain_Present(swapchain.swapchain, 1, 0);
}

get_next_texture :: (swapchain: *Swapchain) -> *Texture {
  idx := IDXGISwapChain3_GetCurrentBackBufferIndex(swapchain.swapchain);
  return *swapchain.textures[idx];
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
    case .Present; return .PRESENT;
  }
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

      b.SyncBefore = global_barrier.SyncBefore;
      b.SyncAfter = global_barrier.SyncAfter;
      b.AccessBefore = global_barrier.AccessBefore;
      b.AccessAfter = global_barrier.AccessAfter;
      b.LayoutBefore = layout_to_d3d12_layout(t.before);
      b.LayoutAfter = layout_to_d3d12_layout(t.after);
      b.pResource = t.texture.rsc;
      b.Subresources.IndexOrFirstMipLevel = 0xFFFFFFFF;
    }
  }

  ID3D12GraphicsCommandList7_Barrier(cmd.cmd, group_count, *groups[0]);
}

clear_rtv :: (cmd: *Cmd, rtv: *Texture, clear_color: ClearColor) {
  handle := ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(cmd.rtv_heap);
  ID3D12Device_CreateRenderTargetView(cmd.device.device, rtv.rsc, null, handle);
  d3d12_clear_color := float.[clear_color.r, clear_color.g, clear_color.b, clear_color.a];

  ID3D12GraphicsCommandList_ClearRenderTargetView(cmd.cmd, handle, *d3d12_clear_color, 0, null);
}

set_render_targets :: (cmd: *Cmd, color_targets: []*Texture, depth_target: *Texture) {
  rtv_head := ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(cmd.rtv_heap);
  rtv_handle_ptr :*D3D12_CPU_DESCRIPTOR_HANDLE;

  if color_targets {
    rtv_handle_ptr = *rtv_head;

    for color_targets {
      handle := D3D12_CPU_DESCRIPTOR_HANDLE.{ ptr = rtv_head.ptr + cast(u64) it_index * cmd.device.rtv_descriptor_size };
      ID3D12Device_CreateRenderTargetView(cmd.device.device, it.rsc, null, handle);
    }
  }

  dsv_handle_ptr :*D3D12_CPU_DESCRIPTOR_HANDLE;

  if depth_target {
    handle := ID3D12DescriptorHeap_GetCPUDescriptorHandleForHeapStart(cmd.dsv_heap);
    ID3D12Device_CreateDepthStencilView(cmd.device.device, depth_target.rsc, null, handle);
    dsv_handle_ptr = *handle;
  }

  ID3D12GraphicsCommandList_OMSetRenderTargets(cmd.cmd, xx color_targets.count, rtv_handle_ptr, .TRUE, dsv_handle_ptr);
}

set_root_signature :: (cmd: *Cmd, root_siganture: *RootSignature) {
  ID3D12GraphicsCommandList_SetGraphicsRootSignature(cmd.cmd, root_siganture.handle);
  ID3D12GraphicsCommandList_SetComputeRootSignature(cmd.cmd, root_siganture.handle);
}

set_pipeline :: (cmd: *Cmd, pipeline: *Pipeline) {
  ID3D12GraphicsCommandList_SetPipelineState(cmd.cmd, pipeline.handle);
}

draw :: (cmd: *Cmd, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) {
  ID3D12GraphicsCommandList_DrawInstanced(cmd.cmd, vertex_count, instance_count, first_vertex, first_instance);
}

draw_indexed :: (cmd: *Cmd, index_count: u32, instance_count: u32, first_index: u32, vertex_offset: s32, first_instance: u32) {
  ID3D12GraphicsCommandList_DrawIndexedInstanced(cmd.cmd, index_count, instance_count, first_index, vertex_offset, first_instance);
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

create_shader :: (using desc: ShaderDesc) -> Shader, bool {
  return .{ code = .{ code.data, xx code.count } }, true;
}

create_root_signature :: (device: *Device, shader: *Shader) -> RootSignature, bool {
  root_siganture: *ID3D12RootSignature;
  result := ID3D12Device_CreateRootSignature(device.device, 0, shader.code.pShaderBytecode, shader.code.BytecodeLength, *uid(ID3D12RootSignature_UUID), xx *root_siganture);
  rif(result, "Unable to create root signature");

  return .{ handle = root_siganture, }, true;
}

create_compute_pipeline :: (device: *Device, using desc: ComputePipelineDesc) -> Pipeline, bool {
  d3d12_desc := D3D12_COMPUTE_PIPELINE_STATE_DESC.{ CS = cs.code, };
  pipeline: *ID3D12PipelineState;
  ID3D12Device_CreateComputePipelineState(device.device, *d3d12_desc, *uid(ID3D12PipelineState_UUID), xx *pipeline);

  return .{ handle = pipeline, }, true;
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

  if root_siganture {
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.ROOT_SIGNATURE; root_signature: *ID3D12RootSignature; };
    so.root_signature = root_siganture.handle;

    write_stream(so);
  }

  if vs {
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.VS; vs: D3D12_SHADER_BYTECODE; };
    so.vs = vs.code;

    write_stream(so);
  }

  if ps {
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.PS; ps: D3D12_SHADER_BYTECODE; };
    so.ps = ps.code;

    write_stream(so);
  }

  if render_target_formats {
    assert(render_target_formats.count <= 8);
    so: struct { type := D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.RENDER_TARGET_FORMATS; rtv_formats: D3D12_RT_FORMAT_ARRAY; };
    so.rtv_formats.NumRenderTargets = xx render_target_formats.count;

    for render_target_formats {
      so.rtv_formats.RTFormats[it_index] = it;
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
  rif(result, "Unable to create pipeline");

  return .{ handle = pipeline, }, true;
}
