# Graph Report - nr1  (2026-09-17)

## Corpus Check
- Corpus is ~13,106 words - fits in a single context window. You may not need a graph.

## Summary
- 28 nodes · 31 edges · 4 communities
- Extraction: 81% EXTRACTED · 19% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Graphify Pipeline Core
- Faceless Video Production
- CLAUDE.md Integration & Query
- Extraction & Update Rules

## God Nodes (most connected - your core abstractions)
1. `Graphify Pipeline (/graphify)` - 16 edges
2. `Dokumentenfälschung Faceless Video` - 7 edges
3. `graphify Section in Project CLAUDE.md` - 4 edges
4. `Query, Path, Explain Guide` - 3 edges
5. `Incremental Update & Cluster-only Guide` - 3 edges
6. `Honesty Rules` - 2 edges
7. `Extraction Subagent Prompt Spec` - 2 edges
8. `Node ID Format Rule` - 2 edges
9. `Commit Hook & CLAUDE.md Integration Guide` - 2 edges
10. `Constrained Query Expansion` - 2 edges

## Surprising Connections (you probably didn't know these)
- `graphify Section in Project CLAUDE.md` --conceptually_related_to--> `Graphify Pipeline (/graphify)`  [INFERRED]
  CLAUDE.md → .claude/skills/graphify/SKILL.md
- `graphify Section in Project CLAUDE.md` --conceptually_related_to--> `Incremental Update & Cluster-only Guide`  [INFERRED]
  CLAUDE.md → .claude/skills/graphify/references/update.md
- `Commit Hook & CLAUDE.md Integration Guide` --references--> `graphify Section in Project CLAUDE.md`  [INFERRED]
  .claude/skills/graphify/references/hooks.md → CLAUDE.md
- `graphify Section in Project CLAUDE.md` --conceptually_related_to--> `Query, Path, Explain Guide`  [INFERRED]
  CLAUDE.md → .claude/skills/graphify/references/query.md
- `Graphify Pipeline (/graphify)` --references--> `Extraction Subagent Prompt Spec`  [EXTRACTED]
  .claude/skills/graphify/SKILL.md → .claude/skills/graphify/references/extraction-spec.md

## Hyperedges (group relationships)
- **Graphify Skill + Reference Guides** — _claude_skills_graphify_skill_graphify, _claude_skills_graphify_references_add_watch_guide, _claude_skills_graphify_references_exports_guide, _claude_skills_graphify_references_extraction_spec_guide, _claude_skills_graphify_references_github_and_merge_guide, _claude_skills_graphify_references_hooks_guide, _claude_skills_graphify_references_query_guide, _claude_skills_graphify_references_transcribe_guide, _claude_skills_graphify_references_update_guide [EXTRACTED 1.00]
- **Faceless Video Production Toolchain** — scripts_dokumentenfaelschung_faceless_video_video, scripts_dokumentenfaelschung_faceless_video_higgsfieldapi, scripts_dokumentenfaelschung_faceless_video_elevenlabs, scripts_dokumentenfaelschung_faceless_video_ffmpeg, scripts_dokumentenfaelschung_faceless_video_fasterwhisper [EXTRACTED 1.00]
- **CLAUDE.md Graphify Integration Chain** — _claude_claude_graphify_pointer, _claude_skills_graphify_skill_graphify, claude_graphify_section, _claude_skills_graphify_references_hooks_guide [INFERRED 0.85]

## Communities (4 total, 0 thin omitted)

### Community 0 - "Graphify Pipeline Core"
Cohesion: 0.18
Nodes (11): graphify Skill Pointer, Add URL & Watch Folder Guide, Exports & Benchmark Guide, GitHub Clone & Cross-repo Merge Guide, Transcribe Video/Audio Guide, Structural (AST) Extraction, Community Detection, God Nodes (+3 more)

### Community 1 - "Faceless Video Production"
Cohesion: 0.22
Nodes (9): ElevenLabs Voice (Cillian), Faceless Style Production Rationale, faster-whisper Subtitle Transcription, ffmpeg Video Assembly, Higgsfield API, Kling 3.0 Model, Hook-Problem-Fazit Narrative Structure, §267 StGB (Urkundenfälschung) (+1 more)

### Community 2 - "CLAUDE.md Integration & Query"
Cohesion: 0.40
Nodes (5): Commit Hook & CLAUDE.md Integration Guide, Query, Path, Explain Guide, Constrained Query Expansion, Honesty Rules, graphify Section in Project CLAUDE.md

### Community 3 - "Extraction & Update Rules"
Cohesion: 0.67
Nodes (3): Extraction Subagent Prompt Spec, Node ID Format Rule, Incremental Update & Cluster-only Guide

## Knowledge Gaps
- **15 isolated node(s):** `graphify Skill Pointer`, `Structural (AST) Extraction`, `Semantic (LLM) Extraction`, `God Nodes`, `Community Detection` (+10 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 17 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Graphify Pipeline (/graphify)` connect `Graphify Pipeline Core` to `CLAUDE.md Integration & Query`, `Extraction & Update Rules`?**
  _High betweenness centrality (0.399) - this node is a cross-community bridge._
- **Why does `Query, Path, Explain Guide` connect `CLAUDE.md Integration & Query` to `Graphify Pipeline Core`?**
  _High betweenness centrality (0.025) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `graphify Section in Project CLAUDE.md` (e.g. with `Commit Hook & CLAUDE.md Integration Guide` and `Query, Path, Explain Guide`) actually correct?**
  _`graphify Section in Project CLAUDE.md` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Incremental Update & Cluster-only Guide` (e.g. with `Node ID Format Rule` and `graphify Section in Project CLAUDE.md`) actually correct?**
  _`Incremental Update & Cluster-only Guide` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `graphify Skill Pointer`, `Structural (AST) Extraction`, `Semantic (LLM) Extraction` to the rest of the system?**
  _15 weakly-connected nodes found - possible documentation gaps or missing edges._