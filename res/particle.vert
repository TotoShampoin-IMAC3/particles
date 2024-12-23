#version 460 core

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec2 a_texcoord;

layout(location = 2) in vec4 a_instance_position;
layout(location = 3) in vec4 a_instance_color;
layout(location = 4) in vec2 a_instance_size;

out vec2 v_texcoord;
out vec4 v_color;

uniform mat4 u_model;
uniform mat4 u_view;
uniform mat4 u_projection;

void main()
{
    vec3 position = a_instance_position.xyz;
    vec3 right = vec3(u_view[0][0], u_view[1][0], u_view[2][0]);
    vec3 up = vec3(u_view[0][1], u_view[1][1], u_view[2][1]);

    v_texcoord = a_texcoord;
    v_color = a_instance_color;

    position += right * a_position.x * a_instance_size.x;
    // position += right * a_position.x * 1.0;
    position += up * a_position.y * a_instance_size.y;
    // position += up * a_position.y * 1.0;

    gl_Position = u_projection * u_view * vec4(position, 1.0);
}
