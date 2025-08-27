#!/bin/bash
# Execute deletion of old OpenShift images using generated deletion plan
# WARNING: This will permanently delete images from your registry!

set -e

echo "🚨 DANGER: About to execute image deletion!"
echo "🎯 Target registry: $(hostname):8443"
echo "📄 Deletion plan: content/working-dir/delete/delete-images.yaml"
echo "⚠️  WARNING: This will PERMANENTLY DELETE images from registry!"
echo ""

# Verify deletion plan exists
if [ ! -f "content/working-dir/delete/delete-images.yaml" ]; then
    echo "❌ ERROR: Deletion plan not found!"
    echo "💡 Run ./oc-mirror-delete-generate.sh first to create deletion plan"
    exit 1
fi

echo "🔍 Deletion plan found - showing summary:"
echo "📊 Images to be deleted: $(grep -c 'imageName:' content/working-dir/delete/delete-images.yaml || echo 'Unable to count')"
echo "💾 Plan size: $(du -sh content/working-dir/delete/delete-images.yaml 2>/dev/null | cut -f1 || echo 'Unknown')"
echo ""

echo "⏰ FINAL CONFIRMATION REQUIRED"
echo "This operation will:"
echo "  • Delete OpenShift versions 4.19.2 through 4.19.6 from registry"
echo "  • Permanently remove image manifests and layers"
echo "  • Keep local cache (119GB) for performance - will NOT be automatically cleaned"
echo "  • Free up registry storage space (requires registry GC afterward)"
echo "  • Preserve current version 4.19.7 and later"
echo ""
echo "🛑 Press Ctrl+C now to abort, or Enter to proceed with deletion..."
read -r

echo ""
echo "🗑️ Executing deletion plan..."
echo "📊 This may take several minutes depending on registry size"
echo ""

# Execute deletion using the generated plan
oc mirror delete \
    --delete-yaml-file content/working-dir/delete/delete-images.yaml \
    docker://$(hostname):8443 \
    --v2 \
    --cache-dir .cache

echo ""
echo "✅ Deletion execution completed!"
echo "🧹 IMPORTANT: Run registry garbage collection to reclaim storage:"
echo "   • For Quay: Log into registry and run GC from admin panel"
echo "   • For mirror-registry: sudo podman exec -it quay-app /bin/bash -c 'registry-garbage-collect'"
echo ""
echo "💡 Next steps:"
echo "   • Verify deleted versions are gone: oc adm release info $(hostname):8443/openshift/release-images:4.19.2-x86_64"
echo "   • Check current version still works: oc adm release info $(hostname):8443/openshift/release-images:4.19.7-x86_64"
echo "   • Monitor registry storage usage: df -h /opt/quay/"
echo ""
echo "🗂️  Cache Management Options:"
echo "   • Cache size: $(du -sh .cache/ 2>/dev/null | cut -f1 || echo 'Unknown')"
echo "   • Keep cache for future operations (recommended for frequent mirroring)"
echo "   • Manual cleanup if space needed: rm -rf .cache/"
echo "   • Or add --force-cache-delete to this script for automatic cleanup"
