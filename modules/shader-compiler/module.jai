ShaderStage :: enum {
  Compute;
  Vertex;
  Pixel;
}

ShaderCompilationArgs :: struct {
  code: string;
  stage: ShaderStage;
  debug: bool;
  embed_debug: bool;
  defines: []string;
}

ShaderCompilationResult :: struct {
  success: bool;
  bytecode: []u8;
  pdb: []u8;
  pdb_name: string;
}

ShaderDescription :: struct {
  path: string;
  output_path: string;
  stage: ShaderStage;
  debug: bool;
  pdb_dir: string;
  defines: []string;
}

compile_shader :: (using args: ShaderCompilationArgs) -> ShaderCompilationResult {
  result: HRESULT;
  compiler: *IDxcCompiler;
  utils: *IDxcUtils;
  defer safe_release(compiler);
  defer safe_release(utils);

  DxcCreateInstance(*CLSID_DxcCompiler, *IDxcCompiler3_UID, xx *compiler);
  DxcCreateInstance(*CLSID_DxcUtils, *IDxcUtils_UID, xx *utils);

  code_blob: *IDxcBlobEncoding;
  defer safe_release(code_blob);
  result = IDxcUtils_CreateBlobFromPinned(utils, code.data, cast(u32) code.count, cast(u32) CP_UTF8, *code_blob);
  rif(result);

  include_handler : *IDxcIncludeHandler;
  defer safe_release(include_handler);
  result = IDxcUtils_CreateDefaultIncludeHandler(utils, *include_handler);
  rif(result);

  code_buffer: DxcBuffer;
  code_buffer.Ptr = IDxcBlob_GetBufferPointer(code_blob);
  code_buffer.Size = IDxcBlob_GetBufferSize(code_blob);

  args: [..]string;
  args.allocator = temp;

  target: string;
  entry: string;
  if #complete stage == {
    case .Compute; target = "cs_6_6"; entry = "cs";
    case .Vertex; target = "vs_6_6"; entry = "vs";
    case .Pixel; target = "ps_6_6"; entry = "ps";
  }

  array_add(*args, "-T");
  array_add(*args, target);
  array_add(*args, "-E");
  array_add(*args, entry);

  if debug {
    array_add(*args, "-Zi");
    array_add(*args, "-Zss");

    if !embed_debug {
      array_add(*args, "-Qstrip_debug");
    }
  }

  for defines {
    array_add(*args, "-D");
    array_add(*args, it);
  }

  args_wide: [..]*u16;
  args_wide.allocator = temp;

  for args {
    array_add(*args_wide, utf8_to_wide(it,, allocator=temp));
  }

  results: *IDxcResult;
  bytecode: *IDxcBlob;
  errors: *IDxcBlobUtf8;
  pdb: *IDxcBlob;
  pdb_path: *IDxcBlobWide;
  defer safe_release(results);
  defer safe_release(bytecode);
  defer safe_release(errors);
  defer safe_release(pdb);
  defer safe_release(pdb_path);

  result = IDxcCompiler3_Compile(xx compiler, *code_buffer, cast(**s16) args_wide.data, cast(u32) args_wide.count, include_handler, *IDxcResult_UID, xx *results);
  rif(result);

  if IDxcResult_HasOutput(results, .ERRORS) {
    IDxcResult_GetOutput(results, .ERRORS, *IDxcBlobUtf8_UID, xx *errors, null);
    print("%", string.{ data = IDxcBlob_GetBufferPointer(errors), count = xx IDxcBlob_GetBufferSize(errors) });
  }

  IDxcOperationResult_GetStatus(results, *result);
  rif(result);

  out_result: ShaderCompilationResult;

  if IDxcResult_HasOutput(results, .OBJECT) {
    IDxcResult_GetOutput(results, .OBJECT, *IDxcBlob_UID, xx *bytecode, null);
    count: s64 = xx IDxcBlob_GetBufferSize(bytecode);
    out_result.bytecode = .{ data = alloc(count,, allocator=temp), count = count, };
    memcpy(out_result.bytecode.data, IDxcBlob_GetBufferPointer(bytecode), count);
  }

  if IDxcResult_HasOutput(results, .PDB) {
    IDxcResult_GetOutput(results, .PDB, *IDxcBlob_UID, xx *pdb, *pdb_path);
    count: s64 = xx IDxcBlob_GetBufferSize(pdb);
    out_result.pdb = .{ data = alloc(count,, allocator=temp), count = count, };
    memcpy(out_result.pdb.data, IDxcBlob_GetBufferPointer(pdb), count);
    out_result.pdb_name = wide_to_utf8(xx IDxcBlobWide_GetStringPointer(pdb_path),, allocator=temp);
  }

  out_result.success = true;
  return out_result;
}

compile_shader_and_save_on_disk :: (using shader_desc: ShaderDescription) -> bool {
  auto_release_temp();


  code := read_entire_file(shader_desc.path);
  defer free(code);
  args := ShaderCompilationArgs.{
    code = code,
    stage = stage,
    debug = debug,
    embed_debug = !pdb_dir,
    defines = defines,
   };

  results := compile_shader(args);

  if !results.success {
    return false;
  }

  if results.bytecode {
    file, is_opened := file_open(output_path, for_writing = true);
    defer file_close(*file);

    if !is_opened {
      log_error("Can't open \"%\"", output_path);
      return false;
    }

    file_write(*file, results.bytecode.data, results.bytecode.count);
  }

  if results.pdb {
    pdb_path := path_join(pdb_dir, results.pdb_name,, allocator=temp);
    file, is_opened := file_open(pdb_path, for_writing = true);
    defer file_close(*file);

    if !is_opened {
      log_error("Can't open \"%\"", pdb_path);
      return false;
    }

    file_write(*file, results.pdb.data, results.pdb.count);
  }


  return true;
}

#scope_module

rif :: (res: HRESULT, msg: string = "") #expand {
  if FAILED(res) {
    print("Error 0x%: %", FormatInt.{value = cast, no_check(u32) res, base = 16}, msg);
    `return .{};
  }
}

CLSID_DxcUtils :: #run uid("6245D6AF-66E0-48FD-80B4-4D271796748C");
CLSID_DxcCompiler :: #run uid("73E22D93-E6CE-47F3-B5BF-F0664F39C1B0");
IDxcUtils_UID :: #run uid("4605C4CB-2019-492A-ADA4-65F20BB7D67F");
IDxcCompiler3_UID :: #run uid("228B4687-5A6A-4730-900C-9702B2203F54");
IDxcResult_UID :: #run uid("58346CDA-DDE7-4497-9461-6F87AF5E0659");
IDxcBlobUtf8_UID :: #run uid("3DA636C9-BA71-4024-A301-30CBF125305B");
IDxcBlob_UID :: #run uid("8BA5FB08-5195-40e2-AC58-0D989C3A0102");
IDxcBlobWide_UID :: #run uid("A3F84EAB-0FAA-497E-A39C-EE6ED60B2D84");

// Ignore now but probably worth trying include objidl.h into generator.
IMalloc :: struct {};
IStream :: struct {};
BSTR :: struct {};

#import "Basic";
#import "String";
#import "Windows";
#import "Windows_Utf8";
#import "File";
#import "d3d12";
#load "dxc_bindings.jai";
