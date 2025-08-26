# [v2] oc-mirror v2 logs report complete content when archives contain only differential content

**Type:** Bug  
**Priority:** Major  
**Component:** oc-mirror  
**Labels:** v2, operational, customer-impact, documentation  

## Description

**Description of problem:**

oc-mirror v2 log output claims to have mirrored complete image sets when the generated archives actually contain only differential/incremental content since the last run. This misleads customers into believing they can transfer only the latest archive set for air-gapped operations, resulting in failed mirror-to-mirror operations.

**Version-Release number of selected component:**
- oc-mirror v2 (4.19.0-202507292137.p0.gaa8c685.assembly.stream.el9-aa8c685)
- OpenShift 4.19.2

**How reproducible:**
Always

**Steps to Reproduce:**

1. Create baseline imageset-config.yaml:
```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 8
mirror:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2
      maxVersion: 4.19.2 
    graph: true
  additionalImages: 
    - name: registry.redhat.io/ubi9/ubi:latest
```

2. Run initial mirror:
```bash
oc-mirror -c imageset-config.yaml file://content --v2 --cache-dir .cache
```
Result: 4 archives totaling 24GB, logs show "192 images mirrored successfully"

3. Add operator to configuration:
```yaml
# Add to imageset-config.yaml:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
      packages:
        - name: web-terminal
```

4. Run second mirror:
```bash
oc-mirror -c imageset-config.yaml file://content --v2 --cache-dir .cache
```

5. Attempt to upload only the new archive set to fresh registry:
```bash
oc-mirror -c imageset-config.yaml --from file://content docker://$(hostname):8443/test --v2
```

**Actual results:**

- Second run logs show: "✓ 191 / 191 release images mirrored successfully" and "✓ 5 / 5 operator images mirrored successfully" and "✓ 1 / 1 additional images mirrored successfully"
- Total log claims: "197 images mirrored successfully" 
- Archive generated: Single 5.5GB file (vs original 24GB)
- Upload to fresh registry fails with: `error processing graph image in local cache: reading manifest latest in localhost:55000/openshift/graph-image: manifest unknown`

**Expected results:**

- Log output should clearly indicate whether archives contain complete content or only differential content since last run
- Archives containing only differential content should be clearly labeled as such
- Error messages should guide users toward resolution (need cumulative content)
- Documentation should explain differential behavior and operational implications

**Additional info:**

This issue has critical operational impact for air-gapped customers who:
1. Assume latest archive set is complete based on log output
2. Transfer only latest archives to air-gapped environments  
3. Experience failed mirror operations due to missing content
4. Must understand cumulative content requirements for successful operations

**Customer Impact:** High - Affects all customers using oc-mirror v2 for operational air-gapped updates

**Reference:** operational_patterns.md contains detailed analysis and testing evidence
