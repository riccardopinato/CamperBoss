# Batch Data Safety Audit — Step 16H

## Existing strengths

Step 9 already provides a versioned ZIP, manifest hashes, schema validation,
inspection, safety backup before restore, replace/merge strategies and logical
rollback. Step 16D/16E added stronger deletion cascades and cross-domain
integrity checks.

## Defect found during Master v20 audit

The backup archive contained physical attachments, but restore reconstructed
model records from JSON without extracting those archived files. Restored
records could therefore retain stale absolute paths from the source device.

This violated portability even though the archive itself contained the bytes.

## Step 16H repair

Schema v2 adds provenance for every archived physical file through sourcePath
and uses collision-resistant archive names. Restore now:

1. validates the archive and hashes;
2. creates the automatic safety backup;
3. stages archived bytes in a temporary directory;
4. copies them through the private document-storage boundary;
5. remaps document, maintenance, GPX and memory paths to the new private paths;
6. applies replace/merge only after materialization;
7. removes newly copied files if restore fails;
8. rolls logical records back to the pre-restore snapshot.

Schema v1 remains inspectable/restorable where legacy basenames are
unambiguous.

## Remaining lifecycle boundary

CamperBoss still uses hard delete for several user entities. The project does
not claim a universal Trash/Restore system. A future lifecycle step must decide
entity-by-entity whether hard delete, archive, trash or purge is appropriate;
it must not introduce soft-delete mechanically everywhere.
