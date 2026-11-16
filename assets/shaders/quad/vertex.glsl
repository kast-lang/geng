attribute vec2 a_pos;
attribute vec2 a_uv;

varying vec4 v_color;
varying vec2 v_uv;

uniform mat4 u_view_matrix;
uniform mat4 u_projection_matrix;
uniform vec2 u_pos;
uniform vec2 u_half_size;

void main() {
    v_uv = a_uv;
    vec2 pos = a_pos * u_half_size + u_pos;
    gl_Position = u_projection_matrix * u_view_matrix * vec4(pos, 0.0, 1.0);
}
