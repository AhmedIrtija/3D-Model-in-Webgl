#version 300 es

// an attribute will receive data from a buffer
in vec3 a_position;
in vec3 a_normal;
in vec3 a_tangent;
in vec2 a_texture_coord;

// transformation matrices
uniform mat4x4 u_m;
uniform mat4x4 u_v;
uniform mat4x4 u_p;

// output to fragment stage
// TODO: Create varyings to pass data to the fragment stage (position, texture coords, and more)
out vec3 output_vpw;
out vec3 output_vnw;
out mat3 output_tbn;
out vec2 output_tc;

void main() {

    // transform a vertex from object space directly to screen space
    // the full chain of transformations is:
    // object space -{model}-> world space -{view}-> view space -{projection}-> clip space
    vec4 vertex_position_world = u_m * vec4(a_position, 1.0);

    // TODO: Construct TBN matrix from normals, tangents and bitangents
    vec3 Normal = normalize(vec3(u_m * vec4(a_normal, 0.0)));
    vec3 Tangents = normalize(vec3(u_m * vec4(a_tangent, 0.0)));
    // TODO: Use the Gram-Schmidt process to re-orthogonalize tangents
    Tangents = normalize(Tangents - dot(Tangents, Normal) * Normal);
    vec3 Bitangents = cross(Normal, Tangents);
    // NOTE: Different from the book, try to do all calculations in world space using the TBN to transform normals
    // HINT: Refer to https://learnopengl.com/Advanced-Lighting/Normal-Mapping for all above
    mat3 tbn = mat3(Tangents, Bitangents, Normal);

    mat3 normal_mat = transpose(inverse(mat3(u_m)));
    vec3 vnw = normalize(normal_mat * a_normal);

    // TODO: Forward data to fragment stage
    output_vpw = vertex_position_world.xyz;
    output_vnw = vnw.xyz;
    output_tbn = tbn;
    output_tc = a_texture_coord;

    gl_Position = u_p * u_v * vertex_position_world;

}