const DirectoryEntryMetadata = @This();

/// CRC checksum of file content
crc_hash: u32,
/// Size of preload data in bytes. Preload data immediately follows
/// the metadata entry
preload_bytes: u16,
/// Index of the external archive this file is saved in. If this index
/// is 0x7fff, the file is saved internally in this VPK file
archive_index: u16,
/// Byte offset of the file content
offset: u32,
/// Size of the file content in bytes
length: u32,

/// Size of the serialized directory entry metadata in bytes (without
/// preload data)
pub const size = 16;

pub fn read(reader: anytype) !DirectoryEntryMetadata {
    const crc_hash = try reader.readIntLittle(u32);
    const preload_bytes = try reader.readIntLittle(u16);
    const archive_index = try reader.readIntLittle(u16);
    const offset = try reader.readIntLittle(u32);
    const length = try reader.readIntLittle(u32);
    const terminator = try reader.readIntLittle(u16);
    if (terminator != 0xffff) return error.InvalidTerminator;

    return DirectoryEntryMetadata{
        .crc_hash = crc_hash,
        .preload_bytes = preload_bytes,
        .archive_index = archive_index,
        .offset = offset,
        .length = length,
    };
}

pub fn write(self: DirectoryEntryMetadata, writer: anytype) !void {
    const terminator: u16 = 0xffff;

    try writer.writeIntLittle(u32, self.crc_hash);
    try writer.writeIntLittle(u16, self.preload_bytes);
    try writer.writeIntLittle(u16, self.archive_index);
    try writer.writeIntLittle(u32, self.offset);
    try writer.writeIntLittle(u32, self.length);
    try writer.writeIntLittle(u16, terminator);
}
