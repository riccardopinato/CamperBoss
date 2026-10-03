# AGENTS.md

## Source of truth

CamperBoss follows the latest Master Prompt / Golden Rules available in the ChatGPT project.

Priority order:

1. Product Truth / current ROADMAP and product contracts.
2. Master Prompt / approved Golden Components.
3. Existing CamperBoss implementation already verified.
4. CERTIFIED internal donors.
5. Approved OSS with compatible license and recorded provenance.
6. External documentation/tools.
7. New code only when reuse is not appropriate.

Never copy blindly. Record provenance and license for COPY/ADAPT/IDEA ONLY reuse.

## Operating rules

- Work from the single `CURRENT` roadmap step unless the user explicitly authorizes a multi-step execution. The request of 2026-10-03 authorizes sequential execution of STEP 16J→16Q without repeated confirmation.
- Keep `main` stable. Do not merge a release chain until the relevant gates are green.
- Read only the code and direct dependencies needed for the active step, except when the active step is explicitly an audit/certification/hardening step.
- Heavy audits are allowed and required when requested by the user or by a certification step.
- Ignore generated/build/vendor folders unless the failure is inside them.
- Prefer existing Golden/internal donor implementations before new architecture.
- Never invent runtime evidence. Build PASS is not device PASS.
- Never invent provider capability, store delivery, offline behavior, encryption, account sync or platform parity.
- Preserve local-first/offline-first core behavior; account/cloud/AI remain optional unless Product Truth changes.
- Sensitive data, secrets, signing keys and service accounts never enter the repository.
- Changes that delete or migrate user data require explicit lifecycle, rollback/recovery and failure tests.

## Validation

Use the project validation ladder:

- FAST: focused analyze/tests for the changed scope.
- FULL: full analyze + full tests + affected platform builds.
- CERTIFIED: FULL plus runtime/device/AppLab evidence, privacy/security/data-safety checks and Evidence Bundle.

CodeRabbit/Fastlane/AppLab complement, not replace, Flutter analyze/test/build.

## Git / delivery

- One logical step should remain reviewable even when several roadmap steps are executed sequentially.
- Use branch/PR evidence for substantial steps.
- Build store artifacts once; delivery must upload the same immutable AAB/IPA artifact rather than rebuilding it.
- Release version/build numbers must be monotonic.
- GitHub Pages must represent the same canonical release candidate SHA that is being certified.

## Completion

A step is DONE only when its code/docs and automated gates are complete.
If only external/device/credential evidence remains, mark the step BLOCKED with the exact gate.
Do not promote STEP 17 AI until STEP 16 release certification is complete.
