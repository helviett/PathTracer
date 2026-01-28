#define ComputeRootSignature ""

[RootSignature(ComputeRootSignature)]
[numthreads(8, 8, 1)]
void cs(uint gid : SV_DispatchThreadID) {
}
