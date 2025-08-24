#!/bin/bash
# Clean up oc-mirror cache directory to reclaim storage space
# Use this after delete operations if storage space is needed

echo "🗂️  oc-mirror Cache Cleanup Utility"
echo "🎯 Target cache directory: .cache/"
echo ""

# Check if cache directory exists
if [ ! -d ".cache" ]; then
    echo "❌ No cache directory found (.cache/)"
    echo "💡 Cache may have already been cleaned or never created"
    exit 0
fi

# Show current cache size
echo "📊 Current cache analysis:"
CACHE_SIZE=$(du -sh .cache/ 2>/dev/null | cut -f1 || echo "Unknown")
CACHE_FILES=$(find .cache/ -type f 2>/dev/null | wc -l || echo "0")
echo "   • Size: $CACHE_SIZE"
echo "   • Files: $CACHE_FILES"
echo ""

echo "⚠️  WARNING: This will delete the entire cache directory!"
echo "Effects of cache cleanup:"
echo "   • ✅ Immediately reclaims ~$CACHE_SIZE of storage space"
echo "   • ✅ No impact on registry content (remains intact)"  
echo "   • ❗ Future oc-mirror operations will rebuild cache from scratch"
echo "   • ❗ First mirror operation after cleanup will be slower"
echo ""

echo "💡 Recommendations:"
echo "   • Keep cache if you plan frequent mirroring operations"
echo "   • Clean cache if storage space is critically needed"  
echo "   • Cache will rebuild automatically on next oc-mirror run"
echo ""

echo "⏰ CONFIRMATION REQUIRED"
echo "🛑 Press Ctrl+C to abort, or Enter to DELETE cache directory..."
read -r

echo ""
echo "🗑️ Removing cache directory..."
rm -rf .cache/

if [ $? -eq 0 ]; then
    echo "✅ Cache cleanup completed successfully!"
    echo "💾 Storage space reclaimed: ~$CACHE_SIZE"
    echo ""
    echo "💡 Next oc-mirror operation will rebuild cache automatically"
else
    echo "❌ Error occurred during cache cleanup"
    echo "🔍 Check permissions and try again"
    exit 1
fi
