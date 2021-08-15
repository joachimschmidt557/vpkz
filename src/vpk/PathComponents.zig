const std = @import("std");
const PathComponents = @This();

path: ?[]const u8,
filename: ?[]const u8,
extension: ?[]const u8,

pub fn joinIntoPath(self: PathComponents, writer: anytype) !void {
    if (self.path) |path| try writer.print("{s}/", .{path});
    if (self.filename) |filename| try writer.writeAll(filename);
    if (self.extension) |extension| try writer.print(".{s}", .{extension});
}

pub fn splitIntoComponents(path: []const u8) PathComponents {
    // Split path from rest
    const last_slash = std.mem.lastIndexOfScalar(u8, path, '/');
    const dirname = if (last_slash) |pos| path[0..pos] else null;
    const rest = if (last_slash) |pos| path[pos..] else path;

    // Split filename from extension
    const last_dot = std.mem.lastIndexOfScalar(u8, rest, '.');
    const filename = if (last_dot) |pos| rest[0..pos] else rest;
    const extension = if (last_dot) |pos| rest[pos..] else null;

    return .{
        .path = dirname,
        .filename = filename,
        .extension = extension,
    };
}
