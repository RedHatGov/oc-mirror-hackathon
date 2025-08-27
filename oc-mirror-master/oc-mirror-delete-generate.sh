#!/bin/bash
# Generate deletion plan for old OpenShift images
# Creates reviewable deletion plan without executing any deletions (SAFE!)

set -e

echo "🗑️ Generating deletion plan for old images..."
echo "🎯 Target registry: $(hostname):8443"
echo "📋 Config: imageset-delete.yaml"
echo "📁 Workspace: file://content (original mirror workspace)"
echo "⚠️  SAFE MODE: No deletions will be executed"
echo ""

# Generate deletion plan (safe preview - no actual deletion occurs)
oc mirror delete \
    -c imageset-delete.yaml \
    --generate \
    --workspace file://content \
    docker://$(hostname):8443 \
    --v2 \
    --cache-dir .cache

echo ""
echo "✅ Deletion plan generated successfully!"
echo "📄 Plan saved to: content/working-dir/delete/delete-images.yaml"
echo "🔍 IMPORTANT: Review the deletion plan before executing!"
echo ""
echo "💡 Next steps:"
echo "   • Review plan: cat content/working-dir/delete/delete-images.yaml"
echo "   • Execute deletion: ./oc-mirror-delete-execute.sh"
echo "   • Or manually: oc mirror delete --delete-yaml-file content/working-dir/delete/delete-images.yaml docker://$(hostname):8443 --v2 --cache-dir .cache"
