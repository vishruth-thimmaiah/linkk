const std = @import("std");

const ElfHeader = @import("header.zig").ElfHeader;
const ElfSection = @import("sections.zig").ElfSection;

pub const ElfRelocations = struct {
    offset: u64,
    info: u64,
    addend: i64,

    pub fn new(allocator: std.mem.Allocator, header: ElfHeader, section: ElfSection) ![]ElfRelocations {
        var relocations = try std.ArrayList(ElfRelocations).initCapacity(allocator, section.data.len / 24);
        defer relocations.deinit();

        for (0..section.data.len / section.entsize) |i| {
            const offset = i * 24;
            const rela = ElfRelocations{
                .offset = std.mem.readInt(u64, section.data[offset .. offset + 8][0..8], header.data),
                .info = std.mem.readInt(u64, section.data[offset + 8 .. offset + 16][0..8], header.data),
                .addend = std.mem.readInt(i64, section.data[offset + 16 .. offset + 24][0..8], header.data),
            };
            try relocations.append(rela);
        }
        return try relocations.toOwnedSlice();
    }

    pub fn get(allocator: std.mem.Allocator, header: ElfHeader, sections: []ElfSection, rela_section: ElfSection, rela_info: usize) !void {
        var section = &sections[rela_info];

        const relas = try ElfRelocations.new(allocator, header, rela_section);
        section.relocations = relas;
    }

    pub fn get_symbol(self: ElfRelocations) usize {
        return self.info >> 32;
    }

    pub fn set_symbol(self: *ElfRelocations, symbol: usize) void {
        self.info = (symbol << 32) + self.get_type();
    }

    pub fn get_type(self: ElfRelocations) usize {
        return self.info & 0xffffffff;
    }

    pub fn set_type(self: *ElfRelocations, typeval: usize) void {
        self.info = self.get_symbol() << 32 + typeval;
    }
};
