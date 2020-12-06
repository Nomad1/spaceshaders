/******* Model fragment shader. Uses environment data and alpha channel for bump ******/

//#define DEBUG_INSTANCING
uniform sampler2D s_texture_0;
uniform vec4 s_spotLightDirection;

uniform vec4 s_environmentColor;
uniform vec4 s_ambientColor;
uniform vec4 s_tintColor;


flat in vec4 Color;
in vec4 TexCoord;
in vec3 Normal;
in vec4 SpotLight;
in vec4 OmniLight;

flat in float VertexScale;

in mat3 ModelMatrix;

#ifdef SUN_LIGHT
in vec3 SunLight;
#endif

const float AmbientLightFlatValue = 0.0;
const float AmbientLightValue = 0.6;
const vec3 AmbientLightPosition = vec3(0.0, 0.0, 1.0);
const float SpotLightValue = 0.4;
const float OmniLightValue = 2.0;
const float SunLightValue = 2.0;

const float BumpValue = 10.0;


const vec4 LightMix = vec4(AmbientLightValue, SpotLightValue, OmniLightValue, SunLightValue);


float saturate(float value)
{
    return clamp(value, 0.0, 1.0);
}

vec3 saturate(vec3 value)
{
    return clamp(value, vec3(0.0), vec3(1.0));
}

vec4 saturate(vec4 value)
{
    return clamp(value, vec4(0.0), vec4(1.0));
}

float hash(vec2 p)
{
    //return fract(sin(dot(p.xy, vec2(12.9898,78.233))) * 43758.5453);
    return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x))));
}

float noise(in vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);  
    vec2 u = f*f*(3.0-2.0*f);
    
    vec2 ii = i.xy + i.y;// * vec2(5.0);
    float a = hash( ii + vec2(0.0,0.0) );
    float b = hash( ii + vec2(1.0,0.0) );    
    float c = hash( ii + vec2(0.0,1.0) );
    float d = hash( ii + vec2(1.0,1.0) ); 

    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

void main(void)
{
#ifdef DEBUG_INSTANCING
    gl_FragColor = Color;
#else
    vec4 texColor = texture(s_texture_0, TexCoord.xy);

    vec3 color;
    vec3 normal;
    vec4 omniPosition;
    
    color = texColor.rgb * Color.rgb;
    color = mix(color, s_environmentColor.rgb, s_environmentColor.a);

    float bump = texColor.a;

#if defined ( COMPAT_QUALITY )
    normal = normalize(Normal + vec3(0.0, 0.0, bump * 2.0 - 1.0)); // cheap code for fake bumping
#elif defined ( LOW_QUALITY )
    const float coef = BumpValue * 0.05;
    bump = bump * (noise(TexCoord.xy * VertexScale) * coef + 0.5);  // noise bumping
    normal = normalize(Normal + vec3(0.0, 0.0, bump * 2.0 - 1.0)); // cheap code for fake bumping
#else

    #if defined ( ULTRA_QUALITY )
    // this one is slow. It's better to use derivatives
    vec2 texStride = 1.0 / vec2(textureSize(s_texture_0, 0));

    float bumpX = texture(s_texture_0, TexCoord.xy + vec2(texStride.x, 0.0)).a;
    float bumpY = texture(s_texture_0, TexCoord.xy + vec2(0.0, texStride.y)).a;
    const float coef = BumpValue;
    #else
    float bumpX = texture(s_texture_0, TexCoord.xy + dFdx(TexCoord.xy)).a;
    float bumpY = texture(s_texture_0, TexCoord.xy + dFdy(TexCoord.xy)).a;
    const float coef = BumpValue * 0.3;
    #endif

    normal = normalize(ModelMatrix * vec3((bump - bumpY) * coef, (bump - bumpX) * coef, 1.0));
#endif
    omniPosition = OmniLight;
    
    color *= s_tintColor.rgb;
    
    float ambient = saturate(dot(normal, AmbientLightPosition) + AmbientLightFlatValue);
    
    float spotDot = saturate(dot(SpotLight.xyz, s_spotLightDirection.xyz)); // we're using 3D spotlight and W component is light length
    float spotAttenuation = smoothstep(0.0, 1.0, SpotLight.w) * smoothstep(s_spotLightDirection.w, 1.0, spotDot);
    float spot = /*dot(normal, SpotLight.xyz) * */spotAttenuation; // Nomad: I'm commenting out normals for spot light
    
    float omniAttenuation = smoothstep(0.0, 1.0, omniPosition.w);
    float omni = dot(normal, omniPosition.xyz) * omniAttenuation;

#ifdef SUN_LIGHT
    float sun = dot(normal, SunLight.xyz);
#else
    float sun = 0.0;
#endif
    
    // 4 components of light is combined to vec4 and then multiplied to LightMix vector
    vec4 light = saturate(vec4(ambient, spot, omni, sun));
    
    gl_FragColor = vec4(mix(s_ambientColor.rgb, color, saturate(dot(light, LightMix)) * Color.a), 1.0);
#endif
}