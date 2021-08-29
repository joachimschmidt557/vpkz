//! A library for working with Valve VPK files
//! File format is described in https://developer.valvesoftware.com/wiki/VPK_File_Format

pub const Header = @import("vpk/Header.zig");
pub const DirectoryEntryMetadata = @import("vpk/DirectoryEntryMetadata.zig");
pub const PathComponents = @import("vpk/PathComponents.zig");
pub const File = @import("vpk/File.zig");
pub const Iterator = @import("vpk/iterator.zig").Iterator;
