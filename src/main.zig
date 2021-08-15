const std = @import("std");
const vpk = @import("vpk.zig");

const log = std.log.scoped(.vpkar);

pub fn main() !void {
    if (std.os.argv.len < 2) {
        log.crit("No vpk file supplied", .{});
        std.os.exit(1);
    }

    const stdout = std.io.getStdOut();
    const raw_writer = stdout.writer();
    var buffered_writer = std.io.bufferedWriter(raw_writer);
    const writer = buffered_writer.writer();
    defer buffered_writer.flush() catch {};

    const vpk_path = std.os.argv[1];
    const file = try std.fs.cwd().openFile(std.mem.span(vpk_path), .{});
    defer file.close();

    const raw_reader = file.reader();
    var buffered_reader = std.io.bufferedReader(raw_reader);
    const reader = buffered_reader.reader();

    _ = try vpk.Header.read(reader);

    var iter = vpk.Iterator{};
    while (try iter.next(reader)) |entry| {
        try entry.path_components.joinIntoPath(writer);
        try writer.print("\n", .{});
    }
}
