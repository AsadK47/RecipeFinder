export const meta = {
  name: 'improve-and-fix',
  description: 'Audit an app area, then sequentially fix + build-verify + commit each confirmed finding to a review branch',
  phases: [
    { title: 'Audit', detail: 'ranked, adversarially-verified findings (via improve-loop)' },
    { title: 'Branch', detail: 'create the review branch off main' },
    { title: 'Fix', detail: 'sequential: implement → BuildProject + affected tests → commit on the branch' },
    { title: 'Report', detail: 'commits made + findings skipped' },
  ],
}

// WHY branch-not-worktree: the xcode-tools MCP builds the ONE open Xcode project
// (the main checkout). A parallel git worktree wouldn't be built by it, so fixes
// can't be verified there. We therefore work on a branch in the working copy and
// apply fixes SEQUENTIALLY — one green build at a time. `main` is never touched.

const area = typeof args === 'string' ? args : (args?.area ?? 'the cook flow')
const branch = (args?.branch) ?? 'improve/auto'
const LIMIT = (args?.limit) ?? 5

const FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    confirmed: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          title: { type: 'string' },
          file: { type: 'string' },
          severity: { type: 'string' },
          fix: { type: 'string' },
          needsDecision: { type: 'boolean', description: 'true if the fix requires a product/design choice' },
        },
        required: ['title', 'file', 'fix', 'needsDecision'],
      },
    },
  },
  required: ['confirmed'],
}

const COMMIT_SCHEMA = {
  type: 'object',
  properties: {
    committed: { type: 'boolean' },
    commitSubject: { type: 'string' },
    reason: { type: 'string', description: 'why skipped, if not committed' },
  },
  required: ['committed'],
}

// 1. AUDIT — reuse the read-only improve-loop workflow to get verified findings.
phase('Audit')
const audit = await workflow('improve-loop', area)
const findings = (audit?.confirmed ?? audit?.result?.confirmed ?? [])
  .filter(f => !f.needsDecision)              // skip product-decision forks
  .slice(0, LIMIT)
log(`Audit surfaced ${findings.length} auto-fixable findings (decision-forks excluded).`)
if (findings.length === 0) return { branch: null, commits: [], note: 'Nothing auto-fixable.' }

// 2. BRANCH — create the review branch off main (idempotent-ish; agent handles existing).
phase('Branch')
await agent(
  `Create/switch to a git branch named "${branch}" off the current main in the RecipeFinder repo. ` +
  `Run: git switch -c "${branch}" (or: git switch "${branch}" if it already exists). ` +
  `Do NOT commit anything yet. Confirm the current branch is "${branch}".`,
  { label: 'branch', phase: 'Branch' }
)

// 3. FIX — sequential (single Xcode build lane). Each fix: implement → verify → commit.
phase('Fix')
const commits = []
for (let i = 0; i < findings.length; i++) {
  const f = findings[i]
  const result = await agent(
    `You are fixing ONE confirmed issue on branch "${branch}" in the RecipeFinder iOS app.\n\n` +
    `FINDING: ${f.title}\nFILE: ${f.file}\nPROPOSED FIX: ${f.fix}\n\n` +
    `Rules (from CLAUDE.md):\n` +
    `- Verify the finding against the real code FIRST; if it's wrong/stale, do NOT edit — return committed=false with the reason.\n` +
    `- Swift 6, no force-unwrap/try!, no Combine, no print(). New Swift files via XcodeWrite.\n` +
    `- Keep the change minimal and focused on THIS finding only.\n` +
    `- Verify: XcodeRefreshCodeIssuesInFile on each edited file, then BuildProject, then RunSomeTests on the directly affected suite.\n` +
    `- ONLY if build + affected tests are green: git add the changed files and git commit with a conventional-commit subject. Never commit to main; you are on "${branch}". Do not git push.\n` +
    `- If the fix needs a product/design decision, or can't be verified green, make NO commit and return committed=false with the reason.\n` +
    `Return the commit subject if you committed.`,
    { label: `fix:${f.title.slice(0, 40)}`, phase: 'Fix', schema: COMMIT_SCHEMA }
  )
  if (result?.committed) {
    commits.push(result.commitSubject ?? f.title)
    log(`✓ committed: ${result.commitSubject ?? f.title}`)
  } else {
    log(`↷ skipped: ${f.title} — ${result?.reason ?? 'unverified'}`)
  }
}

// 4. REPORT
phase('Report')
return {
  branch,
  commits,
  committedCount: commits.length,
  skipped: findings.length - commits.length,
  note: `Review branch "${branch}" — ${commits.length} verified fixes committed. main untouched.`,
}
