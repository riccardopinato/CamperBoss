# Entity Lifecycle & Media Safety Audit — Step 16I

Reference: Master Prompt v20 + Batch Data Safety principles.

## Policy

CamperBoss does not apply soft-delete mechanically. Each entity must have an
explicit lifecycle chosen from:

- hard delete: small/reconstructable data with clear confirmation or undo;
- archive: data that should disappear from active workflows but remain useful;
- trash/restore/purge: high-value user-authored records whose accidental loss
  would be costly;
- cache purge: reproducible offline/downloaded assets.

Physical files are independent resources: a database row may be deleted only
without deleting a file that another live entity still references.

## Current decisions

| Domain | Current lifecycle | Media rule | Follow-up |
| --- | --- | --- | --- |
| Vehicle documents | hard delete | reference-safe cleanup | candidate for Trash/Restore before production maturity |
| Maintenance records | hard delete | reference-safe cleanup | candidate for Trash/Restore |
| Travel memories | hard delete | shared-photo-safe cleanup | candidate for Trash/Restore |
| GPX tracks | hard delete | shared-GPX-safe cleanup | hard delete acceptable with confirmation; export remains available |
| Trips | hard delete + cascade | linked travel media uses lifecycle service | strong candidate for Trash/Restore because cascade blast radius is high |
| Journal entries | hard delete | no owned media in current model | candidate for Trash/Restore |
| Finance entries | hard delete | no owned media | keep simple unless user testing shows need for trash |
| Checklist items | hard delete | none | keep hard delete/undo |
| Offline map/guide packages | delete/purge | reproducible cache/content | no Trash needed |
| Search index | rebuildable | derived data | purge/rebuild only |

## Step 16I invariant

A physical path is deletable only after the owning repository/service has
confirmed that no remaining entity in that domain references it. Update,
delete, trip cascade and backup replace/merge must all respect the same
invariant.

Universal Trash is explicitly not claimed by this step.
