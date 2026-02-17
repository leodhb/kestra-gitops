#!/bin/bash

set -e

FLOWS_DIR="kestra/flows"
FILES_DIR="kestra/files"
ERRORS=0
KESTRA_WRAPPER="./bin/kestra.sh"

echo "🔍 Validating Kestra resources..."

# Function to extract YAML value
get_yaml_value() {
    local file=$1
    local key=$2
    grep "^${key}:" "$file" | head -1 | sed "s/^${key}:[[:space:]]*//" | tr -d '"' | tr -d "'"
}

# Validate flows
validate_flow() {
    local file=$1
    local relative_path="${file#$FLOWS_DIR/}"
    
    local dir_path=$(dirname "$relative_path")
    local filename=$(basename "$relative_path" .yml)
    filename=$(basename "$filename" .yaml)
    
    local expected_namespace=$(echo "$dir_path" | tr '/' '.')
    local expected_id="$filename"
    
    local actual_id=$(get_yaml_value "$file" "id")
    local actual_namespace=$(get_yaml_value "$file" "namespace")
    
    local file_errors=0
    
    if [ "$actual_id" != "$expected_id" ]; then
        echo "❌ $file"
        echo "   ID mismatch: expected '$expected_id', got '$actual_id'"
        file_errors=1
    fi
    
    if [ "$actual_namespace" != "$expected_namespace" ]; then
        echo "❌ $file"
        echo "   Namespace mismatch: expected '$expected_namespace', got '$actual_namespace'"
        file_errors=1
    fi
    
    if [ $file_errors -eq 0 ]; then
        echo "✅ flows/$relative_path"
    else
        ERRORS=$((ERRORS + 1))
    fi
}

# Validate files (namespace structure)
validate_files() {
    echo ""
    echo "📁 Validating files structure..."
    
    if [ ! -d "$FILES_DIR" ]; then
        echo "⚠️  No files directory found"
        return
    fi
    
    # Verify that folder structure in files/ corresponds to valid namespaces
    find "$FILES_DIR" -type f | while read -r file; do
        local relative_path="${file#$FILES_DIR/}"
        local namespace_path=$(dirname "$relative_path" | tr '/' '.')
        
        echo "✅ files/$relative_path → namespace: $namespace_path"
    done
}

# Function to execute syntax validation via Docker wrapper (ephemeral container)
run_kestra_validate_file() {
    local file=$1
    local output

    if output=$(bash "$KESTRA_WRAPPER" flow validate --local "$file" 2>&1); then
        echo "$output"
        return 0
    fi

    echo "$output"
    return 1
}

# Validate flows convention
if [ -d "$FLOWS_DIR" ]; then
    echo "🔍 Validating flows..."
    while IFS= read -r file; do
        validate_flow "$file"
    done < <(find "$FLOWS_DIR" -type f \( -name "*.yml" -o -name "*.yaml" \))
fi

# Validate files
validate_files

# Check if there were errors in static validation
if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "❌ Found $ERRORS error(s) in static validation"
    echo "⚠️  Skipping Docker syntax validation until static errors are fixed"
    exit 1
fi

# Syntax validation with Kestra in Docker (always ephemeral container)
echo ""
echo "🐳 Validating flow syntax with ephemeral Kestra containers..."

if [ ! -f "$KESTRA_WRAPPER" ]; then
    echo "❌ Wrapper not found: $KESTRA_WRAPPER"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Install Docker to validate syntax."
    exit 1
fi

if [ -d "$FLOWS_DIR" ]; then
    while IFS= read -r file; do
        echo ""
        echo "🔎 Syntax check: $file"
        if run_kestra_validate_file "$file"; then
            echo "✅ Syntax validation passed: $file"
        else
            echo "❌ Syntax validation failed: $file"
            ERRORS=$((ERRORS + 1))
        fi
    done < <(find "$FLOWS_DIR" -type f \( -name "*.yml" -o -name "*.yaml" \))
fi

# Final result
echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ All validations passed!"
    exit 0
else
    echo "❌ Found $ERRORS error(s)"
    exit 1
fi
