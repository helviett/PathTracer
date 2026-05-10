#import "Basic";
#import "Windows";
#import "File";
#import "File_Utilities";
#import "String";
#import "rhi";
#import "allocators";
#import "object-pool";
#import "stb_image";
#import "cgltf";
#import "linalg";
Math :: #import "Math";

// have to place it here for now
#import "d3d12"()(INCLUDE_DEBUG_BINDINGS = true);

Window :: #import "Window_Creation";
Input  :: #import "Input";

width :: 1920;
height :: 1080;

INVALID_TEXTURE: u32 : 0xffffffff;
INVALID_MESH: u32 : 0xffffffff;

upload_buffer: Buffer;
upload_ptr: *void;
upload_cmd: Cmd;
resource_allocator: ResourceAllocator;

cube_vertices :: Vector3.[
  // top
  .{  1,  1,  1}, // 0
  .{  1,  1, -1}, // 1
  .{ -1,  1, -1}, // 2
  .{ -1,  1,  1}, // 3
  // bot
  .{  1, -1,  1}, // 4
  .{ -1, -1,  1}, // 5
  .{ -1, -1, -1}, // 6
  .{  1, -1, -1}, // 7
];

cube_indices :: u16.[
  // top (+Y)
  0, 1, 2, 0, 2, 3,
  // bottom (-Y)
  4, 6, 5, 4, 7, 6,
  // front (+Z)
  4, 0, 3, 4, 3, 5,
  // back (-Z)
  7, 2, 6, 7, 1, 2,
  // left (-X)
  5, 3, 2, 5, 2, 6,
  // right (+X)
  4, 1, 7, 4, 0, 1,
];

Camera :: struct {
  yaw, pitch: float;
  position: Vector3;
  right: Vector3 = .{ 1, 0, 0 };
  up: Vector3 = .{ 0, 1, 0 };
  forward: Vector3 = .{ 0, 0, 1 };
}

camera: Camera = .{ position = .{ 0, 0, 2 }, };
world_up :: Vector3.{ 0, 1, 0 };

update_orientation :: (using camera: *Camera, yaw_dt: float, pitch_dt: float) {
  yaw += yaw_dt;
  pitch += pitch_dt;
  print("yaw_dt %, pitch_dt %\n", yaw_dt, pitch_dt);
  print("yaw %, pitch %\n", yaw, pitch);
  clamp(pitch, -85 * to_radians, 85 * to_radians);
  sin_yaw := Math.sin(yaw);
  sin_pitch := Math.sin(pitch);
  cos_yaw := Math.cos(yaw);
  cos_pitch := Math.cos(pitch);

  forward = .{
    x = sin_yaw * cos_pitch,
    y = sin_pitch,
    z = cos_yaw * cos_pitch,
  };
  right = normalize(cross(world_up, forward));
  up = cross(forward, right);
}

update_position :: (using camera: *Camera, right_dt: float, up_dt: float, forward_dt: float) {
  position += right * right_dt + world_up * up_dt + forward * -forward_dt;
}

compute_world_to_camera :: (using camera: Camera) -> Matrix44 {
  return look_at(position, position - forward);
}

main :: () {
  hwnd := Window.create_window(width, height, "PathTracing");
  device: Device;
  swapchain: Swapchain;
  result: bool;

  device, result = create_device();

  if !result {
    return;
  }

  swapchain, result = create_swapchain(device, SwapchainDesc.{ hwnd = hwnd, width = width, height = height, });

  if !result {
    return;
  }

  compute_shader := load_shader_binary(device, "compute.dxil");
  compute_pipeline := create_compute_pipeline(device, .{ cs = compute_shader, });

  triangle_vs := load_shader_binary(device, "triangle_vs.dxil");
  triangle_ps := load_shader_binary(device, "triangle_ps.dxil");

  triangle_root_signature := create_root_signature(device, triangle_vs);

  triangle_pipeline := create_graphics_pipeline(device, .{
    root_siganture = triangle_root_signature,
    vs = triangle_vs,
    ps = triangle_ps,
    render_target_formats = .[ .r8g8b8a8_unorm_srgb, ],
  });

  forward_vs := load_shader_binary(device, "forward_vs.dxil");
  forward_ps := load_shader_binary(device, "forward_ps.dxil");

  forward_root_signature := create_root_signature(device, forward_vs);

  forward_pipeline := create_graphics_pipeline(device, .{
    root_siganture = forward_root_signature,
    vs = forward_vs,
    ps = forward_ps,
    render_target_formats = .[ .r8g8b8a8_unorm_srgb, ],
    depth_stencil_target_format = .d32_sfloat,
    depth_stencil_desc = .{
      enable = true,
      func = .Less,
    },
    vertex_desc = .[
      .{ semantic = .Position, format = .r32g32b32_sfloat, },
      .{ semantic = .Normal, format = .r32g32b32_sfloat, binding = 1, },
      //.{ semantic = .Tangent, format = .r32g32b32a32_sfloat, binding = 1, },
      .{ semantic = .Texcoord0, format = .r32g32_sfloat, binding = 1, },
    ],
  });

  heap_size: u64 = 2 * 1024 * 1024 * 1024;
  gpu_heap := create_memory_heap(device, .{ heap_type = .DEFAULT, size = heap_size, });
  init(*resource_allocator, device, gpu_heap, heap_size);

  upload_heap := create_memory_heap(device, .{ heap_type = .UPLOAD, size = (128 * 1024 * 1024) * 2, });
  upload_resource_allocator: ResourceAllocator;
  init(*upload_resource_allocator, device, upload_heap, (128 * 1024 * 1024) * 3);

  descriptor_heap := create_descriptor_heap(device, .{ type = .Resource, descriptor_count = 4096, });
  sampler_heap := create_descriptor_heap(device, .{ type = .Sampler, descriptor_count = 2048, });

  upload_buffer = create_buffer(*upload_resource_allocator, .{
    size = 128 * 1024 * 1024,
  });
  upload_ptr = map(device, upload_buffer);
  upload_cmd = create_cmd(device);

  sampler := create_sampler(device, .{ address_u = .MirroredRepeat, });

  update_descriptors(device, sampler_heap, .[.{ type = .Sampler, heap_offset = 0, handle = sampler, },]);

  albedo_stub := create_texture(*resource_allocator, .{
    format = .r8g8b8a8_unorm_srgb,
    width = 1,
    height = 1,
    usage = .ShaderResource,
  });

  normal_stub := create_texture(*resource_allocator, .{
    format = .r8g8b8a8_unorm,
    width = 1,
    height = 1,
    usage = .ShaderResource,
  });

  metallic_roughness_stub := create_texture(*resource_allocator, .{
    format = .r8g8b8a8_unorm,
    width = 1,
    height = 1,
    usage = .ShaderResource,
  });



  scene, success := load_gltf_scene(.{
    device = device,
    path = "sponza-gltf/source/Sponza.gltf",
    descriptor_heap = descriptor_heap,
    descriptor_heap_offset = 0,
    albedo_stub = albedo_stub,
    normal_stub = normal_stub,
    metallic_roughness_stub = metallic_roughness_stub,
  });
  //scene, success := load_gltf_scene(device, "DamagedHelmet/glTF/DamagedHelmet.gltf");

  color_target := create_texture(*resource_allocator, .{
    format = .r8g8b8a8_unorm_srgb,
    width = width,
    height = height,
    usage = .RenderTarget,
  });

  depth_target := create_texture(*resource_allocator, .{
    format = .d32_sfloat,
    width = width,
    height = height,
    usage = .DepthStencil,
    clear_depth_stencil = .{ depth = 1.0 },
  });

  cpu_frame := CpuFrame.{
    fence = create_fence(device),
  };

  for 0..gpu_frame_count - 1 {
    cpu_frame.gpu_frames[it] = .{
      cmd = create_cmd(device),
      fence_value = 0,
    };

    buffer := create_buffer(*upload_resource_allocator, .{ size = 4 * 1024 * 1024, name = tprint("frame_%_constant_memory", it) });

    init(*cpu_frame.gpu_frames[it].constant_mem_allocator, device, buffer, 4 * 1024 * 1024);
  }


  cube_vb_size: u64 = xx (cube_vertices.count * size_of(Vector3));
  cube_ib_size: u64 = xx (cube_indices.count * size_of(u16));
  cube_vb := create_buffer(*resource_allocator, .{ size = cube_vb_size, name = "cube_vb" });
  cube_ib := create_buffer(*resource_allocator, .{ size = cube_ib_size, name = "cube_ib" });

  {
    begin(upload_cmd);

    barrier(upload_cmd, .None, .Copy, .[]);
    memcpy(upload_ptr, cube_vertices.data, xx cube_vb_size);
    copy(upload_cmd, BufferCopy.{
      dst = cube_vb,
      dst_offset = 0,
      src = upload_buffer,
      src_offset = 0,
      size = cube_vb_size,
    });
    end(upload_cmd);
    submit(device, upload_cmd);
    wait_for_completion(device);

    begin(upload_cmd);
    memcpy(upload_ptr, cube_indices.data, xx cube_ib_size);
    copy(upload_cmd, BufferCopy.{
      dst = cube_ib,
      dst_offset = 0,
      src = upload_buffer,
      src_offset = 0,
      size = cube_ib_size,
    });
    end(upload_cmd);
    submit(device, upload_cmd);
    wait_for_completion(device);
  }


  quit := false;
  last_time := seconds_since_init();

  while !quit {
      current_time := seconds_since_init();
      dt: float = xx (current_time - last_time);
      last_time = current_time;

      reset_temporary_storage();

      {
        speed :: 1.0;
        mouse_sens :: 0.01;
        right_dt, up_dt, forward_dt: float;
        Input.update_window_events();


        if button_state(.MOUSE_BUTTON_RIGHT) & .DOWN && (Input.mouse_delta_x || Input.mouse_delta_y) {
          print("delta % %\n", Input.mouse_delta_x, Input.mouse_delta_y);
          update_orientation(*camera, -Input.mouse_delta_x * mouse_sens, Input.mouse_delta_y * mouse_sens);
        }

        if button_state(#char "D") & .DOWN {
          right_dt += speed * dt;
        }
        if button_state(#char "A") & .DOWN {
          right_dt -= speed * dt;
        }
        if button_state(#char "E") & .DOWN {
          up_dt += speed * dt;
        }
        if button_state(#char "Q") & .DOWN {
          up_dt -= speed * dt;
        }
        if button_state(#char "W") & .DOWN {
          forward_dt += speed * dt;
        }
        if button_state(#char "S") & .DOWN {
          forward_dt -= speed * dt;
        }

        for Input.events_this_frame {
          if it.type == .QUIT then quit = true;

          if it.type == .KEYBOARD {
            if it.key_code == .ARROW_UP && it.key_pressed {
            }
            if it.key_code == .ARROW_DOWN && it.key_pressed {
            }
          }
        }

        update_position(*camera, right_dt, up_dt, forward_dt);
      }

      using cpu_frame;
      gpu_frame := *gpu_frames[gpu_frame_index];
      using gpu_frame;
      wait_for_fence(device, *fence, fence_value);
      swapchain_texture := get_next_texture(*swapchain);
      reset(*constant_mem_allocator);

      GlobalCb :: struct {
        projection: Matrix44;
        world_to_camera: Matrix44;
      }
      global_cb := GlobalCb.{
        projection = make_perspective_projection(60 * to_radians, cast(float) width / height, 0.01, 100),
        world_to_camera = compute_world_to_camera(camera),
      };
      global_cb_allocation := alloc(*constant_mem_allocator, size_of(GlobalCb), 256);
      memcpy(global_cb_allocation.ptr, *global_cb, size_of(GlobalCb));

      vs := global_cb.world_to_camera * Vector4.{ 0, 0, 0, 1};
      vs = .{ 0, 0, -0.01, 1.0};
      cs := global_cb.projection * vs;
      ndc := cs / cs.w;

      begin(cmd);

      set_descriptor_heaps(cmd, .[ descriptor_heap, sampler_heap ]);

      barrier(cmd, .Present, .Raster | .Copy, .[
        .{ texture = swapchain_texture, before = .Present, after = .CopyTarget, },
        .{ texture = color_target, before = .Undefined, after = .RenderTarget, },
        .{ texture = depth_target, before = .Undefined, after = .DepthStencilTarget, },
        ]
      );

      set_viewport(cmd, .{ width = width, height = height });
      set_scissor(cmd, .{ width = width, height = height });
      clear_render_target(cmd, color_target, .{ });
      clear_depth_stencil_target(cmd, depth_target, .{ depth = 1.0, });

      set_targets(cmd, .[color_target], depth_target);

      set_root_signature(cmd, forward_root_signature);
      set_pipeline(cmd, forward_pipeline);
      set_index_buffer(cmd, scene.index_stream, scene.index_type, 0);
      set_vertex_buffers(cmd, 0, .[.{ buffer = scene.position_stream, stride = size_of(float) * 3 }, .{ buffer = scene.attribute_stream, stride = size_of(float) * (9 - 4) }]);
      set_root_cbv(cmd, xx RootIndex.Globals, constant_mem_allocator.buffer, xx global_cb_allocation.offset);
      set_root_srv(cmd, xx RootIndex.Submeshes, scene.submesh_stream, 0);
      set_root_srv(cmd, xx RootIndex.Materials, scene.material_stream, 0);
      set_root_srv(cmd, xx RootIndex.Transforms, scene.transform_stream, 0);

      for node, node_index: scene.nodes {
        DrawData :: struct {
          submesh_index: u32;
          transform_index: u32;
        };
        mesh := scene.meshes[node.mesh_id];
        for *submesh: mesh.submeshes {
          submesh_index := submesh - scene.submeshes.data;
          draw_data := DrawData.{
            submesh_index = xx submesh_index,
            transform_index = xx node_index,
          };


          set_root_constants(cmd, xx RootIndex.DrawData, draw_data);
          draw_indexed(cmd, submesh.index_count, 1, submesh.first_index, submesh.first_vertex, 0);
        }
      }

      barrier(cmd, .Raster, .Copy, .[.{ texture = color_target, before = .RenderTarget, after = .CopySource, }]);

      copy(cmd, TextureCopy.{
        dst = swapchain_texture,
        src =  color_target,
        width = width,
        height = height,
      });

      barrier(cmd, .Copy, .Present, .[.{ texture = swapchain_texture, before = .CopyTarget, after = .Present, }]);

      end(cmd);
      submit(device, cmd);
      fence_value = next_value(*fence);
      signal(device, *fence, fence_value);
      present(*swapchain);
      gpu_frame_index = (gpu_frame_index + 1) % gpu_frame_count;
  }

  for 0..gpu_frame_count - 1 {
    gpu_frame := *cpu_frame.gpu_frames[it];
    wait_for_fence(device, *cpu_frame.fence, gpu_frame.fence_value);
    destroy(device, gpu_frame.cmd);
  }

  destroy(device, *cpu_frame.fence);

  destroy(*swapchain);
  destroy(device);
}

// Input
button_state :: (key_code: Input.Key_Code) -> Input.Key_Current_State {
  return Input.input_button_states[key_code];
}

RootIndex :: enum u32 {
  Globals :: 0;
  DrawData :: 1;
  Submeshes :: 2;
  Materials :: 3;
  Transforms :: 4;
}

// Scene
Scene :: struct {
  position_stream: Buffer;
  attribute_stream: Buffer;
  index_stream: Buffer;
  submesh_stream: Buffer;
  material_stream: Buffer;
  // Let's keep it static for now
  transform_stream: Buffer;
  index_type: IndexType;

  textures: []Texture;
  meshes: []Mesh;
  submeshes: []Submesh;
  materials: []Material;
  nodes: []Node;
}


Material :: struct {
  albedo_index: u32 = INVALID_TEXTURE;
  normal_index: u32 = INVALID_TEXTURE;
  metallic_roughness_index: u32 = INVALID_TEXTURE;
}

Mesh :: struct {
  submeshes: []Submesh;
}

Submesh :: struct {
  first_index: u32;
  index_count: u32;
  first_vertex: s32;
  material_id: u32;
}

Node :: struct {
  mesh_id: u32 = INVALID_MESH;
  transform: Matrix44;
}

// Could be local to load_gltf_scene, but breaks linting.

cgltf_read_file :: (memory_options: *cgltf_memory_options, file_options: *cgltf_file_options, path: *u8, size: *cgltf_size, data: **void) -> cgltf_result #c_call {
  push_context {
    jai_path := string.{ data = path, count = c_style_strlen(path) };

    if !file_exists(jai_path) {
      return .file_not_found;
    }

    jai_path.count += 1;
    read_data, success := read_entire_file(jai_path, zero_terminated = true);

    if !success {
      return  .io_error;
    }

    data.* = read_data.data;
    size.* = xx read_data.count;

    return .success;
  }
}

cgltf_release_file :: (memory_options: *cgltf_memory_options, file_options: *cgltf_file_options, data: *void) -> void #c_call {
  push_context {
    free(data);
  }
}


cgltf_alloc :: (user: *void, size: cgltf_size) -> *void #c_call {
  push_context {
    return alloc(xx size);
  }
}

cgltf_free :: (user: *void, ptr: *void) -> void #c_call {
  push_context {
    free(ptr);
  }
}

cgltf_calc_size :: (accessor: cgltf_accessor) -> u64 {
  return cgltf_calc_size(accessor.type, accessor.component_type);
}

GltfLoadDesc :: struct {
  device: Device;
  path: string;
  descriptor_heap: DescriptorHeap;
  descriptor_heap_offset: u64;
  albedo_stub, normal_stub, metallic_roughness_stub: Texture;
}

load_gltf_scene :: (using load_desc: GltfLoadDesc) -> Scene, bool {
  auto_release_temp();

  data: *cgltf_data;
  options: cgltf_options;
  options.file.read = cgltf_read_file;
  options.file.release = cgltf_release_file;
  options.memory.alloc_func = cgltf_alloc;
  options.memory.free_func = cgltf_free;

  err := cgltf_parse_file(*options, path.data, *data);

  if err {
    return .{}, false;
  }

  defer cgltf_free(data);

  ImageMeta :: struct {
    format: Format;
    name: *u8;
  }

  derived_image_meta := NewArray(xx data.images_count, ImageMeta,, allocator=temp);

  derive_meta :: (texture: *cgltf_texture, required_format: Format) -> u32 #expand {
    if texture {
      image := texture.image;
      name := texture.name;
      image_index := cgltf_image_index(data, image);

      derived_format := derived_image_meta[image_index].format;
      if derived_format != required_format && derived_format != .unknown {
        print("Ambigious format images[%] requires both % and % formats\n", image_index, required_format, derived_format);
      } else {
        derived_image_meta[image_index] = .{
          format = required_format,
          name = name,
        };
      }

      return xx image_index;
    }

    return INVALID_TEXTURE;
  }

  materials := NewArray(xx data.materials_count, Material);
  // gltf is an awful format so we have to derive image format by looking at it's usage.
  for 0..data.materials_count - 1 {
    material: Material;
    gltf_material := data.materials[it];

    if gltf_material.has_pbr_metallic_roughness {
      material.albedo_index = derive_meta(gltf_material.pbr_metallic_roughness.base_color_texture.texture, .r8g8b8a8_unorm_srgb);
      material.metallic_roughness_index = derive_meta(gltf_material.pbr_metallic_roughness.metallic_roughness_texture.texture, .r8g8b8a8_unorm);
    }

    material.normal_index = derive_meta(gltf_material.normal_texture.texture, .r8g8b8a8_unorm);
    derive_meta(gltf_material.emissive_texture.texture, .r8g8b8a8_unorm);

    materials[it] = material;
  }

  directory := path_strip_filename(path);

  // TODO single memory pool for entire Scene
  textures := NewArray(xx data.images_count, Texture);

  for 0..data.images_count - 1 {
    meta := derived_image_meta[it];
    image := data.images[it];
    uri := string.{ data = image.uri, count = c_style_strlen(image.uri) };

    if meta.format == .unknown {
      print("images[%] = % is unused\n", it, uri);
      continue;
    }

    image_path := path_join(directory, uri,, allocator = temp);
    image_data, success := load_image(image_path);

    if !success {
      print("Unable to load image %\n", image_path);
      // TODO: recover from error; err = something + check between loops?
      break;
    }

    defer free_image(image_data);

    texture: Texture;
    texture, success = upload_image(device, image_data, TextureDesc.{ format = meta.format, });

    textures[it] = texture;
  }

  position_stream_size: u64;
  attribute_stream_size: u64;
  index_count: u64 = 0;
  index_type := IndexType.r16_uint;
  survived_mesh_count: u64;
  survived_primitive_count: u64;

  // gltf is an awful format. This code assumes that accessors access unique regions of buffer.
  // Cause otherwise I would have to find union of accessors and do a bunch of repointing.
  for mesh_index: 0..data.meshes_count - 1 {
    mesh := data.meshes[mesh_index];
    survived_mesh_primitive_count: u64;

    for primitive_index: 0..mesh.primitives_count - 1 {
      primitive := mesh.primitives[primitive_index];

      if primitive.type != .triangles || !primitive.indices {
        continue;
      }

      primitive_index_type: IndexType = ifx primitive.indices.component_type == .r_16u
        then .r16_uint else .r32_uint;
      index_type = max(primitive_index_type, index_type);
      primitive_positions_size: u64;
      primitive_attributes_size: u64;

      attributes: [cgltf_attribute_type.max_enum]*cgltf_accessor;

      for attribute_index: 0..primitive.attributes_count - 1 {
        attribute := primitive.attributes[attribute_index];
        accessor := attribute.data;
        data_size := cgltf_calc_size(accessor) * accessor.count;

        if attribute.index > 0 {
          continue;
        }

        attributes[attribute.type] = accessor;

        if attribute.type == {
          case .position;
            primitive_positions_size += data_size;
          case .normal; #through;
          //case .tangent; #through;
          case .texcoord;
            primitive_attributes_size += data_size;
        }
      }

      has_required_attributes := attributes[cgltf_attribute_type.position]
        && attributes[cgltf_attribute_type.normal]
        && attributes[cgltf_attribute_type.texcoord];
        //&& attributes[cgltf_attribute_type.tangent];

      if has_required_attributes {
        survived_mesh_primitive_count += 1;
        index_count += primitive.indices.count;
        position_stream_size += primitive_positions_size;
        attribute_stream_size += primitive_attributes_size;
      }
    }

    if survived_mesh_primitive_count {
      survived_mesh_count += 1;
      survived_primitive_count += survived_mesh_primitive_count;
    }
  }

  index_size: u64 = xx (ifx index_type == .r16_uint then 2 else 4);
  index_stream_size: u64 = index_count * index_size;

  print("Sizes: Index = %, Position = %, Attributes = %\n", index_stream_size, position_stream_size, index_stream_size);

  position_stream := create_buffer(*resource_allocator, .{ size = position_stream_size, name = "position_stream", });
  attribute_stream := create_buffer(*resource_allocator, .{ size = attribute_stream_size, name = "attribute_stream", });
  index_stream := create_buffer(*resource_allocator, .{ size = index_stream_size, name = "index_stream", });

  meshes := NewArray(xx survived_mesh_count, Mesh, initialized = false);
  submeshes := NewArray(xx survived_primitive_count, Submesh, initialized = false);
  mesh_remap := NewArray(xx data.meshes_count, s32, initialized = false);
  out_mesh_index : s32 = 0;
  out_submesh_index : s32 = 0;
  first_vertex : u64 = 0;
  first_index : u64 = 0;

  position_stream_offset: u64;
  attribute_stream_offset: u64;
  index_stream_offset: u64;

  {
    c_path := to_c_string(path,, temp);
    cgltf_load_buffers(*options, data, c_path);
  }


  for mesh_index: 0..data.meshes_count - 1 {
    mesh := data.meshes[mesh_index];
    start_submesh_index := out_submesh_index;
    should_add_mesh: bool;

    for primitive_index: 0..mesh.primitives_count - 1 {
      primitive := mesh.primitives[primitive_index];

      if primitive.type != .triangles || !primitive.indices {
        continue;
      }

      primitive_index_type: IndexType = ifx primitive.indices.component_type == .r_16u
        then .r16_uint else .r32_uint;
      assert(primitive_index_type == .r16_uint);

      attributes: [cgltf_attribute_type.max_enum]*cgltf_accessor;

      for attribute_index: 0..primitive.attributes_count - 1 {
        attribute := primitive.attributes[attribute_index];
        accessor := attribute.data;

        if attribute.index > 0 {
          continue;
        }

        attributes[attribute.type] = accessor;
      }

      has_required_attributes := attributes[cgltf_attribute_type.position]
        && attributes[cgltf_attribute_type.normal]
        //&& attributes[cgltf_attribute_type.tangent]
        && attributes[cgltf_attribute_type.texcoord];

      if !has_required_attributes {
        continue;
      }

      assert(
        !attributes[cgltf_attribute_type.texcoord].normalized
        && attributes[cgltf_attribute_type.texcoord].component_type == .r_32f
      );
      assert(
        accessor_copy_info_from_accessor(attributes[cgltf_attribute_type.position]).element_size == 4 * 3
      );

      vertex_count := attributes[cgltf_attribute_type.position].count;
      index_count := primitive.indices.count;

      upload_primitive_data(device, position_stream, position_stream_offset, .[
        accessor_copy_info_from_accessor(attributes[cgltf_attribute_type.position])
      ], log = true);

      position_stream_offset += size_of(float) * 3 * vertex_count;

      upload_primitive_data(device, attribute_stream, attribute_stream_offset, .[
        accessor_copy_info_from_accessor(attributes[cgltf_attribute_type.normal]),
        //accessor_copy_info_from_accessor(attributes[cgltf_attribute_type.tangent]),
        accessor_copy_info_from_accessor(attributes[cgltf_attribute_type.texcoord]),
      ]);

      //attribute_stream_offset += size_of(float) * (3 + 2 + 4) * vertex_count;
      attribute_stream_offset += size_of(float) * (3 + 2) * vertex_count;

      upload_primitive_data(device, index_stream, index_stream_offset, .[
        accessor_copy_info_from_accessor(primitive.indices, index_size),
      ]);

      index_stream_offset += index_size * index_count;

      material_index: u32 = xx cgltf_material_index(data, primitive.material);

      submeshes[out_submesh_index] = .{
        first_vertex = xx first_vertex,
        first_index = xx first_index,
        index_count = xx index_count,
        material_id = material_index,
      };
      out_submesh_index += 1;
      first_vertex += vertex_count;
      first_index += index_count;

      should_add_mesh = true;
    }

    if should_add_mesh {
      mesh_remap[mesh_index] = out_mesh_index;
      meshes[out_mesh_index] = .{
        submeshes = .{
          data = submeshes.data + start_submesh_index,
          count = out_submesh_index - start_submesh_index
        }
      };
      out_mesh_index += 1;
    } else {
      mesh_remap[mesh_index] = -1;
    }
  }

  assert(position_stream_offset == position_stream_size && attribute_stream_offset == attribute_stream_size && index_stream_offset == index_stream_size);

  out_node_count := 0;

  for node_index:0..data.nodes_count {
    node := *data.nodes[node_index];

    // No need for hierarchy for now
    if !node.mesh || mesh_remap[cgltf_mesh_index(data, node.mesh)] < 0 {
      continue;
    }

    out_node_count += 1;
  }

  nodes := NewArray(out_node_count, Node, initialized = false);
  out_node_index: s32;

  for node_index:0..data.nodes_count {
    node := *data.nodes[node_index];
    original_node := node;

    // No need for hierarchy for now
    if !node.mesh || mesh_remap[cgltf_mesh_index(data, node.mesh)] < 0 {
      continue;
    }

    object_to_world: Matrix44 = identity();

    while node {
      if node.has_scale {
        object_to_world = scale(node.scale[0], node.scale[1], node.scale[2]) * object_to_world;
      }
      if node.has_rotation {
        // No support for quats yet so just inline dxm implementation here:
        qx: float = node.rotation[0];
        qxx: float = qx * qx;

        qy: float = node.rotation[1];
        qyy: float = qy * qy;

        qz: float = node.rotation[2];
        qzz: float = qz * qz;

        qw: float = node.rotation[3];

        m: Matrix44;
        m.v[0][0] = 1.0 - 2.0 * qyy - 2.0 * qzz;
        m.v[0][1] = 2.0 * qx * qy + 2.0 * qz * qw;
        m.v[0][2] = 2.0 * qx * qz - 2.0 * qy * qw;
        m.v[0][3] = 0.0;

        m.v[1][0] = 2.0 * qx * qy - 2.0 * qz * qw;
        m.v[1][1] = 1.0 - 2.0 * qxx - 2.0 * qzz;
        m.v[1][2] = 2.0 * qy * qz + 2.0 * qx * qw;
        m.v[1][3] = 0.0;

        m.v[2][0] = 2.0 * qx * qz + 2.0 * qy * qw;
        m.v[2][1] = 2.0 * qy * qz - 2.0 * qx * qw;
        m.v[2][2] = 1.0 - 2.0 * qxx - 2.0 * qyy;
        m.v[2][3] = 0.0;

        m.v[3][0] = 0.0;
        m.v[3][1] = 0.0;
        m.v[3][2] = 0.0;
        m.v[3][3] = 1.0;

        m = transpose(m);
        object_to_world = m * object_to_world;
      }
      if node.has_translation {
        object_to_world = translate(node.translation[0], node.translation[1], node.translation[2]) * object_to_world;
      }
      if (node.has_matrix) {
          object_to_world = cast(*Matrix44) node.matrix.data * object_to_world;
      }
      node = node.parent;
    }

    node = original_node;

    nodes[out_node_index] = .{
      mesh_id = xx mesh_remap[cgltf_mesh_index(data, node.mesh)],
      transform = object_to_world,
    };

    out_node_index += 1;
  }


  material_stream := create_buffer(*resource_allocator, .{ size = xx (materials.count * size_of(u32)), name = "material_stream" });
  {
    dst: *u32 = upload_ptr;
    descriptor_offset := descriptor_heap_offset;
    for materials {
      albedo_texture := ifx it.albedo_index != INVALID_TEXTURE then textures[it.albedo_index] else albedo_stub;
      normal_texture := ifx it.normal_index != INVALID_TEXTURE then textures[it.normal_index] else normal_stub;
      metallic_roughness_texture := ifx it.metallic_roughness_index != INVALID_TEXTURE then textures[it.metallic_roughness_index] else metallic_roughness_stub;
      update_descriptors(device, descriptor_heap, .[
        .{ type = .ShaderResourceTexture, heap_offset = xx (descriptor_offset + 0), handle = albedo_texture, texture = .{} },
        .{ type = .ShaderResourceTexture, heap_offset = xx (descriptor_offset + 1), handle = normal_texture, texture = .{} },
        .{ type = .ShaderResourceTexture, heap_offset = xx (descriptor_offset + 2), handle = metallic_roughness_texture, texture = .{} }
      ]);
      dst.* = xx descriptor_offset;
      dst += 1;
      descriptor_offset += 3;
    }
    begin(upload_cmd);
    copy(upload_cmd, BufferCopy.{
        dst = material_stream,
        dst_offset = 0,
        src = upload_buffer,
        src_offset = 0,
        size = xx (materials.count * size_of(u32)),
    });

    end(upload_cmd);
    submit(device, upload_cmd);
    wait_for_completion(device);
  }

  submesh_stream := create_buffer(*resource_allocator, .{ size = xx (submeshes.count * size_of(u32)), name = "submesh_stream" });
  {
    ptr: *u32 = xx upload_ptr;
    for submeshes {
      ptr[it_index] = it.material_id;
    }
    begin(upload_cmd);
    copy(upload_cmd, BufferCopy.{
        dst = submesh_stream,
        dst_offset = 0,
        src = upload_buffer,
        src_offset = 0,
        size = xx (submeshes.count * size_of(u32)),
    });

    end(upload_cmd);
    submit(device, upload_cmd);
    wait_for_completion(device);
  }

  transform_stream := create_buffer(*resource_allocator, .{ size = xx (nodes.count * size_of(Vector3) * 4), name = "transform_stream" });
  {
    ptr: *Vector3 = xx upload_ptr;
    for nodes {
      dst: *Vector3 = ptr + it_index * 4;
      for it.transform.cols {
        dst[it_index] = it.xyz;
      }
    }
    begin(upload_cmd);
    copy(upload_cmd, BufferCopy.{
        dst = transform_stream,
        dst_offset = 0,
        src = upload_buffer,
        src_offset = 0,
        size = xx (nodes.count * size_of(Vector3) * 4),
    });

    end(upload_cmd);
    submit(device, upload_cmd);
    wait_for_completion(device);
  }

  return .{
    position_stream = position_stream,
    attribute_stream = attribute_stream,
    index_stream = index_stream,
    submesh_stream = submesh_stream,
    material_stream = material_stream,
    transform_stream = transform_stream,
    index_type = index_type,
    textures = textures,
    meshes = meshes,
    submeshes = submeshes,
    nodes = nodes,
  }, true;
}

AccessorCopyInfo :: struct {
  accessor: *cgltf_accessor;
  data: *u8;
  element_size: u64;
  stride: u64;
  dst_element_size: u64;
}

accessor_copy_info_from_accessor :: inline (accessor: *cgltf_accessor, dst_element_size: u64 = 0) -> AccessorCopyInfo {
  return .{
    accessor = accessor,
    data = cast(*u8) accessor.buffer_view.buffer.data + accessor.buffer_view.offset + accessor.offset,
    element_size = cgltf_calc_size(accessor),
    stride = accessor.stride,
    dst_element_size = ifx dst_element_size == 0 then cgltf_calc_size(accessor) else dst_element_size,
  };
}

upload_primitive_data :: (device: Device, dst_buffer: Buffer, dst_offset: u64, accessors: []AccessorCopyInfo, log: bool = false) -> u64 {
  dst := upload_ptr;

  element_count: u64 = accessors[0].accessor.count;
  dst_element_size: u64;

  for accessors {
    assert(element_count == it.accessor.count);
    dst_element_size += it.dst_element_size;
  }

  for element_index: 0..element_count - 1 {
    for accessors {
      memcpy(
        dst,
        it.data + element_index * it.stride,
        xx it.element_size
      );
      //memset(
      //  dst + it.element_size,
      //  0,
      //  xx (it.dst_element_size - it.element_size)
      //);
      dst += it.dst_element_size;
    }
  }

  begin(upload_cmd);

  copy(upload_cmd, BufferCopy.{
      dst = dst_buffer,
      dst_offset = dst_offset,
      src = upload_buffer,
      src_offset = 0,
      size = dst_element_size * element_count,
  });

  if log {
    print("upload % bytes % offset\n", dst_element_size * element_count, accessors[0].data);
  }

  end(upload_cmd);
  submit(device, upload_cmd);
  wait_for_completion(device);

  return element_count * dst_element_size;
}

// Renderer

gpu_frame_count : u32 : 2;

GpuFrame :: struct
{
  cmd : Cmd;
  fence_value: u64;
  constant_mem_allocator: BufferMemoryAllocator;
}

CpuFrame :: struct
{
  gpu_frames: [gpu_frame_count]GpuFrame;
  fence: Fence;
  gpu_frame_index: u32;
}

load_shader_binary :: (device: Device, path: string) -> Shader, bool {
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

free_image :: (image: Image) {
  stbi_image_free(image.pixels);
}

upload_image :: (device: Device, image: Image, in_texture_desc: TextureDesc) -> Texture, bool {
  texture_desc := in_texture_desc;
  texture_desc.width = image.width;
  texture_desc.height = image.height;

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

  begin(upload_cmd);

  barrier(upload_cmd, .None, .Copy, .[.{ texture = texture, before = .Undefined, after = .CopyTarget}]);

  copy(upload_cmd, BufferToTextureCopy.{
    buffer = upload_buffer,
    texture = texture,
    width = image.width,
    height = image.height,
  });

  barrier(upload_cmd, .Copy, .Pixel | .Compute, .[.{ texture = texture, before = .CopyTarget, after = .ShaderResource}]);

  end(upload_cmd);
  submit(device, upload_cmd);
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
  device: Device;
}

DescriptorAllocator :: struct {
  offset_allocator: LinearAllocator;
  base_offset: u32;
  descriptor_heap: DescriptorHeap;
  device: Device;
}

init :: (allocator: *ResourceAllocator, device: Device, heap: MemoryHeap, size: u64) {
  init(*allocator.offset_allocator, size);
  allocator.device = device;
  allocator.memory_heap = heap;
}

create_texture :: (using allocator: *ResourceAllocator, texture_desc: TextureDesc) -> Texture, bool {
  requirements := get_texture_allocation_requirements(device, texture_desc);
  allocation := alloc(*offset_allocator, requirements.size, requirements.alignment);
  texture, success := create_texture(device, .{ heap = memory_heap, offset = allocation.offset }, texture_desc);
  assert(success);

  return texture, success;
}

create_buffer :: (using allocator: *ResourceAllocator, buffer_desc: BufferDesc) -> Buffer, bool {
  requirements := get_buffer_allocation_requirements(device, buffer_desc);
  allocation := alloc(*offset_allocator, requirements.size, requirements.alignment);
  buffer, success := create_buffer(device, .{ heap = memory_heap, offset = allocation.offset }, buffer_desc);
  assert(success);

  return buffer, success;
}

init :: (allocator: *DescriptorAllocator, device: Device, heap: DescriptorHeap, descriptor_count: u32, base_offset: u32) {
  init(*allocator.offset_allocator, descriptor_count);
  allocator.device = device;
  allocator.descriptor_heap = heap;
  allocator.base_offset = base_offset;
}

BufferAllocation :: struct {
  ptr: *u8;
  offset: s64;
  size: s64;
}

BufferMemoryAllocator :: struct {
  buffer: Buffer;
  size: s64;
  base_offset: s64;
  offset: s64;
  base_ptr: *u8;
}

init :: (using allocator: *BufferMemoryAllocator, device: Device, in_buffer: Buffer, in_size: s64, in_base_offset: s64 = 0) {
  allocator.* = .{};
  buffer = in_buffer;
  size = in_size;
  base_offset = in_base_offset;

  ptr := map(device, buffer);
  base_ptr = ptr + base_offset;
}

alloc :: (using allocator: *BufferMemoryAllocator, in_size: s64, in_alignment: s64) -> BufferAllocation {
  aligned_offset := align_pot(offset, in_alignment);
  has_enough_memory := (base_offset + size) - aligned_offset >= in_size;
  assert(has_enough_memory);

  if !has_enough_memory {
    // Better than crasing on user side I guess.
    return .{ ptr = base_ptr, offset = base_offset };
  }

  allocation := BufferAllocation.{ ptr = base_ptr + aligned_offset, offset = aligned_offset, size = in_size, };
  offset = aligned_offset + in_size;

  return allocation;
}

reset :: (using allocator: *BufferMemoryAllocator) {
  allocator.offset = 0;
}

// TODO: proper deallocation once any allocator with free implementation arrives.

