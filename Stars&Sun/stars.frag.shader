in vec2 TexCoord;

const vec3 SunColor = vec3(1.0, 0.84, 0.78);
const float Exposure = 0.03;

uniform vec4 s_ambientColor;

#if defined ( TEXTURE )
uniform sampler2D s_texture_0;
#endif

#if defined ( SUN_LIGHT )

#ifdef MODE_COMPAT
uniform float s_cameraFieldOfView;
#else
uniform highp float s_cameraFieldOfView;
#endif

uniform vec4 s_environmentColor;

flat in float Aspect;
flat in vec2 LightPos;

#endif

#if defined ( STARS )

in vec3 SphereCoords;
flat in float ScreenScale;

// Star map shader...procedural space background
// derivative from https://www.shadertoy.com/view/4sBXzG

// See derivation of noise functions by Morgan McGuire at https://www.shadertoy.com/view/4dS3Wd
float hash2(vec2 p)
{
    return fract(sin(dot(p.xy, vec2(12.9898,78.233))) * 43758.5453);
}

float hash(vec2 p)
{
    return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x))));
}

#if defined ( ULTRA_QUALITY )
float noise(vec2 x)
{
    vec2 i = floor(x);
    vec2 f = x - i;
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
#endif

///////////////////////////////////////////////////////////////////////

// Only globals needed for the actual spheremap

// starplane was derived from https://www.shadertoy.com/view/lsfGWH
float starplane(vec3 dir, float screenscale, float n) { 

    float dz = abs(dir.z);
    vec2 basePos = floor(dir.xy * screenscale / dz) * 0.0005;

    float r = hash2(basePos);

    return r * step(1.0 - n * 0.001, r) * dz;
}

float starbox(vec3 dir, float screenscale, float n)
{
    return starplane(dir.xyz, screenscale, n) + starplane(dir.yzx, screenscale, n) + starplane(dir.zxy, screenscale, n);
}    

vec3 sphereColor(vec3 dir, vec3 nebulaHue, float screenscale)
{
#if defined ( ULTRA_QUALITY )
    float n = noise(dir.xy * 6.0) * 2.0;
#else
    const float n = 1.0;
#endif
    return nebulaHue * n * n + vec3(starbox(dir, screenscale, n));
}

#endif

#if defined ( SUN_LIGHT )

vec2 getLight(vec2 uv, vec2 lightPos)
{   
    // Closed Form... https://www.shadertoy.com/view/XtjfzD
    vec2 lightShift = (uv - lightPos);
    lightShift.x *= Aspect;

    float h = dot(lightShift, lightShift) * (2.0 * s_cameraFieldOfView);

    // .. removed lot of XaXh calculations for integral
    const float ks = 0.05;
    const float kt = 0.05;

    float brightness = (ks / h) * exp(-kt * h) * 0.159154940740727;
        
    return vec2(sqrt(brightness), brightness);
}

#endif

void main(void)
{
#if defined ( TEXTURE ) && defined ( SUN_LIGHT )
    vec3 color = texture(s_texture_0, TexCoord).rgb * 0.25 + s_ambientColor.rgb;
#else
    vec3 color = s_ambientColor.rgb;
#endif

#if !defined ( SUN_LIGHT )
    color *= 0.25;
#endif

#if defined ( STARS )
    color = sphereColor(SphereCoords, color, ScreenScale);
#endif

#if defined ( SUN_LIGHT )
    vec2 light = getLight(TexCoord, LightPos);

    color += SunColor * light.x * light.y + s_environmentColor.rgb * Exposure;
#endif

    gl_FragColor = vec4(color.rgb, 1.0);

    gl_FragDepth = 1.0;
}