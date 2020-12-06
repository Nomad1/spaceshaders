uniform mat4 s_pmvMatrix;
uniform vec4 s_cameraRotation;
uniform float s_nearPlaneHeight;
uniform float s_nearPlaneWidth;
uniform float s_cameraFieldOfView;

in vec3 in_position;
in vec2 in_texcoord;
in vec4 in_color;

out vec2 TexCoord;
flat out float Aspect;

#if defined ( STARS )
out vec3 SphereCoords;
flat out float ScreenScale;
#endif

#if defined ( SUN_LIGHT )
flat out vec2 LightPos;
uniform vec3 s_sunLightDirection;
#endif

void main(void)
{
    TexCoord = vec2(in_texcoord.x, 1.0 - in_texcoord.y);
    gl_Position = s_pmvMatrix * vec4(in_position, 1.0);
    //gl_Position.z = gl_Position.w;
    Aspect = s_nearPlaneWidth / s_nearPlaneHeight;

#if defined ( SUN_LIGHT )
    LightPos = s_sunLightDirection.xy * vec2(0.5) + vec2(0.5);
#endif

#if defined ( STARS )
    vec2 uv = TexCoord;

    uv -= 0.5;
    uv *= 2.0;

    uv.x *= Aspect;


    float yaw = -s_cameraRotation.x;
    float pitch = -s_cameraRotation.y;

    // translate (0,0) - (1,1) tex coords to (-aspect, -1.0) - (aspect, 1.0) coords
   
    float sina = sin(yaw);
    float cosa = cos(yaw);
    float sinb = sin(pitch);
    float cosb = cos(pitch);

    vec3 dir = normalize(vec3(uv, -1.0 / s_cameraFieldOfView));

    SphereCoords = mat3(cosa, 0.0, -sina, 0.0, 1.0, 0.0, sina, 0.0, cosa) *
                   (mat3(1.0, 0.0, 0.0, 0.0, cosb, sinb, 0, -sinb, cosb) * dir);

    ScreenScale = s_nearPlaneHeight * 0.5;
#endif
}
