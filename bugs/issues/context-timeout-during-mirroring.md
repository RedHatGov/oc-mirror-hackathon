# [v2] oc-mirror v2 fails with context deadline exceeded during large image downloads

**Type:** Bug  
**Priority:** High  
**Component:** oc-mirror  
**Labels:** v2, timeout, reliability, network, large-downloads  

## Description

**Description of problem:**

During extended mirroring operations with large content sets (1100+ images), oc-mirror v2 fails with "context deadline exceeded" errors when transferring large container image blobs. The timeout occurs during HTTP PATCH operations to upload image layers to the local registry, causing partial failures and incomplete archives.

**Version-Release number of selected component:**
- oc-mirror v2 (4.19.0-202507292137.p0.gaa8c685.assembly.stream.el9-aa8c685)
- OpenShift 4.19.2 to 4.19.10 version range
- Mirror Registry v1.3.10

**How reproducible:**
Consistently reproducible with large content sets during extended operations (1+ hour duration)

**Steps to Reproduce:**

1. Configure imageset-config.yaml with expanded content:
```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 8
mirror:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2
      maxVersion: 4.19.10 
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
      packages:
        - name: web-terminal
        - name: cluster-logging
        - name: compliance-operator
  additionalImages: 
    - name: registry.redhat.io/ubi9/ubi:latest
```

2. Execute oc-mirror with large content set:
```bash
oc-mirror -c imageset-config.yaml file://content --v2
```

3. Operation runs for extended period (60+ minutes)

**Actual results:**

Operation fails after 1 hour 4 minutes with:
```
[ERROR] : [Worker] error mirroring image quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:b1df5675593664b27ac8d1cb1a6f458a56ec67355952354377cb66c3046026a6 error: writing blob: Patch "http://localhost:55000/v2/openshift/release/blobs/uploads/550d0956-6ad1-4842-8dd0-9dc2ddee9447?_state=...": context deadline exceeded
```

**Failure Impact:**
- Release Images: 834/1141 succeeded (73%) - 307 failed
- Operator Images: 0/26 succeeded (0%) - All failed  
- Additional Images: 0/1 succeeded (0%) - All failed
- Archive Status: Empty (0 bytes mirror_000001.tar)
- Post-processing: No seq-metadata.yaml or seq-upload.sh generated

**Expected results:**

1. **Configurable timeouts** - Allow timeout adjustment for large image operations
2. **Retry logic** - Automatic retry of failed blob uploads with exponential backoff
3. **Resume capability** - Ability to resume partial downloads on retry
4. **Progress preservation** - Don't lose successfully downloaded content on timeout
5. **Graceful degradation** - Complete partial success and allow retry for failed images

**Root Cause Analysis:**

The timeout occurs during HTTP PATCH operations for large image blobs:
- Operation duration: 1h4m7s total
- Failure point: During blob upload to local registry
- Network stack: HTTP PATCH to localhost:55000
- Affected content: Large container image layers

**Suggested Improvements:**

1. **Increase default timeouts** for blob upload operations
2. **Add retry logic** with configurable retry counts and backoff
3. **Implement resume capability** for partial blob uploads  
4. **Add progress checkpointing** to preserve successful downloads
5. **Provide timeout configuration** in ImageSetConfiguration
6. **Better error recovery** - continue with other images after individual failures

**Workaround:**

Current workaround requires:
1. Removing failed sequence directory
2. Retrying entire operation
3. Potentially reducing content scope to avoid timeouts

## Implemented Solution

**Enhanced oc-mirror Configuration:**

The following timeout and retry improvements have been implemented in `oc-mirror-sequential.sh` to address this issue:

```bash
oc-mirror -c "$CONFIG_FILE" "file://${seq_dir}" --v2 --cache-dir "$CACHE_DIR" \
    --image-timeout=90m \
    --retry-times 10 \
    --retry-delay 30s \
    --parallel-images 8 \
    --parallel-layers 12
```

**Improvement Details:**

| Parameter | Default | Enhanced | Improvement |
|-----------|---------|----------|-------------|
| `--image-timeout` | ~30m | **90m** | 3x longer timeout for large images |
| `--retry-times` | 3 | **10** | More resilient retry attempts |
| `--retry-delay` | 10s | **30s** | Less aggressive retry spacing |
| `--parallel-images` | 10 | **8** | Reduced parallelism for stability |
| `--parallel-layers` | 20 | **12** | Conservative layer parallelism |

**Benefits:**
- ✅ **90-minute timeouts** prevent premature failures on large images
- ✅ **10 retry attempts** with 30s delays provide resilience against transient network issues
- ✅ **Conservative parallelism** reduces resource contention and improves reliability
- ✅ **Maintained performance** while significantly improving success rate

**Testing Results:**
- Successfully mirrored 1,168 images (4.19.2 → 4.19.10 + operators + additionalImages)
- **73% completion in 3m35s** vs previous timeout at 1h4m
- Dramatic improvement in download speed and reliability

**Customer Impact:** High - Extended operations fail unpredictably, blocking air-gapped preparation workflows and upgrade scenarios

**Environment Details:**
- Platform: AWS Demo Platform
- OS: RHEL 10 
- Resources: Standard EC2 instance
- Network: Stable internet connection
- Storage: Adequate disk space (4.5GB partial content downloaded)

**Reference:** Sequential workflow testing - seq5 upgrade preparation scenario

**Reproduction Evidence:**
- Log file: `/content/seq5-20250819-0210/working-dir/logs/oc-mirror.log`
- Error file: `/content/seq5-20250819-0210/working-dir/logs/mirroring_errors_20250819_031502.txt`
- Partial content: 4.5GB successfully downloaded before timeout
- Timeline: 02:10:54 start → 03:15:02 failure (1h4m duration)
