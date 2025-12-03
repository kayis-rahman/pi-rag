#!/usr/bin/env python3
import os
import re

def organize_swift_imports(filepath):
    """Organize imports in a Swift file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    
    # Find all import lines (including conditional ones)
    imports = []
    non_imports = []
    
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        
        # Check for import statements
        if line.startswith('import '):
            # Handle multi-line imports (rare but possible)
            import_lines = [line]
            j = i + 1
            while j < len(lines) and (lines[j].strip().startswith('//') or lines[j].strip() == ''):
                import_lines.append(lines[j])
                j += 1
            
            imports.append('\n'.join(import_lines))
            i = j
        else:
            non_imports.append(lines[i])
            i += 1
    
    if not imports:
        return  # No imports to organize
    
    # For Swift, we mainly want to sort imports alphabetically
    # but preserve conditional compilation blocks
    sorted_imports = sorted(imports, key=lambda x: x.lower())
    
    # Reconstruct file
    new_content = '\n'.join(sorted_imports) + '\n\n' + '\n'.join(non_imports)
    
    # Clean up extra blank lines
    new_content = re.sub(r'\n\n\n+', '\n\n', new_content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

def main():
    # Find all Swift files
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.endswith('.swift'):
                filepath = os.path.join(root, file)
                print(f"Checking {filepath}")
                
                # Only process files that have imports
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                        if 'import ' in content:
                            print(f"Organizing imports in {filepath}")
                            organize_swift_imports(filepath)
                except Exception as e:
                    print(f"Error processing {filepath}: {e}")

if __name__ == '__main__':
    main()
