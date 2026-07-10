#!/usr/bin/env python3
"""EGA(SCI0)文字抽取 + 自動套用 VGA 譯文,產生 EGA worklist。

- 從 SCI_DUMP_RES dump 的 EGA `text.*` 抽字串,**保留硬換行**(存成 `\\n` 跳脫,因 TSV 行式)。
- 自動套用:EGA 字串去 \\n/空白正規化後若對到 VGA `translation.tsv` 的譯文,直接沿用(flat 中文,靠文字框 word-wrap)。
- 輸出 `translation/ega/translation.tsv`(worklist:escaped-\\n 英文 \\t 中文或英文)。

用法:prep_ega.py <ega_dump_dir> <vga_translation.tsv> <out_tsv>
純 stdlib。
"""
import sys, glob, re, os

def esc(s):
    return s.replace('\\', '\\\\').replace('\n', '\\n').replace('\t', '\\t')

def norm(s):
    return re.sub(r'\s+', ' ', s.replace('\n', ' ')).strip()

def strings_from_text(path):
    d = open(path, 'rb').read()
    body = d[2:] if d and d[0] in (0x83, 0x80) else d
    out = []
    for chunk in body.split(b'\x00'):
        try:
            s = chunk.decode('latin1')
        except Exception:
            continue
        printable = sum(1 for c in s if 32 <= ord(c) < 127 or c == '\n')
        if not s or printable / max(1, len(s)) < 0.92:
            continue
        if len(s.strip()) >= 2 and re.search(r'[A-Za-z]{2,}', s):
            out.append(s)
    return out

def main():
    dump_dir, vga_tsv, out_tsv = sys.argv[1], sys.argv[2], sys.argv[3]

    # VGA 已翻譯:normalized english -> 中文
    vga = {}
    for l in open(vga_tsv, encoding='utf-8'):
        if '\t' not in l:
            continue
        en, zh = l.rstrip('\n').split('\t', 1)
        if zh != en:
            vga[norm(en)] = zh

    # EGA 抽字(原順序、去重)
    seen = set(); rows = []
    for f in sorted(glob.glob(os.path.join(dump_dir, 'text.*'))):
        for s in strings_from_text(f):
            if s in seen:
                continue
            seen.add(s)
            rows.append(s)

    reused = 0
    os.makedirs(os.path.dirname(out_tsv), exist_ok=True)
    with open(out_tsv, 'w', encoding='utf-8') as o:
        for s in rows:
            key = esc(s)
            zh = vga.get(norm(s))
            if zh:
                o.write(f"{key}\t{esc(zh)}\n")  # 沿用 VGA 譯文(flat)
                reused += 1
            else:
                o.write(f"{key}\t{key}\n")       # 待翻
    print(f"EGA 字串 {len(rows)} 則;自動套用 VGA 譯文 {reused} 則 ({100*reused//max(1,len(rows))}%);"
          f"待翻 {len(rows)-reused} 則 → {out_tsv}")

if __name__ == '__main__':
    main()
