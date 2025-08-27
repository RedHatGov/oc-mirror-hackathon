#!/bin/bash
# Mirror content directly from registry to registry (semi-connected flow)
# Bypasses disk storage - direct registry-to-registry mirroring

set -e

echo "🔄 Mirroring content directly to registry..."
echo "🎯 Target: docker://$(hostname):8443 (direct registry)"
echo "📋 Config: imageset-config.yaml"
echo ""

# Direct mirror from source registry to target registry
oc-mirror -c imageset-config.yaml \
    --workspace file://content \
    docker://$(hostname):8443 \
    --v2 \
    --cache-dir .cache

echo ""
echo "✅ Direct mirror to registry complete!"
echo "🗃️ Content mirrored to: $(hostname):8443"
echo "💾 Cache created at: .cache/"
echo "🌐 Registry accessible at: https://$(hostname):8443"
echo ""
echo "💡 Next steps:"
echo "   • Verify content: Browse https://$(hostname):8443"
echo "   • Use for OpenShift installations or upgrades"
echo "   • Use IDMS/ITMS for cluster configuration"
