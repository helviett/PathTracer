#import "Basic";
#import "Windows";
#import "File";
#import "String";
#import "rhi";
#import "allocators";
#import "object-pool";
#import "stb_image";
#import "cgltf";

// have to place it here for now
#import "d3d12"()(INCLUDE_DEBUG_BINDINGS = true);

Window :: #import "Window_Creation";
Input  :: #import "Input";

width :: 1920;
height :: 1080;

upload_buffer: Buffer;
upload_ptr: *void;
upload_cmd: Cmd;
resource_allocator: ResourceAllocator;

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

  {
    data: *cgltf_data;
    options: cgltf_options;
    r := cgltf_parse_file(*options, "sponza-gltf/sponza-png.glb", *data);
    assert(!r);
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
  gpu_heap := create_memory_heap(*device, .{ heap_type = .DEFAULT, size = heap_size, });
  init(*resource_allocator, *device, gpu_heap, heap_size);

  upload_heap := create_memory_heap(*device, .{ heap_type = .UPLOAD, size = (128 * 1024 * 1024) * 2, });
  upload_resource_allocator: ResourceAllocator;
  init(*upload_resource_allocator, *device, upload_heap, (128 * 1024 * 1024) * 2);



  descriptor_heap := create_descriptor_heap(*device, .{ type = .Resource, descriptor_count = 4096, });
  sampler_heap := create_descriptor_heap(*device, .{ type = .Sampler, descriptor_count = 2048, });

  upload_buffer = create_buffer(*upload_resource_allocator, .{
    size = 128 * 1024 * 1024,
  });
  upload_ptr = map(*device, upload_buffer);
  upload_cmd = create_cmd(*device);

  texture: Texture = xx null_handle;
  {
    image, success := load_image("pepe.png");
    assert(success);
    defer stbi_image_free(image.pixels);
    texture, success = upload_image(*device, image);
    assert(success);
  }
  sampler := create_sampler(*device, .{ address_u = .MirroredRepeat, });

  update_descriptors(*device, descriptor_heap, .[
    .{ type = .ShaderResourceBuffer, heap_offset = 0, handle = upload_buffer, buffer = .{ size = 16, }},
    .{ type = .ShaderResourceTexture, heap_offset = 1, handle = texture, texture = .{} },
  ]);

  update_descriptors(*device, sampler_heap, .[.{ type = .Sampler, heap_offset = 0, handle = sampler, },]);

  {
    red := float.[ 1.0, 0.0, 0.0, 1.0 ];
    memcpy(upload_ptr, red.data, 16);
  }



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

      set_descriptor_heaps(*cmd, .[ descriptor_heap, sampler_heap ]);

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

load_image :: (path: string) -> Image, bool {
  image, success := read_entire_file(path);
  defer free(image.data);

  if !success {
    print("Unable to load image %", path);
    return .{}, false;
  }

  width, height, channels: s32;
  pixels := stbi_load_from_memory(image.data, xx image.count, *width, *height, *channels, 4);

  return .{
    pixels = pixels,
    width = xx width,
    height = xx height
  }, true;
}

upload_image :: (device: *Device, image: Image) -> Texture, bool {
  texture_desc := TextureDesc.{
    format = .r8g8b8a8_unorm_srgb,
    width = image.width,
    height = image.height,
  };

  texture, success := create_texture(*resource_allocator, texture_desc);

  if !success {
    print("Unable to create texture");
    return xx null_handle, false;
  }

  row_size := image.width * 4;
  r := get_texture_upload_requirements(texture_desc);
  dst := upload_ptr;
  src := image.pixels;

  for y: 0..image.height - 1 {
    memcpy(dst, src, row_size);
    dst += r.row_size;
    src += row_size;
  }

  begin(*upload_cmd);

  barrier(*upload_cmd, .None, .Copy, .[.{ texture = texture, before = .Undefined, after = .CopyTarget}]);

  copy(*upload_cmd, BufferToTextureCopy.{
    buffer = upload_buffer,
    texture = texture,
    width = image.width,
    height = image.height,
  });

  barrier(*upload_cmd, .Copy, .Pixel | .Compute, .[.{ texture = texture, before = .CopyTarget, after = .ShaderResource}]);

  end(*upload_cmd);
  submit(device, *upload_cmd);
  wait_for_completion(device);

  return texture, true;
}

TextureUploadRequirements :: struct {
  row_alignment: u32;
  array_alignment: u32;
  row_size: u32;
  array_element_size: u32;
}

get_texture_upload_requirements :: (using desc: TextureDesc) -> TextureUploadRequirements {
  using format_desc := get_format_desc(format);

  using requirements := TextureUploadRequirements.{
    row_alignment = D3D12_TEXTURE_DATA_PITCH_ALIGNMENT,
    array_alignment = D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT,
  };
  row_size = align_pot(bytes_per_block * width, row_alignment);
  array_element_size = align_pot(row_size * height, array_alignment);

  return requirements;
}

Image :: struct {
  pixels: *u8;
  width: u32;
  height: u32;
}

ResourceAllocator :: struct {
  offset_allocator: LinearAllocator;
  memory_heap: MemoryHeap;
  device: *Device;
}

DescriptorAllocator :: struct {
  offset_allocator: LinearAllocator;
  base_offset: u32;
  descriptor_heap: DescriptorHeap;
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

init :: (allocator: *DescriptorAllocator, device: *Device, heap: DescriptorHeap, descriptor_count: u32, base_offset: u32) {
  init(*allocator.offset_allocator, descriptor_count);
  allocator.device = device;
  allocator.descriptor_heap = heap;
  allocator.base_offset = base_offset;
}


// TODO: proper deallocation once any allocator with free implementation arrives.

