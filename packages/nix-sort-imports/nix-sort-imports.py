#!/usr/bin/env python3
import re
import sys
import os

def sort_imports_block(match):
    prefix = match.group(1)   # "imports = ["
    imports_text = match.group(2)
    suffix = match.group(3)   # "];"
    
    # SAFETY: If the block contains nested braces, it's likely a complex attribute set.
    # We don't want to sort those as individual lines because they span multiple lines.
    if '{' in imports_text or '}' in imports_text:
        return match.group(0)

    lines = imports_text.split('\n')
    
    import_lines = []
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith('#') or stripped.startswith('/*'):
            continue
        import_lines.append(line)
            
    if not import_lines:
        return match.group(0)
        
    # Sort by stripped path, case-insensitive
    import_lines.sort(key=lambda x: x.strip().lower())
    
    # Reconstruct the block
    result_lines = []
    import_idx = 0
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith('#') or stripped.startswith('/*'):
            result_lines.append(line)
        else:
            result_lines.append(import_lines[import_idx])
            import_idx += 1
            
    return f"{prefix}{'\n'.join(result_lines)}{suffix}"

def sort_file(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Regex for imports = [ ... ];
    # Use re.DOTALL to match across multiple lines
    pattern = r'(imports\s*=\s*\[)(.*?)(\s*\];)'
    new_content = re.sub(pattern, sort_imports_block, content, flags=re.DOTALL)
    
    if new_content != content:
        with open(file_path, 'w') as f:
            f.write(new_content)
        return True
    return False

if __name__ == "__main__":
    for arg in sys.argv[1:]:
        if os.path.isfile(arg):
            sort_file(arg)
