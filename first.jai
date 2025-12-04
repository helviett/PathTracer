build :: () {
  w := compiler_create_workspace();
  o := get_build_options();
  o.output_executable_name = "path_tracer";
  set_optimization(*o, .DEBUG);
  set_build_options(o, w);
  add_build_file(tprint("%main.jai", #filepath), w);

  set_build_options_dc(.{do_output = false});
}

#run build();

#import "Basic";
#import "Compiler";
