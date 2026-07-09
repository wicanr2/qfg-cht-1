#!/usr/bin/env python3
"""SCI1.1 VGA view (kViewVga11) decoder / encoder.

Reverse-engineered from ScummVM source (read-only reference, not modified):
  scummvm-src/engines/sci/graphics/view.cpp
    - GfxView::initData()        SCI1.1 VGA header / loop table / cel table layout
    - unpackCelData()            VGA dual-stream RLE format (offsetRLE control stream +
                                  offsetLiteral pixel stream)
    - GfxView::dumpCelsToDir()   PPM rendering: palette->colors[bitmap[i]], no alpha
  scummvm-src/engines/sci/graphics/palette16.cpp
    - GfxPalette::createFromData()  embedded palette layout
  scummvm-src/engines/sci/resource/resource.cpp
    - ResourceManager::processPatch()  loose patch file header layout (kResourceTypeView,
      _volVersion >= kResVersionSci11 branch)

=====================================================================================
Byte layout notes (see cited functions for the authoritative C++; this is a transcript)
=====================================================================================

View resource data (this is what GfxView::initData() parses; NOT what's on disk in a
patch file -- see "Patch file format" below for the extra wrapper bytes):

Header (headerSize bytes, headerSize = u16LE(0) + 2):
  0x00 u16   headerSizeField      (headerSize = this + 2)
  0x02 u8    loopCount
  0x03 u8    flags                (1=not scalable, 0/0x40=scalable; unused here)
  0x04 u16   version              (unused by decoder)
  0x06 u16   unknown              (unused by decoder)
  0x08 u32   paletteOffset        (0 = no embedded palette)
  0x0C u8    loopSize             (bytes per loop-table entry, >=16)
  0x0D u8    celSize              (bytes per cel-table entry,  >=32)
  0x0E ..    padding out to headerSize (unused)

Loop table: loopCount entries of loopSize bytes, starting at offset headerSize:
  0x00 u8    seekEntry            (0xFF = normal; else this loop mirrors loop #seekEntry,
                                    chased transitively)
  0x02 u8    celCount
  0x0C u32   celDataOffset        (absolute offset of this loop's cel table)
  (bytes 1,3,4..11,12.. beyond the fields above are unused by the decoder)

Cel table: celCount entries of celSize bytes, starting at celDataOffset:
  0x00 i16   width
  0x02 i16   height
  0x04 i16   displaceX
  0x06 i16   displaceY            (+255 if negative, per initData())
  0x08 u8    clearKey             (transparent color index)
  0x18 u32   offsetRLE            (0 if cel is stored fully uncompressed)
  0x1C u32   offsetLiteral        (pixel/literal stream offset; dual-stream format)
  (bytes 0x09..0x17, and anything beyond 0x20 up to celSize, are unused by the decoder)

Embedded palette (at paletteOffset, SCI1.1 "new" format -- see parse_palette()):
  0x00..0x18 header (colorStart at 0x19, format at 0x20, colorCount at 0x1D u16)
  followed by colorCount entries of either 3 bytes (RGB, format==1 CONSTANT) or
  4 bytes (used:RGB, format==0 VARIABLE)

VGA RLE control byte (top 2 bits of each control-stream byte, low 6 bits = run length):
  00 YYYYYY  copy YYYYYY bytes from the pixel stream as-is
  01 YYYYYY  copy YYYYYY+64 bytes from the pixel stream as-is
  10 YYYYYY  fill YYYYYY pixels with the next single pixel-stream byte
  11 YYYYYY  skip (transparent) YYYYYY pixels -- no pixel-stream byte consumed
If offsetRLE == 0, the cel is fully uncompressed: the pixel stream is exactly
width*height bytes, copied as-is (see GfxView::unpackCel / unpackCelData rlePos==0 case).

=====================================================================================
Patch file format (what we must write for ScummVM's loose-patch loader to accept it)
=====================================================================================

ResourceManager::processPatch(), kResourceTypeView branch, _volVersion >= kResVersionSci11
(true for QFG1VGA):
    patchDataOffset = kResourceHeaderSize(2)
                    + byte-at-absolute-offset-3
                    + kViewHeaderSize(22)
                    + kExtraHeaderSize(2)
So with the "extra header count" byte (offset 3) set to 0, the real view resource
data (the "View resource data" section above) must start at absolute byte 26 of the
patch file. Bytes 0..25 are a header:
  offset 0: patch type byte. convertResType() does `type & 0x7F` then table-maps 0 ->
            kResourceTypeView, so 0x80 (or 0x00) works; ScummVM's existing dump tool
            in this repo uses 0x80, so we match that.
  offset 1: unused by processPatch() for View (never read) -- 0x00
  offset 2: unused by processPatch() for View (never read) -- 0x00
  offset 3: extra header byte count N -- we always use 0
  offset 4..25: 22 (kViewHeaderSize) filler bytes, ignored/skipped -- 0x00
  offset 26..: raw view resource data begins here

Filename: SCI1.1-and-later loose patch naming is "<resourceNr>.<ext>"; the view
extension is "v56" (engines/sci/resource/resource.cpp s_resourceTypeSuffixes), so
view 908's patch is "908.v56".

The "dump" files under WP/out/dump/ (produced by this project's SCI_DUMP_RES engine
hook) are NOT patch files -- they're just [0x80, 0x00] followed directly by the raw
view resource data (2-byte wrapper, not the 26-byte patch wrapper). decode_file()
below auto-detects and skips this 2-byte wrapper when present.
"""

import argparse
import struct
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    Image = None


# --------------------------------------------------------------------------------
# Palette
# --------------------------------------------------------------------------------

def parse_palette(data: bytes):
    """Port of GfxPalette::createFromData() (palette16.cpp), SCI1.1 'new' format only
    (the SCI0/SCI1 'old' 256-entry format is also handled since QFG1VGA views may hit
    either branch -- see the (data[0]==0 and data[1]==1) / ...==0 check below, copied
    verbatim from the C++)."""
    if len(data) < 37:
        return None

    if (data[0] == 0 and data[1] == 1) or (
        data[0] == 0 and data[1] == 0 and struct.unpack_from('<H', data, 29)[0] == 0
    ):
        pal_format = 0  # SCI_PAL_FORMAT_VARIABLE
        pal_offset = 260
        color_start = 0
        color_count = 256
    else:
        pal_format = data[32]
        pal_offset = 37
        color_start = data[25]
        color_count = struct.unpack_from('<H', data, 29)[0]

    colors = [(0, 0, 0)] * 256
    off = pal_offset
    if pal_format == 1:  # CONSTANT: r,g,b
        need = pal_offset + 3 * color_count
        if len(data) < need:
            return None
        for c in range(color_start, color_start + color_count):
            colors[c] = (data[off], data[off + 1], data[off + 2])
            off += 3
    else:  # VARIABLE: used,r,g,b
        need = pal_offset + 4 * color_count
        if len(data) < need:
            return None
        for c in range(color_start, color_start + color_count):
            off += 1  # 'used' byte, irrelevant for rendering (see dumpCelsToDir)
            colors[c] = (data[off], data[off + 1], data[off + 2])
            off += 3
    return colors


# --------------------------------------------------------------------------------
# Parsing (GfxView::initData, kViewVga11 branch)
# --------------------------------------------------------------------------------

class Cel:
    def __init__(self, width, height, displaceX, displaceY, clearKey,
                 offsetRLE, offsetLiteral, table_offset):
        self.width = width
        self.height = height
        self.displaceX = displaceX
        self.displaceY = displaceY
        self.clearKey = clearKey
        self.offsetRLE = offsetRLE
        self.offsetLiteral = offsetLiteral
        self.table_offset = table_offset  # absolute offset of this cel's table entry


class Loop:
    def __init__(self, seekEntry, celDataOffset, cels, table_offset):
        self.seekEntry = seekEntry
        self.mirrorFlag = seekEntry != 255
        self.celDataOffset = celDataOffset
        self.cels = cels
        self.table_offset = table_offset


class SCIView:
    def __init__(self, data: bytes):
        self.data = data
        self._parse()

    def _parse(self):
        d = self.data
        self.headerSize = struct.unpack_from('<H', d, 0)[0] + 2
        self.loopCount = d[2]
        self.flags = d[3]
        self.paletteOffset = struct.unpack_from('<I', d, 8)[0]
        self.loopSize = d[12]
        self.celSize = d[13]

        self.palette = None
        if self.paletteOffset:
            self.palette = parse_palette(d[self.paletteOffset:])

        self.loops = []
        for loopNo in range(self.loopCount):
            loop_off = self.headerSize + loopNo * self.loopSize
            loopData = d[loop_off:loop_off + self.loopSize]
            seekEntry = loopData[0]
            celCount = loopData[2]
            celDataOffset = struct.unpack_from('<I', loopData, 12)[0]

            cels = []
            for celNo in range(celCount):
                cs = celDataOffset + celNo * self.celSize
                celData = d[cs:cs + self.celSize]
                width = struct.unpack_from('<h', celData, 0)[0]
                height = struct.unpack_from('<h', celData, 2)[0]
                displaceX = struct.unpack_from('<h', celData, 4)[0]
                displaceY = struct.unpack_from('<h', celData, 6)[0]
                if displaceY < 0:
                    displaceY += 255
                clearKey = celData[8]
                offsetRLE = struct.unpack_from('<I', celData, 24)[0]
                offsetLiteral = struct.unpack_from('<I', celData, 28)[0]
                if offsetRLE and not offsetLiteral:
                    # GK1-hires uncompressed-content quirk (view.cpp comment); kept for
                    # parity even though QFG1VGA never hits this.
                    offsetRLE, offsetLiteral = offsetLiteral, offsetRLE
                cels.append(Cel(width, height, displaceX, displaceY, clearKey,
                                 offsetRLE, offsetLiteral, cs))
            self.loops.append(Loop(seekEntry, celDataOffset, cels, loop_off))

    def resolved_cel(self, loopNo: int, celNo: int) -> Cel:
        """Follow the mirror-chain (initData()'s do/while over seekEntry) to find the
        loop that actually owns the cel data, mirroring only flips displaceX/pixels --
        for our purposes (bitmap extraction) mirroring of the raw bitmap does not apply
        here; GfxView::getBitmap() mirrors row pixels post-decode when mirrorFlag is
        set. We replicate that in decode_cel()."""
        loop = self.loops[loopNo]
        seen = set()
        while loop.seekEntry != 255:
            if loopNo in seen:
                raise ValueError("mirror loop cycle")
            seen.add(loopNo)
            loopNo = loop.seekEntry
            loop = self.loops[loopNo]
        return loop.cels[celNo]


# --------------------------------------------------------------------------------
# Cel bitmap decode (unpackCelData, kViewVga/kViewVga11 branch)
# --------------------------------------------------------------------------------

def unpack_cel_bitmap(data: bytes, cel: Cel) -> bytearray:
    width, height, clear = cel.width, cel.height, cel.clearKey
    pixel_count = width * height
    out = bytearray([clear]) * pixel_count

    if cel.offsetRLE == 0:
        # fully uncompressed: literal stream is exactly pixel_count bytes
        out[:] = data[cel.offsetLiteral:cel.offsetLiteral + pixel_count]
        return out

    rle_ptr = cel.offsetRLE
    lit_ptr = cel.offsetLiteral  # 0 means single-stream (control stream doubles as data)
    pixel_nr = 0
    n = len(data)
    while pixel_nr < pixel_count:
        cur = data[rle_ptr]
        rle_ptr += 1
        run_length = cur & 0x3F
        tag = cur & 0xC0

        if tag == 0x40:
            run_length += 64
            tag = 0x00  # shares the copy-literal code path (C++ fallthrough)

        if tag == 0x00:
            n_copy = min(run_length, pixel_count - pixel_nr)
            if lit_ptr == 0:
                out[pixel_nr:pixel_nr + n_copy] = data[rle_ptr:rle_ptr + n_copy]
                rle_ptr += run_length
            else:
                out[pixel_nr:pixel_nr + n_copy] = data[lit_ptr:lit_ptr + n_copy]
                lit_ptr += run_length
        elif tag == 0x80:
            n_fill = min(run_length, pixel_count - pixel_nr)
            if lit_ptr == 0:
                val = data[rle_ptr]
                rle_ptr += 1
            else:
                val = data[lit_ptr]
                lit_ptr += 1
            out[pixel_nr:pixel_nr + n_fill] = bytes([val]) * n_fill
        else:  # 0xC0: skip / transparent -- leave `clear` already in place
            pass

        pixel_nr += run_length

    return out


def decode_cel(view: SCIView, loopNo: int, celNo: int) -> bytearray:
    """Equivalent of GfxView::getBitmap(): unpack + apply mirroring."""
    loop = view.loops[loopNo]
    src_loop_no = loopNo
    seen = set()
    while loop.seekEntry != 255:
        if src_loop_no in seen:
            raise ValueError("mirror loop cycle")
        seen.add(src_loop_no)
        src_loop_no = loop.seekEntry
        loop = view.loops[src_loop_no]
    cel = loop.cels[celNo]
    bitmap = unpack_cel_bitmap(view.data, cel)

    if view.loops[loopNo].mirrorFlag:
        w, h = cel.width, cel.height
        for row in range(h):
            base = row * w
            line = bitmap[base:base + w]
            line.reverse()
            bitmap[base:base + w] = line

    return bitmap


def cel_to_rgb(view: SCIView, bitmap: bytes, width: int, height: int) -> bytes:
    """Equivalent of GfxView::dumpCelsToDir()'s pixel loop: palette->colors[index],
    no transparency masking (matches the PPM ground-truth files exactly)."""
    if view.palette is None:
        raise ValueError("view has no embedded palette; system palette (999) rendering "
                          "not implemented in this tool")
    pal = view.palette
    out = bytearray(width * height * 3)
    for i, idx in enumerate(bitmap):
        r, g, b = pal[idx]
        out[i * 3] = r
        out[i * 3 + 1] = g
        out[i * 3 + 2] = b
    return bytes(out)


# --------------------------------------------------------------------------------
# File-level helpers (patch / dump wrapper handling)
# --------------------------------------------------------------------------------

def load_view_data(path: Path) -> bytes:
    """Strip the 2-byte SCI_DUMP_RES wrapper ([0x80, 0x00]) if present; otherwise
    treat the file as raw view resource data."""
    raw = path.read_bytes()
    if len(raw) >= 2 and raw[0] == 0x80 and raw[1] == 0x00:
        return raw[2:]
    return raw


def write_ppm(path: Path, width: int, height: int, rgb: bytes):
    with open(path, 'wb') as f:
        f.write(f"P6\n{width} {height}\n255\n".encode('ascii'))
        f.write(rgb)


def write_png(path: Path, width: int, height: int, rgb: bytes):
    if Image is None:
        return
    img = Image.frombytes('RGB', (width, height), rgb)
    img.save(path)


# --------------------------------------------------------------------------------
# Encoding
# --------------------------------------------------------------------------------

def encode_cel_streams(bitmap: bytes, clear_key: int):
    """Re-encode a raw index bitmap using only:
      - 11 YYYYYY (skip) runs for clear_key pixels
      - 00 YYYYYY (copy literal) runs for everything else, chunked to <=63 bytes
    Deliberately avoids the 10 YYYYYY (fill) and 01 YYYYYY (copy+64) opcodes -- this
    is "full literal" re-encoding per docs/40-baked-art-ui.md's encoder spec, which
    ScummVM decodes identically to a hand-optimized encoding (see unpack_cel_bitmap).
    Returns (rle_bytes, literal_bytes)."""
    rle = bytearray()
    literal = bytearray()
    n = len(bitmap)
    i = 0
    while i < n:
        if bitmap[i] == clear_key:
            j = i
            while j < n and bitmap[j] == clear_key:
                j += 1
            run = j - i
            while run > 0:
                chunk = min(run, 63)
                rle.append(0xC0 | chunk)
                run -= chunk
            i = j
        else:
            j = i
            while j < n and bitmap[j] != clear_key:
                j += 1
            run = j - i
            k = i
            while run > 0:
                chunk = min(run, 63)
                rle.append(0x00 | chunk)
                literal.extend(bitmap[k:k + chunk])
                k += chunk
                run -= chunk
            i = j
    return bytes(rle), bytes(literal)


def rebuild_view(view: SCIView, replacements: dict) -> bytes:
    """Rebuild the full view resource byte-for-byte, keeping header/loop-table/
    cel-table/palette region at their original absolute offsets (only the 8
    offsetRLE/offsetLiteral bytes per cel entry are overwritten), and replacing
    the bitmap-stream region (everything from the lowest original offsetRLE/
    offsetLiteral onward) with freshly literal-encoded streams for every cel.

    `replacements`: dict of (loopNo, celNo) -> new raw index bitmap (bytes,
    length must equal cel.width*cel.height) overriding the decoded original for
    that cel; cels not present keep their originally-decoded bitmap (i.e. a
    round-trip re-encode with an empty dict must decode back to pixel-identical
    output).
    """
    d = view.data

    # Metadata region (header + loop tables + cel tables + palette, and anything
    # else that isn't bitmap-stream data) is everything before the first
    # offsetRLE/offsetLiteral referenced by any cel.
    stream_starts = []
    for loop in view.loops:
        for cel in loop.cels:
            if cel.offsetRLE:
                stream_starts.append(cel.offsetRLE)
            if cel.offsetLiteral:
                stream_starts.append(cel.offsetLiteral)
    meta_end = min(stream_starts) if stream_starts else len(d)

    out = bytearray(d[:meta_end])

    for loopNo, loop in enumerate(view.loops):
        if loop.mirrorFlag:
            continue  # mirrored loops carry no cel data of their own
        for celNo, cel in enumerate(loop.cels):
            key = (loopNo, celNo)
            if key in replacements:
                bitmap = replacements[key]
                assert len(bitmap) == cel.width * cel.height, (
                    f"replacement bitmap for loop {loopNo} cel {celNo} has "
                    f"{len(bitmap)} bytes, expected {cel.width * cel.height}")
            else:
                bitmap = unpack_cel_bitmap(d, cel)

            rle_bytes, lit_bytes = encode_cel_streams(bitmap, cel.clearKey)

            new_rle_off = len(out)
            out += rle_bytes
            new_lit_off = len(out)
            out += lit_bytes

            struct.pack_into('<I', out, cel.table_offset + 24, new_rle_off)
            struct.pack_into('<I', out, cel.table_offset + 28, new_lit_off)

    return bytes(out)


def make_patch(view_data: bytes) -> bytes:
    """Wrap raw view resource data into a loose ScummVM SCI patch file body
    (see module docstring: 26-byte header, patch type 0x80, N=0)."""
    header = bytearray(26)
    header[0] = 0x80  # patch type byte -> (0x80 & 0x7F) == 0 -> kResourceTypeView
    header[3] = 0x00  # extra header byte count N
    return bytes(header) + view_data


# --------------------------------------------------------------------------------
# CLI commands
# --------------------------------------------------------------------------------

def cmd_decode(args):
    data = load_view_data(Path(args.input))
    view = SCIView(data)
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    count = 0
    for loopNo, loop in enumerate(view.loops):
        for celNo, cel in enumerate(loop.cels):
            bitmap = decode_cel(view, loopNo, celNo)
            rgb = cel_to_rgb(view, bitmap, cel.width, cel.height)
            base = outdir / f"view_{args.view_id}_{loopNo}_{celNo}"
            write_ppm(base.with_suffix('.ppm'), cel.width, cel.height, rgb)
            if Image is not None:
                write_png(base.with_suffix('.png'), cel.width, cel.height, rgb)
            count += 1
    print(f"decoded {count} cel(s) to {outdir}")


def cmd_verify(args):
    """Compare our decode against reference PPMs (out/allviews style), pixel-exact."""
    data = load_view_data(Path(args.input))
    view = SCIView(data)
    ref_dir = Path(args.ref_dir)

    ok = True
    checked = 0
    for loopNo, loop in enumerate(view.loops):
        for celNo, cel in enumerate(loop.cels):
            ref_path = ref_dir / f"view_{args.view_id}_{loopNo}_{celNo}.ppm"
            if not ref_path.exists():
                print(f"  [skip] {ref_path} not found")
                continue
            bitmap = decode_cel(view, loopNo, celNo)
            rgb = cel_to_rgb(view, bitmap, cel.width, cel.height)

            ref_bytes = ref_path.read_bytes()
            # PPM: header "P6\nW H\n255\n" then raw RGB
            hdr_end = 0
            newlines = 0
            for idx, b in enumerate(ref_bytes):
                if b == 0x0A:
                    newlines += 1
                    if newlines == 3:
                        hdr_end = idx + 1
                        break
            ref_rgb = ref_bytes[hdr_end:]

            checked += 1
            if ref_rgb != rgb:
                ok = False
                # find first mismatch for diagnostics
                for i in range(min(len(ref_rgb), len(rgb))):
                    if ref_rgb[i] != rgb[i]:
                        print(f"  [MISMATCH] loop {loopNo} cel {celNo}: "
                              f"first differing byte at {i} "
                              f"(ours={rgb[i]} ref={ref_rgb[i]}), "
                              f"len ours={len(rgb)} ref={len(ref_rgb)}")
                        break
                else:
                    print(f"  [MISMATCH] loop {loopNo} cel {celNo}: length differs "
                          f"ours={len(rgb)} ref={len(ref_rgb)}")
            else:
                print(f"  [ok] loop {loopNo} cel {celNo} ({cel.width}x{cel.height})")

    print(f"verify: {checked} cel(s) checked, {'ALL OK' if ok else 'MISMATCHES FOUND'}")
    sys.exit(0 if ok else 1)


def cmd_encode(args):
    data = load_view_data(Path(args.input))
    view = SCIView(data)

    replacements = {}
    if args.replace:
        for spec in args.replace:
            # spec: "loop,cel,pngfile"
            loop_s, cel_s, png_path = spec.split(',', 2)
            loopNo, celNo = int(loop_s), int(cel_s)
            cel = view.loops[loopNo].cels[celNo]
            if Image is None:
                raise SystemExit("Pillow required for --replace (PNG input)")
            img = Image.open(png_path)
            if img.size != (cel.width, cel.height):
                raise SystemExit(f"replacement image {png_path} is {img.size}, "
                                  f"expected {(cel.width, cel.height)}")
            bitmap = image_to_indices(img, view.palette, cel.clearKey)
            replacements[(loopNo, celNo)] = bitmap

    new_data = rebuild_view(view, replacements)

    out_path = Path(args.output)
    if args.patch:
        out_path.write_bytes(make_patch(new_data))
        print(f"wrote patch file: {out_path} ({out_path.stat().st_size} bytes)")
    else:
        out_path.write_bytes(new_data)
        print(f"wrote raw view resource: {out_path} ({out_path.stat().st_size} bytes)")


def image_to_indices(img, palette, clear_key: int) -> bytes:
    """Map an RGB(A) Pillow image to the view's embedded-palette indices.
    Exact-match only (nearest-neighbour fallback) -- callers should draw with
    colors sampled from the view's own palette to avoid RGB->index loss (per
    docs/40-baked-art-ui.md's encoder spec). Fully-transparent (alpha==0) pixels
    map to clear_key."""
    if palette is None:
        raise SystemExit("view has no embedded palette; cannot map RGB->index")
    img = img.convert('RGBA')
    w, h = img.size
    px = img.load()

    # Build reverse lookup once (exact RGB match); fall back to nearest for any
    # colors not present in the palette (e.g. anti-aliasing edges).
    exact = {}
    for idx, rgb in enumerate(palette):
        exact.setdefault(rgb, idx)

    def nearest(rgb):
        best_idx, best_d = 0, None
        for idx, prgb in enumerate(palette):
            d = sum((a - b) ** 2 for a, b in zip(rgb, prgb))
            if best_d is None or d < best_d:
                best_d, best_idx = d, idx
        return best_idx

    out = bytearray(w * h)
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                out[y * w + x] = clear_key
                continue
            rgb = (r, g, b)
            idx = exact.get(rgb)
            if idx is None:
                idx = nearest(rgb)
            out[y * w + x] = idx
    return bytes(out)


def cmd_roundtrip(args):
    """decode -> encode (unchanged) -> decode again; compare pixel-for-pixel."""
    data = load_view_data(Path(args.input))
    view = SCIView(data)

    originals = {}
    for loopNo, loop in enumerate(view.loops):
        for celNo, cel in enumerate(loop.cels):
            originals[(loopNo, celNo)] = bytes(decode_cel(view, loopNo, celNo))

    new_data = rebuild_view(view, {})
    view2 = SCIView(new_data)

    ok = True
    for (loopNo, celNo), orig_bitmap in originals.items():
        new_bitmap = bytes(decode_cel(view2, loopNo, celNo))
        if new_bitmap != orig_bitmap:
            ok = False
            for i in range(min(len(orig_bitmap), len(new_bitmap))):
                if orig_bitmap[i] != new_bitmap[i]:
                    print(f"  [MISMATCH] loop {loopNo} cel {celNo} byte {i}: "
                          f"orig={orig_bitmap[i]} new={new_bitmap[i]}")
                    break
        else:
            cel = view.loops[loopNo].cels[celNo]
            print(f"  [ok] loop {loopNo} cel {celNo} ({cel.width}x{cel.height}) "
                  f"round-trip identical")

    print(f"round-trip: {'ALL IDENTICAL' if ok else 'MISMATCHES FOUND'}")

    if args.output:
        Path(args.output).write_bytes(new_data)
        print(f"wrote re-encoded raw view resource: {args.output}")
    if args.patch:
        Path(args.patch).write_bytes(make_patch(new_data))
        print(f"wrote re-encoded patch file: {args.patch}")

    sys.exit(0 if ok else 1)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                  formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)

    p = sub.add_parser('decode', help='decode a view to per-cel PNG/PPM')
    p.add_argument('input', help='view file (dump-wrapped or raw)')
    p.add_argument('outdir')
    p.add_argument('--view-id', type=int, default=0, dest='view_id')
    p.set_defaults(func=cmd_decode)

    p = sub.add_parser('verify', help='compare decode output against reference PPMs')
    p.add_argument('input', help='view file (dump-wrapped or raw)')
    p.add_argument('ref_dir', help='directory of reference view_<id>_<loop>_<cel>.ppm')
    p.add_argument('--view-id', type=int, required=True, dest='view_id')
    p.set_defaults(func=cmd_verify)

    p = sub.add_parser('roundtrip', help='decode -> re-encode (unchanged) -> decode, compare')
    p.add_argument('input', help='view file (dump-wrapped or raw)')
    p.add_argument('--output', help='write re-encoded raw view resource here')
    p.add_argument('--patch', help='write re-encoded loose patch file here')
    p.set_defaults(func=cmd_roundtrip)

    p = sub.add_parser('encode', help='re-encode a view, optionally replacing cels')
    p.add_argument('input', help='view file (dump-wrapped or raw)')
    p.add_argument('output')
    p.add_argument('--replace', action='append',
                    help='loop,cel,pngfile -- replace one cel with a PNG '
                         '(same width/height, RGBA; alpha==0 -> transparent)')
    p.add_argument('--patch', action='store_true',
                    help='wrap output as a loose ScummVM SCI patch file '
                         '(default: write raw view resource data)')
    p.set_defaults(func=cmd_encode)

    args = ap.parse_args()
    args.func(args)


if __name__ == '__main__':
    main()
