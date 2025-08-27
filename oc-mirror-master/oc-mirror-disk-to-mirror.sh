#!/bin/bash
# Upload mirrored content to registry
# Cache will be created fresh on this host - no cache transfer needed!

set -e

echo "🚀 Uploading mirrored content to registry..."
echo "📊 Content size: $(du -sh content/ 2>/dev/null | cut -f1 || echo 'Unknown')"
echo "📋 All necessary metadata is in content/working-dir/"
echo "🏷️  Target registry: $(hostname):8443"
echo ""

# oc-mirror will create cache as needed - content has all the metadata
oc-mirror -c imageset-config.yaml \
    --from file://content \
    docker://$(hostname):8443 \
    --v2 \
    --cache-dir .cache

echo ""
echo "✅ Upload complete!"
echo "✨ Fresh cache created locally for future operations"
