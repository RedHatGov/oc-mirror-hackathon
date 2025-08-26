#!/bin/bash
# Mirror content from registry to local disk storage
# Creates content/ directory with all images and metadata

echo "📥 Mirroring content from registry to disk..."
echo "🎯 Target: file://content (local disk storage)"
echo "📋 Config: imageset-config.yaml"
echo ""

# Create content directory structure and cache
oc-mirror -c imageset-config.yaml \
    file://content \
    --v2 \
    --cache-dir .cache

echo ""
echo "✅ Mirror to disk complete!"
echo "📁 Content saved to: content/"
echo "💾 Cache created at: .cache/"
echo "📦 Ready for transfer to disconnected environment"
echo ""
echo "💡 Next steps:"
echo "   • Archive: tar -czf content.tar.gz content/"
echo "   • Transfer content.tar.gz to disconnected system"  
echo "   • Upload with: ./oc-mirror-disk-to-mirror.sh"
