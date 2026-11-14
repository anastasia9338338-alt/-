-- Picguin crc32; origin {"repo": "wizevaxel/picguin", "commit": "c9c10f5639720d7dedc7955052026d6636b3d5b0"}
-- Adapted module resolution and table exports for the standalone bundle.
--[[
MIT License

Copyright (c) 2026 wizeväxel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]
--!strict
--!native
--!optimize 2

local LOOKUP = buffer.create(0x1000)

for index = 0, 0xFF do
	local crc = index
	for _ = 1, 8 do
		crc = crc % 2 == 1 and bit32.bxor(crc // 2, 0xEDB88320) or crc // 2
	end

	buffer.writeu32(LOOKUP, index * 4, crc)
end

for index = 0, 0xFF do
	local crc = buffer.readu32(LOOKUP, index * 4)
	for cursor = 1, 3 do
		crc = bit32.bxor(crc // 0x100, buffer.readu32(LOOKUP, (crc % 0x100) * 4))
		buffer.writeu32(LOOKUP, cursor * 0x400 + index * 4, crc)
	end
end

local function compute(source: buffer, read_offset: number, read_length: number): number
	local read_end = read_offset + read_length

	local crc = 0xFFFFFFFF
	local offset = read_offset

	while offset + 4 <= read_end do
		crc = bit32.bxor(
			buffer.readu32(LOOKUP, 0xC00 + bit32.bxor((crc % 0x100), buffer.readu8(source, offset)) * 4),
			buffer.readu32(LOOKUP, 0x800 + bit32.bxor((crc // 0x100) % 0x100, buffer.readu8(source, offset + 1)) * 4),
			buffer.readu32(LOOKUP, 0x400 + bit32.bxor((crc // 0x10000) % 0x100, buffer.readu8(source, offset + 2)) * 4),
			buffer.readu32(LOOKUP, bit32.bxor((crc // 0x1000000), buffer.readu8(source, offset + 3)) * 4)
		)

		offset += 4
	end

	while offset < read_end do
		local index = bit32.bxor(crc % 0x100, buffer.readu8(source, offset))
		crc = bit32.bxor(buffer.readu32(LOOKUP, index * 4), crc // 0x100)
		offset += 1
	end

	return bit32.bxor(crc, 0xFFFFFFFF)
end

return {Compute=compute}
