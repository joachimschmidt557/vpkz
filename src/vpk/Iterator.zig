const std = @import("std");
const DirectoryEntryMetadata = @import("DirectoryEntryMetadata.zig");
const PathComponents = @import("PathComponents.zig");
const Iterator = @This();

extension_len: usize = 0,
path_len: usize = 0,
extension_buf: [8]u8 = undefined,
path_buf: [2048]u8 = undefined,
filename_buf: [512]u8 = undefined,
state: State = .extension,

pub const DirectoryEntry = struct {
    path_components: PathComponents,
    metadata: DirectoryEntryMetadata,
};

const State = enum {
    /// Next string will be an extension
    extension,
    /// Next string will be a path
    path,
    /// Next string will be a filename
    filename,
};

/// Memory such as file names referenced in this returned entry
/// becomes invalid with subsequent calls to `next`
pub fn next(self: *Iterator, reader: anytype) !?DirectoryEntry {
    var extension: ?[]const u8 = self.extension_buf[0..self.extension_len];
    var path: ?[]const u8 = self.path_buf[0..self.path_len];
    var filename: ?[]const u8 = undefined;

    loop: while (true) {
        switch (self.state) {
            .extension => {
                if (try reader.readUntilDelimiterOrEof(&self.extension_buf, 0)) |next_str| {
                    if (next_str.len == 0) {
                        // End of directory tree
                        return null;
                    } else {
                        extension = next_str;
                        self.extension_len = next_str.len;
                        self.state = .path;
                    }
                } else return null;
            },
            .path => {
                if (try reader.readUntilDelimiterOrEof(&self.path_buf, 0)) |next_str| {
                    if (next_str.len == 0) {
                        self.state = .extension;
                    } else {
                        path = next_str;
                        self.path_len = next_str.len;
                        self.state = .filename;
                    }
                } else return null;
            },
            .filename => {
                if (try reader.readUntilDelimiterOrEof(&self.filename_buf, 0)) |next_str| {
                    if (next_str.len == 0) {
                        self.state = .path;
                    } else {
                        filename = next_str;
                        break :loop;
                    }
                } else return null;
            },
        }
    }

    if (extension) |str| {
        if (std.mem.eql(u8, str, " ")) extension = null;
    }
    if (path) |str| {
        if (std.mem.eql(u8, str, " ")) path = null;
    }
    if (filename) |str| {
        if (std.mem.eql(u8, str, " ")) filename = null;
    }

    const metadata = try DirectoryEntryMetadata.read(reader);
    if (metadata.preload_bytes > 0) try reader.skipBytes(metadata.preload_bytes, .{});

    return DirectoryEntry{
        .path_components = .{
            .path = path,
            .filename = filename,
            .extension = extension,
        },
        .metadata = metadata,
    };
}
