to_radians :: Math.PI / 180;
to_degrees :: 180 / Math.PI;

Vector3 :: struct {
  x, y, z: float;
}

Vector4 :: struct {
  x, y, z, w: float;

  #overlay (x) xyz: Vector3;
}

Matrix44 :: struct {
  v: [4][4]float;

  #overlay (v) elements: [16]float;
  #overlay (v) cols: [4]Vector4;
}

identity :: inline () -> Matrix44 {
  return .{
    .[
      .[1, 0, 0, 0],
      .[0, 1, 0, 0],
      .[0, 0, 1, 0],
      .[0, 0, 0, 1],
    ]
  };
}

mul :: (l: Matrix44, r: Matrix44) -> Matrix44 {
  res: Matrix44 = ---;
  res.v[0][0] = l.v[0][0] * r.v[0][0] + l.v[1][0] * r.v[0][1] + l.v[2][0] * r.v[0][2] + l.v[3][0] * r.v[0][3];
  res.v[1][0] = l.v[0][0] * r.v[1][0] + l.v[1][0] * r.v[1][1] + l.v[2][0] * r.v[1][2] + l.v[3][0] * r.v[1][3];
  res.v[2][0] = l.v[0][0] * r.v[2][0] + l.v[1][0] * r.v[2][1] + l.v[2][0] * r.v[2][2] + l.v[3][0] * r.v[2][3];
  res.v[3][0] = l.v[0][0] * r.v[3][0] + l.v[1][0] * r.v[3][1] + l.v[2][0] * r.v[3][2] + l.v[3][0] * r.v[3][3];

  res.v[0][1] = l.v[0][1] * r.v[0][0] + l.v[1][1] * r.v[0][1] + l.v[2][1] * r.v[0][2] + l.v[3][1] * r.v[0][3];
  res.v[1][1] = l.v[0][1] * r.v[1][0] + l.v[1][1] * r.v[1][1] + l.v[2][1] * r.v[1][2] + l.v[3][1] * r.v[1][3];
  res.v[2][1] = l.v[0][1] * r.v[2][0] + l.v[1][1] * r.v[2][1] + l.v[2][1] * r.v[2][2] + l.v[3][1] * r.v[2][3];
  res.v[3][1] = l.v[0][1] * r.v[3][0] + l.v[1][1] * r.v[3][1] + l.v[2][1] * r.v[3][2] + l.v[3][1] * r.v[3][3];

  res.v[0][2] = l.v[0][2] * r.v[0][0] + l.v[1][2] * r.v[0][1] + l.v[2][2] * r.v[0][2] + l.v[3][2] * r.v[0][3];
  res.v[1][2] = l.v[0][2] * r.v[1][0] + l.v[1][2] * r.v[1][1] + l.v[2][2] * r.v[1][2] + l.v[3][2] * r.v[1][3];
  res.v[2][2] = l.v[0][2] * r.v[2][0] + l.v[1][2] * r.v[2][1] + l.v[2][2] * r.v[2][2] + l.v[3][2] * r.v[2][3];
  res.v[3][2] = l.v[0][2] * r.v[3][0] + l.v[1][2] * r.v[3][1] + l.v[2][2] * r.v[3][2] + l.v[3][2] * r.v[3][3];

  res.v[0][3] = l.v[0][3] * r.v[0][0] + l.v[1][3] * r.v[0][1] + l.v[2][3] * r.v[0][2] + l.v[3][3] * r.v[0][3];
  res.v[1][3] = l.v[0][3] * r.v[1][0] + l.v[1][3] * r.v[1][1] + l.v[2][3] * r.v[1][2] + l.v[3][3] * r.v[1][3];
  res.v[2][3] = l.v[0][3] * r.v[2][0] + l.v[1][3] * r.v[2][1] + l.v[2][3] * r.v[2][2] + l.v[3][3] * r.v[2][3];
  res.v[3][3] = l.v[0][3] * r.v[3][0] + l.v[1][3] * r.v[3][1] + l.v[2][3] * r.v[3][2] + l.v[3][3] * r.v[3][3];

  return res;
}

mul :: (m: Matrix44, v: Vector4) -> Vector4 {
  return m.cols[0] * v.x + m.cols[1] * v.y + m.cols[2] * v.z + m.cols[3] * v.w;
}

operator * :: (l: Matrix44, r: Matrix44) -> Matrix44 {
  return inline mul(l, r);
}

operator * :: (m: Matrix44, v: Vector4) -> Vector4 {
  return inline mul(m, v);
}

inverse :: (m: Matrix44) -> Matrix44 {
  a := m.cols[0].xyz;
  b := m.cols[1].xyz;
  c := m.cols[2].xyz;
  d := m.cols[3].xyz;

  x := m.v[0][3];
  y := m.v[1][3];
  z := m.v[2][3];
  w := m.v[3][3];

  s := cross(a, b);
  t := cross(c, d);
  u := a * y - b * x;
  v := c * w - d * z;

  inv_det := 1.0 / (dot(s, v) + dot(t, u));
  s *= inv_det;
  t *= inv_det;
  u *= inv_det;
  v *= inv_det;

  r0 := cross(b, v) + t * y;
  r1 := cross(v, a) - t * x;
  r2 := cross(d, u) + s * w;
  r3 := cross(u, c) - s * z;

  return from_rows(
    .{ xyz = r0, w = -dot(b, t) },
    .{ xyz = r1, w =  dot(a, t) },
    .{ xyz = r2, w = -dot(d, s) },
    .{ xyz = r3, w =  dot(c, s) },
  );
}

inverse_affine :: (m: Matrix44) -> Matrix44 {
  a := m.cols[0].xyz;
  b := m.cols[1].xyz;
  c := m.cols[2].xyz;
  d := m.cols[3].xyz;

  x := m.v[0][3];
  y := m.v[1][3];
  z := m.v[2][3];
  w := m.v[3][3];

  s := cross(a, b);
  t := cross(c, d);

  inv_det := 1.0 / dot(s, c);
  s *= inv_det;
  t *= inv_det;
  v := c * inv_det;

  r0 := cross(b, v);
  r1 := cross(v, a);

  return from_rows(
    .{ xyz = r0, w = -dot(b, t) },
    .{ xyz = r1, w =  dot(a, t) },
    .{ xyz = s,  w = -dot(d, s) },
    .{ 0, 0, 0, 1},
  );
}

from_rows :: inline (r0: Vector4, r1: Vector4, r2: Vector4, r3: Vector4) -> Matrix44 {
  return .{
    cols = .[
      .{ r0.x, r1.x, r2.x, r3.x, },
      .{ r0.y, r1.y, r2.y, r3.y, },
      .{ r0.z, r1.z, r2.z, r3.z, },
      .{ r0.w, r1.w, r2.w, r3.w, },
    ]
  };
}

transpose :: inline (m: Matrix44) -> Matrix44 {
  return from_rows(
    m.cols[0],
    m.cols[1],
    m.cols[2],
    m.cols[3]
  );
}

rotate_x :: inline (angle: float) -> Matrix44 {
  sina := Math.sin(angle);
  cosa := Math.cos(angle);
  return .{
    v = .[
      .[1, 0, 0, 0],
      .[0, cosa, sina, 0],
      .[0, -sina, cosa, 0],
      .[0, 0, 0, 1],
    ]
  };
}

rotate_y :: inline (angle: float) -> Matrix44 {
  sina := Math.sin(angle);
  cosa := Math.cos(angle);
  return .{
    v = .[
      .[cosa, 0, -sina, 0],
      .[0, 1, 0, 0],
      .[sina, 0, cosa, 0],
      .[0, 0, 0, 1],
    ]
  };
}

rotate_z :: inline (angle: float) -> Matrix44 {
  sina := Math.sin(angle);
  cosa := Math.cos(angle);
  return .{
    v = .[
      .[cosa, sina, 0, 0],
      .[-sina, cosa, 0, 0],
      .[0, 0, 1, 0],
      .[0, 0, 0, 1],
    ]
  };
}

scale :: inline (x: float, y: float, z: float) -> Matrix44 {
  return from_rows(
    .{ x, 0, 0, 0 },
    .{ 0, y, 0, 0 },
    .{ 0, 0, z, 0 },
    .{ 0, 0, 0, 1}
  );
}

translate :: inline (x: float, y: float, z: float) -> Matrix44 {
  return from_rows(
    .{ 1, 0, 0, x },
    .{ 0, 1, 0, y },
    .{ 0, 0, 1, z },
    .{ 0, 0, 0, 1}
  );
}

operator * :: inline (v: Vector4, s: float) -> Vector4 #symmetric {
  return .{ x = v.x * s, y = v.y * s, z = v.z * s, w = v.w * s };
}

operator / :: inline (v: Vector4, s: float) -> Vector4 {
  return .{ x = v.x / s, y = v.y / s, z = v.z / s, w = v.w / s };
}

operator * :: inline (l: Vector4, r: Vector4) -> Vector4 {
  return .{ x = l.x * r.x, y = l.y * r.y, z = l.z * r.z, w = l.w * r.w };
}

operator + :: inline (l: Vector4, r: Vector4) -> Vector4 {
  return .{ x = l.x + r.x, y = l.y + r.y, z = l.z + r.z, w = l.w + r.w };
}

operator - :: inline (l: Vector4, r: Vector4) -> Vector4 {
  return .{ x = l.x - r.x, y = l.y - r.y, z = l.z - r.z, w = l.w - r.w };
}

dot :: inline (l: Vector4, r: Vector4) -> float {
  return l.x * r.x + l.y * r.y + l.z * r.z + l.w * r.w;
}

operator * :: inline (v: Vector3, s: float) -> Vector3 #symmetric {
  return .{ x = v.x * s, y = v.y * s, z = v.z * s };
}

operator / :: inline (v: Vector3, s: float) -> Vector3 {
  return .{ x = v.x / s, y = v.y / s, z = v.z / s };
}

operator * :: inline (l: Vector3, r: Vector3) -> Vector3 {
  return .{ x = l.x * r.x, y = l.y * r.y, z = l.z * r.z };
}

operator + :: inline (l: Vector3, r: Vector3) -> Vector3 {
  return .{ x = l.x + r.x, y = l.y + r.y, z = l.z + r.z };
}

operator - :: inline (l: Vector3, r: Vector3) -> Vector3 {
  return .{ x = l.x - r.x, y = l.y - r.y, z = l.z - r.z };
}

cross :: inline (l: Vector3, r: Vector3) -> Vector3 {
  return .{ l.y * r.z - l.z * r.y, l.z * r.x - l.x * r.z, l.x * r.y - l.y * r.x };
}

dot :: inline (l: Vector3, r: Vector3) -> float {
  return l.x * r.x + l.y * r.y + l.z * r.z;
}

length_sq :: inline (v: $T) -> float {
  return dot(v, v);
}

length :: inline (v: $T) -> float {
  return Math.sqrt(length_sq(v));
}

normalize :: inline (v: $T) -> T {
  len := length(v);

  return v / len;
}

make_ortho_projection :: inline (width: float, height: float, near: float, far: float) -> Matrix44 {
  d := far - near;
  return from_rows(
    .{ 2 / width, 0, 0, 0 },
    .{ 0, 2 / height, 0, 0 },
    .{ 0, 0, 1 / -d, -near / d },
    .{ 0, 0, 0, 1 }
  );
}

make_perspective_projection :: inline (fov_y: float, aspect_ratio: float, near: float, far: float) -> Matrix44 {
  g := 1.0 / Math.tan(fov_y / 2.0);
  return from_rows(
    .{ g / aspect_ratio, 0, 0, 0 },
    .{ 0, g, 0, 0 },
    .{ 0, 0, far / (near - far), (far * near) / (near - far) },
    .{ 0, 0, -1, 0},
  );
}

look_at :: inline (camera_position: Vector3, look_at_position: Vector3, world_up: Vector3 = .{0, 1, 0}) -> Matrix44 {
  forward := normalize(camera_position - look_at_position);
  assert(length_sq(cross(world_up, forward)) > 0.000001);
  right := normalize(cross(world_up, forward));
  up := cross(forward, right);

  camera_to_world := Matrix44.{
    cols = .[
      .{ xyz = right },
      .{ xyz = up },
      .{ xyz = forward },
      .{ xyz = camera_position, w = 1}
    ]
  };

  // CtW = T * R
  // WtC = inv(T * R) = inv(R) * inv(T) = t(R) * inv(T) = t(R) * translation(-camera_position)
  world_to_camera := from_rows(
    .{ xyz = right, w = -dot(right, camera_position) },
    .{ xyz = up, w = -dot(up, camera_position) },
    .{ xyz = forward, w = -dot(forward, camera_position) },
    .{ 0, 0, 0, 1 },
  );

  return world_to_camera;
}

#scope_module

Math :: #import "Math";
#import "Basic";
