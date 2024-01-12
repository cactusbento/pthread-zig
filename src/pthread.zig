//! See `man pthread`
//!
//! A more ziggified interface for pthreads.

const std = @import("std");
const builtin = @import("builtin");
const c = @cImport({
    @cInclude("pthread.h");
});
const PThread = @This();

pub const Attribute = c.pthread_attr_t;
pub const Mutex = c.pthread_mutex_t;
pub const Condition = c.pthread_cond_t;
pub const RWLock = c.pthread_rwlock_t;
pub const Key = c.pthread_key_t;

pt: c.pthread_t,

/// See `man pthread_create`
pub fn create(attribute: ?*Attribute, routine: *const fn (?*anyopaque) callconv(.C) ?*anyopaque, arg: ?*anyopaque) !PThread {
    var pt: PThread = .{
        .pt = undefined,
    };
    if (builtin.mode == .Debug) {
        std.debug.print("PThread.create(\n", .{});
        std.debug.print("    thread:  {*}\n", .{&pt.pt});
        std.debug.print("    attr:    {?*}\n", .{attribute});
        std.debug.print("    routine: {*}\n", .{routine});
        std.debug.print("    arg:     {?*}\n", .{arg});
        std.debug.print(")\n", .{});
    }
    const result = c.pthread_create(&pt.pt, attribute, routine, arg);
    switch (std.os.errno(result)) {
        .SUCCESS => return pt,
        .AGAIN => return error.LackResource,
        .INVAL => return error.AttrInvalid,
        .PERM => return error.AccessDenied,
        .INTR => unreachable,
        else => return error.UnexpectedError,
    }
}

/// See `man pthread_equal`
pub fn equal(this: *PThread, other: *PThread) bool {
    return c.pthread_equal(this.pt, other.pt) != 0;
}

/// See `man pthread_kill`
///
/// See `std.os.SIG` for sig.
pub fn kill(this: *PThread, sig: usize) !void {
    const result = c.pthread_kill(this.pt, @intFromEnum(sig));
    switch (std.os.errno(result)) {
        .SUCCESS => return,
        .INVAL => return error.InvalidThread,
        else => return error.UnexpectedError,
    }
}

/// See `man pthread_cancel`
pub fn cancel(this: *PThread) !void {
    const result = c.pthread_cancel(this.pt);
    switch (std.os.errno(result)) {
        .SUCCESS => return,
        .SRCH => return error.ThreadNotFound,
        else => return error.UnexpectedError,
    }
}

/// See `man pthread_self`
pub fn self(this: *PThread) c.pthread_t {
    return this.pt;
}

/// See `man pthread_detach`
pub fn detach(this: *PThread) !void {
    const result = c.pthread_detach(this.pt);
    switch (std.os.errno(result)) {
        .SUCCESS => return,
        .INVAL => return error.NotJoinable,
        .SRCH => return error.ThreadNotFound,
        else => return error.UnexpectedError,
    }
}

/// See `man pthread_join`
///
/// This will return a pointer to the return type
/// that must be freed with `std.mem.Allocator.free`.
/// If `ReturnType` is `void`, `null` will be passed
/// as `value_ptr`.
pub fn join(this: *PThread, comptime ReturnType: type) !*ReturnType {
    var val: *anyopaque = undefined;
    const ap: **anyopaque = &val;

    const result = if (ReturnType != void)
        c.pthread_join(this.pt, @ptrCast(@alignCast(ap)))
    else
        c.pthread_join(this.pt, null);

    switch (std.os.errno(result)) {
        .SUCCESS => {
            if (builtin.mode == .Debug) {
                std.debug.print("{*}.join(): After:\n", .{this});
                std.debug.print("    val: {*}\n", .{val});
                std.debug.print("    ap:  {*}\n", .{ap});
            }

            const rv: *ReturnType = @ptrCast(@alignCast(val));
            return rv;
        },
        .SRCH => return error.NoThreadFound,
        .INVAL => return error.NotJoinable,
        .DEADLK => return error.DeadlockDetected,
        .INTR => unreachable,
        else => return error.UnexpectedError,
    }
}

/// See `man pthread_exit`
pub fn exit(retval: ?*anyopaque) noreturn {
    if (builtin.mode == .Debug) {
        std.debug.print("pthread.exit({*})\n", .{retval});
    }

    c.pthread_exit(retval);
}

/// TODO: Fix garbage data when an item is computed in comptime.
///
/// Helper function for passing in Zig data structures into
/// `callconv(.C)` functions. Use with `pthreads.create`.
///
/// Accepts only a pointer to a tuple:
/// ```zig
/// PThread.argBundle(&.{allocator, data})
/// ```
pub fn argBundle(args: anytype) *anyopaque {
    const ti = @typeInfo(@TypeOf(args));
    if (ti != .Pointer) @compileError("argBundle only accepts a pointer to a tuple");
    const ti2 = @typeInfo(ti.Pointer.child);
    if (ti2 != .Struct) @compileError("argBundle only accepts a pointer to a tuple");
    if (!ti2.Struct.is_tuple) @compileError("argBundle only accepts a pointer to a tuple");

    if (builtin.mode == .Debug) {
        std.debug.print("PThread.argBundle({*})\n", .{args});
    }

    return @ptrCast(@alignCast(@constCast(args)));
}
