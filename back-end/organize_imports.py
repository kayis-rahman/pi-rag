#!/usr/bin/env python3
import os
import re
import sys

def organize_java_imports(filepath):
    """Organize imports in a Java file according to standard conventions."""
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Find package line
    package_line = None
    for i, line in enumerate(lines):
        if line.strip().startswith('package '):
            package_line = i
            break
    
    if package_line is None:
        return  # No package declaration found
    
    # Find all import lines
    imports = []
    import_start = None
    import_end = None
    
    for i, line in enumerate(lines):
        if line.strip().startswith('import '):
            if import_start is None:
                import_start = i
            import_end = i
            imports.append(line.strip())
    
    if not imports:
        return  # No imports to organize
    
    # Categorize imports
    java_imports = sorted([imp for imp in imports if imp.startswith('import java.')])
    javax_imports = sorted([imp for imp in imports if imp.startswith('import javax.')])
    third_party_imports = sorted([imp for imp in imports if 
                                 imp.startswith('import org.') or
                                 imp.startswith('import com.fasterxml.') or
                                 imp.startswith('import io.') or
                                 imp.startswith('import jakarta.')])
    project_imports = sorted([imp for imp in imports if imp.startswith('import com.sparkage.')])
    static_imports = sorted([imp for imp in imports if imp.startswith('import static ')])
    
    # Build new content
    new_lines = lines[:package_line + 1]  # Include package line
    new_lines.append('\n')
    
    # Add organized imports with blank lines between groups
    for group in [java_imports, javax_imports, third_party_imports, project_imports, static_imports]:
        if group:
            new_lines.extend(line + '\n' for line in group)
            new_lines.append('\n')
    
    # Find where the class/interface/enum starts
    class_start = None
    for i in range(import_end + 1, len(lines)):
        line = lines[i].strip()
        if line.startswith(('public ', 'class ', 'interface ', 'enum ', 'abstract ', 'final ')) or \
           (line and not line.startswith('//') and not line.startswith('/*') and not line.startswith('*') and not line.startswith('import ')):
            class_start = i
            break
    
    if class_start is not None:
        new_lines.extend(lines[class_start:])
    else:
        # Fallback: add everything after imports
        new_lines.extend(lines[import_end + 1:])
    
    # Write back to file
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

def main():
    # Find all Java files
    for root, dirs, files in os.walk('src'):
        for file in files:
            if file.endswith('.java'):
                filepath = os.path.join(root, file)
                print(f"Organizing imports in {filepath}")
                try:
                    organize_java_imports(filepath)
                except Exception as e:
                    print(f"Error processing {filepath}: {e}")

if __name__ == '__main__':
    main()
