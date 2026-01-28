Handle :: #type, distinct u64;

null_handle : Handle : 0xFFFFFFFF;

ObjectPool :: struct ($T: Type, $HT: Type = Handle) {
  objects: [..]T;
  free_list: [..]u32;
}

add_object :: (using pool: *ObjectPool($T, $HT), object: T) -> HT {
  if free_list.count > 0 {
    index := pop(*free_list);
    objects[index] = object;

    return cast(HT) index;
  }

  index := objects.count;
  array_add(*objects, object);

  return cast(HT) index;
}

remove_object :: (using pool: *ObjectPool($T, $HT), handle: HT) -> T, bool {
  index := cast(u64) handle;

  if index < cast(u64) objects.count {
    array_add(*free_list, cast(u32) index);
    object := objects[index];
    objects[index] = .{};

    return object, true;
  }

  return .{}, false;
}

try_get_object :: (using pool: ObjectPool($T, $HT), handle: HT) -> T, bool {
  index := cast(u64) handle;

  if index < cast(u64) objects.count {
    return objects[index], true;
  }

  return .{}, false;
}

get_object :: (using pool: ObjectPool($T, $HT), handle: HT) -> T {
  object, success := try_get_object(pool, handle);
  assert(success);

  return object;
}

reset :: (using pool: *ObjectPool($T, $HT)) {
  array_reset(*objects);
  array_reset(*free_list);
}

#scope_module

#import "Basic";
