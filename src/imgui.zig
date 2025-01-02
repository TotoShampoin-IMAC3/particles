const std = @import("std");
const engine = @import("toto-zingine");
pub const zimgui = @import("Zig-ImGui");

pub extern fn ImGui_ImplGlfw_InitForOpenGL(window: *engine.glfw.GLFWwindow, install_callbacks: bool) bool;
pub extern fn ImGui_ImplGlfw_NewFrame() void;
pub extern fn ImGui_ImplGlfw_Shutdown() void;
pub extern fn ImGui_ImplOpenGL3_Init(glsl_version: ?[*:0]const u8) bool;
pub extern fn ImGui_ImplOpenGL3_Shutdown() void;
pub extern fn ImGui_ImplOpenGL3_NewFrame() void;
pub extern fn ImGui_ImplOpenGL3_RenderDrawData(draw_data: *const anyopaque) void;

pub fn initContext() void {
    const context = zimgui.CreateContext();
    zimgui.SetCurrentContext(context);
    {
        const io = zimgui.GetIO();
        io.IniFilename = null;
        io.ConfigFlags = zimgui.ConfigFlags.with(
            io.ConfigFlags,
            .{ .NavEnableKeyboard = true, .NavEnableGamepad = true },
        );
    }
}

pub fn start(window: *engine.Window) void {
    _ = ImGui_ImplGlfw_InitForOpenGL(window.glfw_window, true);
    _ = ImGui_ImplOpenGL3_Init("#version 330");
}
pub fn stop() void {
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
}

pub fn beginDrawing() void {
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    zimgui.NewFrame();
}
pub fn endDrawing() void {
    zimgui.Render();
    ImGui_ImplOpenGL3_RenderDrawData(zimgui.GetDrawData());
}

pub const RenderData = struct {
    window: *engine.Window,
    camera: *engine.Camera,
    time: *engine.Time,
    transform: *engine.Transform,
    noise_scale: f32 = 5.0,
    exposure: f32 = 1.0,
    gamma: f32 = 2.2,
};
pub fn render(data: *RenderData) void {
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    zimgui.NewFrame();
    {
        _, const height = data.window.getSize();
        zimgui.SetNextWindowSize(zimgui.Vec2.init(500, 0));
        zimgui.SetNextWindowPosExt(zimgui.Vec2.init(0, @floatFromInt(height)), .{}, zimgui.Vec2.init(0, 1));
        if (zimgui.BeginExt("##Menu", null, .{ .NoResize = true, .NoTitleBar = true })) {
            _ = zimgui.SliderFloat("Exposure", &data.exposure, 0.0, 5.0);
            _ = zimgui.SliderFloat("Gamma", &data.gamma, 0.0, 5.0);
            _ = zimgui.SliderFloat("Noise Seed", &data.noise_scale, 1.0, 10.0);
            zimgui.End();
        }

        zimgui.SetNextWindowSize(zimgui.Vec2.init(0, 0));
        zimgui.SetNextWindowPosExt(zimgui.Vec2.init(0, 0), .{}, zimgui.Vec2.init(0, 0));
        if (zimgui.BeginExt("##FPS", null, .{ .NoResize = true, .NoTitleBar = true })) {
            _ = zimgui.Text("%.3f", 1.0 / data.time.delta);
            _ = zimgui.Text("%.3f %.3f %.3f %.3f", data.transform.rotation.quat.r, data.transform.rotation.quat.i, data.transform.rotation.quat.j, data.transform.rotation.quat.k);
            _ = zimgui.Text("%.3f", data.transform.rotation.quat.norm());
            zimgui.End();
        }
    }
    zimgui.Render();
    ImGui_ImplOpenGL3_RenderDrawData(zimgui.GetDrawData());
}
