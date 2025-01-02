const std = @import("std");
const zingine = @import("toto-zingine");

pub const Events = struct {
    window: *zingine.Window,
    camera: *zingine.Camera,
    control: *zingine.controls.OrbitControl,

    mouse_holding: bool = false,
    last_x: f64 = 0,
    last_y: f64 = 0,
    FAR: f32 = 1000.0,

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
        data.camera.projection = zingine.projection.perspective(std.math.rad_per_deg * 45.0, aspect, 0.1, data.FAR);
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
