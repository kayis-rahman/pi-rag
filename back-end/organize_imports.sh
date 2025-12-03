#!/bin/bash

# Function to organize imports in a Java file
organize_java_imports() {
    local file="$1"
    
    # Create a temporary file
    temp_file=$(mktemp)
    
    # Extract package declaration
    package_line=$(grep "^package " "$file")
    
    # Extract all import lines
    import_lines=$(grep "^import " "$file")
    
    # Separate different types of imports
    java_imports=$(echo "$import_lines" | grep "^import java\." | sort)
    javax_imports=$(echo "$import_lines" | grep "^import javax\." | sort)
    third_party_imports=$(echo "$import_lines" | grep "^import org\.\|^import com\.fasterxml\.\|^import io\.\|^import jakarta\." | sort)
    project_imports=$(echo "$import_lines" | grep "^import com\.sparkage\." | sort)
    static_imports=$(echo "$import_lines" | grep "^import static " | sort)
    
    # Extract the rest of the file (everything after imports)
    rest_of_file=$(sed -n '/^import /d; /^$/d; /^package /d; 1,/^package /d; /^import /d; p' "$file" | sed -n '/^public\|^class\|^interface\|^enum/,$p')
    
    # Write organized file
    echo "$package_line" > "$temp_file"
    echo "" >> "$temp_file"
    
    # Add java imports
    if [ -n "$java_imports" ]; then
        echo "$java_imports" >> "$temp_file"
        echo "" >> "$temp_file"
    fi
    
    # Add javax imports
    if [ -n "$javax_imports" ]; then
        echo "$javax_imports" >> "$temp_file"
        echo "" >> "$temp_file"
    fi
    
    # Add third-party imports
    if [ -n "$third_party_imports" ]; then
        echo "$third_party_imports" >> "$temp_file"
        echo "" >> "$temp_file"
    fi
    
    # Add project imports
    if [ -n "$project_imports" ]; then
        echo "$project_imports" >> "$temp_file"
        echo "" >> "$temp_file"
    fi
    
    # Add static imports
    if [ -n "$static_imports" ]; then
        echo "$static_imports" >> "$temp_file"
        echo "" >> "$temp_file"
    fi
    
    # Add the rest of the file
    echo "$rest_of_file" >> "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$file"
}

# Find and process all Java files
find src -name "*.java" -type f | while read -r file; do
    echo "Organizing imports in $file"
    organize_java_imports "$file"
done

echo "Import organization complete!"
