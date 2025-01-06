const std = @import("std");
const zingine = @import("toto-zingine");

const imgui = @import("./imgui.zig");
const context = @import("./context.zig").context;
const Events = @import("./events.zig").Events;
const shaderm = @import("./shaderm.zig");

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
    var waves_uniforms = [_]shaderm.UniformComponent{
        .{ .name = "u_radius", .value = .{ .float = 5.0 } },
        .{ .name = "u_particle_size", .value = .{ .vec2 = zingine.Vec2.new(.{ 0.5, 0.5 }) } },
    };
    var box_uniforms = [_]shaderm.UniformComponent{
        .{ .name = "u_box_min", .value = .{ .vec3 = zingine.Vec3.new(.{ -10.0, -10.0, -10.0 }) } },
        .{ .name = "u_box_max", .value = .{ .vec3 = zingine.Vec3.new(.{ 10.0, 10.0, 10.0 }) } },
        .{ .name = "u_gravity", .value = .{ .vec3 = zingine.Vec3.new(.{ 0.0, -9.8, 0.0 }) } },
    };

    var comps = [_]shaderm.ShaderComponent{
        .{
            .name = "waves",
            .program = try zingine.loaders.shader.loadComputeShader("res/particles/waves.comp"),
            .uniforms = &waves_uniforms,
        },
        .{
            .name = "balls",
            .program = try zingine.loaders.shader.loadComputeShader("res/particles/balls.comp"),
            .uniforms = &box_uniforms,
        },
    };
    var shaders = shaderm.ShaderManager{
        .shaders = &comps,
    };
    defer shaders.delete();

    shaders.index = 1;
    var index: i32 = 1;

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
    zingine.gl.cullFace(.Back);
    zingine.gl.blendFunc(.SrcAlpha, .OneMinusSrcAlpha);

    imgui.initContext();
    imgui.start(&context.window);
    var style = zimgui.GetStyle().?;
    style.WindowRounding = 4.0;
    style.WindowBorderSize = 2.0;
    style.FrameRounding = 2.0;

    var time = zingine.Time.init();
    while (!context.window.shouldClose()) {
        cube.transform.scaling = val: {
            const min = box_uniforms[0].value.vec3;
            const max = box_uniforms[1].value.vec3;
            break :val max.sub(min).scale(0.5);
        };
        cube.transform.position = val: {
            const min = box_uniforms[0].value.vec3;
            const max = box_uniforms[1].value.vec3;
            break :val max.add(min).scale(0.5);
        };

        const start = zingine.time.getTime();
        camera.transform.position = control.toPosition();
        camera.transform.lookAt(zingine.Vec3.zero, zingine.Vec3.up);

        particles.mesh.bindInstanceBase(.ShaderStorage, 0);
        shaders.current().program.use();
        shaders.current().program.setUniform("u_time", f32, @floatCast(time.current));
        shaders.current().program.setUniform("u_delta_time", f32, @floatCast(time.delta));
        shaders.current().program.setUniform("u_size", i32, particles.mesh.instance_count);
        shaders.current().apply();
        zingine.Compute.dispatch(@intCast(particles.mesh.instance_count), 1, 1);
        zingine.Compute.memoryBarrier(.ShaderStorage);

        zingine.clear(.{ .clear_color = true, .clear_depth = true });

        zingine.gl.enable(.CullFace);
        zingine.gl.polygonMode(.FrontAndBack, .Fill);
        particles.setupAndRender(camera);

        zingine.gl.disable(.CullFace);
        zingine.gl.polygonMode(.FrontAndBack, .Line);
        cube.setupAndRender(camera);

        const end = zingine.time.getTime();

        imgui.beginDrawing();
        zimgui.SetNextWindowPos(.{ .x = 0, .y = 0 });
        zimgui.SetNextWindowSize(.{ .x = 320, .y = 0 });
        if (zimgui.Begin("Info")) {
            zimgui.Text("FPS: %.2f", 1 / (end - start));
            if (zimgui.CollapsingHeader_BoolPtr("Particles", null)) {
                if (zimgui.InputInt("Shader", &index)) {
                    shaders.index = @intCast(index);
                    shaders.index %= shaders.shaders.len;
                }
                for (shaders.current().uniforms) |*uniform| {
                    switch (uniform.value) {
                        .float => |*value| if (zimgui.InputFloat(@ptrCast(uniform.name), value)) {
                            shaders.current().program.setUniform(uniform.name, f32, value.*);
                        },
                        .vec2 => |*value| if (zimgui.InputFloat2(@ptrCast(uniform.name), &value.data)) {
                            shaders.current().program.setUniform(uniform.name, zingine.Vec2, value.*);
                        },
                        .vec3 => |*value| if (zimgui.InputFloat3(@ptrCast(uniform.name), &value.data)) {
                            shaders.current().program.setUniform(uniform.name, zingine.Vec3, value.*);
                        },
                        .vec4 => |*value| if (zimgui.InputFloat4(@ptrCast(uniform.name), &value.data)) {
                            shaders.current().program.setUniform(uniform.name, zingine.Vec4, value.*);
                        },
                    }
                }
            }
            zimgui.End();
        }

        imgui.endDrawing();

        context.window.swapBuffers();
        zingine.Window.pollEvents();

        time.update();
    }
}
