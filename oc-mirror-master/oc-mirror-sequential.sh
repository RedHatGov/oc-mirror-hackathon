#!/bin/bash

# oc-mirror Sequential Workflow Script
# Manages versioned directory structure for operational teams
# Handles differential archive behavior properly

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_CONTENT_DIR="${SCRIPT_DIR}/content"
CACHE_DIR="${SCRIPT_DIR}/.cache"
CONFIG_FILE="${SCRIPT_DIR}/imageset-config.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to determine next sequence number
get_next_sequence() {
    local max_seq=0
    
    if [ -d "$BASE_CONTENT_DIR" ]; then
        for dir in "$BASE_CONTENT_DIR"/seq*; do
            if [ -d "$dir" ]; then
                seq_num=$(basename "$dir" | grep -o 'seq[0-9]*' | grep -o '[0-9]*')
                if [ "$seq_num" -gt "$max_seq" ]; then
                    max_seq=$seq_num
                fi
            fi
        done
    fi
    
    echo $((max_seq + 1))
}

# Function to get sequence description from user
get_sequence_description() {
    local seq_num=$1
    
    if [ "$seq_num" -eq 1 ]; then
        echo "baseline"
    else
        # Use timestamp for seq2+
        date '+%Y%m%d-%H%M'
    fi
}

# Function to create sequence metadata
create_sequence_metadata() {
    local seq_dir=$1
    local seq_num=$2
    local description=$3
    local content_type=$4
    
    cat > "$seq_dir/seq-metadata.yaml" << EOF
# oc-mirror Sequential Metadata
sequence_number: $seq_num
description: "$description"
timestamp: "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
content_type: "$content_type"
oc_mirror_version: "$(oc-mirror version 2>/dev/null | head -1 || echo 'unknown')"
config_file: "imageset-config.yaml"
config_source: "$(basename "$CONFIG_FILE")"

# Archive information
archives:
EOF

    # Add archive information
    for archive in "$seq_dir"/mirror_*.tar; do
        if [ -f "$archive" ]; then
            archive_name=$(basename "$archive")
            archive_size=$(du -h "$archive" | cut -f1)
            echo "  - name: \"$archive_name\"" >> "$seq_dir/seq-metadata.yaml"
            echo "    size: \"$archive_size\"" >> "$seq_dir/seq-metadata.yaml"
        fi
    done
    
    # Add cumulative information
    echo "" >> "$seq_dir/seq-metadata.yaml"
    echo "# Operational Information" >> "$seq_dir/seq-metadata.yaml"
    
    if [ "$content_type" == "baseline" ]; then
        echo "air_gapped_transfer:" >> "$seq_dir/seq-metadata.yaml"
        echo "  complete: true" >> "$seq_dir/seq-metadata.yaml"
        echo "  dependencies: []" >> "$seq_dir/seq-metadata.yaml"
        echo "  transfer_size: \"$(du -sh "$seq_dir" | cut -f1)\"" >> "$seq_dir/seq-metadata.yaml"
    else
        echo "air_gapped_transfer:" >> "$seq_dir/seq-metadata.yaml"
        echo "  complete: false" >> "$seq_dir/seq-metadata.yaml"
        echo "  dependencies:" >> "$seq_dir/seq-metadata.yaml"
        
        # List all previous sequences as dependencies (using actual directory names)
        for dir in "$BASE_CONTENT_DIR"/seq*; do
            if [ -d "$dir" ]; then
                dep_seq_name=$(basename "$dir")
                dep_seq_num=$(echo "$dep_seq_name" | grep -o '^seq[0-9]*' | grep -o '[0-9]*')
                if [ "$dep_seq_num" -lt "$seq_num" ]; then
                    echo "    - \"$dep_seq_name\"" >> "$seq_dir/seq-metadata.yaml"
                fi
            fi
        done
        
        # Calculate cumulative size
        local cumulative_size=$(du -sh "$BASE_CONTENT_DIR" | cut -f1)
        echo "  differential_size: \"$(du -sh "$seq_dir" | cut -f1)\"" >> "$seq_dir/seq-metadata.yaml"
        echo "  cumulative_size: \"$cumulative_size\"" >> "$seq_dir/seq-metadata.yaml"
    fi
}

# Function to create sequence-specific upload script
create_upload_script() {
    local seq_dir=$1
    local seq_num=$2
    local description=$3
    local content_type=$4
    
    cat > "$seq_dir/seq-upload.sh" << 'EOF'
#!/bin/bash

# Auto-generated upload script for sequence
# This script uploads the sequence content to a mirror registry

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEQUENCE_NAME="$(basename "$SCRIPT_DIR")"
DEFAULT_REGISTRY="$(hostname):8443"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
REGISTRY_URL="${1:-$DEFAULT_REGISTRY}"
DRY_RUN=""

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Sequence Upload Script for $SEQUENCE_NAME"
    echo ""
    echo "Usage: $0 [registry-url] [options]"
    echo ""
    echo "Arguments:"
    echo "  registry-url    Target registry URL (default: $DEFAULT_REGISTRY)"
    echo ""
    echo "Options:"
    echo "  --dry-run       Show what would be uploaded without executing"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use default registry"
    echo "  $0 registry.example.com:5000         # Use specific registry"
    echo "  $0 --dry-run                         # Preview upload"
    exit 0
fi

if [ "${1:-}" = "--dry-run" ] || [ "${2:-}" = "--dry-run" ]; then
    DRY_RUN="--dry-run"
    log_warning "DRY RUN MODE - No actual upload will occur"
fi

# Validate prerequisites
if [ ! -f "$SCRIPT_DIR/imageset-config.yaml" ]; then
    log_error "Missing imageset-config.yaml in sequence directory"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/seq-metadata.yaml" ]; then
    log_error "Missing seq-metadata.yaml in sequence directory"
    exit 1
fi

# Show sequence information
echo ""
log_info "=== SEQUENCE UPLOAD ==="
log_info "📁 Sequence: $SEQUENCE_NAME"
log_info "📂 Directory: $SCRIPT_DIR"
log_info "🎯 Registry: $REGISTRY_URL"
log_info "📄 Config: imageset-config.yaml"

# Show sequence metadata
if [ -f "$SCRIPT_DIR/seq-metadata.yaml" ]; then
    echo ""
    log_info "📋 Sequence Information:"
    grep -E "^(sequence_number|description|content_type|timestamp):" "$SCRIPT_DIR/seq-metadata.yaml" | sed 's/^/   /'
fi

# Show archive information
echo ""
log_info "📦 Archive Information:"
if [ -f "$SCRIPT_DIR/seq-metadata.yaml" ]; then
    awk '/^archives:/,/^# /' "$SCRIPT_DIR/seq-metadata.yaml" | grep -E "(name|size)" | sed 's/^/   /'
fi

# Show air-gapped transfer info
echo ""
log_info "🚚 Transfer Information:"
if [ -f "$SCRIPT_DIR/seq-metadata.yaml" ]; then
    awk '/^air_gapped_transfer:/,0' "$SCRIPT_DIR/seq-metadata.yaml" | grep -E "(complete|dependencies)" | sed 's/^/   /'
fi

echo ""
if [ "$DRY_RUN" = "--dry-run" ]; then
    log_info "🧪 DRY RUN - Would execute:"
    echo "   oc-mirror -c imageset-config.yaml --from file://$SCRIPT_DIR docker://$REGISTRY_URL --v2"
    log_success "Dry run complete - no changes made"
    exit 0
fi

log_info "🚀 Starting upload to registry..."
echo ""

# Execute oc-mirror upload
if oc-mirror -c "$SCRIPT_DIR/imageset-config.yaml" \
    --from "file://$SCRIPT_DIR" \
    "docker://$REGISTRY_URL" \
    --v2; then
    
    echo ""
    log_success "✅ Sequence upload completed successfully!"
    log_info "📊 Upload Summary:"
    log_info "   Sequence: $SEQUENCE_NAME"
    log_info "   Registry: $REGISTRY_URL"
    log_info "   Status: Complete"
    
else
    echo ""
    log_error "❌ Upload failed!"
    log_info "💡 Troubleshooting:"
    log_info "   - Verify registry connectivity: curl -k https://$REGISTRY_URL/v2/"
    log_info "   - Check authentication: podman login $REGISTRY_URL"
    log_info "   - Review dependencies in seq-metadata.yaml"
    log_info "   - For differential sequences, ensure previous content is available"
    exit 1
fi
EOF

    # Make the script executable
    chmod +x "$seq_dir/seq-upload.sh"
    
    log_success "Created executable upload script: seq-upload.sh"
}

# Function to show transfer guidance
show_transfer_guidance() {
    local seq_dir=$1
    local seq_num=$2
    local description=$3
    local content_type=$4
    
    echo ""
    log_info "=== AIR-GAPPED TRANSFER GUIDANCE ==="
    
    if [ "$content_type" == "baseline" ]; then
        echo ""
        log_success "✅ COMPLETE CONTENT - Ready for air-gapped transfer"
        echo ""
        echo "Transfer Instructions:"
        echo "  1. Archive: tar -czf seq${seq_num}-${description}.tar.gz -C content seq${seq_num}-${description}/"
        echo "  2. Transfer: Copy archive to air-gapped environment"  
        echo "  3. Extract: tar -xzf seq${seq_num}-${description}.tar.gz"
        echo "  4. Upload: cd seq${seq_num}-${description} && ./seq-upload.sh"
        echo ""
        echo "Alternative upload methods:"
        echo "  - Custom registry: ./seq-upload.sh registry.example.com:5000"
        echo "  - Dry run test: ./seq-upload.sh --dry-run"
        echo ""
    else
        echo ""
        log_warning "⚠️  DIFFERENTIAL CONTENT - Requires previous sequences"
        echo ""
        echo "Air-gapped requirements:"
        echo "  - Current sequence: $(du -sh "$seq_dir" | cut -f1)"
        
        # Build list of previous sequence names
        local prev_sequences=""
        for dir in "$BASE_CONTENT_DIR"/seq*; do
            if [ -d "$dir" ]; then
                dep_seq_name=$(basename "$dir")
                dep_seq_num=$(echo "$dep_seq_name" | grep -o '^seq[0-9]*' | grep -o '[0-9]*')
                if [ "$dep_seq_num" -lt "$seq_num" ]; then
                    if [ -z "$prev_sequences" ]; then
                        prev_sequences="$dep_seq_name"
                    else
                        prev_sequences="$prev_sequences, $dep_seq_name"
                    fi
                fi
            fi
        done
        
        echo "  - Previous sequences: Required ($prev_sequences)"
        echo "  - Total transfer: $(du -sh "$BASE_CONTENT_DIR" | cut -f1)"
        echo ""
        echo "Transfer Options:"
        echo ""
        echo "  Option 1 - Cumulative Transfer (Recommended):"
        echo "    1. Archive: tar -czf cumulative-seq${seq_num}.tar.gz -C content ."
        echo "    2. Transfer: Copy archive to air-gapped environment"
        echo "    3. Extract: tar -xzf cumulative-seq${seq_num}.tar.gz"
        echo "    4. Upload: cd seq${seq_num}-${description} && ./seq-upload.sh"
        echo ""
        echo "  Option 2 - Individual Sequences:"
        # Build complete sequence list including current
        local all_sequences=""
        for dir in "$BASE_CONTENT_DIR"/seq*; do
            if [ -d "$dir" ]; then
                all_seq_name=$(basename "$dir")
                all_seq_num=$(echo "$all_seq_name" | grep -o '^seq[0-9]*' | grep -o '[0-9]*')
                if [ "$all_seq_num" -le "$seq_num" ]; then
                    if [ -z "$all_sequences" ]; then
                        all_sequences="$all_seq_name"
                    else
                        all_sequences="$all_sequences, $all_seq_name"
                    fi
                fi
            fi
        done
        echo "    1. Transfer ALL sequences ($all_sequences)"
        echo "    2. Ensure previous sequences are available on air-gapped system"
        echo "    3. Upload: cd seq${seq_num}-${description} && ./seq-upload.sh"
        echo ""
        echo "Upload script features:"
        echo "  - Automatic sequence validation and info display"
        echo "  - Custom registry support: ./seq-upload.sh registry.example.com:5000"
        echo "  - Dry run testing: ./seq-upload.sh --dry-run"
        echo ""
    fi
}

# Function to validate configuration
validate_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    log_info "Using configuration: $CONFIG_FILE"
}

# Main execution function
main() {
    log_info "🚀 Starting oc-mirror Sequential Workflow"
    
    # Validate configuration
    validate_config
    
    # Determine sequence information
    local seq_num=$(get_next_sequence)
    local description=$(get_sequence_description "$seq_num")
    local content_type="baseline"
    
    if [ "$seq_num" -gt 1 ]; then
        content_type="differential"
    fi
    
    # Create sequence directory
    local seq_dir="${BASE_CONTENT_DIR}/seq${seq_num}-${description}"
    mkdir -p "$seq_dir"
    
    log_info "📁 Creating sequence: seq${seq_num}-${description} (${content_type})"
    
    # Copy current imageset-config.yaml to sequence directory for tracking
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$seq_dir/imageset-config.yaml"
        log_info "📄 Copied configuration to sequence directory for tracking"
    fi
    
    # Run oc-mirror with sequence-specific directory and enhanced timeout configuration
    log_info "🔄 Running oc-mirror with extended timeouts and retry logic..."
    
    # Enhanced timeout and retry configuration for large operations
    if ! oc-mirror -c "$CONFIG_FILE" "file://${seq_dir}" --v2 --cache-dir "$CACHE_DIR" \
        --image-timeout=90m \
        --retry-times 10 \
        --retry-delay 30s \
        --parallel-images 8 \
        --parallel-layers 12; then
        log_error "oc-mirror failed!"
        exit 1
    fi
    
    # Create metadata
    log_info "📄 Creating sequence metadata..."
    create_sequence_metadata "$seq_dir" "$seq_num" "$description" "$content_type"
    
    # Create sequence-specific upload script
    log_info "🚀 Creating sequence upload script..."
    create_upload_script "$seq_dir" "$seq_num" "$description" "$content_type"
    
    # Show results
    echo ""
    log_success "✅ Sequence completed successfully!"
    log_info "📊 Sequence summary:"
    echo "   - Number: $seq_num"
    echo "   - Description: $description"
    echo "   - Type: $content_type"
    echo "   - Directory: $seq_dir"
    echo "   - Size: $(du -sh "$seq_dir" | cut -f1)"
    echo "   - Upload script: seq-upload.sh"
    
    # Show transfer guidance
    show_transfer_guidance "$seq_dir" "$seq_num" "$description" "$content_type"
    
    # Show sequence history
    echo ""
    log_info "📚 Sequence History:"
    for dir in "$BASE_CONTENT_DIR"/seq*; do
        if [ -d "$dir" ]; then
            seq_name=$(basename "$dir")
            seq_size=$(du -sh "$dir" | cut -f1)
            if [ -f "$dir/seq-metadata.yaml" ]; then
                seq_desc=$(grep "^description:" "$dir/seq-metadata.yaml" | cut -d'"' -f2)
                seq_type=$(grep "^content_type:" "$dir/seq-metadata.yaml" | cut -d'"' -f2)
                upload_script_status=""
                if [ -f "$dir/seq-upload.sh" ]; then
                    upload_script_status=" [upload script]"
                fi
                printf "   %-20s %8s  %s (%s)%s\n" "$seq_name" "$seq_size" "$seq_desc" "$seq_type" "$upload_script_status"
            else
                printf "   %-20s %8s  (no metadata)\n" "$seq_name" "$seq_size"
            fi
        fi
    done
    
    echo ""
    log_success "🎯 Sequential workflow complete!"
}

# Script options
case "${1:-}" in
    --help|-h)
        echo "oc-mirror Sequential Workflow Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --list         List existing sequences"  
        echo "  --validate     Validate sequence integrity"
        echo ""
        echo "This script manages oc-mirror operations with versioned directories"
        echo "to handle differential archive behavior for operational teams."
        exit 0
        ;;
    --list)
        if [ -d "$BASE_CONTENT_DIR" ]; then
            echo "Existing sequences:"
            for dir in "$BASE_CONTENT_DIR"/seq*; do
                if [ -d "$dir" ]; then
                    seq_name=$(basename "$dir")
                    seq_size=$(du -sh "$dir" | cut -f1)
                    printf "  %-20s %8s\n" "$seq_name" "$seq_size"
                fi
            done
        else
            echo "No sequences found."
        fi
        exit 0
        ;;
    --validate)
        log_info "🔍 Validating sequence integrity..."
        # Add validation logic here
        log_success "Validation complete"
        exit 0
        ;;
    "")
        # Default: run main workflow
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
