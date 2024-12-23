const std = @import("std");
const zingine = @import("toto-zingine");
const zimgui = @import("Zig-ImGui");

const context = @import("./context.zig").context;

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

    const Events = struct {
        window: *zingine.Window,
        camera: *zingine.Camera,
        control: *zingine.controls.OrbitControl,

        mouse_holding: bool = false,
        last_x: f64 = 0,
        last_y: f64 = 0,

        const Self = @This();

        pub fn setup(self: *const Self, window: *zingine.Window) void {
            window.setUserPointer(self);
            _ = window.setFrameBufferSizeCallback(Self.onResize);
            _ = window.setCursorPosCallback(Self.onMouseMove);
            _ = window.setMouseButtonCallback(Self.onMouseButton);
            _ = window.setScrollCallback(Self.onScroll);
        }
        pub fn onResize(win: zingine.Window, width: i32, height: i32) void {
            const aspect = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
            const data = win.getUserPointer(Self).?;
            data.camera.projection = zingine.projection.perspective(std.math.rad_per_deg * 45.0, aspect, 0.1, FAR);
            zingine.Renderer.setSize(@intCast(width), @intCast(height));
            zingine.gl.viewport(0, 0, width, height);
        }
        pub fn onMouseMove(win: zingine.Window, x: f64, y: f64) void {
            const data = win.getUserPointer(Self).?;
            const dx: f32 = @floatCast(x - data.last_x);
            const dy: f32 = @floatCast(y - data.last_y);
            const width, const height = win.getSize();
            const fw: f32 = @floatFromInt(width);
            const fh: f32 = @floatFromInt(height);
            const size = @min(fw, fh);
            if (data.mouse_holding) {
                data.control.move(dy / size * 2, -dx / size * 2, 0.0);
            }
            data.last_x = x;
            data.last_y = y;
        }
        pub fn onMouseButton(win: zingine.Window, button: i32, action: i32, _: i32) void {
            const data = win.getUserPointer(Self).?;
            if (button == zingine.glfw.GLFW_MOUSE_BUTTON_LEFT) {
                data.mouse_holding = action == zingine.glfw.GLFW_PRESS;
                // if (zimgui.GetIO().WantCaptureMouse) {
                //     data.mouse_holding = false;
                // }
            }
        }
        pub fn onScroll(win: zingine.Window, _: f64, dy: f64) void {
            const data = win.getUserPointer(Self).?;
            data.control.move(0.0, 0.0, @floatCast(-dy * 0.1));
        }
    };
    Events.setup(&Events{
        .window = &context.window,
        .camera = &camera,
        .control = &control,
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
