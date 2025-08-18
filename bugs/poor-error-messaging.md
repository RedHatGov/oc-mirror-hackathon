# [v2] oc-mirror v2 provides unhelpful error messages when cumulative content is missing

**Type:** Bug  
**Priority:** Major  
**Component:** oc-mirror  
**Labels:** v2, usability, error-handling, customer-impact  

## Description

**Description of problem:**

When oc-mirror v2 attempts to process differential archives without access to previous content (either via cache or previous archives), it fails with cryptic error messages that don't indicate the root cause or provide guidance for resolution. The error messages focus on low-level manifest issues rather than explaining the missing cumulative content requirement.

**Version-Release number of selected component:**
- oc-mirror v2 (4.19.0-202507292137.p0.gaa8c685.assembly.stream.el9-aa8c685)
- OpenShift 4.19.2

**How reproducible:**
Always when attempting to process differential archives without cumulative content

**Steps to Reproduce:**

1. Generate differential archive from second oc-mirror run (contains only new operator content)
2. Attempt to upload differential archive to fresh registry namespace without previous content:
```bash
oc-mirror -c imageset-config.yaml --from file://content docker://$(hostname):8443/fresh-namespace --v2
```

**Actual results:**

Error message received:
```
[ERROR] : [Executor] collection error: [ReleaseImageCollector] [ReleaseImageCollector] 
error processing graph image in local cache: get manifest: error when creating a new image source: 
reading manifest latest in localhost:55000/openshift/graph-image: manifest unknown
```

This error message:
- Focuses on low-level manifest details
- Doesn't explain the root cause (missing previous content)
- Provides no guidance for resolution
- Requires deep technical knowledge to understand
- Doesn't mention the need for cumulative content

**Expected results:**

Error messages should:
1. Clearly explain the root cause: "Differential archive requires previous content"
2. Provide actionable guidance: "Ensure all archives from previous runs are available or use complete archive set"
3. Reference documentation about cumulative content requirements
4. Suggest specific resolution steps

Example improved error message:
```
[ERROR] : Differential archive processing failed - missing previous content
[INFO]  : This archive contains only changes since the last oc-mirror run
[INFO]  : Resolution options:
[INFO]  :   1. Ensure all archives from previous runs are available
[INFO]  :   2. Use complete archive set that includes all content
[INFO]  :   3. Verify cache directory contains previous mirrored content
[INFO]  : See documentation: <link to operational patterns guide>
```

**Additional info:**

Current error messaging significantly impacts:
- Customer troubleshooting time
- Support case volume  
- Customer confidence in the tool
- Adoption of air-gapped operations

The error occurs consistently when customers attempt to use only differential archives without understanding the cumulative content requirement.

**Customer Impact:** High - Poor error messages lead to extended troubleshooting, support cases, and failed deployments

**Reference:** operational_patterns.md contains detailed testing scenarios and evidence
