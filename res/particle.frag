#version 330 core

in vec2 v_texcoord;
in vec4 v_color;

out vec4 f_color;

uniform sampler2D u_texture;
uniform bool u_use_texture;

void main()
{
    f_color = v_color;
    if (u_use_texture)
    {
        f_color *= texture(u_texture, v_texcoord);
    }
    else
    {
        f_color.a = distance(v_texcoord, vec2(0.5)) < 0.5 ? 1.0 : 0.0;
    }

    if (f_color.a < 0.25)
    {
        discard;
    }
}
