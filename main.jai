#import "Basic";
#import "Windows";
#import "File";
#import "String";
#import "rhi";
#import "allocators";
#import "object-pool";

// have to place it here for now
#import "dxgi";
#import "d3d12"()(INCLUDE_DEBUG_BINDINGS = true);

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


