# AGENTS.md

## Source of truth

CamperBoss uses the App Factory resolver, not chat memory or an unspecified
"latest" prompt.

For Factory-dependent development, audit, roadmap, hardening or release work,
resolve once per session:

1. https://github.com/riccardopinato/App-Factory-Core
2. `CURRENT.yaml`
3. the file selected by `master.path`
4. the file selected by `golden_index.path`
5. `golden/GOLDEN_REGISTRY.yaml`
6. only the Golden documents relevant to the task

Pin the resolved App-Factory-Core commit SHA as the Factory baseline for the
session. Refresh only after an explicit request or after the Core itself was
updated.

CamperBoss authority order:

1. Current Product Truth / `ROADMAP.md` and project contracts.
2. Resolved App Factory Master Prompt and relevant Golden.
3. Existing CamperBoss implementation and tests.
4. CERTIFIED internal donors.
5. Approved OSS with compatible license and recorded provenance.
6. Current provider/framework documentation.
7. New code only when reuse is not appropriate.

Never copy blindly. Record provenance and license for COPY / ADAPT / IDEA ONLY
reuse.

## Operating rules

- Keep `main` stable and prefer branch -> PR -> green gates for substantial work.
- Read only the code and direct dependencies needed for the active task, except
  for an explicitly authorized audit/certification/hardening pass.
- Heavy audits are allowed when requested by the user or required by a
  certification step.
- Ignore generated/build/vendor folders unless the failure is inside them.
- Prefer existing Golden/internal donor implementations before new architecture.
- Never invent runtime evidence. Build PASS is not device PASS.
- Never invent provider capability, store delivery, offline behavior,
  encryption, account sync or platform parity.
- Preserve the local-first/offline-first core; account/cloud/AI remain optional
  unless Product Truth changes.
- Sensitive data, secrets, signing keys and service accounts never enter the
  repository.
- Changes that delete or migrate user data require explicit lifecycle,
  rollback/recovery and failure tests.
- Do not merge a PR unless the user explicitly requests the merge.

## Code hygiene

For every substantial code/configuration/dependency change, evaluate whether
the new implementation supersedes existing code.

Adding a replacement without evaluating removal of the superseded implementation
is incomplete work.

Within the affected subsystem, check when relevant:

- dead/unreachable or superseded code;
- duplicate services/repositories/coordinators/schedulers/listeners/workers;
- stale workarounds, feature flags and TODOs;
- unused dependencies;
- unused assets/resources/translations;
- deprecated APIs touched by the task.

Cleanup must remain bounded to the affected subsystem. Do not use this rule to
justify unrelated architectural rewrites.

Run the relevant validation again after final cleanup. A green test/build from
before deletion does not validate the final tree.

## Validation

Use the project validation ladder:

- FAST: focused analyze/tests for the changed scope.
- FULL: full analyze + full tests + affected platform builds.
- CERTIFIED: FULL plus runtime/device/AppLab evidence,
  privacy/security/data-safety checks and Evidence Bundle.

CodeRabbit/Fastlane/AppLab complement, not replace, Flutter analyze/test/build.

## Git / delivery

- One logical step should remain reviewable even when several roadmap steps are
  executed sequentially.
- Use branch/PR evidence for substantial steps.
- Build store artifacts once; delivery must upload the same immutable AAB/IPA
  artifact rather than rebuilding it.
- Release version/build numbers must be monotonic.
- GitHub Pages must represent the same canonical release-candidate SHA that is
  being certified.

## Completion

A task is DONE only when its code/docs and automated gates are complete.

Before completion of substantial implementation, report:
- obsolete/superseded code evaluated;
- code/dependencies/assets removed or deliberately retained;
- relevant validation rerun after cleanup;
- remaining findings intentionally left outside scope.

If only external/device/credential evidence remains, mark the step BLOCKED with
the exact gate.

Do not promote STEP 17 AI until STEP 16 release certification is complete.
