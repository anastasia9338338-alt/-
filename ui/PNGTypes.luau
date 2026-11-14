-- Picguin types; origin {"repo": "wizevaxel/picguin", "commit": "c9c10f5639720d7dedc7955052026d6636b3d5b0"}
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
--!optimize 2

export type Error<Code> = {
	code: "ok",
	message: "",
} | {
	code: Code,
	message: string,
}

export type ColorSpace = "truecolor" | "grayscale" | "indexed"

export type DisposeOperation = "none" | "background" | "previous"
export type BlendOperation = "source" | "over"

export type CriticalChunk =
	| "IHDR" | "PLTE" | "IDAT" | "IEND"
export type AncillaryChunk =
	| "tRNS" | "cHRM" | "gAMA" | "iCCP"
	| "sBIT" | "sRGB" | "cICP" | "mDCV"
	| "cLLI" | "tEXt" | "zTXt" | "iTXt"
	| "bKGD" | "pHYs" | "sPLT" | "eXIf"
	| "tIME" | "acTL" | "fcTL" | "fdAT"
export type Chunk = CriticalChunk | AncillaryChunk

return {}
