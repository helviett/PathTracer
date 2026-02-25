AT_COMPILE_TIME :: true;
CGLTF_PATH :: "../../external/cgltf";

#run,stallable {
  set_build_options_dc(.{do_output=false});
  if !generate_bindings() {
    compiler_set_workspace_status(.FAILED);
  }
}

generate_bindings :: () -> bool {
  build_cpp_static_lib("cgltf", "cgltf.c");

  output_filename := "cgltf_bindings.jai";
  options: Generate_Bindings_Options;
  {
    using options;

    array_add(*source_files, tprint("%/cgltf.h", CGLTF_PATH));
    array_add(*libraries, .{ filename = "cgltf", });
  }

  return generate_bindings(options, output_filename);
}

#scope_file

#import "Basic";
#import "Bindings_Generator";
#import "Compiler";
#import "File";
#import "String";
#import "BuildCpp";
