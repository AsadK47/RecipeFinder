export const meta = {
  name: 'improve-loop',
  description: 'Audit an area of the app across lenses, adversarially verify each finding, return a ranked confidence-tagged report (read-only; fixing stays human-in-the-loop).',
  whenToUse: 'Run before a fix session on a feature/loop to get a trustworthy, de-noised list of real issues. Pass the target area as args, e.g. "the cook flow" or "RecipeFinder/Views/Import".',
  phases: [
    { title: 'Audit', detail: 'parallel lenses: bugs / UX / performance' },
    { title: 'Verify', detail: 'adversarially confirm each finding against the code' },
    { title: 'Report', detail: 'rank confirmed findings, list dropped ones' },
  ],
}

// Target area comes from args (string) or {area}. Defaults to the core loop.
const area = (typeof args === 'string' && args.trim())
  ? args.trim()
  : (args && args.area) ? args.area
  : 'the core loop: import/add → find → cook → track'

const FINDINGS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          title: { type: 'string' },
          file: { type: 'string', description: 'file:line' },
          severity: { type: 'string', enum: ['high', 'medium', 'low'] },
          detail: { type: 'string' },
          fix: { type: 'string', description: 'one-line suggested fix' },
        },
        required: ['title', 'file', 'severity', 'detail', 'fix'],
      },
    },
  },
  required: ['findings'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    confirmed: { type: 'boolean', description: 'true only if the code clearly confirms the premise' },
    reason: { type: 'string' },
    correctedFile: { type: 'string', description: 'accurate file:line if the finding was off' },
  },
  required: ['confirmed', 'reason'],
}

const LENSES = [
  { key: 'bugs', prompt: `Find correctness bugs and failure modes in ${area}. Read excerpts to ground every claim in file:line.` },
  { key: 'ux', prompt: `Find UX friction, confusing states, missing feedback, and dead-ends in ${area}. Ground each in file:line.` },
  { key: 'perf', prompt: `Find latency, main-thread blocking, and wasted work (e.g. work in SwiftUI body, per-call regex, sync Core Data on main) in ${area}. Ground each in file:line.` },
]

phase('Audit')
const audits = await parallel(LENSES.map((l) => () =>
  agent(
    `${l.prompt}\nReturn ~6-10 concrete findings, worst first. No generic advice.`,
    { label: `audit:${l.key}`, phase: 'Audit', agentType: 'Explore', schema: FINDINGS_SCHEMA }
  )
))
const findings = audits.filter(Boolean).flatMap((a) => a.findings)
log(`Collected ${findings.length} raw findings across ${LENSES.length} lenses`)

// LESSON (this repo): audit findings are frequently OVERSTATED — e.g. "scaling wipes
// check-offs" was false once the count-guard was read. So verify the PREMISE against
// the code before trusting it. Default to refuted when the code doesn't clearly confirm.
phase('Verify')
const verified = await parallel(findings.map((f) => () =>
  agent(
    `Adversarially verify this audit finding by READING the referenced code. Is the premise actually true as stated? Findings are often overstated or mislocated. Set confirmed=true ONLY if the code clearly confirms it; otherwise confirmed=false with a reason.\n\nFinding: ${JSON.stringify(f)}`,
    { label: `verify:${f.file}`, phase: 'Verify', agentType: 'Explore', schema: VERDICT_SCHEMA }
  ).then((v) => ({ ...f, verdict: v }))
))

const rank = { high: 0, medium: 1, low: 2 }
const confirmed = verified
  .filter(Boolean)
  .filter((x) => x.verdict && x.verdict.confirmed)
  .sort((a, b) => rank[a.severity] - rank[b.severity])
const dropped = verified.filter(Boolean).filter((x) => x.verdict && !x.verdict.confirmed)

phase('Report')
log(`Confirmed ${confirmed.length}; dropped ${dropped.length} as overstated/unconfirmed`)
return {
  area,
  confirmed,
  droppedAsUnconfirmed: dropped.map((d) => ({ title: d.title, file: d.file, why: d.verdict.reason })),
}
