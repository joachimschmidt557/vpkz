//! Represents an immutable VPK file

const std = @import("std");
const Header = @import("Header.zig");
const Iterator = @import("iterator.zig").Iterator;
const File = @This();

path: []const u8,
file: std.fs.File,
header: Header,

pub fn open(path: []const u8) !File {
    const file = try std.fs.cwd().openFile(path, .{});
    const header = try Header.read(file.reader());

    return File{
        .path = path,
        .file = file,
        .header = header,
    };
}

pub fn deinit(self: *File) void {
    self.file.close();
}

pub const FileIterator = Iterator(std.fs.File.Reader);

pub fn iterate(self: *File) !FileIterator {
    try self.file.seekTo(self.header.size());

    return FileIterator.init(self.file.reader());
}
