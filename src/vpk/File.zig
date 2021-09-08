//! Represents an immutable VPK file

const std = @import("std");
const Header = @import("Header.zig");
const Iterator = @import("iterator.zig").Iterator;
const DirectoryEntryMetadata = @import("DirectoryEntryMetadata.zig");
const PathComponents = @import("PathComponents.zig");
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

pub fn extractAll(self: *File, output: std.fs.Dir) !void {
    var iterator = try self.iterate();
    iterator.skip_preload_data = false;

    // Directory entries are grouped by extension and then by
    // path. This means that files with the same extension and path
    // are in the directory tree in a linear sequence. We want to
    // avoid opening and closing the output path for every file here,
    // so we memorize it in case the next file is in the same output
    // path. If not, close this directory and open a new one
    var current_dir = output;
    var current_path: ?[]const u8 = null;
    defer if (current_path) |_| current_dir.close();

    // The same goes for the external archives: Often, successive
    // directory entries will be in the same external file
    var current_archive_index: u16 = 0x7fff;
    var current_external_archive_path: [1024]u8 = undefined;
    var current_external_archive: std.fs.File = undefined;
    defer if (current_archive_index != 0x7fff) current_external_archive.close();

    while (try iterator.next()) |entry| {
        const metadata = entry.metadata;
        const path_components = entry.path_components;

        // Open output path
        var dir: std.fs.Dir = undefined;
        if (path_components.path) |entry_path| {
            if (current_path) |open_path| {
                if (std.mem.eql(u8, entry_path, open_path)) {
                    // The same directory is already open
                    dir = current_dir;
                } else {
                    // Another path is open, close that one and open
                    // the new path
                    current_dir.close();
                    dir = try output.makeOpenPath(entry_path, .{});
                    current_dir = dir;
                }
            } else {
                // No path is currently open
                dir = try output.makeOpenPath(entry_path, .{});
                current_dir = dir;
            }

            current_path = entry_path;
        } else {
            dir = output;
        }

        // Open output file
        var filename_buf: [1024]u8 = undefined;
        var filename_buf_writer = std.io.fixedBufferStream(&filename_buf);
        try path_components.joinIntoFilename(filename_buf_writer.writer());

        const file = try dir.createFile(filename_buf_writer.getWritten(), .{});
        defer file.close();

        // Write file data
        const buf_size = 4096;
        var buf: [buf_size]u8 = undefined;

        if (metadata.preload_bytes > 0) {
            @panic("TODO write preload bytes");
        }

        if (metadata.archive_index == 0x7fff) {
            // File contents are internally in this VPK file
            @panic("TODO write internal file contents");
        } else {
            // File contents are externally in another VPK file
            if (current_archive_index != metadata.archive_index) {
                var external_path_writer = std.io.fixedBufferStream(&current_external_archive_path);
                try external_path_writer.writer().print("{s}{:0>3}.vpk", .{
                    self.path[0 .. self.path.len - "dir.vpk".len],
                    metadata.archive_index,
                });

                if (current_archive_index != 0x7fff) current_external_archive.close();
                current_external_archive = try std.fs.cwd().openFile(external_path_writer.getWritten(), .{});
                current_archive_index = metadata.archive_index;
            }

            try current_external_archive.seekTo(metadata.offset);

            var remaining = metadata.length;
            while (remaining > 0) {
                const amt = std.math.min(remaining, buf_size);
                try current_external_archive.reader().readNoEof(buf[0..amt]);
                try file.writer().writeAll(buf[0..amt]);
                remaining -= amt;
            }
        }
    }
}
