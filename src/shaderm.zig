const std = @import("std");
const zingine = @import("toto-zingine");

pub const UniformComponent = struct {
    name: []const u8,
    value: union(enum) {
        float: f32,
        vec2: zingine.Vec2,
        vec3: zingine.Vec3,
        vec4: zingine.Vec4,
    },
};

pub const ShaderComponent = struct {
    name: []const u8,
    program: zingine.ShaderProgram,
    uniforms: []UniformComponent,

    pub fn apply(self: *ShaderComponent) void {
        for (self.uniforms) |uniform| {
            switch (uniform.value) {
                .float => |*value| self.program.setUniform(uniform.name, f32, value.*),
                .vec2 => |*value| self.program.setUniform(uniform.name, zingine.Vec2, value.*),
                .vec3 => |*value| self.program.setUniform(uniform.name, zingine.Vec3, value.*),
                .vec4 => |*value| self.program.setUniform(uniform.name, zingine.Vec4, value.*),
            }
        }
    }
};

pub const ShaderManager = struct {
    shaders: []ShaderComponent,
    index: usize = 0,

    pub fn delete(self: *ShaderManager) void {
        for (self.shaders) |*shader| {
            shader.program.delete();
        }
    }

    pub fn current(self: *ShaderManager) *ShaderComponent {
        return &self.shaders[self.index];
    }
};
