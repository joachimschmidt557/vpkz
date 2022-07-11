const std = @import("std");
const vpk = @import("vpk.zig");

const log = std.log.scoped(.vpkar);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        log.err("No vpk file supplied", .{});
        std.os.exit(1);
    }

    // const stdout = std.io.getStdOut();
    // var buffered_writer = std.io.bufferedWriter(stdout.writer());
    // const writer = buffered_writer.writer();
    // defer buffered_writer.flush() catch {};

    const vpk_path = args[1];
    var vpk_file = try vpk.File.open(std.mem.span(vpk_path));

    try vpk_file.extractAll(std.fs.cwd());
    // var iter = try vpk_file.iterate();
    // while (try iter.next()) |entry| {
    //     try entry.path_components.joinIntoPath(writer);
    //     try writer.print("\n", .{});
    // }
}
