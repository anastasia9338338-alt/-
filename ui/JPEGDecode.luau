-- lua-img-ascii JPEG decoder; {"repo": "tiberium/lua-img-ascii", "commit": "822915dd0cc1d72280a018dde0a622fe59fa696b"}
-- Astral changes: separable IDCT, progressive scans, restart handling and size bounds.
--[[
MIT License

Copyright (c) 2024 Tomasz Skalniak

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
local M = {}

local JPEG_START_OF_IMAGE = 0xD8
local JPEG_END_OF_IMAGE = 0xD9
local JPEG_START_OF_FRAME_BASELINE = 0xC0
local JPEG_DEFINE_HUFFMAN_TABLE = 0xC4
local JPEG_DEFINE_QUANTIZATION_TABLE = 0xDB
local JPEG_START_OF_SCAN = 0xDA
local JPEG_RESTART_INTERVAL = 0xDD
local JPEG_RESTART_MARKER_MINIMUM = 0xD0
local JPEG_RESTART_MARKER_MAXIMUM = 0xD7
local JPEG_MARKER_PREFIX = 0xFF
local JPEG_BYTE_STUFFING = 0x00
local JPEG_8_BIT_PRECISION = 8
local JPEG_DC_TABLE_CLASS = 0
local JPEG_AC_TABLE_CLASS = 1
local JPEG_QUANTIZATION_8_BIT = 0
local JPEG_BLOCK_SIZE = 8
local JPEG_FIRST_LUA_INDEX = 1
local JPEG_CENTER_VALUE = 128
local JPEG_MAXIMUM_VALUE = 255
local JPEG_COMPONENT_GRAYSCALE = 1
local JPEG_COMPONENT_RGB = 3
local JPEG_16_BIT_SEGMENT_LENGTH = 2
local JPEG_COMPONENT_HEADER_SIZE = 3
local JPEG_DQT_TABLE_INFORMATION_SIZE = 1
local JPEG_DQT_8_BIT_TABLE_SIZE = 64
local JPEG_DHT_TABLE_INFORMATION_SIZE = 1
local JPEG_DHT_CODE_LENGTH_COUNT = 16
local JPEG_CHROMA_RED = 1.402
local JPEG_CHROMA_GREEN_CB = 0.344136
local JPEG_CHROMA_GREEN_CR = 0.714136
local JPEG_CHROMA_BLUE = 1.772

local ZIGZAG = {
	1,
	2,
	9,
	17,
	10,
	3,
	4,
	11,
	18,
	25,
	33,
	26,
	19,
	12,
	5,
	6,
	13,
	20,
	27,
	34,
	41,
	49,
	42,
	35,
	28,
	21,
	14,
	7,
	8,
	15,
	22,
	29,
	36,
	43,
	50,
	57,
	58,
	51,
	44,
	37,
	30,
	23,
	16,
	24,
	31,
	38,
	45,
	52,
	59,
	60,
	53,
	46,
	39,
	32,
	40,
	47,
	54,
	61,
	62,
	55,
	48,
	56,
	63,
	64,
}

local function read_uint16(data, offset)
	return data:byte(offset) * 256 + data:byte(offset + 1)
end

local function clamp(value)
	return math.max(0, math.min(JPEG_MAXIMUM_VALUE, math.floor(value + 0.5)))
end

local function new_bit_reader(data, offset)
	return { data = data, offset = offset, current_byte = nil, bit_index = JPEG_8_BIT_PRECISION }
end

local function read_bit(reader)
	if reader.bit_index == JPEG_8_BIT_PRECISION then
		local byte = reader.data:byte(reader.offset)
		if not byte then
			error("Unexpected end of JPEG scan data.")
		end
		reader.offset = reader.offset + 1
		if byte == JPEG_MARKER_PREFIX then
			local next_byte = reader.data:byte(reader.offset)
			while next_byte == JPEG_MARKER_PREFIX do
				reader.offset = reader.offset + 1
				next_byte = reader.data:byte(reader.offset)
			end
			if next_byte == JPEG_BYTE_STUFFING then
				reader.offset = reader.offset + 1
			elseif
				next_byte
				and next_byte >= JPEG_RESTART_MARKER_MINIMUM
				and next_byte <= JPEG_RESTART_MARKER_MAXIMUM
			then
				reader.offset = reader.offset + 1
			else
				error("Unexpected JPEG marker in scan data.")
			end
		end
		reader.current_byte = byte
		reader.bit_index = 0
	end

	local bit = math.floor(reader.current_byte / 2 ^ (JPEG_8_BIT_PRECISION - JPEG_FIRST_LUA_INDEX - reader.bit_index))
		% 2
	reader.bit_index = reader.bit_index + 1
	return bit
end

local function read_bits(reader, count)
	local value = 0
	for _ = JPEG_FIRST_LUA_INDEX, count do
		value = value * 2 + read_bit(reader)
	end
	return value
end

local function receive_extend(reader, length)
	if length == 0 then
		return 0
	end
	local value = read_bits(reader, length)
	local threshold = 2 ^ (length - 1)
	return value < threshold and value - (2 ^ length - 1) or value
end

local function read_huffman(reader, table)
	local code = 0
	for length = JPEG_FIRST_LUA_INDEX, JPEG_DHT_CODE_LENGTH_COUNT do
		code = code * 2 + read_bit(reader)
		local symbol = table[length] and table[length][code]
		if symbol then
			return symbol
		end
	end
	error("Invalid JPEG Huffman code.")
end

local BASIS={}
for x=0,7 do BASIS[x]={};for u=0,7 do BASIS[x][u]=math.cos((2*x+1)*u*math.pi/16)*(u==0 and 1/math.sqrt(2)or 1)end end
local function idct_block(coefficients)
 local output,temporary={},{}
 for v=0,7 do for x=0,7 do
  local total=0;for u=0,7 do total+=coefficients[v*8+u+1]*BASIS[x][u]end;temporary[v*8+x+1]=total
 end end
 for y=0,7 do for x=0,7 do
  local total=0;for v=0,7 do total+=temporary[v*8+x+1]*BASIS[y][v]end
  output[y*8+x+1]=clamp(total*.25+128)
 end end
 return output
end
local function restart(reader)
 reader.bit_index=8
 local p=reader.offset
 assert(reader.data:byte(p)==255,'Missing JPEG restart marker')
 while reader.data:byte(p)==255 do p+=1 end
 local marker=reader.data:byte(p);assert(marker and marker>=208 and marker<=215,'Invalid JPEG restart marker')
 reader.offset=p+1
end
local function scan_block(reader,component,coeff,dc_table,ac_table,ss,se,ah,al,state,progressive)
 local step=2^al
 if ss==0 then
  if ah==0 then component.dc+=receive_extend(reader,read_huffman(reader,dc_table));coeff[1]=component.dc*step
  else coeff[1]+=read_bit(reader)*step end
  if progressive then return end
 end
 local k=math.max(ss,1)
 local function refine(index)
  local v=coeff[index]
  if read_bit(reader)==1 and math.floor(math.abs(v)/step)%2==0 then coeff[index]=v+(v<0 and-step or step)end
 end
 if ah==0 then
  if state.EOB>0 then state.EOB-=1;return end
  while k<=se do
   local symbol=read_huffman(reader,ac_table);local run,size=math.floor(symbol/16),symbol%16
   if size==0 then
    if run==15 then k+=16 else state.EOB=2^run+read_bits(reader,run)-1;break end
   else
    k+=run;assert(k<=se,'JPEG AC coefficient exceeds scan');coeff[ZIGZAG[k+1]]=receive_extend(reader,size)*step;k+=1
   end
  end
 elseif state.EOB>0 then
  while k<=se do local index=ZIGZAG[k+1];if coeff[index]~=0 then refine(index)end;k+=1 end
  state.EOB-=1
 else
  while k<=se do
   local symbol=read_huffman(reader,ac_table);local run,size=math.floor(symbol/16),symbol%16;local value
   if size==0 then
    if run<15 then
     state.EOB=2^run+read_bits(reader,run)
     while k<=se do local index=ZIGZAG[k+1];if coeff[index]~=0 then refine(index)end;k+=1 end
     state.EOB-=1;break
    end
    run=16
   else assert(size==1,'Invalid JPEG refinement coefficient');value=read_bit(reader)==1 and step or-step end
   while k<=se do
    local index=ZIGZAG[k+1]
    if coeff[index]~=0 then refine(index)
    elseif run==0 then break else run-=1 end
    k+=1
   end
   if value then assert(k<=se,'JPEG refinement exceeds scan');coeff[ZIGZAG[k+1]]=value;k+=1
   else assert(run==0,'Truncated JPEG zero run')end
  end
 end
end

local function parse_huffman_table(data, offset, length, tables)
	local end_offset = offset + length
	while offset < end_offset do
		local information = data:byte(offset)
		offset = offset + JPEG_DHT_TABLE_INFORMATION_SIZE
		local table_class = math.floor(information / 16)
		local table_id = information % 16
		if table_class ~= JPEG_DC_TABLE_CLASS and table_class ~= JPEG_AC_TABLE_CLASS then
			error("JPEG has an invalid Huffman table class.")
		end

		local counts = {}
		local symbol_count = 0
		for index = JPEG_FIRST_LUA_INDEX, JPEG_DHT_CODE_LENGTH_COUNT do
			counts[index] = data:byte(offset + index - JPEG_FIRST_LUA_INDEX)
			symbol_count = symbol_count + counts[index]
		end
		offset = offset + JPEG_DHT_CODE_LENGTH_COUNT

		local huffman = {}
		local code = 0
		for code_length = JPEG_FIRST_LUA_INDEX, JPEG_DHT_CODE_LENGTH_COUNT do
			huffman[code_length] = {}
			for _ = JPEG_FIRST_LUA_INDEX, counts[code_length] do
				huffman[code_length][code] = data:byte(offset)
				offset = offset + 1
				code = code + 1
			end
			code = code * 2
		end
		if offset > end_offset + 1 then
			error("JPEG Huffman table exceeds its segment.")
		end
		tables[table_class][table_id] = huffman
	end
end

local function write_block(component, block, x_offset, y_offset)
	for y = 0, JPEG_BLOCK_SIZE - 1 do
		local destination_y = y_offset + y
		if destination_y < component.height then
			for x = 0, JPEG_BLOCK_SIZE - 1 do
				local destination_x = x_offset + x
				if destination_x < component.width then
					component.samples[destination_y * component.width + destination_x + JPEG_FIRST_LUA_INDEX] =
						block[y * JPEG_BLOCK_SIZE + x + JPEG_FIRST_LUA_INDEX]
				end
			end
		end
	end
end

---@param jpeg string
---@return { width: number, height: number, channels: number, pixels: number[] }
function M.decode(jpeg)
	if type(jpeg) ~= "string" or jpeg:byte(1) ~= JPEG_MARKER_PREFIX or jpeg:byte(2) ~= JPEG_START_OF_IMAGE then
		error("Input is not a JPEG file.")
	end

	local offset = 3
	local quantization_tables = {}
	local huffman_tables = { [JPEG_DC_TABLE_CLASS] = {}, [JPEG_AC_TABLE_CLASS] = {} }
	local components = {}
	local components_by_id = {}
	local width
	local height
	local maximum_horizontal_sampling
	local maximum_vertical_sampling
	local restart_interval = 0
    local progressive=false;local scans=0

	while offset <= #jpeg do
		while jpeg:byte(offset) == JPEG_MARKER_PREFIX do
			offset = offset + 1
		end
		local marker = jpeg:byte(offset)
		offset = offset + 1
		if marker == JPEG_END_OF_IMAGE then
			break
		elseif marker < JPEG_RESTART_MARKER_MINIMUM or marker > JPEG_RESTART_MARKER_MAXIMUM then
			local segment_length = read_uint16(jpeg, offset)
			local segment_offset = offset + JPEG_16_BIT_SEGMENT_LENGTH
			local segment_data_length = segment_length - JPEG_16_BIT_SEGMENT_LENGTH
			offset = segment_offset + segment_data_length

			if marker == JPEG_DEFINE_QUANTIZATION_TABLE then
				local table_offset = segment_offset
				while table_offset < offset do
					local information = jpeg:byte(table_offset)
					table_offset = table_offset + JPEG_DQT_TABLE_INFORMATION_SIZE
					if math.floor(information / 16) ~= JPEG_QUANTIZATION_8_BIT then
						error("Only 8-bit JPEG quantization tables are supported.")
					end
					local table_id = information % 16
					local table = {}
					for index = JPEG_FIRST_LUA_INDEX, JPEG_DQT_8_BIT_TABLE_SIZE do
						table[ZIGZAG[index]] = jpeg:byte(table_offset + index - JPEG_FIRST_LUA_INDEX)
					end
					table_offset = table_offset + JPEG_DQT_8_BIT_TABLE_SIZE
					quantization_tables[table_id] = table
				end
			elseif marker == JPEG_START_OF_FRAME_BASELINE or marker==0xC2 then
                progressive=marker==0xC2
				if jpeg:byte(segment_offset) ~= JPEG_8_BIT_PRECISION then
					error("Only 8-bit JPEG precision is supported.")
				end
				height = read_uint16(jpeg, segment_offset + 1)
				width = read_uint16(jpeg, segment_offset + 3)
				assert(width>0 and height>0 and width<=4096 and height<=4096 and width*height<=1048576,"JPEG frame exceeds 1 megapixel")
                local component_count = jpeg:byte(segment_offset + 5)
				if component_count ~= JPEG_COMPONENT_GRAYSCALE and component_count ~= JPEG_COMPONENT_RGB then
					error("Only grayscale and three-component JPEG images are supported.")
				end
				maximum_horizontal_sampling = 0
				maximum_vertical_sampling = 0
				for index = JPEG_FIRST_LUA_INDEX, component_count do
					local component_offset = segment_offset
						+ 6
						+ (index - JPEG_FIRST_LUA_INDEX) * JPEG_COMPONENT_HEADER_SIZE
					local sampling = jpeg:byte(component_offset + 1)
					local component = {
						id = jpeg:byte(component_offset),
						h = math.floor(sampling / 16),
						v = sampling % 16,
						quantization_id = jpeg:byte(component_offset + 2),
						dc = 0,
					}
					assert(component.h>=1 and component.h<=4 and component.v>=1 and component.v<=4,"Invalid JPEG sampling")
                    maximum_horizontal_sampling = math.max(maximum_horizontal_sampling, component.h)
					maximum_vertical_sampling = math.max(maximum_vertical_sampling, component.v)
					table.insert(components, component)
					components_by_id[component.id] = component
				end
			elseif marker == JPEG_DEFINE_HUFFMAN_TABLE then
				parse_huffman_table(jpeg, segment_offset, segment_data_length, huffman_tables)
			elseif marker == JPEG_RESTART_INTERVAL then
				restart_interval = read_uint16(jpeg, segment_offset)
			elseif marker == JPEG_START_OF_SCAN then
				if not width then
					error("JPEG scan appears before its frame.")
				end
                scans+=1;assert(scans<=128,'Too many JPEG scans')
                local scan_count=jpeg:byte(segment_offset);assert(scan_count>=1 and scan_count<=#components,'Invalid JPEG scan components')
                local selected={}
                for index=1,scan_count do
                    local p=segment_offset+1+(index-1)*2
                    local c=assert(components_by_id[jpeg:byte(p)],'Unknown JPEG scan component')
                    local tables=jpeg:byte(p+1);c.dc_table_id=math.floor(tables/16);c.ac_table_id=tables%16;c.dc=0;selected[#selected+1]=c
                end
                local spectral=segment_offset+1+scan_count*2
                local ss,se,approx=jpeg:byte(spectral),jpeg:byte(spectral+1),jpeg:byte(spectral+2)
                local ah,al=math.floor(approx/16),approx%16
                assert(ss<=se and se<=63 and ah<=13 and al<=13,'Invalid JPEG spectral range')
                assert(progressive or(ss==0 and se==63 and ah==0 and al==0),'Invalid sequential JPEG scan')
                assert(not progressive or(ss==0 and se==0 or ss>0 and scan_count==1),'Invalid progressive JPEG scan')
                local mcu_columns=math.ceil(width/(8*maximum_horizontal_sampling));local mcu_rows=math.ceil(height/(8*maximum_vertical_sampling))
                for _,c in ipairs(components)do
                    c.quantization=assert(quantization_tables[c.quantization_id],'Missing JPEG quantization table')
                    c.width=math.ceil(width*c.h/maximum_horizontal_sampling);c.height=math.ceil(height*c.v/maximum_vertical_sampling)
                    c.block_columns=mcu_columns*c.h;c.blocks=c.blocks or{}
                end
                local reader=new_bit_reader(jpeg,offset);local state={EOB=0};local units=0
                local function decode(c,x,y)
                    local index=y*c.block_columns+x+1;local block=c.blocks[index]
                    if not block then block=table.create(64,0);c.blocks[index]=block end
                    local dc=huffman_tables[0][c.dc_table_id];local ac=huffman_tables[1][c.ac_table_id]
                    assert(ss~=0 or ah~=0 or dc,'Missing JPEG DC table');assert(se==0 or ac,'Missing JPEG AC table')
                    scan_block(reader,c,block,dc,ac,ss,se,ah,al,state,progressive)
                end
                local columns=scan_count==1 and math.ceil(selected[1].width/8)or mcu_columns
                local rows=scan_count==1 and math.ceil(selected[1].height/8)or mcu_rows
                for y=0,rows-1 do for x=0,columns-1 do
                    if restart_interval>0 and units>0 and units%restart_interval==0 then
                        restart(reader);state.EOB=0;for _,c in ipairs(selected)do c.dc=0 end
                    end
                    if scan_count==1 then decode(selected[1],x,y)
                    else for _,c in ipairs(selected)do for by=0,c.v-1 do for bx=0,c.h-1 do decode(c,x*c.h+bx,y*c.v+by)end end end end
                    units+=1
                end end
                offset=reader.offset
			end
		end
	end

	if not width then
		error("JPEG is missing a baseline frame.")
	end

    for _,c in ipairs(components)do
        assert(c.blocks,'JPEG component has no image data');c.samples={}
        for index,block in pairs(c.blocks)do
            local coefficients=table.create(64)
            for k=1,64 do coefficients[k]=block[k]*c.quantization[k]end
            write_block(c,idct_block(coefficients),((index-1)%c.block_columns)*8,math.floor((index-1)/c.block_columns)*8)
        end
        c.blocks=nil
    end

	local pixels = {}
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local samples = {}
			for index, component in ipairs(components) do
				local sample_x = math.floor(x * component.h / maximum_horizontal_sampling)
				local sample_y = math.floor(y * component.v / maximum_vertical_sampling)
				samples[index] = component.samples[sample_y * component.width + sample_x + JPEG_FIRST_LUA_INDEX]
			end
			if #components == JPEG_COMPONENT_GRAYSCALE then
				table.insert(pixels, samples[1])
				table.insert(pixels, samples[1])
				table.insert(pixels, samples[1])
			else
				local luminance = samples[1]
				local blue_chroma = samples[2] - JPEG_CENTER_VALUE
				local red_chroma = samples[3] - JPEG_CENTER_VALUE
				table.insert(pixels, clamp(luminance + JPEG_CHROMA_RED * red_chroma))
				table.insert(
					pixels,
					clamp(luminance - JPEG_CHROMA_GREEN_CB * blue_chroma - JPEG_CHROMA_GREEN_CR * red_chroma)
				)
				table.insert(pixels, clamp(luminance + JPEG_CHROMA_BLUE * blue_chroma))
			end
		end
	end

	return { width = width, height = height, channels = JPEG_COMPONENT_RGB, pixels = pixels }
end

return M
