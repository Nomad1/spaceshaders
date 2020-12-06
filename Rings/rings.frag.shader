uniform sampler2D s_texture_0;
uniform sampler2D s_texture_1;

uniform vec4 s_tcClip2;
uniform vec4 s_tcTransform2;
uniform float s_ringZoom;
uniform float s_time;

in vec2 TexCoord;
flat in vec4 Color;

void main(void)
{
    vec2 centerPoint = vec2(0.5, 0.5 * s_ringZoom);
    float center = 1.0 - (1.0 - 0.414414414414414) / s_ringZoom;

    vec2 uv = TexCoord.xy;

    uv.y = 1.0 - uv.y;

    uv -= centerPoint;
    uv /= centerPoint.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x) + s_time * 0.5;
    float vlength = (r - center) / (0.99999 - center);
    
    // constant to determine the size of central gap and inner circle radius
    // Output to screen from 2D texture
    
    vec2 tc = vec2((abs(sin(angle)) * 0.6666 + 0.1666) * step(s_ringZoom, 1.0), vlength);

    tc = tc * s_tcTransform2.zw + s_tcTransform2.xy;
    
    gl_FragColor = texture(s_texture_1, tc) * Color * step(0.001, vlength) * step(vlength, 0.999);
}