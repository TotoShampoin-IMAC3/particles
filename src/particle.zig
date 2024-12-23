const zingine = @import("toto-zingine");

// NOTE: structs aren't aligned the same way in CPU and in GPU
pub const ParticleStruct = struct {
    position: zingine.Vec4,
    color: zingine.Vec4,
    size: zingine.Vec2,
    __padding: zingine.Vec2,
};

pub const BillboardMaterial = struct {
    color: zingine.Color = zingine.Color.White,
    texture: ?zingine.Texture = null,

    pub fn delete(self: *BillboardMaterial) void {
        _ = self;
    }

    var shader: zingine.ShaderProgram = undefined;
    pub fn init() !void {
        shader = try zingine.loaders.shader.loadShaderProgram(
            "res/particle.vert",
            "res/particle.frag",
        );
    }
    pub fn deinit() void {
        shader.delete();
    }
    pub fn useShader() void {
        shader.use();
    }
    pub fn setCameraUniforms(camera: zingine.Camera) void {
        shader.setUniform("u_projection", zingine.Mat4, camera.projection);
        shader.setUniform("u_view", zingine.Mat4, camera.viewMatrix());
    }
    pub fn setTransformUniform(transform: zingine.Transform) void {
        shader.setUniform("u_model", zingine.Mat4, transform.matrix());
    }
    pub fn applyMaterialUniforms(material: BillboardMaterial) void {
        _ = material;
    }
};

pub const InstancedBasicMesh = zingine.InstancedMesh(zingine.BasicVertex, ParticleStruct);
pub const ParticleObject = zingine.SingleMatObject(InstancedBasicMesh, BillboardMaterial);
