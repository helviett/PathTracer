AT_COMPILE_TIME :: true;
BUILD_DIR :: "build";

#if AT_COMPILE_TIME {
  pdb_dir :: #run path_join(BUILD_DIR, "shader-pdb");
  compiled_shader_dir :: #run path_join(BUILD_DIR, "compiled-shaders");
  shader_dir :: #run path_join(#filepath, "shaders");
} else {
  pdb_dir :: "shader-pdb";
  compiled_shader_dir :: "compiled-shaders";
  shader_dir :: #run path_join(#filepath, "shaders");
}

build :: () {
  w := compiler_create_workspace();
  o := get_build_options();
  o.output_executable_name = "path_tracer";
  o.output_path = BUILD_DIR;
  make_directory_if_it_does_not_exist(o.output_path);
  set_optimization(*o, .DEBUG);
  set_build_options(o, w);
  add_build_file(tprint("%main.jai", #filepath), w);
  set_build_options_dc(.{do_output=false});
}

compile_shaders :: () {
  make_directory_if_it_does_not_exist(pdb_dir);
  make_directory_if_it_does_not_exist(compiled_shader_dir);

  shader_descriptions := ShaderDescription.[
    .{
      path = #run path_join(shader_dir, "compute.hlsl"),
      output_path = #run path_join(compiled_shader_dir, "compute.dxil"),
      stage = .Compute,
      debug = true,
      pdb_dir = pdb_dir,
    },
    .{
      path = #run path_join(shader_dir, "triangle.hlsl"),
      output_path = #run path_join(compiled_shader_dir, "triangle_vs.dxil"),
      stage = .Vertex,
      debug = true,
      pdb_dir = pdb_dir,
    },
    .{
      path = #run path_join(shader_dir, "triangle.hlsl"),
      output_path = #run path_join(compiled_shader_dir, "triangle_ps.dxil"),
      stage = .Pixel,
      debug = true,
      pdb_dir = pdb_dir,
    }
  ];

  for shader_descriptions {
    compile_shader_and_save_on_disk(it);
  }
}

#if AT_COMPILE_TIME {
  #run {
    build();
    compile_shaders();
  }
} else {

  #import "System";

  // Run shader compiler only for debug
  main :: () {
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    compile_shaders();
  }
}

#import "Basic";
#import "Compiler";
#import "File";
#import "String";
#import "shader-compiler";
