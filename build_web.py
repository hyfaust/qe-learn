#!/usr/bin/env python3
"""
Build script: converts chapter README.md files into HTML pages
for the Quantum ESPRESSO tutorial web project.

Usage: python3 build_web.py
"""
import os
import re
import sys

# Try to import markdown library
try:
    import markdown
    from markdown.extensions import codehilite, fenced_code, tables, toc, admonition
    HAS_MARKDOWN = True
except ImportError:
    HAS_MARKDOWN = False

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CHAPTERS_DIR = os.path.join(BASE_DIR, 'chapters')
WEB_CHAPTERS_DIR = os.path.join(BASE_DIR, 'site')

CHAPTER_MAP = {
    '01_qe_basics': ('01', '量子ESPRESSO入门与DFT基础'),
    '02_plane_waves_pseudopotentials': ('02', '平面波基组与赝势'),
    '03_k_sampling': ('03', 'k空间采样与布里渊区'),
    '04_bands_and_dos': ('04', '能带结构与态密度'),
    '05_metallic_systems': ('05', '金属体系与展宽方法'),
    '06_structural_optimization': ('06', '结构优化与力学性质'),
    '07_magnetism': ('07', '磁性与自旋极化计算'),
    '08_phonon_basics': ('08', '声子计算与晶格动力学'),
    '09_dielectric_spectroscopy': ('09', '介电与光谱性质'),
    '10_advanced_functionals': ('10', '高级泛函与电子关联修正'),
    '11_md_neb': ('11', '分子动力学与反应路径'),
    '12_automation_capstone': ('12', '综合实战与自动化'),
}


def md_to_html_fallback(md_text):
    """Simple Markdown-to-HTML converter when the markdown library is not available."""
    lines = md_text.split('\n')
    html_lines = []
    in_code = False
    in_table = False
    in_list = False
    code_lang = ''

    for line in lines:
        # Code blocks
        if line.strip().startswith('```'):
            if in_code:
                html_lines.append('</code></pre>')
                in_code = False
            else:
                code_lang = line.strip()[3:].strip()
                cls = f' class="language-{code_lang}"' if code_lang else ''
                html_lines.append(f'<pre><code{cls}>')
                in_code = True
            continue

        if in_code:
            html_lines.append(line.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))
            continue

        # Tables
        if '|' in line and line.strip().startswith('|'):
            cells = [c.strip() for c in line.strip().strip('|').split('|')]
            if all(re.match(r'^[-:]+$', c) for c in cells):
                continue  # separator row
            if not in_table:
                html_lines.append('<table>')
                tag = 'th'
                in_table = True
            else:
                tag = 'td'
            row = ''.join(f'<{tag}>{c}</{tag}>' for c in cells)
            html_lines.append(f'<tr>{row}</tr>')
            continue
        elif in_table:
            html_lines.append('</table>')
            in_table = False

        # Empty line
        if not line.strip():
            if in_list:
                html_lines.append('</ul>')
                in_list = False
            html_lines.append('')
            continue

        # Headings
        m = re.match(r'^(#{1,6})\s+(.*)', line)
        if m:
            level = len(m.group(1))
            text = m.group(2)
            html_lines.append(f'<h{level}>{inline_format(text)}</h{level}>')
            continue

        # Horizontal rule
        if re.match(r'^[-*_]{3,}\s*$', line):
            html_lines.append('<hr>')
            continue

        # List items
        if re.match(r'^\s*[-*+]\s+', line):
            if not in_list:
                html_lines.append('<ul>')
                in_list = True
            text = re.sub(r'^\s*[-*+]\s+', '', line)
            html_lines.append(f'<li>{inline_format(text)}</li>')
            continue

        if re.match(r'^\s*\d+\.\s+', line):
            text = re.sub(r'^\s*\d+\.\s+', '', line)
            html_lines.append(f'<li>{inline_format(text)}</li>')
            continue

        # Blockquote
        if line.strip().startswith('>'):
            text = line.strip()[1:].strip()
            html_lines.append(f'<blockquote><p>{inline_format(text)}</p></blockquote>')
            continue

        # Regular paragraph
        html_lines.append(f'<p>{inline_format(line)}</p>')

    if in_code:
        html_lines.append('</code></pre>')
    if in_table:
        html_lines.append('</table>')
    if in_list:
        html_lines.append('</ul>')

    return '\n'.join(html_lines)


def inline_format(text):
    """Apply inline Markdown formatting."""
    # Bold
    text = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', text)
    # Italic
    text = re.sub(r'\*(.+?)\*', r'<em>\1</em>', text)
    # Inline code
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    # Links
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', text)
    return text


def convert_md_to_html(md_text):
    """Convert Markdown text to HTML."""
    if HAS_MARKDOWN:
        extensions = [
            'markdown.extensions.fenced_code',
            'markdown.extensions.tables',
            'markdown.extensions.toc',
            'markdown.extensions.admonition',
            'markdown.extensions.codehilite',
            'markdown.extensions.nl2br',
        ]
        return markdown.markdown(md_text, extensions=extensions)
    else:
        return md_to_html_fallback(md_text)


# ===== LaTeX protection =====
# The markdown library escapes <, >, & inside LaTeX formulas,
# breaking KaTeX rendering. We protect LaTeX blocks with placeholders.

_LATEX_PLACEHOLDER_PREFIX = '\x00LATEX'

def _protect_latex(md_text):
    """Replace LaTeX blocks with placeholders before markdown conversion."""
    protected = []
    counter = [0]

    def _replace(m):
        tag = f'{_LATEX_PLACEHOLDER_PREFIX}{counter[0]}\x00'
        counter[0] += 1
        protected.append((tag, m.group(0)))
        return tag

    # Protect display math $$...$$ first (greedy, multiline)
    md_text = re.sub(r'\$\$.+?\$\$', _replace, md_text, flags=re.DOTALL)
    # Protect inline math $...$ (non-greedy, single line)
    md_text = re.sub(r'\$[^\$\n]+?\$', _replace, md_text)
    # Protect \(...\) and \[...\]
    md_text = re.sub(r'\\\(.+?\\\)', _replace, md_text, flags=re.DOTALL)
    md_text = re.sub(r'\\\[.+?\\\]', _replace, md_text, flags=re.DOTALL)

    return md_text, protected

def _restore_latex(html_text, protected):
    """Restore LaTeX blocks from placeholders after markdown conversion."""
    for tag, original in protected:
        html_text = html_text.replace(tag, original)
    return html_text


def build_chapter(chapter_dir, num_str, title):
    """Build a single chapter HTML file."""
    readme_path = os.path.join(CHAPTERS_DIR, chapter_dir, 'README.md')
    if not os.path.exists(readme_path):
        print(f"  [SKIP] {readme_path} not found")
        return False

    with open(readme_path, 'r', encoding='utf-8') as f:
        md_text = f.read()

    # Protect LaTeX from markdown HTML escaping
    md_text, latex_blocks = _protect_latex(md_text)

    html_content = convert_md_to_html(md_text)

    # Restore LaTeX blocks
    html_content = _restore_latex(html_content, latex_blocks)

    # Rewrite relative links to point to chapter source files
    # e.g. href="inputs/si_scf.in" -> href="chapters/01_qe_basics/inputs/si_scf.in"
    chapter_prefix = f'chapters/{chapter_dir}/'
    html_content = re.sub(
        r'href="(?!https?://|#|chapters/)([^"]+)"',
        lambda m: f'href="{chapter_prefix}{m.group(1)}"',
        html_content
    )

    output_path = os.path.join(WEB_CHAPTERS_DIR, f'{num_str}.html')
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html_content)

    print(f"  [OK] {output_path}")
    return True


def main():
    os.makedirs(WEB_CHAPTERS_DIR, exist_ok=True)

    print("Building Quantum ESPRESSO Tutorial Web Project...")
    print(f"Chapters source: {CHAPTERS_DIR}")
    print(f"Web output: {WEB_CHAPTERS_DIR}")
    print(f"Markdown library: {'available' if HAS_MARKDOWN else 'NOT available (using fallback)'}")
    print()

    built = 0
    for chapter_dir, (num_str, title) in CHAPTER_MAP.items():
        if build_chapter(chapter_dir, num_str, title):
            built += 1

    print(f"\nDone! Built {built}/{len(CHAPTER_MAP)} chapters.")
    print(f"Open {os.path.join(BASE_DIR, 'index.html')} in a browser to view.")


if __name__ == '__main__':
    main()
