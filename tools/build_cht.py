#!/usr/bin/env python3
"""英雄傳奇1 繁中化 build 工具。

輸入:UTF-8 的 translation.tsv(英文原文 <TAB> 中文譯文,每行一則)。
輸出:
  - runtime translation.tsv(英文 <TAB> Big5 bytes):ScummVM SCI 引擎讀取,做內容比對替換。
    TAB/LF 不出現在 Big5,故可安全當分隔。
  - qfg1_big5.fnt:Big5 點陣字型,格式對齊 ScummVM Graphics::Big5Font::loadPrefixedRaw:
    每字 = big-endian Big5 碼(高位元已設)+ height 列 × 2 bytes(16px 寬 1bpp,MSB 在左)。

用法:build_cht.py <in_utf8_tsv> <out_dir> [--size N] [--font PATH] [--face IDX]
純輸出;字型渲染用 Pillow。
"""
import sys, struct, argparse
from PIL import Image, ImageFont, ImageDraw

WIDTH = 16  # Big5Font 固定字寬 kChineseTraditionalWidth

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tsv")
    ap.add_argument("outdir")
    ap.add_argument("--size", type=int, default=14, help="字型高度(px)")
    ap.add_argument("--font", default="/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc")
    ap.add_argument("--face", type=int, default=0)
    a = ap.parse_args()
    H = a.size

    # 讀來源。col1==col2(未翻譯)或 col2 空 → 跳過,只收已翻譯者。
    rows = []
    chars = set()
    total_lines = 0
    with open(a.tsv, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line or "\t" not in line:
                continue
            total_lines += 1
            en, zh = line.split("\t", 1)
            if not zh or zh == en:
                continue  # 未翻譯
            rows.append((en, zh))
            chars.update(zh)

    # 1) runtime tsv(Big5)
    runtime = a.outdir + "/translation.tsv"
    with open(runtime, "wb") as out:
        for en, zh in rows:
            try:
                big5 = zh.encode("big5")
            except UnicodeEncodeError as e:
                sys.stderr.write(f"WARN: 無法 Big5 編碼一則:{e}\n")
                continue
            out.write(en.encode("latin1", "replace"))
            out.write(b"\t")
            out.write(big5)
            out.write(b"\n")

    # 2) 烘 Big5 字型(只含用到的字)
    font = ImageFont.truetype(a.font, H, index=a.face)
    glyphs = []  # (big5code, bytes)
    baked = 0
    for ch in sorted(chars):
        try:
            b5 = ch.encode("big5")
        except UnicodeEncodeError:
            continue
        if len(b5) != 2:
            continue
        code = (b5[0] << 8) | b5[1]  # 高位元組 >=0x81 → 0x8000 已設
        # 渲染到 WIDTH×H 1bpp:以字面 ink bbox 置中,避免全形標點/小字偏高。
        img = Image.new("L", (WIDTH, H), 0)
        d = ImageDraw.Draw(img)
        try:
            bbox = d.textbbox((0, 0), ch, font=font)  # (l,t,r,b) 實際墨水範圍
        except Exception:
            bbox = (0, 0, WIDTH, H)
        gw = bbox[2] - bbox[0]
        gh = bbox[3] - bbox[1]
        ox = (WIDTH - gw) // 2 - bbox[0]
        oy = (H - gh) // 2 - bbox[1]
        d.text((ox, oy), ch, fill=255, font=font)
        rows_bytes = bytearray()
        px = img.load()
        for y in range(H):
            for byte_i in range(WIDTH // 8):  # 2 bytes / 列
                bits = 0
                for bit in range(8):
                    x = byte_i * 8 + bit
                    on = 1 if px[x, y] >= 128 else 0
                    bits = (bits << 1) | on
                rows_bytes.append(bits)
        glyphs.append((code, bytes(rows_bytes)))
        baked += 1

    fnt = a.outdir + "/qfg1_big5.fnt"
    with open(fnt, "wb") as out:
        for code, bmp in glyphs:
            out.write(struct.pack(">H", code))
            out.write(bmp)
        out.write(struct.pack(">H", 0xFFFF))  # 終結

    print(f"譯文 {len(rows)} 則 → {runtime}")
    print(f"字型 {baked} 字 (H={H}, W={WIDTH}) → {fnt}")

if __name__ == "__main__":
    main()
