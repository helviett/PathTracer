//
// This file was auto-generated using the following command:
//
// jai ./modules/cgltf/generate.jai
//



cgltf_size :: u64;
cgltf_ssize :: s64;
cgltf_float :: float;
cgltf_int :: s32;
cgltf_uint :: u32;
cgltf_bool :: s32;

cgltf_file_type :: enum s32 {
    invalid  :: 0;
    gltf     :: 1;
    glb      :: 2;
    max_enum :: 3;

    cgltf_file_type_invalid  :: invalid;
    cgltf_file_type_gltf     :: gltf;
    cgltf_file_type_glb      :: glb;
    cgltf_file_type_max_enum :: max_enum;
}

cgltf_result :: enum s32 {
    success         :: 0;
    data_too_short  :: 1;
    unknown_format  :: 2;
    invalid_json    :: 3;
    invalid_gltf    :: 4;
    invalid_options :: 5;
    file_not_found  :: 6;
    io_error        :: 7;
    out_of_memory   :: 8;
    legacy_gltf     :: 9;
    max_enum        :: 10;

    cgltf_result_success         :: success;
    cgltf_result_data_too_short  :: data_too_short;
    cgltf_result_unknown_format  :: unknown_format;
    cgltf_result_invalid_json    :: invalid_json;
    cgltf_result_invalid_gltf    :: invalid_gltf;
    cgltf_result_invalid_options :: invalid_options;
    cgltf_result_file_not_found  :: file_not_found;
    cgltf_result_io_error        :: io_error;
    cgltf_result_out_of_memory   :: out_of_memory;
    cgltf_result_legacy_gltf     :: legacy_gltf;
    cgltf_result_max_enum        :: max_enum;
}

cgltf_memory_options :: struct {
    alloc_func: #type (user: *void, size: cgltf_size) -> *void #c_call;
    free_func:  #type (user: *void, ptr: *void) -> void #c_call;
    user_data:  *void;
}

cgltf_file_options :: struct {
    read:      #type (memory_options: *cgltf_memory_options, file_options: *cgltf_file_options, path: *u8, size: *cgltf_size, data: **void) -> cgltf_result #c_call;
    release:   #type (memory_options: *cgltf_memory_options, file_options: *cgltf_file_options, data: *void) -> void #c_call;
    user_data: *void;
}

cgltf_options :: struct {
    type:             cgltf_file_type; /* invalid == auto detect */
    json_token_count: cgltf_size; /* 0 == auto */
    memory:           cgltf_memory_options;
    file:             cgltf_file_options;
}

cgltf_buffer_view_type :: enum s32 {
    invalid  :: 0;
    indices  :: 1;
    vertices :: 2;
    max_enum :: 3;

    cgltf_buffer_view_type_invalid  :: invalid;
    cgltf_buffer_view_type_indices  :: indices;
    cgltf_buffer_view_type_vertices :: vertices;
    cgltf_buffer_view_type_max_enum :: max_enum;
}

cgltf_attribute_type :: enum s32 {
    invalid  :: 0;
    position :: 1;
    normal   :: 2;
    tangent  :: 3;
    texcoord :: 4;
    color    :: 5;
    joints   :: 6;
    weights  :: 7;
    custom   :: 8;
    max_enum :: 9;

    cgltf_attribute_type_invalid  :: invalid;
    cgltf_attribute_type_position :: position;
    cgltf_attribute_type_normal   :: normal;
    cgltf_attribute_type_tangent  :: tangent;
    cgltf_attribute_type_texcoord :: texcoord;
    cgltf_attribute_type_color    :: color;
    cgltf_attribute_type_joints   :: joints;
    cgltf_attribute_type_weights  :: weights;
    cgltf_attribute_type_custom   :: custom;
    cgltf_attribute_type_max_enum :: max_enum;
}

cgltf_component_type :: enum s32 {
    invalid  :: 0;
    r_8      :: 1;
    r_8u     :: 2;
    r_16     :: 3;
    r_16u    :: 4;
    r_32u    :: 5;
    r_32f    :: 6;
    max_enum :: 7;

    cgltf_component_type_invalid  :: invalid;
    cgltf_component_type_r_8      :: r_8;
    cgltf_component_type_r_8u     :: r_8u;
    cgltf_component_type_r_16     :: r_16;
    cgltf_component_type_r_16u    :: r_16u;
    cgltf_component_type_r_32u    :: r_32u;
    cgltf_component_type_r_32f    :: r_32f;
    cgltf_component_type_max_enum :: max_enum;
}

cgltf_type :: enum s32 {
    invalid  :: 0;
    scalar   :: 1;
    vec2     :: 2;
    vec3     :: 3;
    vec4     :: 4;
    mat2     :: 5;
    mat3     :: 6;
    mat4     :: 7;
    max_enum :: 8;

    cgltf_type_invalid  :: invalid;
    cgltf_type_scalar   :: scalar;
    cgltf_type_vec2     :: vec2;
    cgltf_type_vec3     :: vec3;
    cgltf_type_vec4     :: vec4;
    cgltf_type_mat2     :: mat2;
    cgltf_type_mat3     :: mat3;
    cgltf_type_mat4     :: mat4;
    cgltf_type_max_enum :: max_enum;
}

cgltf_primitive_type :: enum s32 {
    invalid        :: 0;
    points         :: 1;
    lines          :: 2;
    line_loop      :: 3;
    line_strip     :: 4;
    triangles      :: 5;
    triangle_strip :: 6;
    triangle_fan   :: 7;
    max_enum       :: 8;

    cgltf_primitive_type_invalid        :: invalid;
    cgltf_primitive_type_points         :: points;
    cgltf_primitive_type_lines          :: lines;
    cgltf_primitive_type_line_loop      :: line_loop;
    cgltf_primitive_type_line_strip     :: line_strip;
    cgltf_primitive_type_triangles      :: triangles;
    cgltf_primitive_type_triangle_strip :: triangle_strip;
    cgltf_primitive_type_triangle_fan   :: triangle_fan;
    cgltf_primitive_type_max_enum       :: max_enum;
}

cgltf_alpha_mode :: enum s32 {
    opaque   :: 0;
    mask     :: 1;
    blend    :: 2;
    max_enum :: 3;

    cgltf_alpha_mode_opaque   :: opaque;
    cgltf_alpha_mode_mask     :: mask;
    cgltf_alpha_mode_blend    :: blend;
    cgltf_alpha_mode_max_enum :: max_enum;
}

cgltf_animation_path_type :: enum s32 {
    invalid     :: 0;
    translation :: 1;
    rotation    :: 2;
    scale       :: 3;
    weights     :: 4;
    max_enum    :: 5;

    cgltf_animation_path_type_invalid     :: invalid;
    cgltf_animation_path_type_translation :: translation;
    cgltf_animation_path_type_rotation    :: rotation;
    cgltf_animation_path_type_scale       :: scale;
    cgltf_animation_path_type_weights     :: weights;
    cgltf_animation_path_type_max_enum    :: max_enum;
}

cgltf_interpolation_type :: enum s32 {
    linear       :: 0;
    step         :: 1;
    cubic_spline :: 2;
    max_enum     :: 3;

    cgltf_interpolation_type_linear       :: linear;
    cgltf_interpolation_type_step         :: step;
    cgltf_interpolation_type_cubic_spline :: cubic_spline;
    cgltf_interpolation_type_max_enum     :: max_enum;
}

cgltf_camera_type :: enum s32 {
    invalid      :: 0;
    perspective  :: 1;
    orthographic :: 2;
    max_enum     :: 3;

    cgltf_camera_type_invalid      :: invalid;
    cgltf_camera_type_perspective  :: perspective;
    cgltf_camera_type_orthographic :: orthographic;
    cgltf_camera_type_max_enum     :: max_enum;
}

cgltf_light_type :: enum s32 {
    invalid     :: 0;
    directional :: 1;
    point       :: 2;
    spot        :: 3;
    max_enum    :: 4;

    cgltf_light_type_invalid     :: invalid;
    cgltf_light_type_directional :: directional;
    cgltf_light_type_point       :: point;
    cgltf_light_type_spot        :: spot;
    cgltf_light_type_max_enum    :: max_enum;
}

cgltf_data_free_method :: enum s32 {
    none         :: 0;
    file_release :: 1;
    memory_free  :: 2;
    max_enum     :: 3;

    cgltf_data_free_method_none         :: none;
    cgltf_data_free_method_file_release :: file_release;
    cgltf_data_free_method_memory_free  :: memory_free;
    cgltf_data_free_method_max_enum     :: max_enum;
}

cgltf_extras :: struct {
    start_offset: cgltf_size; /* this field is deprecated and will be removed in the future; use data instead */
    end_offset:   cgltf_size; /* this field is deprecated and will be removed in the future; use data instead */

    data:         *u8;
}

cgltf_extension :: struct {
    name: *u8;
    data: *u8;
}

cgltf_buffer :: struct {
    name:             *u8;
    size:             cgltf_size;
    uri:              *u8;
    data:             *void; /* loaded by cgltf_load_buffers */
    data_free_method: cgltf_data_free_method;
    extras:           cgltf_extras;
    extensions_count: cgltf_size;
    extensions:       *cgltf_extension;
}

cgltf_meshopt_compression_mode :: enum s32 {
    invalid    :: 0;
    attributes :: 1;
    triangles  :: 2;
    indices    :: 3;
    max_enum   :: 4;

    cgltf_meshopt_compression_mode_invalid    :: invalid;
    cgltf_meshopt_compression_mode_attributes :: attributes;
    cgltf_meshopt_compression_mode_triangles  :: triangles;
    cgltf_meshopt_compression_mode_indices    :: indices;
    cgltf_meshopt_compression_mode_max_enum   :: max_enum;
}

cgltf_meshopt_compression_filter :: enum s32 {
    none        :: 0;
    octahedral  :: 1;
    quaternion  :: 2;
    exponential :: 3;
    max_enum    :: 4;

    cgltf_meshopt_compression_filter_none        :: none;
    cgltf_meshopt_compression_filter_octahedral  :: octahedral;
    cgltf_meshopt_compression_filter_quaternion  :: quaternion;
    cgltf_meshopt_compression_filter_exponential :: exponential;
    cgltf_meshopt_compression_filter_max_enum    :: max_enum;
}

cgltf_meshopt_compression :: struct {
    buffer: *cgltf_buffer;
    offset: cgltf_size;
    size:   cgltf_size;
    stride: cgltf_size;
    count:  cgltf_size;
    mode:   cgltf_meshopt_compression_mode;
    filter: cgltf_meshopt_compression_filter;
}

cgltf_buffer_view :: struct {
    name:                    *u8;
    buffer:                  *cgltf_buffer;
    offset:                  cgltf_size;
    size:                    cgltf_size;
    stride:                  cgltf_size; /* 0 == automatically determined by accessor */
    type:                    cgltf_buffer_view_type;
    data:                    *void; /* overrides buffer->data if present, filled by extensions */
    has_meshopt_compression: cgltf_bool;
    meshopt_compression:     cgltf_meshopt_compression;
    extras:                  cgltf_extras;
    extensions_count:        cgltf_size;
    extensions:              *cgltf_extension;
}

cgltf_accessor_sparse :: struct {
    count:                  cgltf_size;
    indices_buffer_view:    *cgltf_buffer_view;
    indices_byte_offset:    cgltf_size;
    indices_component_type: cgltf_component_type;
    values_buffer_view:     *cgltf_buffer_view;
    values_byte_offset:     cgltf_size;
}

cgltf_accessor :: struct {
    name:             *u8;
    component_type:   cgltf_component_type;
    normalized:       cgltf_bool;
    type:             cgltf_type;
    offset:           cgltf_size;
    count:            cgltf_size;
    stride:           cgltf_size;
    buffer_view:      *cgltf_buffer_view;
    has_min:          cgltf_bool;
    min:              [16] cgltf_float;
    has_max:          cgltf_bool;
    max:              [16] cgltf_float;
    is_sparse:        cgltf_bool;
    sparse:           cgltf_accessor_sparse;
    extras:           cgltf_extras;
    extensions_count: cgltf_size;
    extensions:       *cgltf_extension;
}

cgltf_attribute :: struct {
    name:  *u8;
    type:  cgltf_attribute_type;
    index: cgltf_int;
    data:  *cgltf_accessor;
}

cgltf_image :: struct {
    name:             *u8;
    uri:              *u8;
    buffer_view:      *cgltf_buffer_view;
    mime_type:        *u8;
    extras:           cgltf_extras;
    extensions_count: cgltf_size;
    extensions:       *cgltf_extension;
}

cgltf_filter_type :: enum s32 {
    undefined              :: 0;
    nearest                :: 9728;
    linear                 :: 9729;
    nearest_mipmap_nearest :: 9984;
    linear_mipmap_nearest  :: 9985;
    nearest_mipmap_linear  :: 9986;
    linear_mipmap_linear   :: 9987;

    cgltf_filter_type_undefined              :: undefined;
    cgltf_filter_type_nearest                :: nearest;
    cgltf_filter_type_linear                 :: linear;
    cgltf_filter_type_nearest_mipmap_nearest :: nearest_mipmap_nearest;
    cgltf_filter_type_linear_mipmap_nearest  :: linear_mipmap_nearest;
    cgltf_filter_type_nearest_mipmap_linear  :: nearest_mipmap_linear;
    cgltf_filter_type_linear_mipmap_linear   :: linear_mipmap_linear;
}

cgltf_wrap_mode :: enum s32 {
    clamp_to_edge   :: 33071;
    mirrored_repeat :: 33648;
    repeat          :: 10497;

    cgltf_wrap_mode_clamp_to_edge   :: clamp_to_edge;
    cgltf_wrap_mode_mirrored_repeat :: mirrored_repeat;
    cgltf_wrap_mode_repeat          :: repeat;
}

cgltf_sampler :: struct {
    name:             *u8;
    mag_filter:       cgltf_filter_type;
    min_filter:       cgltf_filter_type;
    wrap_s:           cgltf_wrap_mode;
    wrap_t:           cgltf_wrap_mode;
    extras:           cgltf_extras;
    extensions_count: cgltf_size;
    extensions:       *cgltf_extension;
}

cgltf_texture :: struct {
    name:             *u8;
    image:            *cgltf_image;
    sampler:          *cgltf_sampler;
    has_basisu:       cgltf_bool;
    basisu_image:     *cgltf_image;
    has_webp:         cgltf_bool;
    webp_image:       *cgltf_image;
    extras:           cgltf_extras;
    extensions_count: cgltf_size;
    extensions:       *cgltf_extension;
}

cgltf_texture_transform :: struct {
    offset:       [2] cgltf_float;
    rotation:     cgltf_float;
    scale:        [2] cgltf_float;
    has_texcoord: cgltf_bool;
    texcoord:     cgltf_int;
}

cgltf_texture_view :: struct {
    texture:       *cgltf_texture;
    texcoord:      cgltf_int;
    scale:         cgltf_float; /* equivalent to strength for occlusion_texture */
    has_transform: cgltf_bool;
    transform:     cgltf_texture_transform;
}

cgltf_pbr_metallic_roughness :: struct {
    base_color_texture:         cgltf_texture_view;
    metallic_roughness_texture: cgltf_texture_view;

    base_color_factor:          [4] cgltf_float;
    metallic_factor:            cgltf_float;
    roughness_factor:           cgltf_float;
}

cgltf_pbr_specular_glossiness :: struct {
    diffuse_texture:             cgltf_texture_view;
    specular_glossiness_texture: cgltf_texture_view;

    diffuse_factor:              [4] cgltf_float;
    specular_factor:             [3] cgltf_float;
    glossiness_factor:           cgltf_float;
}

cgltf_clearcoat :: struct {
    clearcoat_texture:           cgltf_texture_view;
    clearcoat_roughness_texture: cgltf_texture_view;
    clearcoat_normal_texture:    cgltf_texture_view;

    clearcoat_factor:            cgltf_float;
    clearcoat_roughness_factor:  cgltf_float;
}

cgltf_transmission :: struct {
    transmission_texture: cgltf_texture_view;
    transmission_factor:  cgltf_float;
}

cgltf_ior :: struct {
    ior: cgltf_float;
}

cgltf_specular :: struct {
    specular_texture:       cgltf_texture_view;
    specular_color_texture: cgltf_texture_view;
    specular_color_factor:  [3] cgltf_float;
    specular_factor:        cgltf_float;
}

cgltf_volume :: struct {
    thickness_texture:    cgltf_texture_view;
    thickness_factor:     cgltf_float;
    attenuation_color:    [3] cgltf_float;
    attenuation_distance: cgltf_float;
}

cgltf_sheen :: struct {
    sheen_color_texture:     cgltf_texture_view;
    sheen_color_factor:      [3] cgltf_float;
    sheen_roughness_texture: cgltf_texture_view;
    sheen_roughness_factor:  cgltf_float;
}

cgltf_emissive_strength :: struct {
    emissive_strength: cgltf_float;
}

cgltf_iridescence :: struct {
    iridescence_factor:            cgltf_float;
    iridescence_texture:           cgltf_texture_view;
    iridescence_ior:               cgltf_float;
    iridescence_thickness_min:     cgltf_float;
    iridescence_thickness_max:     cgltf_float;
    iridescence_thickness_texture: cgltf_texture_view;
}

cgltf_diffuse_transmission :: struct {
    diffuse_transmission_texture:       cgltf_texture_view;
    diffuse_transmission_factor:        cgltf_float;
    diffuse_transmission_color_factor:  [3] cgltf_float;
    diffuse_transmission_color_texture: cgltf_texture_view;
}

cgltf_anisotropy :: struct {
    anisotropy_strength: cgltf_float;
    anisotropy_rotation: cgltf_float;
    anisotropy_texture:  cgltf_texture_view;
}

cgltf_dispersion :: struct {
    dispersion: cgltf_float;
}

cgltf_material :: struct {
    name:                        *u8;
    has_pbr_metallic_roughness:  cgltf_bool;
    has_pbr_specular_glossiness: cgltf_bool;
    has_clearcoat:               cgltf_bool;
    has_transmission:            cgltf_bool;
    has_volume:                  cgltf_bool;
    has_ior:                     cgltf_bool;
    has_specular:                cgltf_bool;
    has_sheen:                   cgltf_bool;
    has_emissive_strength:       cgltf_bool;
    has_iridescence:             cgltf_bool;
    has_diffuse_transmission:    cgltf_bool;
    has_anisotropy:              cgltf_bool;
    has_dispersion:              cgltf_bool;
    pbr_metallic_roughness:      cgltf_pbr_metallic_roughness;
    pbr_specular_glossiness:     cgltf_pbr_specular_glossiness;
    clearcoat:                   cgltf_clearcoat;
    ior:                         cgltf_ior;
    specular:                    cgltf_specular;
    sheen:                       cgltf_sheen;
    transmission:                cgltf_transmission;
    volume:                      cgltf_volume;
    emissive_strength:           cgltf_emissive_strength;
    iridescence:                 cgltf_iridescence;
    diffuse_transmission:        cgltf_diffuse_transmission;
    anisotropy:                  cgltf_anisotropy;
    dispersion:                  cgltf_dispersion;
    normal_texture:              cgltf_texture_view;
    occlusion_texture:           cgltf_texture_view;
    emissive_texture:            cgltf_texture_view;
    emissive_factor:             [3] cgltf_float;
    alpha_mode:                  cgltf_alpha_mode;
    alpha_cutoff:                cgltf_float;
    double_sided:                cgltf_bool;
    unlit:                       cgltf_bool;
    extras:                      cgltf_extras;
    extensions_count:            cgltf_size;
    extensions:                  *cgltf_extension;
}

cgltf_material_mapping :: struct {
    variant:  cgltf_size;
    material: *cgltf_material;
    extras:   cgltf_extras;
}

cgltf_morph_target :: struct {
    attributes:       *cgltf_attribute;
    attributes_count: cgltf_size;
}

cgltf_draco_mesh_compression :: struct {
    buffer_view:      *cgltf_buffer_view;
    attributes:       *cgltf_attribute;
    attributes_count: cgltf_size;
}

cgltf_mesh_gpu_instancing :: struct {
    attributes:       *cgltf_attribute;
    attributes_count: cgltf_size;
}

cgltf_primitive :: struct {
    type:                       cgltf_primitive_type;
    indices:                    *cgltf_accessor;
    material:                   *cgltf_material;
    attributes:                 *cgltf_attribute;
    attributes_count:           cgltf_size;
    targets:                    *cgltf_morph_target;
    targets_count:              cgltf_size;
    extras:                     cgltf_extras;
    has_draco_mesh_compression: cgltf_bool;
    draco_mesh_compression:     cgltf_draco_mesh_compression;
    mappings:                   *cgltf_material_mapping;
    mappings_count:             cgltf_size;
    extensions_count:           cgltf_size;
    extensions:                 *cgltf_extension;
}

cgltf_mesh :: struct {
    name:               *u8;
    primitives:         *cgltf_primitive;
    primitives_count:   cgltf_size;
    weights:            *cgltf_float;
    weights_count:      cgltf_size;
    target_names:       **u8;
    target_names_count: cgltf_size;
    extras:             cgltf_extras;
    extensions_count:   cgltf_size;
    extensions:         *cgltf_extension;
}

cgltf_skin :: struct {
    name:                  *u8;
    joints:                **cgltf_node;
    joints_count:          cgltf_size;
    skeleton:              *cgltf_node;
    inverse_bind_matrices: *cgltf_accessor;
    extras:                cgltf_extras;
    extensions_count:      cgltf_size;
    extensions:            *cgltf_extension;
}

cgltf_camera_perspective :: struct {
    has_aspect_ratio: cgltf_bool;
    aspect_ratio:     cgltf_float;
    yfov:             cgltf_float;
    has_zfar:         cgltf_bool;
    zfar:             cgltf_float;
    znear:            cgltf_float;
    extras:           cgltf_extras;
}

cgltf_camera_orthographic :: struct {
    xmag:   cgltf_float;
    ymag:   cgltf_float;
    zfar:   cgltf_float;
    znear:  cgltf_float;
    extras: cgltf_extras;
}

cgltf_camera :: struct {
    name:             *u8;
    type:             cgltf_camera_type;
    data:             union {
        perspective:  cgltf_camera_perspective;
        orthographic: cgltf_camera_orthographic;
    };

    extras:           cgltf_extras;
    extensions_count: cgltf_size;
    extensions:       *cgltf_extension;
}

cgltf_light :: struct {
    name:                  *u8;
    color:                 [3] cgltf_float;
    intensity:             cgltf_float;
    type:                  cgltf_light_type;
    range:                 cgltf_float;
    spot_inner_cone_angle: cgltf_float;
    spot_outer_cone_angle: cgltf_float;
    extras:                cgltf_extras;
}

cgltf_node :: struct {
    name:                    *u8;
    parent:                  *cgltf_node;
    children:                **cgltf_node;
    children_count:          cgltf_size;
    skin:                    *cgltf_skin;
    mesh:                    *cgltf_mesh;
    camera:                  *cgltf_camera;
    light:                   *cgltf_light;
    weights:                 *cgltf_float;
    weights_count:           cgltf_size;
    has_translation:         cgltf_bool;
    has_rotation:            cgltf_bool;
    has_scale:               cgltf_bool;
    has_matrix:              cgltf_bool;
    translation:             [3] cgltf_float;
    rotation:                [4] cgltf_float;
    scale:                   [3] cgltf_float;
    matrix:                  [16] cgltf_float;
    extras:                  cgltf_extras;
    has_mesh_gpu_instancing: cgltf_bool;
    mesh_gpu_instancing:     cgltf_mesh_gpu_instancing;
    extensions_count:        cgltf_size;
    extensions:              *cgltf_extension;
}

cgltf_scene :: struct {
    name:             *u8;
    nodes:            **cgltf_node;
    nodes_count:      cgltf_size;
    extras:           cgltf_extras;
    extensions_count: cgltf_size;
    extensions:       *cgltf_extension;
}

cgltf_animation_sampler :: struct {
    input:            *cgltf_accessor;
    output:           *cgltf_accessor;
    interpolation:    cgltf_interpolation_type;
    extras:           cgltf_extras;
    extensions_count: cgltf_size;
    extensions:       *cgltf_extension;
}

cgltf_animation_channel :: struct {
    sampler:          *cgltf_animation_sampler;
    target_node:      *cgltf_node;
    target_path:      cgltf_animation_path_type;
    extras:           cgltf_extras;
    extensions_count: cgltf_size;
    extensions:       *cgltf_extension;
}

cgltf_animation :: struct {
    name:             *u8;
    samplers:         *cgltf_animation_sampler;
    samplers_count:   cgltf_size;
    channels:         *cgltf_animation_channel;
    channels_count:   cgltf_size;
    extras:           cgltf_extras;
    extensions_count: cgltf_size;
    extensions:       *cgltf_extension;
}

cgltf_material_variant :: struct {
    name:   *u8;
    extras: cgltf_extras;
}

cgltf_asset :: struct {
    copyright:        *u8;
    generator:        *u8;
    version:          *u8;
    min_version:      *u8;
    extras:           cgltf_extras;
    extensions_count: cgltf_size;
    extensions:       *cgltf_extension;
}

cgltf_data :: struct {
    file_type:                 cgltf_file_type;
    file_data:                 *void;

    asset:                     cgltf_asset;

    meshes:                    *cgltf_mesh;
    meshes_count:              cgltf_size;

    materials:                 *cgltf_material;
    materials_count:           cgltf_size;

    accessors:                 *cgltf_accessor;
    accessors_count:           cgltf_size;

    buffer_views:              *cgltf_buffer_view;
    buffer_views_count:        cgltf_size;

    buffers:                   *cgltf_buffer;
    buffers_count:             cgltf_size;

    images:                    *cgltf_image;
    images_count:              cgltf_size;

    textures:                  *cgltf_texture;
    textures_count:            cgltf_size;

    samplers:                  *cgltf_sampler;
    samplers_count:            cgltf_size;

    skins:                     *cgltf_skin;
    skins_count:               cgltf_size;

    cameras:                   *cgltf_camera;
    cameras_count:             cgltf_size;

    lights:                    *cgltf_light;
    lights_count:              cgltf_size;

    nodes:                     *cgltf_node;
    nodes_count:               cgltf_size;

    scenes:                    *cgltf_scene;
    scenes_count:              cgltf_size;

    scene:                     *cgltf_scene;

    animations:                *cgltf_animation;
    animations_count:          cgltf_size;

    variants:                  *cgltf_material_variant;
    variants_count:            cgltf_size;

    extras:                    cgltf_extras;

    data_extensions_count:     cgltf_size;
    data_extensions:           *cgltf_extension;

    extensions_used:           **u8;
    extensions_used_count:     cgltf_size;

    extensions_required:       **u8;
    extensions_required_count: cgltf_size;

    json:                      *u8;
    json_size:                 cgltf_size;

    bin:                       *void;
    bin_size:                  cgltf_size;

    memory:                    cgltf_memory_options;
    file:                      cgltf_file_options;
}

cgltf_parse :: (options: *cgltf_options, data: *void, size: cgltf_size, out_data: **cgltf_data) -> cgltf_result #foreign cgltf;

cgltf_parse_file :: (options: *cgltf_options, path: *u8, out_data: **cgltf_data) -> cgltf_result #foreign cgltf;

cgltf_load_buffers :: (options: *cgltf_options, data: *cgltf_data, gltf_path: *u8) -> cgltf_result #foreign cgltf;

cgltf_load_buffer_base64 :: (options: *cgltf_options, size: cgltf_size, base64: *u8, out_data: **void) -> cgltf_result #foreign cgltf;

cgltf_decode_string :: (_string: *u8) -> cgltf_size #foreign cgltf;
cgltf_decode_uri :: (uri: *u8) -> cgltf_size #foreign cgltf;

cgltf_validate :: (data: *cgltf_data) -> cgltf_result #foreign cgltf;

cgltf_free :: (data: *cgltf_data) -> void #foreign cgltf;

cgltf_node_transform_local :: (node: *cgltf_node, out_matrix: *cgltf_float) -> void #foreign cgltf;
cgltf_node_transform_world :: (node: *cgltf_node, out_matrix: *cgltf_float) -> void #foreign cgltf;

cgltf_buffer_view_data :: (view: *cgltf_buffer_view) -> *u8 #foreign cgltf;

cgltf_find_accessor :: (prim: *cgltf_primitive, type: cgltf_attribute_type, index: cgltf_int) -> *cgltf_accessor #foreign cgltf;

cgltf_accessor_read_float :: (accessor: *cgltf_accessor, index: cgltf_size, out: *cgltf_float, element_size: cgltf_size) -> cgltf_bool #foreign cgltf;
cgltf_accessor_read_uint :: (accessor: *cgltf_accessor, index: cgltf_size, out: *cgltf_uint, element_size: cgltf_size) -> cgltf_bool #foreign cgltf;
cgltf_accessor_read_index :: (accessor: *cgltf_accessor, index: cgltf_size) -> cgltf_size #foreign cgltf;

cgltf_num_components :: (type: cgltf_type) -> cgltf_size #foreign cgltf;
cgltf_component_size :: (component_type: cgltf_component_type) -> cgltf_size #foreign cgltf;
cgltf_calc_size :: (type: cgltf_type, component_type: cgltf_component_type) -> cgltf_size #foreign cgltf;

cgltf_accessor_unpack_floats :: (accessor: *cgltf_accessor, out: *cgltf_float, float_count: cgltf_size) -> cgltf_size #foreign cgltf;
cgltf_accessor_unpack_indices :: (accessor: *cgltf_accessor, out: *void, out_component_size: cgltf_size, index_count: cgltf_size) -> cgltf_size #foreign cgltf;

/* this function is deprecated and will be removed in the future; use cgltf_extras::data instead */
cgltf_copy_extras_json :: (data: *cgltf_data, extras: *cgltf_extras, dest: *u8, dest_size: *cgltf_size) -> cgltf_result #foreign cgltf;

cgltf_mesh_index :: (data: *cgltf_data, object: *cgltf_mesh) -> cgltf_size #foreign cgltf;
cgltf_material_index :: (data: *cgltf_data, object: *cgltf_material) -> cgltf_size #foreign cgltf;
cgltf_accessor_index :: (data: *cgltf_data, object: *cgltf_accessor) -> cgltf_size #foreign cgltf;
cgltf_buffer_view_index :: (data: *cgltf_data, object: *cgltf_buffer_view) -> cgltf_size #foreign cgltf;
cgltf_buffer_index :: (data: *cgltf_data, object: *cgltf_buffer) -> cgltf_size #foreign cgltf;
cgltf_image_index :: (data: *cgltf_data, object: *cgltf_image) -> cgltf_size #foreign cgltf;
cgltf_texture_index :: (data: *cgltf_data, object: *cgltf_texture) -> cgltf_size #foreign cgltf;
cgltf_sampler_index :: (data: *cgltf_data, object: *cgltf_sampler) -> cgltf_size #foreign cgltf;
cgltf_skin_index :: (data: *cgltf_data, object: *cgltf_skin) -> cgltf_size #foreign cgltf;
cgltf_camera_index :: (data: *cgltf_data, object: *cgltf_camera) -> cgltf_size #foreign cgltf;
cgltf_light_index :: (data: *cgltf_data, object: *cgltf_light) -> cgltf_size #foreign cgltf;
cgltf_node_index :: (data: *cgltf_data, object: *cgltf_node) -> cgltf_size #foreign cgltf;
cgltf_scene_index :: (data: *cgltf_data, object: *cgltf_scene) -> cgltf_size #foreign cgltf;
cgltf_animation_index :: (data: *cgltf_data, object: *cgltf_animation) -> cgltf_size #foreign cgltf;
cgltf_animation_sampler_index :: (animation: *cgltf_animation, object: *cgltf_animation_sampler) -> cgltf_size #foreign cgltf;
cgltf_animation_channel_index :: (animation: *cgltf_animation, object: *cgltf_animation_channel) -> cgltf_size #foreign cgltf;

#scope_file

#import "Basic"; // For assert

cgltf :: #library,no_dll "./cgltf";

#run {
    {
        info := type_info(cgltf_memory_options);
        for info.members {
            if it.name == {
                case "alloc_func";
                    assert(it.offset_in_bytes == 0, "cgltf_memory_options.alloc_func has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_memory_options.alloc_func has unexpected size % instead of 8", it.type.runtime_size);
                case "free_func";
                    assert(it.offset_in_bytes == 8, "cgltf_memory_options.free_func has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_memory_options.free_func has unexpected size % instead of 8", it.type.runtime_size);
                case "user_data";
                    assert(it.offset_in_bytes == 16, "cgltf_memory_options.user_data has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_memory_options.user_data has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_memory_options) == 24, "cgltf_memory_options has size % instead of 24", size_of(cgltf_memory_options));
    }

    {
        info := type_info(cgltf_file_options);
        for info.members {
            if it.name == {
                case "read";
                    assert(it.offset_in_bytes == 0, "cgltf_file_options.read has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_file_options.read has unexpected size % instead of 8", it.type.runtime_size);
                case "release";
                    assert(it.offset_in_bytes == 8, "cgltf_file_options.release has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_file_options.release has unexpected size % instead of 8", it.type.runtime_size);
                case "user_data";
                    assert(it.offset_in_bytes == 16, "cgltf_file_options.user_data has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_file_options.user_data has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_file_options) == 24, "cgltf_file_options has size % instead of 24", size_of(cgltf_file_options));
    }

    {
        info := type_info(cgltf_options);
        for info.members {
            if it.name == {
                case "type";
                    assert(it.offset_in_bytes == 0, "cgltf_options.type has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_options.type has unexpected size % instead of 4", it.type.runtime_size);
                case "json_token_count";
                    assert(it.offset_in_bytes == 8, "cgltf_options.json_token_count has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_options.json_token_count has unexpected size % instead of 8", it.type.runtime_size);
                case "memory";
                    assert(it.offset_in_bytes == 16, "cgltf_options.memory has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_options.memory has unexpected size % instead of 24", it.type.runtime_size);
                case "file";
                    assert(it.offset_in_bytes == 40, "cgltf_options.file has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_options.file has unexpected size % instead of 24", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_options) == 64, "cgltf_options has size % instead of 64", size_of(cgltf_options));
    }

    {
        info := type_info(cgltf_extras);
        for info.members {
            if it.name == {
                case "start_offset";
                    assert(it.offset_in_bytes == 0, "cgltf_extras.start_offset has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_extras.start_offset has unexpected size % instead of 8", it.type.runtime_size);
                case "end_offset";
                    assert(it.offset_in_bytes == 8, "cgltf_extras.end_offset has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_extras.end_offset has unexpected size % instead of 8", it.type.runtime_size);
                case "data";
                    assert(it.offset_in_bytes == 16, "cgltf_extras.data has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_extras.data has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_extras) == 24, "cgltf_extras has size % instead of 24", size_of(cgltf_extras));
    }

    {
        info := type_info(cgltf_extension);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_extension.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_extension.name has unexpected size % instead of 8", it.type.runtime_size);
                case "data";
                    assert(it.offset_in_bytes == 8, "cgltf_extension.data has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_extension.data has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_extension) == 16, "cgltf_extension has size % instead of 16", size_of(cgltf_extension));
    }

    {
        info := type_info(cgltf_buffer);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_buffer.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer.name has unexpected size % instead of 8", it.type.runtime_size);
                case "size";
                    assert(it.offset_in_bytes == 8, "cgltf_buffer.size has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer.size has unexpected size % instead of 8", it.type.runtime_size);
                case "uri";
                    assert(it.offset_in_bytes == 16, "cgltf_buffer.uri has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer.uri has unexpected size % instead of 8", it.type.runtime_size);
                case "data";
                    assert(it.offset_in_bytes == 24, "cgltf_buffer.data has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer.data has unexpected size % instead of 8", it.type.runtime_size);
                case "data_free_method";
                    assert(it.offset_in_bytes == 32, "cgltf_buffer.data_free_method has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_buffer.data_free_method has unexpected size % instead of 4", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 40, "cgltf_buffer.extras has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_buffer.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 64, "cgltf_buffer.extensions_count has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 72, "cgltf_buffer.extensions has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_buffer) == 80, "cgltf_buffer has size % instead of 80", size_of(cgltf_buffer));
    }

    {
        info := type_info(cgltf_meshopt_compression);
        for info.members {
            if it.name == {
                case "buffer";
                    assert(it.offset_in_bytes == 0, "cgltf_meshopt_compression.buffer has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_meshopt_compression.buffer has unexpected size % instead of 8", it.type.runtime_size);
                case "offset";
                    assert(it.offset_in_bytes == 8, "cgltf_meshopt_compression.offset has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_meshopt_compression.offset has unexpected size % instead of 8", it.type.runtime_size);
                case "size";
                    assert(it.offset_in_bytes == 16, "cgltf_meshopt_compression.size has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_meshopt_compression.size has unexpected size % instead of 8", it.type.runtime_size);
                case "stride";
                    assert(it.offset_in_bytes == 24, "cgltf_meshopt_compression.stride has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_meshopt_compression.stride has unexpected size % instead of 8", it.type.runtime_size);
                case "count";
                    assert(it.offset_in_bytes == 32, "cgltf_meshopt_compression.count has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_meshopt_compression.count has unexpected size % instead of 8", it.type.runtime_size);
                case "mode";
                    assert(it.offset_in_bytes == 40, "cgltf_meshopt_compression.mode has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_meshopt_compression.mode has unexpected size % instead of 4", it.type.runtime_size);
                case "filter";
                    assert(it.offset_in_bytes == 44, "cgltf_meshopt_compression.filter has unexpected offset % instead of 44", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_meshopt_compression.filter has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_meshopt_compression) == 48, "cgltf_meshopt_compression has size % instead of 48", size_of(cgltf_meshopt_compression));
    }

    {
        info := type_info(cgltf_buffer_view);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_buffer_view.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer_view.name has unexpected size % instead of 8", it.type.runtime_size);
                case "buffer";
                    assert(it.offset_in_bytes == 8, "cgltf_buffer_view.buffer has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer_view.buffer has unexpected size % instead of 8", it.type.runtime_size);
                case "offset";
                    assert(it.offset_in_bytes == 16, "cgltf_buffer_view.offset has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer_view.offset has unexpected size % instead of 8", it.type.runtime_size);
                case "size";
                    assert(it.offset_in_bytes == 24, "cgltf_buffer_view.size has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer_view.size has unexpected size % instead of 8", it.type.runtime_size);
                case "stride";
                    assert(it.offset_in_bytes == 32, "cgltf_buffer_view.stride has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer_view.stride has unexpected size % instead of 8", it.type.runtime_size);
                case "type";
                    assert(it.offset_in_bytes == 40, "cgltf_buffer_view.type has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_buffer_view.type has unexpected size % instead of 4", it.type.runtime_size);
                case "data";
                    assert(it.offset_in_bytes == 48, "cgltf_buffer_view.data has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer_view.data has unexpected size % instead of 8", it.type.runtime_size);
                case "has_meshopt_compression";
                    assert(it.offset_in_bytes == 56, "cgltf_buffer_view.has_meshopt_compression has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_buffer_view.has_meshopt_compression has unexpected size % instead of 4", it.type.runtime_size);
                case "meshopt_compression";
                    assert(it.offset_in_bytes == 64, "cgltf_buffer_view.meshopt_compression has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_buffer_view.meshopt_compression has unexpected size % instead of 48", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 112, "cgltf_buffer_view.extras has unexpected offset % instead of 112", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_buffer_view.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 136, "cgltf_buffer_view.extensions_count has unexpected offset % instead of 136", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer_view.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 144, "cgltf_buffer_view.extensions has unexpected offset % instead of 144", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_buffer_view.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_buffer_view) == 152, "cgltf_buffer_view has size % instead of 152", size_of(cgltf_buffer_view));
    }

    {
        info := type_info(cgltf_accessor_sparse);
        for info.members {
            if it.name == {
                case "count";
                    assert(it.offset_in_bytes == 0, "cgltf_accessor_sparse.count has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_accessor_sparse.count has unexpected size % instead of 8", it.type.runtime_size);
                case "indices_buffer_view";
                    assert(it.offset_in_bytes == 8, "cgltf_accessor_sparse.indices_buffer_view has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_accessor_sparse.indices_buffer_view has unexpected size % instead of 8", it.type.runtime_size);
                case "indices_byte_offset";
                    assert(it.offset_in_bytes == 16, "cgltf_accessor_sparse.indices_byte_offset has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_accessor_sparse.indices_byte_offset has unexpected size % instead of 8", it.type.runtime_size);
                case "indices_component_type";
                    assert(it.offset_in_bytes == 24, "cgltf_accessor_sparse.indices_component_type has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_accessor_sparse.indices_component_type has unexpected size % instead of 4", it.type.runtime_size);
                case "values_buffer_view";
                    assert(it.offset_in_bytes == 32, "cgltf_accessor_sparse.values_buffer_view has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_accessor_sparse.values_buffer_view has unexpected size % instead of 8", it.type.runtime_size);
                case "values_byte_offset";
                    assert(it.offset_in_bytes == 40, "cgltf_accessor_sparse.values_byte_offset has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_accessor_sparse.values_byte_offset has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_accessor_sparse) == 48, "cgltf_accessor_sparse has size % instead of 48", size_of(cgltf_accessor_sparse));
    }

    {
        info := type_info(cgltf_accessor);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_accessor.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_accessor.name has unexpected size % instead of 8", it.type.runtime_size);
                case "component_type";
                    assert(it.offset_in_bytes == 8, "cgltf_accessor.component_type has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_accessor.component_type has unexpected size % instead of 4", it.type.runtime_size);
                case "normalized";
                    assert(it.offset_in_bytes == 12, "cgltf_accessor.normalized has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_accessor.normalized has unexpected size % instead of 4", it.type.runtime_size);
                case "type";
                    assert(it.offset_in_bytes == 16, "cgltf_accessor.type has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_accessor.type has unexpected size % instead of 4", it.type.runtime_size);
                case "offset";
                    assert(it.offset_in_bytes == 24, "cgltf_accessor.offset has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_accessor.offset has unexpected size % instead of 8", it.type.runtime_size);
                case "count";
                    assert(it.offset_in_bytes == 32, "cgltf_accessor.count has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_accessor.count has unexpected size % instead of 8", it.type.runtime_size);
                case "stride";
                    assert(it.offset_in_bytes == 40, "cgltf_accessor.stride has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_accessor.stride has unexpected size % instead of 8", it.type.runtime_size);
                case "buffer_view";
                    assert(it.offset_in_bytes == 48, "cgltf_accessor.buffer_view has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_accessor.buffer_view has unexpected size % instead of 8", it.type.runtime_size);
                case "has_min";
                    assert(it.offset_in_bytes == 56, "cgltf_accessor.has_min has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_accessor.has_min has unexpected size % instead of 4", it.type.runtime_size);
                case "min";
                    assert(it.offset_in_bytes == 60, "cgltf_accessor.min has unexpected offset % instead of 60", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "cgltf_accessor.min has unexpected size % instead of 64", it.type.runtime_size);
                case "has_max";
                    assert(it.offset_in_bytes == 124, "cgltf_accessor.has_max has unexpected offset % instead of 124", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_accessor.has_max has unexpected size % instead of 4", it.type.runtime_size);
                case "max";
                    assert(it.offset_in_bytes == 128, "cgltf_accessor.max has unexpected offset % instead of 128", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "cgltf_accessor.max has unexpected size % instead of 64", it.type.runtime_size);
                case "is_sparse";
                    assert(it.offset_in_bytes == 192, "cgltf_accessor.is_sparse has unexpected offset % instead of 192", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_accessor.is_sparse has unexpected size % instead of 4", it.type.runtime_size);
                case "sparse";
                    assert(it.offset_in_bytes == 200, "cgltf_accessor.sparse has unexpected offset % instead of 200", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_accessor.sparse has unexpected size % instead of 48", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 248, "cgltf_accessor.extras has unexpected offset % instead of 248", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_accessor.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 272, "cgltf_accessor.extensions_count has unexpected offset % instead of 272", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_accessor.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 280, "cgltf_accessor.extensions has unexpected offset % instead of 280", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_accessor.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_accessor) == 288, "cgltf_accessor has size % instead of 288", size_of(cgltf_accessor));
    }

    {
        info := type_info(cgltf_attribute);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_attribute.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_attribute.name has unexpected size % instead of 8", it.type.runtime_size);
                case "type";
                    assert(it.offset_in_bytes == 8, "cgltf_attribute.type has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_attribute.type has unexpected size % instead of 4", it.type.runtime_size);
                case "index";
                    assert(it.offset_in_bytes == 12, "cgltf_attribute.index has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_attribute.index has unexpected size % instead of 4", it.type.runtime_size);
                case "data";
                    assert(it.offset_in_bytes == 16, "cgltf_attribute.data has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_attribute.data has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_attribute) == 24, "cgltf_attribute has size % instead of 24", size_of(cgltf_attribute));
    }

    {
        info := type_info(cgltf_image);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_image.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_image.name has unexpected size % instead of 8", it.type.runtime_size);
                case "uri";
                    assert(it.offset_in_bytes == 8, "cgltf_image.uri has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_image.uri has unexpected size % instead of 8", it.type.runtime_size);
                case "buffer_view";
                    assert(it.offset_in_bytes == 16, "cgltf_image.buffer_view has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_image.buffer_view has unexpected size % instead of 8", it.type.runtime_size);
                case "mime_type";
                    assert(it.offset_in_bytes == 24, "cgltf_image.mime_type has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_image.mime_type has unexpected size % instead of 8", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 32, "cgltf_image.extras has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_image.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 56, "cgltf_image.extensions_count has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_image.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 64, "cgltf_image.extensions has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_image.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_image) == 72, "cgltf_image has size % instead of 72", size_of(cgltf_image));
    }

    {
        info := type_info(cgltf_sampler);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_sampler.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_sampler.name has unexpected size % instead of 8", it.type.runtime_size);
                case "mag_filter";
                    assert(it.offset_in_bytes == 8, "cgltf_sampler.mag_filter has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_sampler.mag_filter has unexpected size % instead of 4", it.type.runtime_size);
                case "min_filter";
                    assert(it.offset_in_bytes == 12, "cgltf_sampler.min_filter has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_sampler.min_filter has unexpected size % instead of 4", it.type.runtime_size);
                case "wrap_s";
                    assert(it.offset_in_bytes == 16, "cgltf_sampler.wrap_s has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_sampler.wrap_s has unexpected size % instead of 4", it.type.runtime_size);
                case "wrap_t";
                    assert(it.offset_in_bytes == 20, "cgltf_sampler.wrap_t has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_sampler.wrap_t has unexpected size % instead of 4", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 24, "cgltf_sampler.extras has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_sampler.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 48, "cgltf_sampler.extensions_count has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_sampler.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 56, "cgltf_sampler.extensions has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_sampler.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_sampler) == 64, "cgltf_sampler has size % instead of 64", size_of(cgltf_sampler));
    }

    {
        info := type_info(cgltf_texture);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_texture.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_texture.name has unexpected size % instead of 8", it.type.runtime_size);
                case "image";
                    assert(it.offset_in_bytes == 8, "cgltf_texture.image has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_texture.image has unexpected size % instead of 8", it.type.runtime_size);
                case "sampler";
                    assert(it.offset_in_bytes == 16, "cgltf_texture.sampler has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_texture.sampler has unexpected size % instead of 8", it.type.runtime_size);
                case "has_basisu";
                    assert(it.offset_in_bytes == 24, "cgltf_texture.has_basisu has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_texture.has_basisu has unexpected size % instead of 4", it.type.runtime_size);
                case "basisu_image";
                    assert(it.offset_in_bytes == 32, "cgltf_texture.basisu_image has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_texture.basisu_image has unexpected size % instead of 8", it.type.runtime_size);
                case "has_webp";
                    assert(it.offset_in_bytes == 40, "cgltf_texture.has_webp has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_texture.has_webp has unexpected size % instead of 4", it.type.runtime_size);
                case "webp_image";
                    assert(it.offset_in_bytes == 48, "cgltf_texture.webp_image has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_texture.webp_image has unexpected size % instead of 8", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 56, "cgltf_texture.extras has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_texture.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 80, "cgltf_texture.extensions_count has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_texture.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 88, "cgltf_texture.extensions has unexpected offset % instead of 88", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_texture.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_texture) == 96, "cgltf_texture has size % instead of 96", size_of(cgltf_texture));
    }

    {
        info := type_info(cgltf_texture_transform);
        for info.members {
            if it.name == {
                case "offset";
                    assert(it.offset_in_bytes == 0, "cgltf_texture_transform.offset has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_texture_transform.offset has unexpected size % instead of 8", it.type.runtime_size);
                case "rotation";
                    assert(it.offset_in_bytes == 8, "cgltf_texture_transform.rotation has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_texture_transform.rotation has unexpected size % instead of 4", it.type.runtime_size);
                case "scale";
                    assert(it.offset_in_bytes == 12, "cgltf_texture_transform.scale has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_texture_transform.scale has unexpected size % instead of 8", it.type.runtime_size);
                case "has_texcoord";
                    assert(it.offset_in_bytes == 20, "cgltf_texture_transform.has_texcoord has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_texture_transform.has_texcoord has unexpected size % instead of 4", it.type.runtime_size);
                case "texcoord";
                    assert(it.offset_in_bytes == 24, "cgltf_texture_transform.texcoord has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_texture_transform.texcoord has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_texture_transform) == 28, "cgltf_texture_transform has size % instead of 28", size_of(cgltf_texture_transform));
    }

    {
        info := type_info(cgltf_texture_view);
        for info.members {
            if it.name == {
                case "texture";
                    assert(it.offset_in_bytes == 0, "cgltf_texture_view.texture has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_texture_view.texture has unexpected size % instead of 8", it.type.runtime_size);
                case "texcoord";
                    assert(it.offset_in_bytes == 8, "cgltf_texture_view.texcoord has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_texture_view.texcoord has unexpected size % instead of 4", it.type.runtime_size);
                case "scale";
                    assert(it.offset_in_bytes == 12, "cgltf_texture_view.scale has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_texture_view.scale has unexpected size % instead of 4", it.type.runtime_size);
                case "has_transform";
                    assert(it.offset_in_bytes == 16, "cgltf_texture_view.has_transform has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_texture_view.has_transform has unexpected size % instead of 4", it.type.runtime_size);
                case "transform";
                    assert(it.offset_in_bytes == 20, "cgltf_texture_view.transform has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 28, "cgltf_texture_view.transform has unexpected size % instead of 28", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_texture_view) == 48, "cgltf_texture_view has size % instead of 48", size_of(cgltf_texture_view));
    }

    {
        info := type_info(cgltf_pbr_metallic_roughness);
        for info.members {
            if it.name == {
                case "base_color_texture";
                    assert(it.offset_in_bytes == 0, "cgltf_pbr_metallic_roughness.base_color_texture has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_pbr_metallic_roughness.base_color_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "metallic_roughness_texture";
                    assert(it.offset_in_bytes == 48, "cgltf_pbr_metallic_roughness.metallic_roughness_texture has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_pbr_metallic_roughness.metallic_roughness_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "base_color_factor";
                    assert(it.offset_in_bytes == 96, "cgltf_pbr_metallic_roughness.base_color_factor has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "cgltf_pbr_metallic_roughness.base_color_factor has unexpected size % instead of 16", it.type.runtime_size);
                case "metallic_factor";
                    assert(it.offset_in_bytes == 112, "cgltf_pbr_metallic_roughness.metallic_factor has unexpected offset % instead of 112", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_pbr_metallic_roughness.metallic_factor has unexpected size % instead of 4", it.type.runtime_size);
                case "roughness_factor";
                    assert(it.offset_in_bytes == 116, "cgltf_pbr_metallic_roughness.roughness_factor has unexpected offset % instead of 116", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_pbr_metallic_roughness.roughness_factor has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_pbr_metallic_roughness) == 120, "cgltf_pbr_metallic_roughness has size % instead of 120", size_of(cgltf_pbr_metallic_roughness));
    }

    {
        info := type_info(cgltf_pbr_specular_glossiness);
        for info.members {
            if it.name == {
                case "diffuse_texture";
                    assert(it.offset_in_bytes == 0, "cgltf_pbr_specular_glossiness.diffuse_texture has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_pbr_specular_glossiness.diffuse_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "specular_glossiness_texture";
                    assert(it.offset_in_bytes == 48, "cgltf_pbr_specular_glossiness.specular_glossiness_texture has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_pbr_specular_glossiness.specular_glossiness_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "diffuse_factor";
                    assert(it.offset_in_bytes == 96, "cgltf_pbr_specular_glossiness.diffuse_factor has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "cgltf_pbr_specular_glossiness.diffuse_factor has unexpected size % instead of 16", it.type.runtime_size);
                case "specular_factor";
                    assert(it.offset_in_bytes == 112, "cgltf_pbr_specular_glossiness.specular_factor has unexpected offset % instead of 112", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "cgltf_pbr_specular_glossiness.specular_factor has unexpected size % instead of 12", it.type.runtime_size);
                case "glossiness_factor";
                    assert(it.offset_in_bytes == 124, "cgltf_pbr_specular_glossiness.glossiness_factor has unexpected offset % instead of 124", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_pbr_specular_glossiness.glossiness_factor has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_pbr_specular_glossiness) == 128, "cgltf_pbr_specular_glossiness has size % instead of 128", size_of(cgltf_pbr_specular_glossiness));
    }

    {
        info := type_info(cgltf_clearcoat);
        for info.members {
            if it.name == {
                case "clearcoat_texture";
                    assert(it.offset_in_bytes == 0, "cgltf_clearcoat.clearcoat_texture has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_clearcoat.clearcoat_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "clearcoat_roughness_texture";
                    assert(it.offset_in_bytes == 48, "cgltf_clearcoat.clearcoat_roughness_texture has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_clearcoat.clearcoat_roughness_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "clearcoat_normal_texture";
                    assert(it.offset_in_bytes == 96, "cgltf_clearcoat.clearcoat_normal_texture has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_clearcoat.clearcoat_normal_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "clearcoat_factor";
                    assert(it.offset_in_bytes == 144, "cgltf_clearcoat.clearcoat_factor has unexpected offset % instead of 144", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_clearcoat.clearcoat_factor has unexpected size % instead of 4", it.type.runtime_size);
                case "clearcoat_roughness_factor";
                    assert(it.offset_in_bytes == 148, "cgltf_clearcoat.clearcoat_roughness_factor has unexpected offset % instead of 148", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_clearcoat.clearcoat_roughness_factor has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_clearcoat) == 152, "cgltf_clearcoat has size % instead of 152", size_of(cgltf_clearcoat));
    }

    {
        info := type_info(cgltf_transmission);
        for info.members {
            if it.name == {
                case "transmission_texture";
                    assert(it.offset_in_bytes == 0, "cgltf_transmission.transmission_texture has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_transmission.transmission_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "transmission_factor";
                    assert(it.offset_in_bytes == 48, "cgltf_transmission.transmission_factor has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_transmission.transmission_factor has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_transmission) == 56, "cgltf_transmission has size % instead of 56", size_of(cgltf_transmission));
    }

    {
        info := type_info(cgltf_ior);
        for info.members {
            if it.name == {
                case "ior";
                    assert(it.offset_in_bytes == 0, "cgltf_ior.ior has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_ior.ior has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_ior) == 4, "cgltf_ior has size % instead of 4", size_of(cgltf_ior));
    }

    {
        info := type_info(cgltf_specular);
        for info.members {
            if it.name == {
                case "specular_texture";
                    assert(it.offset_in_bytes == 0, "cgltf_specular.specular_texture has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_specular.specular_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "specular_color_texture";
                    assert(it.offset_in_bytes == 48, "cgltf_specular.specular_color_texture has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_specular.specular_color_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "specular_color_factor";
                    assert(it.offset_in_bytes == 96, "cgltf_specular.specular_color_factor has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "cgltf_specular.specular_color_factor has unexpected size % instead of 12", it.type.runtime_size);
                case "specular_factor";
                    assert(it.offset_in_bytes == 108, "cgltf_specular.specular_factor has unexpected offset % instead of 108", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_specular.specular_factor has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_specular) == 112, "cgltf_specular has size % instead of 112", size_of(cgltf_specular));
    }

    {
        info := type_info(cgltf_volume);
        for info.members {
            if it.name == {
                case "thickness_texture";
                    assert(it.offset_in_bytes == 0, "cgltf_volume.thickness_texture has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_volume.thickness_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "thickness_factor";
                    assert(it.offset_in_bytes == 48, "cgltf_volume.thickness_factor has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_volume.thickness_factor has unexpected size % instead of 4", it.type.runtime_size);
                case "attenuation_color";
                    assert(it.offset_in_bytes == 52, "cgltf_volume.attenuation_color has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "cgltf_volume.attenuation_color has unexpected size % instead of 12", it.type.runtime_size);
                case "attenuation_distance";
                    assert(it.offset_in_bytes == 64, "cgltf_volume.attenuation_distance has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_volume.attenuation_distance has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_volume) == 72, "cgltf_volume has size % instead of 72", size_of(cgltf_volume));
    }

    {
        info := type_info(cgltf_sheen);
        for info.members {
            if it.name == {
                case "sheen_color_texture";
                    assert(it.offset_in_bytes == 0, "cgltf_sheen.sheen_color_texture has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_sheen.sheen_color_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "sheen_color_factor";
                    assert(it.offset_in_bytes == 48, "cgltf_sheen.sheen_color_factor has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "cgltf_sheen.sheen_color_factor has unexpected size % instead of 12", it.type.runtime_size);
                case "sheen_roughness_texture";
                    assert(it.offset_in_bytes == 64, "cgltf_sheen.sheen_roughness_texture has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_sheen.sheen_roughness_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "sheen_roughness_factor";
                    assert(it.offset_in_bytes == 112, "cgltf_sheen.sheen_roughness_factor has unexpected offset % instead of 112", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_sheen.sheen_roughness_factor has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_sheen) == 120, "cgltf_sheen has size % instead of 120", size_of(cgltf_sheen));
    }

    {
        info := type_info(cgltf_emissive_strength);
        for info.members {
            if it.name == {
                case "emissive_strength";
                    assert(it.offset_in_bytes == 0, "cgltf_emissive_strength.emissive_strength has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_emissive_strength.emissive_strength has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_emissive_strength) == 4, "cgltf_emissive_strength has size % instead of 4", size_of(cgltf_emissive_strength));
    }

    {
        info := type_info(cgltf_iridescence);
        for info.members {
            if it.name == {
                case "iridescence_factor";
                    assert(it.offset_in_bytes == 0, "cgltf_iridescence.iridescence_factor has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_iridescence.iridescence_factor has unexpected size % instead of 4", it.type.runtime_size);
                case "iridescence_texture";
                    assert(it.offset_in_bytes == 8, "cgltf_iridescence.iridescence_texture has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_iridescence.iridescence_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "iridescence_ior";
                    assert(it.offset_in_bytes == 56, "cgltf_iridescence.iridescence_ior has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_iridescence.iridescence_ior has unexpected size % instead of 4", it.type.runtime_size);
                case "iridescence_thickness_min";
                    assert(it.offset_in_bytes == 60, "cgltf_iridescence.iridescence_thickness_min has unexpected offset % instead of 60", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_iridescence.iridescence_thickness_min has unexpected size % instead of 4", it.type.runtime_size);
                case "iridescence_thickness_max";
                    assert(it.offset_in_bytes == 64, "cgltf_iridescence.iridescence_thickness_max has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_iridescence.iridescence_thickness_max has unexpected size % instead of 4", it.type.runtime_size);
                case "iridescence_thickness_texture";
                    assert(it.offset_in_bytes == 72, "cgltf_iridescence.iridescence_thickness_texture has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_iridescence.iridescence_thickness_texture has unexpected size % instead of 48", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_iridescence) == 120, "cgltf_iridescence has size % instead of 120", size_of(cgltf_iridescence));
    }

    {
        info := type_info(cgltf_diffuse_transmission);
        for info.members {
            if it.name == {
                case "diffuse_transmission_texture";
                    assert(it.offset_in_bytes == 0, "cgltf_diffuse_transmission.diffuse_transmission_texture has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_diffuse_transmission.diffuse_transmission_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "diffuse_transmission_factor";
                    assert(it.offset_in_bytes == 48, "cgltf_diffuse_transmission.diffuse_transmission_factor has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_diffuse_transmission.diffuse_transmission_factor has unexpected size % instead of 4", it.type.runtime_size);
                case "diffuse_transmission_color_factor";
                    assert(it.offset_in_bytes == 52, "cgltf_diffuse_transmission.diffuse_transmission_color_factor has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "cgltf_diffuse_transmission.diffuse_transmission_color_factor has unexpected size % instead of 12", it.type.runtime_size);
                case "diffuse_transmission_color_texture";
                    assert(it.offset_in_bytes == 64, "cgltf_diffuse_transmission.diffuse_transmission_color_texture has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_diffuse_transmission.diffuse_transmission_color_texture has unexpected size % instead of 48", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_diffuse_transmission) == 112, "cgltf_diffuse_transmission has size % instead of 112", size_of(cgltf_diffuse_transmission));
    }

    {
        info := type_info(cgltf_anisotropy);
        for info.members {
            if it.name == {
                case "anisotropy_strength";
                    assert(it.offset_in_bytes == 0, "cgltf_anisotropy.anisotropy_strength has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_anisotropy.anisotropy_strength has unexpected size % instead of 4", it.type.runtime_size);
                case "anisotropy_rotation";
                    assert(it.offset_in_bytes == 4, "cgltf_anisotropy.anisotropy_rotation has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_anisotropy.anisotropy_rotation has unexpected size % instead of 4", it.type.runtime_size);
                case "anisotropy_texture";
                    assert(it.offset_in_bytes == 8, "cgltf_anisotropy.anisotropy_texture has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_anisotropy.anisotropy_texture has unexpected size % instead of 48", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_anisotropy) == 56, "cgltf_anisotropy has size % instead of 56", size_of(cgltf_anisotropy));
    }

    {
        info := type_info(cgltf_dispersion);
        for info.members {
            if it.name == {
                case "dispersion";
                    assert(it.offset_in_bytes == 0, "cgltf_dispersion.dispersion has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_dispersion.dispersion has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_dispersion) == 4, "cgltf_dispersion has size % instead of 4", size_of(cgltf_dispersion));
    }

    {
        info := type_info(cgltf_material);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_material.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_material.name has unexpected size % instead of 8", it.type.runtime_size);
                case "has_pbr_metallic_roughness";
                    assert(it.offset_in_bytes == 8, "cgltf_material.has_pbr_metallic_roughness has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_pbr_metallic_roughness has unexpected size % instead of 4", it.type.runtime_size);
                case "has_pbr_specular_glossiness";
                    assert(it.offset_in_bytes == 12, "cgltf_material.has_pbr_specular_glossiness has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_pbr_specular_glossiness has unexpected size % instead of 4", it.type.runtime_size);
                case "has_clearcoat";
                    assert(it.offset_in_bytes == 16, "cgltf_material.has_clearcoat has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_clearcoat has unexpected size % instead of 4", it.type.runtime_size);
                case "has_transmission";
                    assert(it.offset_in_bytes == 20, "cgltf_material.has_transmission has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_transmission has unexpected size % instead of 4", it.type.runtime_size);
                case "has_volume";
                    assert(it.offset_in_bytes == 24, "cgltf_material.has_volume has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_volume has unexpected size % instead of 4", it.type.runtime_size);
                case "has_ior";
                    assert(it.offset_in_bytes == 28, "cgltf_material.has_ior has unexpected offset % instead of 28", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_ior has unexpected size % instead of 4", it.type.runtime_size);
                case "has_specular";
                    assert(it.offset_in_bytes == 32, "cgltf_material.has_specular has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_specular has unexpected size % instead of 4", it.type.runtime_size);
                case "has_sheen";
                    assert(it.offset_in_bytes == 36, "cgltf_material.has_sheen has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_sheen has unexpected size % instead of 4", it.type.runtime_size);
                case "has_emissive_strength";
                    assert(it.offset_in_bytes == 40, "cgltf_material.has_emissive_strength has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_emissive_strength has unexpected size % instead of 4", it.type.runtime_size);
                case "has_iridescence";
                    assert(it.offset_in_bytes == 44, "cgltf_material.has_iridescence has unexpected offset % instead of 44", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_iridescence has unexpected size % instead of 4", it.type.runtime_size);
                case "has_diffuse_transmission";
                    assert(it.offset_in_bytes == 48, "cgltf_material.has_diffuse_transmission has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_diffuse_transmission has unexpected size % instead of 4", it.type.runtime_size);
                case "has_anisotropy";
                    assert(it.offset_in_bytes == 52, "cgltf_material.has_anisotropy has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_anisotropy has unexpected size % instead of 4", it.type.runtime_size);
                case "has_dispersion";
                    assert(it.offset_in_bytes == 56, "cgltf_material.has_dispersion has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.has_dispersion has unexpected size % instead of 4", it.type.runtime_size);
                case "pbr_metallic_roughness";
                    assert(it.offset_in_bytes == 64, "cgltf_material.pbr_metallic_roughness has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 120, "cgltf_material.pbr_metallic_roughness has unexpected size % instead of 120", it.type.runtime_size);
                case "pbr_specular_glossiness";
                    assert(it.offset_in_bytes == 184, "cgltf_material.pbr_specular_glossiness has unexpected offset % instead of 184", it.offset_in_bytes);
                    assert(it.type.runtime_size == 128, "cgltf_material.pbr_specular_glossiness has unexpected size % instead of 128", it.type.runtime_size);
                case "clearcoat";
                    assert(it.offset_in_bytes == 312, "cgltf_material.clearcoat has unexpected offset % instead of 312", it.offset_in_bytes);
                    assert(it.type.runtime_size == 152, "cgltf_material.clearcoat has unexpected size % instead of 152", it.type.runtime_size);
                case "ior";
                    assert(it.offset_in_bytes == 464, "cgltf_material.ior has unexpected offset % instead of 464", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.ior has unexpected size % instead of 4", it.type.runtime_size);
                case "specular";
                    assert(it.offset_in_bytes == 472, "cgltf_material.specular has unexpected offset % instead of 472", it.offset_in_bytes);
                    assert(it.type.runtime_size == 112, "cgltf_material.specular has unexpected size % instead of 112", it.type.runtime_size);
                case "sheen";
                    assert(it.offset_in_bytes == 584, "cgltf_material.sheen has unexpected offset % instead of 584", it.offset_in_bytes);
                    assert(it.type.runtime_size == 120, "cgltf_material.sheen has unexpected size % instead of 120", it.type.runtime_size);
                case "transmission";
                    assert(it.offset_in_bytes == 704, "cgltf_material.transmission has unexpected offset % instead of 704", it.offset_in_bytes);
                    assert(it.type.runtime_size == 56, "cgltf_material.transmission has unexpected size % instead of 56", it.type.runtime_size);
                case "volume";
                    assert(it.offset_in_bytes == 760, "cgltf_material.volume has unexpected offset % instead of 760", it.offset_in_bytes);
                    assert(it.type.runtime_size == 72, "cgltf_material.volume has unexpected size % instead of 72", it.type.runtime_size);
                case "emissive_strength";
                    assert(it.offset_in_bytes == 832, "cgltf_material.emissive_strength has unexpected offset % instead of 832", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.emissive_strength has unexpected size % instead of 4", it.type.runtime_size);
                case "iridescence";
                    assert(it.offset_in_bytes == 840, "cgltf_material.iridescence has unexpected offset % instead of 840", it.offset_in_bytes);
                    assert(it.type.runtime_size == 120, "cgltf_material.iridescence has unexpected size % instead of 120", it.type.runtime_size);
                case "diffuse_transmission";
                    assert(it.offset_in_bytes == 960, "cgltf_material.diffuse_transmission has unexpected offset % instead of 960", it.offset_in_bytes);
                    assert(it.type.runtime_size == 112, "cgltf_material.diffuse_transmission has unexpected size % instead of 112", it.type.runtime_size);
                case "anisotropy";
                    assert(it.offset_in_bytes == 1072, "cgltf_material.anisotropy has unexpected offset % instead of 1072", it.offset_in_bytes);
                    assert(it.type.runtime_size == 56, "cgltf_material.anisotropy has unexpected size % instead of 56", it.type.runtime_size);
                case "dispersion";
                    assert(it.offset_in_bytes == 1128, "cgltf_material.dispersion has unexpected offset % instead of 1128", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.dispersion has unexpected size % instead of 4", it.type.runtime_size);
                case "normal_texture";
                    assert(it.offset_in_bytes == 1136, "cgltf_material.normal_texture has unexpected offset % instead of 1136", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_material.normal_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "occlusion_texture";
                    assert(it.offset_in_bytes == 1184, "cgltf_material.occlusion_texture has unexpected offset % instead of 1184", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_material.occlusion_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "emissive_texture";
                    assert(it.offset_in_bytes == 1232, "cgltf_material.emissive_texture has unexpected offset % instead of 1232", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_material.emissive_texture has unexpected size % instead of 48", it.type.runtime_size);
                case "emissive_factor";
                    assert(it.offset_in_bytes == 1280, "cgltf_material.emissive_factor has unexpected offset % instead of 1280", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "cgltf_material.emissive_factor has unexpected size % instead of 12", it.type.runtime_size);
                case "alpha_mode";
                    assert(it.offset_in_bytes == 1292, "cgltf_material.alpha_mode has unexpected offset % instead of 1292", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.alpha_mode has unexpected size % instead of 4", it.type.runtime_size);
                case "alpha_cutoff";
                    assert(it.offset_in_bytes == 1296, "cgltf_material.alpha_cutoff has unexpected offset % instead of 1296", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.alpha_cutoff has unexpected size % instead of 4", it.type.runtime_size);
                case "double_sided";
                    assert(it.offset_in_bytes == 1300, "cgltf_material.double_sided has unexpected offset % instead of 1300", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.double_sided has unexpected size % instead of 4", it.type.runtime_size);
                case "unlit";
                    assert(it.offset_in_bytes == 1304, "cgltf_material.unlit has unexpected offset % instead of 1304", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_material.unlit has unexpected size % instead of 4", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 1312, "cgltf_material.extras has unexpected offset % instead of 1312", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_material.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 1336, "cgltf_material.extensions_count has unexpected offset % instead of 1336", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_material.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 1344, "cgltf_material.extensions has unexpected offset % instead of 1344", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_material.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_material) == 1352, "cgltf_material has size % instead of 1352", size_of(cgltf_material));
    }

    {
        info := type_info(cgltf_material_mapping);
        for info.members {
            if it.name == {
                case "variant";
                    assert(it.offset_in_bytes == 0, "cgltf_material_mapping.variant has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_material_mapping.variant has unexpected size % instead of 8", it.type.runtime_size);
                case "material";
                    assert(it.offset_in_bytes == 8, "cgltf_material_mapping.material has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_material_mapping.material has unexpected size % instead of 8", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 16, "cgltf_material_mapping.extras has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_material_mapping.extras has unexpected size % instead of 24", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_material_mapping) == 40, "cgltf_material_mapping has size % instead of 40", size_of(cgltf_material_mapping));
    }

    {
        info := type_info(cgltf_morph_target);
        for info.members {
            if it.name == {
                case "attributes";
                    assert(it.offset_in_bytes == 0, "cgltf_morph_target.attributes has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_morph_target.attributes has unexpected size % instead of 8", it.type.runtime_size);
                case "attributes_count";
                    assert(it.offset_in_bytes == 8, "cgltf_morph_target.attributes_count has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_morph_target.attributes_count has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_morph_target) == 16, "cgltf_morph_target has size % instead of 16", size_of(cgltf_morph_target));
    }

    {
        info := type_info(cgltf_draco_mesh_compression);
        for info.members {
            if it.name == {
                case "buffer_view";
                    assert(it.offset_in_bytes == 0, "cgltf_draco_mesh_compression.buffer_view has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_draco_mesh_compression.buffer_view has unexpected size % instead of 8", it.type.runtime_size);
                case "attributes";
                    assert(it.offset_in_bytes == 8, "cgltf_draco_mesh_compression.attributes has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_draco_mesh_compression.attributes has unexpected size % instead of 8", it.type.runtime_size);
                case "attributes_count";
                    assert(it.offset_in_bytes == 16, "cgltf_draco_mesh_compression.attributes_count has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_draco_mesh_compression.attributes_count has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_draco_mesh_compression) == 24, "cgltf_draco_mesh_compression has size % instead of 24", size_of(cgltf_draco_mesh_compression));
    }

    {
        info := type_info(cgltf_mesh_gpu_instancing);
        for info.members {
            if it.name == {
                case "attributes";
                    assert(it.offset_in_bytes == 0, "cgltf_mesh_gpu_instancing.attributes has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_mesh_gpu_instancing.attributes has unexpected size % instead of 8", it.type.runtime_size);
                case "attributes_count";
                    assert(it.offset_in_bytes == 8, "cgltf_mesh_gpu_instancing.attributes_count has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_mesh_gpu_instancing.attributes_count has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_mesh_gpu_instancing) == 16, "cgltf_mesh_gpu_instancing has size % instead of 16", size_of(cgltf_mesh_gpu_instancing));
    }

    {
        info := type_info(cgltf_primitive);
        for info.members {
            if it.name == {
                case "type";
                    assert(it.offset_in_bytes == 0, "cgltf_primitive.type has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_primitive.type has unexpected size % instead of 4", it.type.runtime_size);
                case "indices";
                    assert(it.offset_in_bytes == 8, "cgltf_primitive.indices has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_primitive.indices has unexpected size % instead of 8", it.type.runtime_size);
                case "material";
                    assert(it.offset_in_bytes == 16, "cgltf_primitive.material has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_primitive.material has unexpected size % instead of 8", it.type.runtime_size);
                case "attributes";
                    assert(it.offset_in_bytes == 24, "cgltf_primitive.attributes has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_primitive.attributes has unexpected size % instead of 8", it.type.runtime_size);
                case "attributes_count";
                    assert(it.offset_in_bytes == 32, "cgltf_primitive.attributes_count has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_primitive.attributes_count has unexpected size % instead of 8", it.type.runtime_size);
                case "targets";
                    assert(it.offset_in_bytes == 40, "cgltf_primitive.targets has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_primitive.targets has unexpected size % instead of 8", it.type.runtime_size);
                case "targets_count";
                    assert(it.offset_in_bytes == 48, "cgltf_primitive.targets_count has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_primitive.targets_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 56, "cgltf_primitive.extras has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_primitive.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "has_draco_mesh_compression";
                    assert(it.offset_in_bytes == 80, "cgltf_primitive.has_draco_mesh_compression has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_primitive.has_draco_mesh_compression has unexpected size % instead of 4", it.type.runtime_size);
                case "draco_mesh_compression";
                    assert(it.offset_in_bytes == 88, "cgltf_primitive.draco_mesh_compression has unexpected offset % instead of 88", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_primitive.draco_mesh_compression has unexpected size % instead of 24", it.type.runtime_size);
                case "mappings";
                    assert(it.offset_in_bytes == 112, "cgltf_primitive.mappings has unexpected offset % instead of 112", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_primitive.mappings has unexpected size % instead of 8", it.type.runtime_size);
                case "mappings_count";
                    assert(it.offset_in_bytes == 120, "cgltf_primitive.mappings_count has unexpected offset % instead of 120", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_primitive.mappings_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 128, "cgltf_primitive.extensions_count has unexpected offset % instead of 128", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_primitive.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 136, "cgltf_primitive.extensions has unexpected offset % instead of 136", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_primitive.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_primitive) == 144, "cgltf_primitive has size % instead of 144", size_of(cgltf_primitive));
    }

    {
        info := type_info(cgltf_mesh);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_mesh.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_mesh.name has unexpected size % instead of 8", it.type.runtime_size);
                case "primitives";
                    assert(it.offset_in_bytes == 8, "cgltf_mesh.primitives has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_mesh.primitives has unexpected size % instead of 8", it.type.runtime_size);
                case "primitives_count";
                    assert(it.offset_in_bytes == 16, "cgltf_mesh.primitives_count has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_mesh.primitives_count has unexpected size % instead of 8", it.type.runtime_size);
                case "weights";
                    assert(it.offset_in_bytes == 24, "cgltf_mesh.weights has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_mesh.weights has unexpected size % instead of 8", it.type.runtime_size);
                case "weights_count";
                    assert(it.offset_in_bytes == 32, "cgltf_mesh.weights_count has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_mesh.weights_count has unexpected size % instead of 8", it.type.runtime_size);
                case "target_names";
                    assert(it.offset_in_bytes == 40, "cgltf_mesh.target_names has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_mesh.target_names has unexpected size % instead of 8", it.type.runtime_size);
                case "target_names_count";
                    assert(it.offset_in_bytes == 48, "cgltf_mesh.target_names_count has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_mesh.target_names_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 56, "cgltf_mesh.extras has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_mesh.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 80, "cgltf_mesh.extensions_count has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_mesh.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 88, "cgltf_mesh.extensions has unexpected offset % instead of 88", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_mesh.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_mesh) == 96, "cgltf_mesh has size % instead of 96", size_of(cgltf_mesh));
    }

    {
        info := type_info(cgltf_skin);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_skin.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_skin.name has unexpected size % instead of 8", it.type.runtime_size);
                case "joints";
                    assert(it.offset_in_bytes == 8, "cgltf_skin.joints has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_skin.joints has unexpected size % instead of 8", it.type.runtime_size);
                case "joints_count";
                    assert(it.offset_in_bytes == 16, "cgltf_skin.joints_count has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_skin.joints_count has unexpected size % instead of 8", it.type.runtime_size);
                case "skeleton";
                    assert(it.offset_in_bytes == 24, "cgltf_skin.skeleton has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_skin.skeleton has unexpected size % instead of 8", it.type.runtime_size);
                case "inverse_bind_matrices";
                    assert(it.offset_in_bytes == 32, "cgltf_skin.inverse_bind_matrices has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_skin.inverse_bind_matrices has unexpected size % instead of 8", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 40, "cgltf_skin.extras has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_skin.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 64, "cgltf_skin.extensions_count has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_skin.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 72, "cgltf_skin.extensions has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_skin.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_skin) == 80, "cgltf_skin has size % instead of 80", size_of(cgltf_skin));
    }

    {
        info := type_info(cgltf_camera_perspective);
        for info.members {
            if it.name == {
                case "has_aspect_ratio";
                    assert(it.offset_in_bytes == 0, "cgltf_camera_perspective.has_aspect_ratio has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_camera_perspective.has_aspect_ratio has unexpected size % instead of 4", it.type.runtime_size);
                case "aspect_ratio";
                    assert(it.offset_in_bytes == 4, "cgltf_camera_perspective.aspect_ratio has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_camera_perspective.aspect_ratio has unexpected size % instead of 4", it.type.runtime_size);
                case "yfov";
                    assert(it.offset_in_bytes == 8, "cgltf_camera_perspective.yfov has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_camera_perspective.yfov has unexpected size % instead of 4", it.type.runtime_size);
                case "has_zfar";
                    assert(it.offset_in_bytes == 12, "cgltf_camera_perspective.has_zfar has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_camera_perspective.has_zfar has unexpected size % instead of 4", it.type.runtime_size);
                case "zfar";
                    assert(it.offset_in_bytes == 16, "cgltf_camera_perspective.zfar has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_camera_perspective.zfar has unexpected size % instead of 4", it.type.runtime_size);
                case "znear";
                    assert(it.offset_in_bytes == 20, "cgltf_camera_perspective.znear has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_camera_perspective.znear has unexpected size % instead of 4", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 24, "cgltf_camera_perspective.extras has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_camera_perspective.extras has unexpected size % instead of 24", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_camera_perspective) == 48, "cgltf_camera_perspective has size % instead of 48", size_of(cgltf_camera_perspective));
    }

    {
        info := type_info(cgltf_camera_orthographic);
        for info.members {
            if it.name == {
                case "xmag";
                    assert(it.offset_in_bytes == 0, "cgltf_camera_orthographic.xmag has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_camera_orthographic.xmag has unexpected size % instead of 4", it.type.runtime_size);
                case "ymag";
                    assert(it.offset_in_bytes == 4, "cgltf_camera_orthographic.ymag has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_camera_orthographic.ymag has unexpected size % instead of 4", it.type.runtime_size);
                case "zfar";
                    assert(it.offset_in_bytes == 8, "cgltf_camera_orthographic.zfar has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_camera_orthographic.zfar has unexpected size % instead of 4", it.type.runtime_size);
                case "znear";
                    assert(it.offset_in_bytes == 12, "cgltf_camera_orthographic.znear has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_camera_orthographic.znear has unexpected size % instead of 4", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 16, "cgltf_camera_orthographic.extras has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_camera_orthographic.extras has unexpected size % instead of 24", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_camera_orthographic) == 40, "cgltf_camera_orthographic has size % instead of 40", size_of(cgltf_camera_orthographic));
    }

    {
        info := type_info(cgltf_camera);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_camera.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_camera.name has unexpected size % instead of 8", it.type.runtime_size);
                case "type";
                    assert(it.offset_in_bytes == 8, "cgltf_camera.type has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_camera.type has unexpected size % instead of 4", it.type.runtime_size);
                case "data";
                    assert(it.offset_in_bytes == 16, "cgltf_camera.data has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "cgltf_camera.data has unexpected size % instead of 48", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 64, "cgltf_camera.extras has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_camera.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 88, "cgltf_camera.extensions_count has unexpected offset % instead of 88", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_camera.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 96, "cgltf_camera.extensions has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_camera.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_camera) == 104, "cgltf_camera has size % instead of 104", size_of(cgltf_camera));
    }

    {
        info := type_info(cgltf_light);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_light.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_light.name has unexpected size % instead of 8", it.type.runtime_size);
                case "color";
                    assert(it.offset_in_bytes == 8, "cgltf_light.color has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "cgltf_light.color has unexpected size % instead of 12", it.type.runtime_size);
                case "intensity";
                    assert(it.offset_in_bytes == 20, "cgltf_light.intensity has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_light.intensity has unexpected size % instead of 4", it.type.runtime_size);
                case "type";
                    assert(it.offset_in_bytes == 24, "cgltf_light.type has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_light.type has unexpected size % instead of 4", it.type.runtime_size);
                case "range";
                    assert(it.offset_in_bytes == 28, "cgltf_light.range has unexpected offset % instead of 28", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_light.range has unexpected size % instead of 4", it.type.runtime_size);
                case "spot_inner_cone_angle";
                    assert(it.offset_in_bytes == 32, "cgltf_light.spot_inner_cone_angle has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_light.spot_inner_cone_angle has unexpected size % instead of 4", it.type.runtime_size);
                case "spot_outer_cone_angle";
                    assert(it.offset_in_bytes == 36, "cgltf_light.spot_outer_cone_angle has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_light.spot_outer_cone_angle has unexpected size % instead of 4", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 40, "cgltf_light.extras has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_light.extras has unexpected size % instead of 24", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_light) == 64, "cgltf_light has size % instead of 64", size_of(cgltf_light));
    }

    {
        info := type_info(cgltf_node);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_node.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_node.name has unexpected size % instead of 8", it.type.runtime_size);
                case "parent";
                    assert(it.offset_in_bytes == 8, "cgltf_node.parent has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_node.parent has unexpected size % instead of 8", it.type.runtime_size);
                case "children";
                    assert(it.offset_in_bytes == 16, "cgltf_node.children has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_node.children has unexpected size % instead of 8", it.type.runtime_size);
                case "children_count";
                    assert(it.offset_in_bytes == 24, "cgltf_node.children_count has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_node.children_count has unexpected size % instead of 8", it.type.runtime_size);
                case "skin";
                    assert(it.offset_in_bytes == 32, "cgltf_node.skin has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_node.skin has unexpected size % instead of 8", it.type.runtime_size);
                case "mesh";
                    assert(it.offset_in_bytes == 40, "cgltf_node.mesh has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_node.mesh has unexpected size % instead of 8", it.type.runtime_size);
                case "camera";
                    assert(it.offset_in_bytes == 48, "cgltf_node.camera has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_node.camera has unexpected size % instead of 8", it.type.runtime_size);
                case "light";
                    assert(it.offset_in_bytes == 56, "cgltf_node.light has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_node.light has unexpected size % instead of 8", it.type.runtime_size);
                case "weights";
                    assert(it.offset_in_bytes == 64, "cgltf_node.weights has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_node.weights has unexpected size % instead of 8", it.type.runtime_size);
                case "weights_count";
                    assert(it.offset_in_bytes == 72, "cgltf_node.weights_count has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_node.weights_count has unexpected size % instead of 8", it.type.runtime_size);
                case "has_translation";
                    assert(it.offset_in_bytes == 80, "cgltf_node.has_translation has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_node.has_translation has unexpected size % instead of 4", it.type.runtime_size);
                case "has_rotation";
                    assert(it.offset_in_bytes == 84, "cgltf_node.has_rotation has unexpected offset % instead of 84", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_node.has_rotation has unexpected size % instead of 4", it.type.runtime_size);
                case "has_scale";
                    assert(it.offset_in_bytes == 88, "cgltf_node.has_scale has unexpected offset % instead of 88", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_node.has_scale has unexpected size % instead of 4", it.type.runtime_size);
                case "has_matrix";
                    assert(it.offset_in_bytes == 92, "cgltf_node.has_matrix has unexpected offset % instead of 92", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_node.has_matrix has unexpected size % instead of 4", it.type.runtime_size);
                case "translation";
                    assert(it.offset_in_bytes == 96, "cgltf_node.translation has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "cgltf_node.translation has unexpected size % instead of 12", it.type.runtime_size);
                case "rotation";
                    assert(it.offset_in_bytes == 108, "cgltf_node.rotation has unexpected offset % instead of 108", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "cgltf_node.rotation has unexpected size % instead of 16", it.type.runtime_size);
                case "scale";
                    assert(it.offset_in_bytes == 124, "cgltf_node.scale has unexpected offset % instead of 124", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "cgltf_node.scale has unexpected size % instead of 12", it.type.runtime_size);
                case "matrix";
                    assert(it.offset_in_bytes == 136, "cgltf_node.matrix has unexpected offset % instead of 136", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "cgltf_node.matrix has unexpected size % instead of 64", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 200, "cgltf_node.extras has unexpected offset % instead of 200", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_node.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "has_mesh_gpu_instancing";
                    assert(it.offset_in_bytes == 224, "cgltf_node.has_mesh_gpu_instancing has unexpected offset % instead of 224", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_node.has_mesh_gpu_instancing has unexpected size % instead of 4", it.type.runtime_size);
                case "mesh_gpu_instancing";
                    assert(it.offset_in_bytes == 232, "cgltf_node.mesh_gpu_instancing has unexpected offset % instead of 232", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "cgltf_node.mesh_gpu_instancing has unexpected size % instead of 16", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 248, "cgltf_node.extensions_count has unexpected offset % instead of 248", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_node.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 256, "cgltf_node.extensions has unexpected offset % instead of 256", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_node.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_node) == 264, "cgltf_node has size % instead of 264", size_of(cgltf_node));
    }

    {
        info := type_info(cgltf_scene);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_scene.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_scene.name has unexpected size % instead of 8", it.type.runtime_size);
                case "nodes";
                    assert(it.offset_in_bytes == 8, "cgltf_scene.nodes has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_scene.nodes has unexpected size % instead of 8", it.type.runtime_size);
                case "nodes_count";
                    assert(it.offset_in_bytes == 16, "cgltf_scene.nodes_count has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_scene.nodes_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 24, "cgltf_scene.extras has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_scene.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 48, "cgltf_scene.extensions_count has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_scene.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 56, "cgltf_scene.extensions has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_scene.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_scene) == 64, "cgltf_scene has size % instead of 64", size_of(cgltf_scene));
    }

    {
        info := type_info(cgltf_animation_sampler);
        for info.members {
            if it.name == {
                case "input";
                    assert(it.offset_in_bytes == 0, "cgltf_animation_sampler.input has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation_sampler.input has unexpected size % instead of 8", it.type.runtime_size);
                case "output";
                    assert(it.offset_in_bytes == 8, "cgltf_animation_sampler.output has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation_sampler.output has unexpected size % instead of 8", it.type.runtime_size);
                case "interpolation";
                    assert(it.offset_in_bytes == 16, "cgltf_animation_sampler.interpolation has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_animation_sampler.interpolation has unexpected size % instead of 4", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 24, "cgltf_animation_sampler.extras has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_animation_sampler.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 48, "cgltf_animation_sampler.extensions_count has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation_sampler.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 56, "cgltf_animation_sampler.extensions has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation_sampler.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_animation_sampler) == 64, "cgltf_animation_sampler has size % instead of 64", size_of(cgltf_animation_sampler));
    }

    {
        info := type_info(cgltf_animation_channel);
        for info.members {
            if it.name == {
                case "sampler";
                    assert(it.offset_in_bytes == 0, "cgltf_animation_channel.sampler has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation_channel.sampler has unexpected size % instead of 8", it.type.runtime_size);
                case "target_node";
                    assert(it.offset_in_bytes == 8, "cgltf_animation_channel.target_node has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation_channel.target_node has unexpected size % instead of 8", it.type.runtime_size);
                case "target_path";
                    assert(it.offset_in_bytes == 16, "cgltf_animation_channel.target_path has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_animation_channel.target_path has unexpected size % instead of 4", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 24, "cgltf_animation_channel.extras has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_animation_channel.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 48, "cgltf_animation_channel.extensions_count has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation_channel.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 56, "cgltf_animation_channel.extensions has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation_channel.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_animation_channel) == 64, "cgltf_animation_channel has size % instead of 64", size_of(cgltf_animation_channel));
    }

    {
        info := type_info(cgltf_animation);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_animation.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation.name has unexpected size % instead of 8", it.type.runtime_size);
                case "samplers";
                    assert(it.offset_in_bytes == 8, "cgltf_animation.samplers has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation.samplers has unexpected size % instead of 8", it.type.runtime_size);
                case "samplers_count";
                    assert(it.offset_in_bytes == 16, "cgltf_animation.samplers_count has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation.samplers_count has unexpected size % instead of 8", it.type.runtime_size);
                case "channels";
                    assert(it.offset_in_bytes == 24, "cgltf_animation.channels has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation.channels has unexpected size % instead of 8", it.type.runtime_size);
                case "channels_count";
                    assert(it.offset_in_bytes == 32, "cgltf_animation.channels_count has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation.channels_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 40, "cgltf_animation.extras has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_animation.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 64, "cgltf_animation.extensions_count has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 72, "cgltf_animation.extensions has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_animation.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_animation) == 80, "cgltf_animation has size % instead of 80", size_of(cgltf_animation));
    }

    {
        info := type_info(cgltf_material_variant);
        for info.members {
            if it.name == {
                case "name";
                    assert(it.offset_in_bytes == 0, "cgltf_material_variant.name has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_material_variant.name has unexpected size % instead of 8", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 8, "cgltf_material_variant.extras has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_material_variant.extras has unexpected size % instead of 24", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_material_variant) == 32, "cgltf_material_variant has size % instead of 32", size_of(cgltf_material_variant));
    }

    {
        info := type_info(cgltf_asset);
        for info.members {
            if it.name == {
                case "copyright";
                    assert(it.offset_in_bytes == 0, "cgltf_asset.copyright has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_asset.copyright has unexpected size % instead of 8", it.type.runtime_size);
                case "generator";
                    assert(it.offset_in_bytes == 8, "cgltf_asset.generator has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_asset.generator has unexpected size % instead of 8", it.type.runtime_size);
                case "version";
                    assert(it.offset_in_bytes == 16, "cgltf_asset.version has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_asset.version has unexpected size % instead of 8", it.type.runtime_size);
                case "min_version";
                    assert(it.offset_in_bytes == 24, "cgltf_asset.min_version has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_asset.min_version has unexpected size % instead of 8", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 32, "cgltf_asset.extras has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_asset.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "extensions_count";
                    assert(it.offset_in_bytes == 56, "cgltf_asset.extensions_count has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_asset.extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions";
                    assert(it.offset_in_bytes == 64, "cgltf_asset.extensions has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_asset.extensions has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_asset) == 72, "cgltf_asset has size % instead of 72", size_of(cgltf_asset));
    }

    {
        info := type_info(cgltf_data);
        for info.members {
            if it.name == {
                case "file_type";
                    assert(it.offset_in_bytes == 0, "cgltf_data.file_type has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "cgltf_data.file_type has unexpected size % instead of 4", it.type.runtime_size);
                case "file_data";
                    assert(it.offset_in_bytes == 8, "cgltf_data.file_data has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.file_data has unexpected size % instead of 8", it.type.runtime_size);
                case "asset";
                    assert(it.offset_in_bytes == 16, "cgltf_data.asset has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 72, "cgltf_data.asset has unexpected size % instead of 72", it.type.runtime_size);
                case "meshes";
                    assert(it.offset_in_bytes == 88, "cgltf_data.meshes has unexpected offset % instead of 88", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.meshes has unexpected size % instead of 8", it.type.runtime_size);
                case "meshes_count";
                    assert(it.offset_in_bytes == 96, "cgltf_data.meshes_count has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.meshes_count has unexpected size % instead of 8", it.type.runtime_size);
                case "materials";
                    assert(it.offset_in_bytes == 104, "cgltf_data.materials has unexpected offset % instead of 104", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.materials has unexpected size % instead of 8", it.type.runtime_size);
                case "materials_count";
                    assert(it.offset_in_bytes == 112, "cgltf_data.materials_count has unexpected offset % instead of 112", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.materials_count has unexpected size % instead of 8", it.type.runtime_size);
                case "accessors";
                    assert(it.offset_in_bytes == 120, "cgltf_data.accessors has unexpected offset % instead of 120", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.accessors has unexpected size % instead of 8", it.type.runtime_size);
                case "accessors_count";
                    assert(it.offset_in_bytes == 128, "cgltf_data.accessors_count has unexpected offset % instead of 128", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.accessors_count has unexpected size % instead of 8", it.type.runtime_size);
                case "buffer_views";
                    assert(it.offset_in_bytes == 136, "cgltf_data.buffer_views has unexpected offset % instead of 136", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.buffer_views has unexpected size % instead of 8", it.type.runtime_size);
                case "buffer_views_count";
                    assert(it.offset_in_bytes == 144, "cgltf_data.buffer_views_count has unexpected offset % instead of 144", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.buffer_views_count has unexpected size % instead of 8", it.type.runtime_size);
                case "buffers";
                    assert(it.offset_in_bytes == 152, "cgltf_data.buffers has unexpected offset % instead of 152", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.buffers has unexpected size % instead of 8", it.type.runtime_size);
                case "buffers_count";
                    assert(it.offset_in_bytes == 160, "cgltf_data.buffers_count has unexpected offset % instead of 160", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.buffers_count has unexpected size % instead of 8", it.type.runtime_size);
                case "images";
                    assert(it.offset_in_bytes == 168, "cgltf_data.images has unexpected offset % instead of 168", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.images has unexpected size % instead of 8", it.type.runtime_size);
                case "images_count";
                    assert(it.offset_in_bytes == 176, "cgltf_data.images_count has unexpected offset % instead of 176", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.images_count has unexpected size % instead of 8", it.type.runtime_size);
                case "textures";
                    assert(it.offset_in_bytes == 184, "cgltf_data.textures has unexpected offset % instead of 184", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.textures has unexpected size % instead of 8", it.type.runtime_size);
                case "textures_count";
                    assert(it.offset_in_bytes == 192, "cgltf_data.textures_count has unexpected offset % instead of 192", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.textures_count has unexpected size % instead of 8", it.type.runtime_size);
                case "samplers";
                    assert(it.offset_in_bytes == 200, "cgltf_data.samplers has unexpected offset % instead of 200", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.samplers has unexpected size % instead of 8", it.type.runtime_size);
                case "samplers_count";
                    assert(it.offset_in_bytes == 208, "cgltf_data.samplers_count has unexpected offset % instead of 208", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.samplers_count has unexpected size % instead of 8", it.type.runtime_size);
                case "skins";
                    assert(it.offset_in_bytes == 216, "cgltf_data.skins has unexpected offset % instead of 216", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.skins has unexpected size % instead of 8", it.type.runtime_size);
                case "skins_count";
                    assert(it.offset_in_bytes == 224, "cgltf_data.skins_count has unexpected offset % instead of 224", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.skins_count has unexpected size % instead of 8", it.type.runtime_size);
                case "cameras";
                    assert(it.offset_in_bytes == 232, "cgltf_data.cameras has unexpected offset % instead of 232", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.cameras has unexpected size % instead of 8", it.type.runtime_size);
                case "cameras_count";
                    assert(it.offset_in_bytes == 240, "cgltf_data.cameras_count has unexpected offset % instead of 240", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.cameras_count has unexpected size % instead of 8", it.type.runtime_size);
                case "lights";
                    assert(it.offset_in_bytes == 248, "cgltf_data.lights has unexpected offset % instead of 248", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.lights has unexpected size % instead of 8", it.type.runtime_size);
                case "lights_count";
                    assert(it.offset_in_bytes == 256, "cgltf_data.lights_count has unexpected offset % instead of 256", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.lights_count has unexpected size % instead of 8", it.type.runtime_size);
                case "nodes";
                    assert(it.offset_in_bytes == 264, "cgltf_data.nodes has unexpected offset % instead of 264", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.nodes has unexpected size % instead of 8", it.type.runtime_size);
                case "nodes_count";
                    assert(it.offset_in_bytes == 272, "cgltf_data.nodes_count has unexpected offset % instead of 272", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.nodes_count has unexpected size % instead of 8", it.type.runtime_size);
                case "scenes";
                    assert(it.offset_in_bytes == 280, "cgltf_data.scenes has unexpected offset % instead of 280", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.scenes has unexpected size % instead of 8", it.type.runtime_size);
                case "scenes_count";
                    assert(it.offset_in_bytes == 288, "cgltf_data.scenes_count has unexpected offset % instead of 288", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.scenes_count has unexpected size % instead of 8", it.type.runtime_size);
                case "scene";
                    assert(it.offset_in_bytes == 296, "cgltf_data.scene has unexpected offset % instead of 296", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.scene has unexpected size % instead of 8", it.type.runtime_size);
                case "animations";
                    assert(it.offset_in_bytes == 304, "cgltf_data.animations has unexpected offset % instead of 304", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.animations has unexpected size % instead of 8", it.type.runtime_size);
                case "animations_count";
                    assert(it.offset_in_bytes == 312, "cgltf_data.animations_count has unexpected offset % instead of 312", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.animations_count has unexpected size % instead of 8", it.type.runtime_size);
                case "variants";
                    assert(it.offset_in_bytes == 320, "cgltf_data.variants has unexpected offset % instead of 320", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.variants has unexpected size % instead of 8", it.type.runtime_size);
                case "variants_count";
                    assert(it.offset_in_bytes == 328, "cgltf_data.variants_count has unexpected offset % instead of 328", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.variants_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extras";
                    assert(it.offset_in_bytes == 336, "cgltf_data.extras has unexpected offset % instead of 336", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_data.extras has unexpected size % instead of 24", it.type.runtime_size);
                case "data_extensions_count";
                    assert(it.offset_in_bytes == 360, "cgltf_data.data_extensions_count has unexpected offset % instead of 360", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.data_extensions_count has unexpected size % instead of 8", it.type.runtime_size);
                case "data_extensions";
                    assert(it.offset_in_bytes == 368, "cgltf_data.data_extensions has unexpected offset % instead of 368", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.data_extensions has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions_used";
                    assert(it.offset_in_bytes == 376, "cgltf_data.extensions_used has unexpected offset % instead of 376", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.extensions_used has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions_used_count";
                    assert(it.offset_in_bytes == 384, "cgltf_data.extensions_used_count has unexpected offset % instead of 384", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.extensions_used_count has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions_required";
                    assert(it.offset_in_bytes == 392, "cgltf_data.extensions_required has unexpected offset % instead of 392", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.extensions_required has unexpected size % instead of 8", it.type.runtime_size);
                case "extensions_required_count";
                    assert(it.offset_in_bytes == 400, "cgltf_data.extensions_required_count has unexpected offset % instead of 400", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.extensions_required_count has unexpected size % instead of 8", it.type.runtime_size);
                case "json";
                    assert(it.offset_in_bytes == 408, "cgltf_data.json has unexpected offset % instead of 408", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.json has unexpected size % instead of 8", it.type.runtime_size);
                case "json_size";
                    assert(it.offset_in_bytes == 416, "cgltf_data.json_size has unexpected offset % instead of 416", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.json_size has unexpected size % instead of 8", it.type.runtime_size);
                case "bin";
                    assert(it.offset_in_bytes == 424, "cgltf_data.bin has unexpected offset % instead of 424", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.bin has unexpected size % instead of 8", it.type.runtime_size);
                case "bin_size";
                    assert(it.offset_in_bytes == 432, "cgltf_data.bin_size has unexpected offset % instead of 432", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "cgltf_data.bin_size has unexpected size % instead of 8", it.type.runtime_size);
                case "memory";
                    assert(it.offset_in_bytes == 440, "cgltf_data.memory has unexpected offset % instead of 440", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_data.memory has unexpected size % instead of 24", it.type.runtime_size);
                case "file";
                    assert(it.offset_in_bytes == 464, "cgltf_data.file has unexpected offset % instead of 464", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "cgltf_data.file has unexpected size % instead of 24", it.type.runtime_size);
            }
        }
        assert(size_of(cgltf_data) == 488, "cgltf_data has size % instead of 488", size_of(cgltf_data));
    }
}

