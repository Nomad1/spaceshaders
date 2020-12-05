uniform mat4 s_pmvMatrix;

in vec3 in_position;
in vec2 in_texcoord;
in vec4 in_color;

out vec2 TexCoord;
flat out vec4 Color;

void main(void)
{
    TexCoord = in_texcoord;
    Color = in_color.bgra;
    gl_Position = s_pmvMatrix * vec4(in_position, 1.0);
}