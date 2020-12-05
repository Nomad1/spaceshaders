/***************************************************************
   Spherify shader for planets, shields and other rotating stuff
   Author: Nomad1

*  https://www.shadertoy.com/view/MlycWw
*  

***************************************************************/

uniform sampler2D s_texture_0;
uniform float s_time;

flat in vec4 Color;

in vec2 TexCoord;

const float AnimationSpeed = 0.005;
const float CellSize = 32.0;
const vec3 BaseColor = vec3(0.05);
const float BaseOpacity = 0.05;

float hex(vec2 p)
{
    p.x *= 0.57735*2.0;
    p.y += mod(floor(p.x), 2.0)*0.5;
    p = abs((mod(p, 1.0) - 0.5));
    return abs(max(p.x*1.5 + p.y, p.y*2.0) - 1.0);
}

// Taken from https://github.com/glslify/glsl-aastep
float aastep(float threshold, float value)
{
    float afwidth = length(vec2(dFdx(value), dFdy(value))) * 0.70710678118654757;
    return smoothstep(threshold-afwidth, threshold+afwidth, value);
}

void main(void)
{
    vec2 uv = TexCoord.xy;
    uv -= 0.5;
    uv *= 2.0;
    
    float r = length(uv);
    uv *= asin(r)/(r * sqrt(2.0));

    // renormalize uv
#if !defined(USE_TEXTURE)
    uv /= 2.0;
    uv += 0.5;
#endif

    // animation
    uv.x += s_time * AnimationSpeed;
    
    
#ifdef USE_TEXTURE
    uv.x *= 0.5;
    
    float alpha = (1.0 - pow(r, 512.0)); // remove sphere border

    vec3 texColor = texture(s_texture_0, fract(uv)).rgb * (1.0 - r * r) * Color.rgb;
    
#else
    vec3 sphereColor = Color.rgb;
    vec2 p = uv * CellSize; // average cell size
    float hexDist = hex(p) + 0.4;
    
    vec3 texColor = mix(sphereColor.rgb + BaseColor, sphereColor.rgb, aastep(0.5, hexDist));

    float alpha = (1.0 - pow(r, 128.0)) * pow(r, 16.0) + r * 0.1 + BaseOpacity;
#endif

    alpha *= Color.a;

    if (alpha < 0.01)
        discard;

    gl_FragColor = vec4(texColor, alpha);
}