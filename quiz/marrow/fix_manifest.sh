#!/bin/bash

# Script to correct manifest.json file based on actual JSON files in subject directories
# Run this script from the quiz/marrow directory

# Backup the original manifest
cp manifest.json manifest.json.backup

# Define all subject directories
subjects=("anatomy" "biochemistry" "physiology" "pathology" "pharmacology" "microbiology" "fmt" "psm" "ophthalmology" "ent" "medicine" "surgery" "pediatrics" "obgy" "psychiatry" "radiology" "orthopedics" "anaesthesia" "dermatology")

# Process each subject
for subject in "${subjects[@]}"; do
    echo "Processing $subject..."
    
    # Check if subject directory exists
    if [ ! -d "$subject" ]; then
        echo "Directory $subject not found, skipping..."
        continue
    fi
    
    # Get all JSON files in the subject directory
    json_files=($(find "$subject" -name "*.json" -type f | sed 's|^.*/||'))
    
    # Create a temporary file for the corrected manifest section
    temp_file=$(mktemp)
    
    # Extract the current subject section from manifest
    jq -r ".$subject[] | \"\(.name)|\(.file)\"" manifest.json > "$temp_file"
    
    # Process each line and correct the filename
    while IFS='|' read -r name current_file; do
        # Skip empty lines
        if [ -z "$name" ]; then
            continue
        fi
        
        # Generate expected filename pattern from the name
        expected_pattern=$(echo "$name" | 
            tr '[:upper:]' '[:lower:]' | 
            sed -e 's/ and /_/g' -e 's/ of /_/g' -e 's/ & /_/g' -e 's/ /_/g' -e 's/,//g' -e 's/__*/_/g')
        
        # Find the matching JSON file
        matched_file=""
        for json_file in "${json_files[@]}"; do
            json_pattern=$(echo "$json_file" | 
                tr '[:upper:]' '[:lower:]' | 
                sed 's/\.json$//')
            
            if [ "$json_pattern" = "$expected_pattern" ]; then
                matched_file="$json_file"
                break
            fi
        done
        
        # If no match found, try fuzzy matching
        if [ -z "$matched_file" ]; then
            for json_file in "${json_files[@]}"; do
                json_pattern=$(echo "$json_file" | 
                    tr '[:upper:]' '[:lower:]' | 
                    sed 's/\.json$//')
                
                # Use Levenshtein distance for fuzzy matching (simplified)
                if [ $(echo "$json_pattern" | grep -c "$expected_pattern") -gt 0 ] || 
                   [ $(echo "$expected_pattern" | grep -c "$json_pattern") -gt 0 ]; then
                    matched_file="$json_file"
                    break
                fi
            done
        fi
        
        # Output the corrected entry
        if [ -n "$matched_file" ]; then
            echo "    { \"name\": \"$name\", \"file\": \"$matched_file\" },"
        else
            echo "    { \"name\": \"$name\", \"file\": \"$current_file\" },"
            echo "    # WARNING: No matching JSON file found for: $name" >&2
        fi
    done < "$temp_file" > "${temp_file}_corrected"
    
    # Replace the section in the manifest (this part would need jq or sed magic)
    # For simplicity, we'll create a new manifest file
    if [ "$subject" = "anatomy" ]; then
        echo "{" > manifest_corrected.json
        echo "  \"$subject\": [" >> manifest_corrected.json
        cat "${temp_file}_corrected" | sed '$ s/,$//' >> manifest_corrected.json
        echo "  ]," >> manifest_corrected.json
    else
        echo "  \"$subject\": [" >> manifest_corrected.json
        cat "${temp_file}_corrected" | sed '$ s/,$//' >> manifest_corrected.json
        echo "  ]," >> manifest_corrected.json
    fi
    
    # Clean up
    rm "$temp_file" "${temp_file}_corrected"
done

# Finish the JSON file
sed -i '$ s/,$//' manifest_corrected.json
echo "}" >> manifest_corrected.json

echo "Correction complete. Check manifest_corrected.json"
echo "Original manifest backed up as manifest.json.backup"
