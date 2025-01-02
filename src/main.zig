const std = @import("std");
const zingine = @import("toto-zingine");

const imgui = @import("./imgui.zig");
const context = @import("./context.zig").context;
const Events = @import("./events.zig").Events;

const zimgui = imgui.zimgui;

const ParticleStruct = @import("./particle.zig").ParticleStruct;
const InstancedBasicMesh = @import("./particle.zig").InstancedBasicMesh;
const BillboardMaterial = @import("./particle.zig").BillboardMaterial;
const ParticleObject = @import("./particle.zig").ParticleObject;

pub fn main() !void {
    try context.begin();
    defer context.end();
    try BillboardMaterial.init();
    defer BillboardMaterial.deinit();
    try zingine.ForwardBasicMaterial.init();
    defer zingine.ForwardBasicMaterial.deinit();

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    // var compute = try zingine.loaders.shader.loadComputeShader("res/particles/waves.comp");
    var compute = try zingine.loaders.shader.loadComputeShader("res/particles/balls.comp");
    defer compute.delete();

    var init_particles: [64]ParticleStruct = undefined;
    for (&init_particles) |*particle| {
        particle.position = zingine.Vec4.new(.{
            prng.random().float(f32) * 20.0 - 10.0,
            prng.random().float(f32) * 20.0 - 10.0,
            prng.random().float(f32) * 20.0 - 10.0,
            1.0,
        });
        particle.color = zingine.Vec4.new(.{ 1.0, 1.0, 1.0, 1.0 });
        particle.size = zingine.Vec2.new(.{ 0.5, 0.5 });
        particle.speed = zingine.Vec4.new(.{
            prng.random().float(f32) * 20.0 - 10.0,
            prng.random().float(f32) * 20.0 - 10.0,
            prng.random().float(f32) * 20.0 - 10.0,
            0.0,
        });
    }

    var particles = ParticleObject{
        .mesh = try InstancedBasicMesh.create(
            zingine.shapes.basicQuad(),
            &init_particles,
        ),
        .material = BillboardMaterial{},
    };
    defer particles.delete();

    var cube = zingine.ForwardBasicObject{
        .mesh = try zingine.BasicMesh.create(zingine.shapes.basicCube()),
        .material = .{ .color = zingine.Color.White.toVec4() },
    };
    defer cube.delete();
    cube.transform.scaling = zingine.Vec3.new(.{ 10.0, 10.0, 10.0 });

    const FAR = 1000.0;

    var camera = zingine.camera.perspectiveCamera(std.math.rad_per_deg * 45.0, 800.0 / 600.0, 0.1, FAR);
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

    compute.use();
    compute.setUniform("u_size", i32, particles.mesh.instance_count);

    // compute.setUniform("u_radius", f32, 25.0);

    compute.setUniform("u_box_min", zingine.Vec3, zingine.Vec3.new(.{ -10.0, -10.0, -10.0 }));
    compute.setUniform("u_box_max", zingine.Vec3, zingine.Vec3.new(.{ 10.0, 10.0, 10.0 }));
    compute.setUniform("u_gravity", zingine.Vec3, zingine.Vec3.new(.{ 0.0, -9.8, 0.0 }));

    imgui.initContext();
    imgui.start(&context.window);

    var time = zingine.Time.init();
    while (!context.window.shouldClose()) {
        camera.transform.position = control.toPosition();
        camera.transform.lookAt(zingine.Vec3.zero, zingine.Vec3.up);

        particles.mesh.bindInstanceBase(.ShaderStorage, 0);
        compute.use();
        compute.setUniform("u_time", f32, @floatCast(time.current));
        compute.setUniform("u_delta_time", f32, @floatCast(time.delta));
        zingine.Compute.dispatch(@intCast(particles.mesh.instance_count), 1, 1);
        zingine.Compute.memoryBarrier(.ShaderStorage);

        zingine.clear(.{ .clear_color = true, .clear_depth = true });

        zingine.gl.enable(.CullFace);
        zingine.gl.polygonMode(.FrontAndBack, .Fill);
        particles.setupAndRender(camera);

        zingine.gl.disable(.CullFace);
        zingine.gl.polygonMode(.FrontAndBack, .Line);
        cube.setupAndRender(camera);

        imgui.beginDrawing();
        if (zimgui.Begin("##Menu")) {
            zimgui.Text("FPS: %.2f", 1 / time.delta);
            zimgui.End();
        }
        imgui.endDrawing();

        context.window.swapBuffers();
        zingine.Window.pollEvents();

        time.update();
    }
}
