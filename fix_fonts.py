import re

with open('c:/Users/akula/Desktop/PROJECTS/DieselTechnicalSolutions/dts/lib/services/pdf_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Fix ThemeData for Estimate
content = re.sub(
    r"final normalFont = pw\.Font\.ttf\(await rootBundle\.load\('assets/fonts/roboto1\.ttf'\)\);\s*final pdf = pw\.Document\(\s*theme: pw\.ThemeData\.withFont\(\s*base: normalFont,\s*bold: normalFont,\s*italic: normalFont,\s*boldItalic: normalFont,\s*\),\s*\);",
    r"final rupeeFont = pw.Font.ttf(await rootBundle.load('assets/fonts/roboto1.ttf'));\n    final pdf = pw.Document();",
    content
)

def replace_rupee_style(match):
    text = match.group(1)
    style = match.group(2)
    # add fontFallback: [rupeeFont] to style
    if 'fontFallback' not in style:
        if 'pw.TextStyle(' in style:
            style = style.replace('pw.TextStyle(', 'pw.TextStyle(fontFallback: [rupeeFont], ')
        elif 'const pw.TextStyle(' in style:
            style = style.replace('const pw.TextStyle(', 'pw.TextStyle(fontFallback: [rupeeFont], ')
    return f"pw.Text({text}, {style})"

# This regex matches pw.Text('...₹...', ...) or pw.Text("...₹...", ...) and extracts the text and style.
content = re.sub(r"pw\.Text\(([^,]+?₹[^,]+?),\s*(.*?style:\s*(?:const\s*)?pw\.TextStyle\([^)]+\))\)", replace_rupee_style, content)

with open('c:/Users/akula/Desktop/PROJECTS/DieselTechnicalSolutions/dts/lib/services/pdf_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated fonts.')
