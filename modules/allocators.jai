LinearAllocator :: struct {
  offset: u64;
  mem_size: u64;
}

Allocation :: struct {
  offset: u64;
}

init :: (using allocator: *LinearAllocator, size: u64) {
  offset = 0;
  mem_size = size;
}

alloc :: (using allocator: *LinearAllocator, size: u64, alignment: u64) -> Allocation {
  aligned_offset := align_pot(allocator.offset, alignment);
  assert(aligned_offset + size <= mem_size);
  allocation := Allocation.{ offset = aligned_offset };
  offset = aligned_offset + size;

  return allocation;
}

free :: (using allocator: *LinearAllocator, allocation: Allocation) {
  // no-op
}

reset :: (using allocator: *LinearAllocator) {
  allocator.offset = 0;
}

align_pot :: inline (value: $T, alignment: T) -> T {
  return (value + alignment - 1) & ~(alignment - 1);
}

#scope_module

#import "Basic";
