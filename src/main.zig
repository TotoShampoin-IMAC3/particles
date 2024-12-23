const std = @import("std");
const zingine = @import("toto-zingine");
const zimgui = @import("Zig-ImGui");

const context = @import("./context.zig").context;
const Events = @import("./events.zig").Events;

const ParticleStruct = @import("./particle.zig").ParticleStruct;
const InstancedBasicMesh = @import("./particle.zig").InstancedBasicMesh;
const BillboardMaterial = @import("./particle.zig").BillboardMaterial;
const ParticleObject = @import("./particle.zig").ParticleObject;

pub fn main() !void {
    try context.begin();
    defer context.end();
    try BillboardMaterial.init();
    defer BillboardMaterial.deinit();

    var particles = ParticleObject{
        .mesh = try InstancedBasicMesh.create(
            zingine.shapes.basicQuad(),
            &[_]ParticleStruct{undefined} ** 64,
        ),
        .material = BillboardMaterial{},
    };
    defer particles.delete();

    var compute = try zingine.loaders.shader.loadComputeShader("res/particle.comp");
    defer compute.delete();

    const FAR = 1000.0;

    var camera = zingine.camera.perspectiveCamera(std.math.deg_per_rad * 45.0, 800.0 / 600.0, 0.1, FAR);
    var control = zingine.controls.OrbitControl{};

    Events.setup(&Events{
        .window = &context.window,
        .camera = &camera,
        .control = &control,
        .FAR = FAR,
    }, &context.window);

    zingine.viewport(.{ .x = 0, .y = 0, .width = 800, .height = 600 });
    zingine.clear(.{ .color = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1.0 } });
    zingine.gl.enable(.DepthTest);
    zingine.gl.enable(.CullFace);
    zingine.gl.enable(.Blend);
    zingine.gl.enable(.AlphaTest);
    zingine.gl.cullFace(.Back);
    zingine.gl.blendFunc(.SrcAlpha, .OneMinusSrcAlpha);
    zingine.gl.depthFunc(.Less);
    zingine.gl.alphaFunc(.Greater, 0.5);

    var time = zingine.Time.init();
    while (!context.window.shouldClose()) {
        camera.transform.position = control.toPosition();
        camera.transform.lookAt(zingine.Vec3.zero, zingine.Vec3.up);

        particles.mesh.bindInstanceBase(.ShaderStorage, 0);
        compute.use();
        compute.setUniform("u_time", f32, @floatCast(time.current));
        compute.setUniform("u_size", i32, particles.mesh.instance_count);
        compute.setUniform("u_radius", f32, 25.0);
        zingine.Compute.dispatch(@intCast(particles.mesh.instance_count), 1, 1);
        zingine.Compute.memoryBarrier(.ShaderStorage);

        zingine.clear(.{ .clear_color = true, .clear_depth = true });

        particles.setupAndRender(camera);

        context.window.swapBuffers();
        zingine.Window.pollEvents();

        time.update();
    }
}
