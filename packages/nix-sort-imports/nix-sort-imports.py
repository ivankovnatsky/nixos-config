#!/usr/bin/env python3
import re
import sys
import os


def sort_imports_block(match):
    prefix = match.group(1)  # "imports = ["
    imports_text = match.group(2)
    suffix = match.group(3)  # "];"

    lines = imports_text.split("\n")

    elements = []  # List of (type, content) where type is 'import' or 'other'
    current_import = []
    depth = 0

    for line in lines:
        stripped = line.strip()

        if depth == 0:
            # Standalone comments or empty lines
            if not stripped or stripped.startswith("#") or stripped.startswith("/*"):
                elements.append(("other", line))
                continue

            # Start of a new import element
            current_import.append(line)
            depth += line.count("{") - line.count("}")

            if depth == 0:
                elements.append(("import", "\n".join(current_import)))
                current_import = []
        else:
            # We are inside a nested block ({ ... })
            current_import.append(line)
            depth += line.count("{") - line.count("}")

            if depth == 0:
                elements.append(("import", "\n".join(current_import)))
                current_import = []

    # Safety: if depth != 0, it's unbalanced (invalid Nix or regex overshoot)
    if depth != 0 or current_import:
        return match.group(0)

    # Sort only 'import' elements
    imports_only = [e for e in elements if e[0] == "import"]
    # Sort by the content of the first line (usually the path or '{')
    imports_only.sort(key=lambda x: x[1].strip().lower())

    # Reconstruct the block preserving 'other' (comments/whitespace) in their relative positions
    result = []
    import_idx = 0
    for e_type, e_content in elements:
        if e_type == "import":
            result.append(imports_only[import_idx][1])
            import_idx += 1
        else:
            result.append(e_content)

    return f"{prefix}{'\n'.join(result)}{suffix}"


def sort_file(file_path):
    with open(file_path, "r") as f:
        content = f.read()

    # Regex for imports = [ ... ];
    pattern = r"(imports\s*=\s*\[)(.*?)(\s*\];)"
    new_content = re.sub(pattern, sort_imports_block, content, flags=re.DOTALL)

    if new_content != content:
        with open(file_path, "w") as f:
            f.write(new_content)
        return True
    return False


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        if os.path.isfile(arg):
            sort_file(arg)
