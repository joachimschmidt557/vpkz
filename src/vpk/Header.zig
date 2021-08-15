const Header = @This();

/// Magic number
pub const magic: u32 = 0x55aa1234;

/// Only versions 1 and 2 are supported
version: u32,
/// Size of the directory tree in bytes
///
/// Versions: 1, 2
tree_size: u32,
/// Size of the section containing files saved internally in this VPK
///
/// Versions: 2
file_data_section_size: u32 = 0,
/// Size of the section containing MD5 checksums for files saved
/// outside of this VPK
///
/// Versions: 2
archive_md5_section_size: u32 = 0,
/// Size of the section containing MD5 checksums for files saved
/// internally in this VPK
///
/// Versions: 2
other_md5_section_size: u32 = 0,
/// Size of the section containing a cryptographic signature of the
/// file content
///
/// Versions: 2
signature_section_size: u32 = 0,

pub fn read(reader: anytype) !Header {
    const signature = try reader.readIntLittle(u32);
    if (signature != magic) return error.InvalidSignature;

    const version = try reader.readIntLittle(u32);
    switch (version) {
        1 => return Header{
            .version = 1,
            .tree_size = try reader.readIntLittle(u32),
        },
        2 => return Header{
            .version = 2,
            .tree_size = try reader.readIntLittle(u32),
            .file_data_section_size = try reader.readIntLittle(u32),
            .archive_md5_section_size = try reader.readIntLittle(u32),
            .other_md5_section_size = try reader.readIntLittle(u32),
            .signature_section_size = try reader.readIntLittle(u32),
        },
        else => return error.UnsupportedVersion,
    }
}

pub fn write(writer: anytype, header: Header) !void {
    try writer.writeIntLittle(u32, magic);
    try writer.writeIntLittle(u32, header.version);

    try writer.writeIntLittle(u32, header.tree_size);
    
    // Version 2 exclusive fields
    if (header.version == 2) {
        try writer.writeIntLittle(u32, header.file_data_section_size);        
        try writer.writeIntLittle(u32, header.archive_md5_section_size);        
        try writer.writeIntLittle(u32, header.other_md5_section_size);        
        try writer.writeIntLittle(u32, header.signature_section_size);        
    }
}
