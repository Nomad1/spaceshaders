//#define DEBUG_INSTANCING
// Uniforms
uniform mat4 s_pmvMatrix;

uniform vec4 s_omniLightPosition;
uniform vec4 s_spotLightPosition;

#ifdef SUN_LIGHT
uniform vec3 s_sunLightPosition;
#endif

// Attributes
in vec3 in_position;
in vec2 in_texcoord;
in vec3 in_normal;
//in int in_surfaceId;

// Instanced attributes
in mat4 in_modelMatrix;
in int in_instanceId;
in vec4 in_color;
in vec4 in_tcTransform;
in int in_flag;
//in int in_targetSurfaceId;

#ifdef TWO_LAYER_MAPPING
in vec4 in_color2;
in vec4 in_tcTransform2;
flat out vec4 Color2;
#endif

// Out to fragment shader
flat out vec4 Color;
out vec4 TexCoord;

#ifndef MODEL_MODE
out vec3 Normal;
out vec4 SpotLight;
out vec4 OmniLight;
flat out vec3 LightDirection;

#ifdef ASTEROID
flat out float VertexScale;
#endif

out mat3 ModelMatrix;

#ifdef SUN_LIGHT
out vec3 SunLight;
#endif

flat out float Flag;

#endif

float rand(float n){ return fract(sin(n) * 43758.5453123); }

void main(void)
{
#ifdef DEBUG_INSTANCING
    Color = vec4(rand(in_instanceId + 0.0), rand(in_instanceId + 1.0), rand(in_instanceId + 2.0), 1.0);
#else
    Color = in_color.bgra;
#endif

    vec2 tc = in_texcoord * in_tcTransform.zw + in_tcTransform.xy;

#ifdef TWO_LAYER_MAPPING
    Color2 = in_color2.bgra;
    vec2 tc2 = in_texcoord * in_tcTransform2.zw + in_tcTransform2.xy;
    TexCoord = vec4(tc, tc2);
#else
    TexCoord = vec4(tc, tc);
#endif

    vec4 pos = (in_modelMatrix * vec4(in_position, 1.0));

#ifdef ASTEROID
    VertexScale = pos.w * 700.0;
#endif
    gl_Position = s_pmvMatrix * pos;

#ifndef MODEL_MODE    
    Flag = float(in_flag);
    ModelMatrix = mat3(in_modelMatrix);

    vec3 normal = in_normal.xyz;
    
    Normal = normalize(ModelMatrix * normal);

#if defined ( NORMAL_QUALITY ) || defined ( HIGH_QUALITY ) || defined ( ULTRA_QUALITY )
    vec3 t = -vec3(abs(normal.y) + abs(normal.z), abs(normal.x), 0); // calculate local space tangent
    vec3 b = cross(t, normal);
    t = cross(b, normal); // restore valid tangent

    ModelMatrix = mat3(normalize(ModelMatrix * t), normalize(ModelMatrix * b), Normal);
#endif

    vec3 spotLight = s_spotLightPosition.xyz - pos.xyz;
    float spotLength = length(spotLight.xyz);
    SpotLight = vec4(spotLight.xyz / spotLength, spotLength / s_spotLightPosition.w);
    
    vec3 omniLight = s_omniLightPosition.xyz - pos.xyz;
    float omniLength = length(omniLight.xyz);
    OmniLight = vec4(omniLight.xyz / omniLength, 1.0 - omniLength / s_omniLightPosition.w);
    
#ifdef SUN_LIGHT
    vec3 sunLight = s_sunLightPosition - pos.xyz;
    SunLight = normalize(sunLight);
#endif

#endif
}
