#version 300 es

#define MAX_LIGHTS 16

// Fragment shaders don't have a default precision so we need
// to pick one. mediump is a good default. It means "medium precision".
precision mediump float;

uniform bool u_show_normals;

// struct definitions
struct AmbientLight {
    vec3 color;
    float intensity;
};

struct DirectionalLight {
    vec3 direction;
    vec3 color;
    float intensity;
};

struct PointLight {
    vec3 position;
    vec3 color;
    float intensity;
};

struct Material {
    vec3 kA;
    vec3 kD;
    vec3 kS;
    float shininess;
    sampler2D map_kD;
    sampler2D map_nS;
    sampler2D map_norm;
};

// lights and materials
uniform AmbientLight u_lights_ambient[MAX_LIGHTS];
uniform DirectionalLight u_lights_directional[MAX_LIGHTS];
uniform PointLight u_lights_point[MAX_LIGHTS];

uniform Material u_material;

// camera position in world space
uniform vec3 u_eye;

// with webgl 2, we now have to define an out that will be the color of the fragment
out vec4 o_fragColor;

// received from vertex stage
// TODO: Create variables to receive from the vertex stage
in vec3 output_vpw;
in vec3 output_vnw;
in mat3 output_tbn;
in vec2 output_tc;

// Shades an ambient light and returns this light's contribution
vec3 shadeAmbientLight(Material material, AmbientLight light) {

    // TODO: Implement this
    // TODO: Include the material's map_kD to scale kA and to provide texture even in unlit areas
    // NOTE: We could use a separate map_kA for this, but most of the time we just want the same texture in unlit areas
    // HINT: Refer to http://paulbourke.net/dataformats/mtl/ for details
    // HINT: Parts of ./shaders/phong.frag.glsl can be re-used here
    if(light.intensity == 0.0){
        return vec3(0);
    }
    vec3 kA = texture(u_material.map_kD, output_tc).rgb;
    return light.color * light.intensity * material.kA * kA;
}

// Shades a directional light and returns its contribution
vec3 shadeDirectionalLight(Material material, DirectionalLight light, vec3 normal, vec3 eye, vec3 vertex_position) {
    
    // TODO: Implement this
    // TODO: Use the material's map_kD and map_nS to scale kD and shininess
    // HINT: The darker pixels in the roughness map (map_nS) are the less shiny it should be
    // HINT: Refer to http://paulbourke.net/dataformats/mtl/ for details
    // HINT: Parts of ./shaders/phong.frag.glsl can be re-used here
    vec3 answer = vec3(0);
    if(light.intensity == 0.0){
        return answer;
    }

    vec3 Normal = normalize(normal);
    vec3 Light = -normalize(light.direction);
    vec3 Vector = normalize(vertex_position - eye);

    vec3 kD = texture(u_material.map_kD, output_tc).rgb;
    vec3 shiny = texture(u_material.map_nS, output_tc).rgb;

    float Light_Normal = max(dot(Light, Normal), 0.0);
    answer += Light_Normal * light.color * light.intensity * material.kD * kD;

    vec3 Reflect = reflect(Light, Normal);
    answer += pow(max(dot(Reflect, Vector), 0.0), material.shininess) * light.color * light.intensity * material.kS * shiny;
    return answer;
}

// Shades a point light and returns its contribution
vec3 shadePointLight(Material material, PointLight light, vec3 normal, vec3 eye, vec3 vertex_position) {

    // TODO: Implement this
    // TODO: Use the material's map_kD and map_nS to scale kD and shininess
    // HINT: The darker pixels in the roughness map (map_nS) are the less shiny it should be
    // HINT: Refer to http://paulbourke.net/dataformats/mtl/ for details
    // HINT: Parts of ./shaders/phong.frag.glsl can be re-used here
    vec3 answer = vec3(0);
    if (light.intensity == 0.0){
        return answer;
    }
    vec3 Normal = normalize(normal);
    float Distance = distance(light.position, vertex_position);
    vec3 Light = normalize(light.position - vertex_position);
    vec3 Vector = normalize(vertex_position - eye);

    vec3 kD = texture(u_material.map_kD, output_tc).rgb;
    vec3 shiny = texture(u_material.map_nS, output_tc).rgb;

    float Light_Normal = max(dot(Light, Normal), 0.0);
    answer += Light_Normal * light.color * light.intensity * material.kD * kD;

    vec3 Reflect = reflect(Light, Normal);
    answer += pow( max(dot(Reflect, Vector), 0.0), material.shininess) * light.color * light.intensity * material.kS * shiny;

    answer *= 1.0 / (Distance * Distance + 1.0);

    return answer;
}

void main() {

    // TODO: Calculate the normal from the normal map and tbn matrix to get the world normal
    vec3 normal = texture(u_material.map_norm, output_tc).rgb;
    normal = normal * 2.0 - 1.0;
    normal = normalize(output_tbn * normal);

    // if we only want to visualize the normals, no further computations are needed
    // !do not change this code!
    if (u_show_normals == true) {
        o_fragColor = vec4(normal, 1.0);
        return;
    }

    // we start at 0.0 contribution for this vertex
    vec3 light_contribution = vec3(0.0);

    // iterate over all possible lights and add their contribution
    for(int i = 0; i < MAX_LIGHTS; i++) {
        // TODO: Call your shading functions here like you did in A5
        light_contribution += shadeAmbientLight(u_material, u_lights_ambient[i]);
        light_contribution += shadeDirectionalLight(u_material, u_lights_directional[i], output_vnw, u_eye, output_vpw);
        light_contribution += shadePointLight(u_material, u_lights_point[i], output_vnw, u_eye, output_vpw);
    }

    o_fragColor = vec4(light_contribution, 1.0);
}