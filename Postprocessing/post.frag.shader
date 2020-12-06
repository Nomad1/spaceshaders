// uniforms

uniform mediump sampler2D s_texture_0;
uniform lowp sampler2D s_texture_1;

uniform mediump float s_nearPlaneWidth;
uniform mediump float s_nearPlaneHeight;
uniform mediump float s_cameraFieldOfView;

uniform vec4 s_environmentColor;
uniform vec4 s_ambientColor;
uniform vec4 s_goreColor;

//uniform float s_debugParam0;
//uniform float s_debugParam1;
//uniform float s_debugParam2;

// parameters

#ifdef FXAA
in vec2 TexCoord[5];
#else
in vec2 TexCoord[1];
#endif

flat in float Aspect;
flat in vec2 LightPos;
in vec4 LightDir;

// options

#define DITHER

// constants

#if defined( ULTRA_QUALITY )
 const int Samples = 12;
 const float Weight = 0.8;
 const float Decay = 0.8;
 const float Exposure = 0.03;
#elif defined( HIGH_QUALITY )
 const int Samples = 8;
 const float Weight = 0.8;
 const float Decay = 0.8;
 const float Exposure = 0.03;
#elif defined( NORMAL_QUALITY )
 const int Samples = 6;
 const float Weight = 0.9;
 const float Decay = 0.9;
 const float Exposure = 0.04;
#else
 const int Samples = 3;
 const float Weight = 0.9;
 const float Decay = 0.9;
 const float Exposure = 0.04;
#endif

const float Step = 0.010 / float(Samples);
const vec3 SunColor = vec3(1.0, 0.84, 0.78);

in vec3 Coords[Samples];
in float NSteps;

// methods

#ifdef DITHER

const float Bayer8x8[] = float[]
    ( /* 8x8 Bayer ordered dithering pattern */
        0.0, 0.5, 0.125, 0.625, 0.03125, 0.53125, 0.15625, 0.65625, 
        0.75, 0.25, 0.875, 0.375, 0.78125, 0.28125, 0.90625, 0.40625,
        0.1875, 0.6875, 0.0625, 0.5625, 0.21875, 0.71875, 0.09375, 0.59375,
        0.9375, 0.4375, 0.8125, 0.3125, 0.96875, 0.46875, 0.84375, 0.34375,
        0.046875, 0.546875, 0.171875, 0.671875, 0.015625, 0.515625, 0.140625, 0.640625,
        0.796875, 0.296875, 0.921875, 0.421875, 0.765625, 0.265625, 0.890625, 0.390625,
        0.234375, 0.734375, 0.109375, 0.609375, 0.203125, 0.703125, 0.078125, 0.578125,
        0.984375, 0.484375, 0.859375, 0.359375, 0.953125, 0.453125, 0.828125, 0.328125
    );

const mat4 Bayer4x4 = mat4(
    vec4(0.0, 0.75, 0.1875, 0.9375),
    vec4(0.5, 0.25, 0.6875, 0.4375),
    vec4(0.125, 0.875, 0.0625, 0.8125),
    vec4(0.625, 0.375, 0.5625, 0.3125));

float bayer2(vec2 a)
{
    float y = floor(a.y);

    return fract(floor(a.x) * 0.5 + y * y * 0.75);
}

float bayer4_comp(vec2 a)
{
    return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

float bayer4(vec2 a)
{
    return Bayer4x4[int(a.x) % 4][int(a.y) % 4];
}

float bayer8(vec2 a)
{
    return Bayer8x8[int(a.x) % 8 + (int(a.y) % 8) * 8];
}

#endif

#ifdef LENS_FLARE

// derived from https://www.shadertoy.com/view/4sX3Rs

vec3 lensflare(vec2 uv, vec2 pos)
{
    uv.x *= Aspect;
    pos.x *= Aspect;
    vec2 main = uv-pos;
    vec2 uvd = uv*(length(uv));
    
    float ang = atan(main.x,main.y);
    
    float f2 = max(1.0/(1.0+32.0*pow(length(uvd+0.8*pos),2.0)),0.0)*0.325;
    float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.85*pos),2.0)),0.0)*0.299;
    float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.9*pos),2.0)),0.0)*0.273;
    
    vec2 uvx = mix(uv,uvd,-0.5);
    
    float f4 = max(0.01-pow(length(uvx+0.4*pos),2.4),0.0)*7.8;
    float f42 = max(0.01-pow(length(uvx+0.45*pos),2.4),0.0)*6.5;
    float f43 = max(0.01-pow(length(uvx+0.5*pos),2.4),0.0)*3.9;
    
    uvx = mix(uv,uvd,-0.4);
    
    float f5 = max(0.01-pow(length(uvx+0.2*pos),5.5),0.0)*2.6;
    float f52 = max(0.01-pow(length(uvx+0.4*pos),5.5),0.0)*2.6;
    float f53 = max(0.01-pow(length(uvx+0.6*pos),5.5),0.0)*2.6;
    
    uvx = mix(uv,uvd,-0.5);
    
    float f6 = max(0.01-pow(length(uvx-0.3*pos),1.6),0.0)*7.8;
    float f62 = max(0.01-pow(length(uvx-0.325*pos),1.6),0.0)*3.9;
    float f63 = max(0.01-pow(length(uvx-0.35*pos),1.6),0.0)*6.5;
    
    return vec3(f2 + f4 + f5 + f6, f22 + f42 + f52 + f62, f23 + f43 + f53 + f63) - vec3(length(uvd)*0.05);
}
#endif

float hex(vec2 p)
{
    p.x *= 0.57735*2.0;
    p.y += mod(floor(p.x), 2.0)*0.5;
    p = abs((mod(p, 1.0) - 0.5));
    return abs(max(p.x*1.5 + p.y, p.y*2.0) - 1.0);
}

float goreColor(vec2 uv)
{
    float value = dot(uv, uv);

    return value * (0.75 + step(hex(vec2(uv.x * Aspect * 16.0, uv.y * 16.0)) + 0.4, 0.5) * 0.25);
}

vec2 getLight(vec2 uv, vec2 lightPos)
{   
    // Closed Form... https://www.shadertoy.com/view/XtjfzD
    vec2 lightShift = (uv - lightPos);
    lightShift.x *= Aspect;

    float h = dot(lightShift, lightShift) * (2.0 * s_cameraFieldOfView);
    #ifndef SUN_LIGHT
        h = clamp(h, 0.2, 100.0);
    #endif

    // .. removed lot of XaXh calculations for integral
    const float ks = 0.05;
    const float kt = 0.05;

    float brightness = (ks / h) * exp(-kt * h) * 0.159154940740727;
        
    return vec2(sqrt(brightness), brightness);
}

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

#ifdef BLUR
vec4 blur5vh(sampler2D image, vec2 uv, vec2 resolution, vec2 direction)
{
  vec2 offv = direction * vec2(1.3333333333333333) / resolution;
  vec2 offh = vec2(offv.y, offv.x);

  vec4 color = vec4(0.0);
  color += texture(image, uv + offv);
  color += texture(image, uv - offv);
  color += texture(image, uv + offh);
  color += texture(image, uv - offh);

  return texture(image, uv) * 0.29411764705882354 + color * 0.176470588235294; 
}
#endif

#ifdef FXAA

    #define FXAA_REDUCE_MIN   (1.0/ 128.0)
    #define FXAA_REDUCE_MUL   (1.0 / 8.0)
    #define FXAA_SPAN_MAX     8.0

vec4 fxaa(sampler2D dtex, sampler2D tex,
            vec2 fragCoord[5], vec2 resolution, out float depth, out float depthMix)
{
    vec4 color;
    vec2 inverseVP = vec2(1.0 / resolution.x, 1.0 / resolution.y);

    float lumaNW = texture(dtex, fragCoord[1]).r;
    float lumaNE = texture(dtex, fragCoord[2]).r;
    float lumaSW = texture(dtex, fragCoord[3]).r;
    float lumaSE = texture(dtex, fragCoord[4]).r;
    float lumaM  = texture(dtex, fragCoord[0]).r;

    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));
    
    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));
    
    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) *
                          (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
    
    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = min(vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX),
              max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
              dir * rcpDirMin));

    depthMix = length(dir); // edge detection

    dir *= inverseVP;

    float lumaA = 0.5 * (
        texture(dtex, fragCoord[0] + dir * (1.0 / 3.0 - 0.5)).r +
        texture(dtex, fragCoord[0] + dir * (2.0 / 3.0 - 0.5)).r);

    float lumaB = lumaA * 0.5 + 0.25 * (
        texture(dtex, fragCoord[0] - dir * 0.5).r +
        texture(dtex, fragCoord[0] + dir * 0.5).r);

    
    vec3 rgbA = 0.5 * (
        texture(tex, fragCoord[0] + dir * (1.0 / 3.0 - 0.5)).xyz +
        texture(tex, fragCoord[0] + dir * (2.0 / 3.0 - 0.5)).xyz);

    vec3 rgbB = rgbA * 0.5 + 0.25 * (
        texture(tex, fragCoord[0] - dir * 0.5).xyz +
        texture(tex, fragCoord[0] + dir * 0.5).xyz);

    float a = 1.0;// texture(tex, fragCoord[0]).a; // we don't have background alpha at all

    if ((lumaB < lumaMin) || (lumaB > lumaMax))
    {
        color = vec4(rgbA, a);
        depth = lumaA;
    }
    else
    {
        color = vec4(rgbB, a);
        depth = lumaB;
    }

    return color;
}
#endif

void main(void)
{
    vec2 dir = LightDir.xy;
    float len = LightDir.z;
    float distance = LightDir.w;

    float nsteps = NSteps;

    vec4 localGoreColor = s_goreColor;

#ifdef DITHER
    vec2 dither = (dir / nsteps) * bayer4(gl_FragCoord.xy);
#endif

#if defined( FXAA )
    float depthMix;
    float obj;
    vec4 backColor = fxaa(s_texture_0, s_texture_1, TexCoord, vec2(s_nearPlaneWidth, s_nearPlaneHeight), obj, depthMix);
#else
    #if defined ( PIXELIZE )
        vec2 lowRes = vec2(s_nearPlaneWidth, s_nearPlaneHeight) * 0.25;
        vec2 texCoord = floor(TexCoord[0] * lowRes) / lowRes;

        vec4 backColor = texture(s_texture_1, texCoord);
        float obj = texture(s_texture_0, texCoord).r;

        localGoreColor = vec4(-0.5, -0.5, -0.5, 0.75);
    #elif defined ( BLUR )
        float obj = blur5vh(s_texture_0, TexCoord[0], vec2(s_nearPlaneWidth, s_nearPlaneHeight), vec2(0.0, 1.5)).r;
        vec4 backColor = blur5vh(s_texture_1, TexCoord[0], vec2(s_nearPlaneWidth, s_nearPlaneHeight), vec2(0.0, 1.5));

        localGoreColor = vec4(-0.5, -0.5, -0.5, 0.75);
    #else
        vec4 backColor = texture(s_texture_1, TexCoord[0]);
        float obj = texture(s_texture_0, TexCoord[0]).r;
    #endif
#endif



#if defined(HIGH_QUALITY) || defined(ULTRA_QUALITY)
    float occ = 3.0;
#else
    // don't do the cycle for opaque pixels in normal and low quality
    float occ = step(1.0, obj);

    nsteps *= occ;
    
    occ = 3.0 - occ * 3.0;
#endif
    int insteps = clamp(int(nsteps), 0, Samples);
    
    for(int i = 0; i < insteps; i++)
    {
        float s = step(1.0, texture(s_texture_0, Coords[i].xy
            #ifdef DITHER
                + dither
            #endif
        ).r) ;

#if defined( LOW_QUALITY )
        if (s == 0.0) // this saves a lot of power, but picture quality is low
           break; 
        
        occ += Coords[i].z;
#else
        occ += s * Coords[i].z;
#endif
    }   

    occ *= 1.0 - len;

    vec2 light = getLight(TexCoord[0], LightPos);

    float depthValue =
#if defined ( LOW_QUALITY ) || defined ( NORMAL_QUALITY )
        step(1.0, obj);
#else
        smoothstep(0.5, 1.3, pow(obj, 5.0));
#endif

#if defined(FXAA)
    depthValue += depthMix * 0.01;
#endif
    float goreValue = goreColor(TexCoord[0] - vec2(0.5)) * localGoreColor.a;

    vec4 values = saturate(vec4(light.y * depthValue, pow(obj * 1.3 - 0.17, 3.0), occ * Exposure, goreValue));

    const vec4 coefs = vec4(0.2, 0.6, 1.0, 1.0);

    float alpha = dot(values, coefs);

    gl_FragColor = vec4(
        backColor.rgb * (1.0 - alpha)
            + SunColor.rgb * light.x * values.x
            + s_ambientColor.rgb * values.y
            + s_environmentColor.rgb * values.z
            + localGoreColor.rgb * values.w
#ifdef LENS_FLARE
            + lensflare(TexCoord[0] - vec2(0.5), LightPos - vec2(0.5))
#endif
            , 1.0);
}