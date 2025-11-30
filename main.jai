#import "Basic";
#import "Windows";
#import "dxgi";
#import "d3d12"()(INCLUDE_DEBUG_BINDINGS = true);

Window :: #import "Window_Creation";
Input  :: #import "Input";

width :: 1920;
height :: 1080;

main :: () {
  hwnd := Window.create_window(width, height, "PathTracing");

  result, device := create_device();

  if !result {
    return;
  }

  quit := false;
  while !quit { 
      Input.update_window_events();
      for Input.events_this_frame {
          if it.type == .QUIT then quit = true;
      }
  }
}

Device :: struct
{
  factory: *IDXGIFactory6;
  debug: *ID3D12Debug1;
  adapter: *IDXGIAdapter2;
  device: ID3D12Device;
}

create_device :: () -> bool, Device {
  debug: *ID3D12Debug1;

  rif :: (res: HRESULT, msg: string) #expand {
    if FAILED(res) {
      print(msg);
      `return false, .{};
    }
  }

  dxgi_factory_flags: u32;

  if SUCCEEDED(D3D12GetDebugInterface(*uid(ID3D12Debug1_UUID), xx *debug)) {
    ID3D12Debug1_EnableDebugLayer(debug);

    dxgi_factory_flags |= DXGI_CREATE_FACTORY_DEBUG;
  }

  factory2 : *IDXGIFactory2;
  result := CreateDXGIFactory2(dxgi_factory_flags, *uid(IDXGIFactory2_UUID), xx *factory2);

  rif(result, "Failed to create factory");

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

  device: ID3D12Device5;

  result = D3D12CreateDevice(adapter, .D3D_FEATURE_LEVEL_12_2, *uid(ID3D12Device5_UUID), xx *device);

  rif(result, "Failed to create device");

  return true, .{
    factory = factory6,
    debug = debug,
    adapter = adapter,
    device = device,
  };
}
