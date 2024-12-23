const std = @import("std");
const zingine = @import("toto-zingine");

pub const context = struct {
    pub var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;
    pub var allocator: std.mem.Allocator = undefined;
    pub var window: zingine.Window = undefined;

    pub fn begin() !void {
        gpa = std.heap.GeneralPurposeAllocator(.{}){};
        allocator = gpa.allocator();
        try zingine.Window.init();
        window = try zingine.Window.create(.{ .width = 800, .height = 600, .title = "Hello, World!" });
        window.makeContextCurrent();
        try zingine.init.init(allocator);
    }
    pub fn end() void {
        zingine.init.deinit();
        window.destroy();
        zingine.Window.terminate();
        const status = gpa.deinit();
        if (status != .ok) {
            std.debug.print("Error deinitializing allocator: {}\n", .{status});
        }
    }
};
