# Evidence retention

Keep one current full-suite evidence set, reproducible test/coverage tools, reviewed positive/negative mappings, and unique mutation or capability controls. Superseded runtime logs and coverage snapshots are archived in Git history rather than duplicated in the current tree.

[Archive manifest](evidence-retention.json) identifies the pre-cleanup commit and hashes of removed files. Historical provenance retains original input/output hashes as historical records; removed payloads must be read at that commit, not assumed present today. Source verification, deployment/dependency attestations and chain simulations serve different purposes and are retained.

No production sources, tests, deployment inputs or coverage denominators were changed by this cleanup.
