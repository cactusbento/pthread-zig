const std = @import("std");
const pthread = @import("pthread");

fn work(args_p: ?*anyopaque) callconv(.C) ?*anyopaque {
    const args: *struct { std.mem.Allocator, i32 } = @ptrCast(@alignCast(args_p.?));
    // const alloc: std.mem.Allocator = args.*[0];
    const i: i32 = args.*[1];
    std.debug.print("Hello World! {any}\n", .{i});
    std.debug.print("    args: {any}\n", .{args.*});
    return null;
    // const rv = alloc.create(i32) catch @panic("OOM");
    // rv.* = 200;
    // std.debug.print("    addr: {*}\n", .{rv});
    // pthread.exit(@ptrCast(@alignCast(rv)));
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Garbage data is produced when `i` is
    // computed in comptime.
    var i: i32 = 100;
    _ = &i;
    var pt = try pthread.create(
        null,
        work,
        pthread.argBundle(&.{ allocator, i }),
    );

    std.time.sleep(std.time.ns_per_s);

    const rv = try pt.join(void);
    _ = rv; // autofix
    // defer allocator.destroy(rv);

    // std.debug.print("Got: {any}\n", .{rv.*});
}
