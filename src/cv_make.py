#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2026 Marcin Kaim
# SPDX-License-Identifier: Apache-2.0

import sys
import re
import argparse
import logging
from bs4 import BeautifulSoup
from markdown_it import MarkdownIt
from jinja2 import Template
from weasyprint import HTML, CSS

def setup_diagnostics(verbose: bool = False):
    """Logging configuration for WeasyPrint and preprocessor engine."""
    log_level = logging.DEBUG if verbose else logging.INFO
    
    logging.basicConfig(
        level=log_level,
        format="[%(levelname)s] %(name)s: %(message)s",
        stream=sys.stderr,
        force=True
    )

    weasyprint_logger = logging.getLogger("weasyprint")
    weasyprint_logger.setLevel(log_level)

def slugify(text):
    text = text.lower()
    text = re.sub(r'[^a-z0-9]+', '-', text)
    text = re.sub(r'-+', '-', text)
    return text.strip('-')

def parse_args():
    parser = argparse.ArgumentParser(prog="cv-make", description="CV Make Internal PDF Compiler")
    parser.add_argument("-p", "--photo", help="Path to profile photograph")
    parser.add_argument("-s", "--style", action="append", default=[], help="Path to custom CSS stylesheet")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose diagnostic logging")
    return parser.parse_args()

def main():
    try:
        args = parse_args()
        setup_diagnostics(args.verbose)

        print("[cv-make-engine] Ingesting Markdown from stdin...", file=sys.stderr)
        markdown_text = sys.stdin.read()

        # Stage 1 & 2: Parse Markdown AST and render initial HTML
        md = MarkdownIt("commonmark")
        html_raw = md.render(markdown_text)

        soup = BeautifulSoup(html_raw, "html.parser")

        # Stage 3: Header Block and Photo Integration
        first_h2 = soup.find("h2")
        header_left_elements = []
        remaining_elements = []

        if first_h2:
            current = soup.contents[0] if soup.contents else None
            is_header = True
            while current:
                next_sibling = current.next_sibling
                if current == first_h2:
                    is_header = False
                
                if is_header:
                    header_left_elements.append(current)
                else:
                    remaining_elements.append(current)
                current = next_sibling
        else:
            header_left_elements = list(soup.contents)
            remaining_elements = []

        header_main = soup.new_tag("header", attrs={"class": "header-main"})
        header_left = soup.new_tag("div", attrs={"class": "header-left"})
        
        for elem in header_left_elements:
            if elem.parent:
                elem.extract()
            header_left.append(elem)
        header_main.append(header_left)

        if args.photo:
            header_right = soup.new_tag("div", attrs={"class": "header-right"})
            img_tag = soup.new_tag("img", attrs={
                "src": args.photo,
                "alt": "Profile Photo",
                "class": "profile-photo"
            })
            header_right.append(img_tag)
            header_main.append(header_right)

        soup.clear()
        soup.append(header_main)

        # Stage 4: Multi-Level Section Wrapping & Slugification
        nested_elements = []
        stack = []

        for elem in remaining_elements:
            if elem.name and elem.name in ["h1", "h2", "h3", "h4"]:
                level = int(elem.name[1])
                heading_text = elem.get_text()
                slug = slugify(heading_text)
                
                sec_tag = soup.new_tag("section", attrs={
                    "class": f"cv-section level-{level}",
                    "id": slug,
                    "data-title": heading_text
                })
                
                while stack and stack[-1][0] >= level:
                    stack.pop()
                
                sec_tag.append(elem)
                
                if stack:
                    stack[-1][1].append(sec_tag)
                else:
                    nested_elements.append(sec_tag)
                
                stack.append((level, sec_tag))
            else:
                if stack:
                    stack[-1][1].append(elem)
                else:
                    nested_elements.append(elem)

        for elem in nested_elements:
            soup.append(elem)

        # Stage 5: Generic Double-Pipe Splitter & Flex-Line Engine
        for node in soup.find_all(["h3", "h4", "p"]):
            if node.get_text() and "||" in node.get_text():
                raw_inner_html = "".join(str(c) for c in node.contents)
                if "||" in raw_inner_html:
                    left_html, right_html = raw_inner_html.split("||", 1)
                    left_html = left_html.strip()
                    right_html = right_html.strip()

                    left_span = soup.new_tag("span", attrs={"class": "line-left"})
                    left_soup = BeautifulSoup(left_html, "html.parser")
                    for child in list(left_soup.contents):
                        left_span.append(child)

                    right_span = soup.new_tag("span", attrs={"class": "line-right"})
                    right_soup = BeautifulSoup(right_html, "html.parser")
                    for child in list(right_soup.contents):
                        right_span.append(child)

                    node.clear()
                    node.append(left_span)
                    node.append(right_span)

                    classes = node.get("class", [])
                    if isinstance(classes, str):
                        classes = [classes]
                    if "flex-line" not in classes:
                        classes.append("flex-line")
                    node["class"] = classes

                    if node.name == "p":
                        node.name = "div"

        # Stage 6: Stylesheet Preparation & HTML Compilation
        stylesheets = ["/app/styles/default.css"] + args.style

        html_template = Template("""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>CV Document</title>
</head>
<body>
    {{ content }}
</body>
</html>
""")

        compiled_html = html_template.render(content=str(soup))

        # Stage 7: PDF Compilation via WeasyPrint with explicit CSS objects
        print("[cv-make-engine] Rendering PDF via WeasyPrint...", file=sys.stderr)
        
        css_objects = []
        for style_path in stylesheets:
            print(f"[cv-make-engine] Loading stylesheet: {style_path}", file=sys.stderr)
            css_objects.append(CSS(filename=style_path))

        pdf_doc = HTML(string=compiled_html, base_url="/app")
        pdf_doc.write_pdf(sys.stdout.buffer, stylesheets=css_objects)
        print("[cv-make-engine] PDF compilation completed successfully.", file=sys.stderr)

    except Exception as e:
        print(f"[ERROR] Engine compilation failed: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
