const std = @import("std");
const zimgui = @import("./build-zimgui.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "particles",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const toto_zingine = b.dependency("toto-zingine", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("toto-zingine", toto_zingine.module("toto-zingine"));

    // TODO: Remove this once ZLS is able to read local dependency caches
    {
        const toto_zilgebra = b.dependency("toto-zilgebra", .{
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("toto-zilgebra", toto_zilgebra.module("toto-zilgebra"));
        const toto_zigl = b.dependency("toto-zigl", .{
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("toto-zigl", toto_zigl.module("toto-zigl"));
        const zstbi = b.dependency("zstbi", .{
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("zstbi", zstbi.module("root"));
        exe.root_module.linkLibrary(zstbi.artifact("zstbi"));
        const obj = b.dependency("obj", .{
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("obj", obj.module("obj"));
    }

    addImgui(b, exe, .{ .target = target, .optimize = optimize });

    b.installArtifact(exe);

    const install = b.getInstallStep();
    const install_data = b.addInstallDirectory(.{
        .source_dir = b.path("res"),
        .install_dir = .{ .prefix = {} },
        .install_subdir = "bin/res",
    });
    install.dependOn(&install_data.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

const Params = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};
fn addImgui(b: *std.Build, exe: *std.Build.Step.Compile, params: Params) void {
    const ZigImGui_dep = b.dependency("ZigImGui", .{
        .target = params.target,
        .optimize = params.optimize,
        .enable_freetype = true,
        .enable_lunasvg = false,
    });
    const imgui_dep = ZigImGui_dep.builder.dependency("imgui", params);

    const imgui_glfw = zimgui.create_imgui_glfw_static_lib(
        b,
        params.target,
        params.optimize,
        imgui_dep,
        ZigImGui_dep,
    );
    const imgui_opengl = zimgui.create_imgui_opengl_static_lib(
        b,
        params.target,
        params.optimize,
        imgui_dep,
        ZigImGui_dep,
    );

    exe.root_module.addImport("Zig-ImGui", ZigImGui_dep.module("Zig-ImGui"));

    exe.linkLibrary(imgui_glfw);
    exe.linkLibrary(imgui_opengl);
}
