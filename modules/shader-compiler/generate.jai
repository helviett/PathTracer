DXC_PATH :: "../../external/dxc";

#run,stallable {
  set_build_options_dc(.{do_output=false});
  if !generate_bindings() {
    compiler_set_workspace_status(.FAILED);
  }
}

generate_bindings :: () -> bool {
  output_filename: string;
  options: Generate_Bindings_Options;
  {
    using options;

    output_filename = "dxc_bindings.jai";
    array_add(*library_search_paths, tprint("%/bin/x64", DXC_PATH));
    array_add(*libraries, .{filename="dxcompiler.dll"});

    array_add(*source_files, "d3dcompiler.h");
    array_add(*source_files, tprint("%/inc/dxcapi.h", DXC_PATH));

    array_add(*extra_clang_arguments, "-x", "c++", "-DWIN32_LEAN_AND_MEAN");

    mimic_spacing_flags &= ~(Mimic_Spacing_Flags.VTABLE);
    log_stripped_declarations = false;
  }

  return generate_bindings(options, output_filename);
}

#scope_file

#import "Basic";
#import "Bindings_Generator";
#import "Compiler";
#import "File";
#import "String";
