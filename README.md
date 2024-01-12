# PThread for Zig

Built for `0.12.0-dev.2075+f5978181e`

The basic functions are here. Will appreciate contributions to cover the 
rest of the functions.

```zig
const std = @import("std");
const pthread = @import("pthread");

fn work(args_p: ?*anyopaque) callconv(.C) ?*anyopaque {
    const args: *struct { std.mem.Allocator, i32 } = @ptrCast(@alignCast(args_p.?));
    // const alloc: std.mem.Allocator = args.*[0];
    const i: i32 = args.*[1];
    std.debug.print("Hello World! {d}\n", .{i});
    return null;
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

    _ = try pt.join(void);
}
```

## Todo:

* Fix garbage data from passing around comptime data.
