---
description: Does workflow:implementation-workflow fire on this natural phrasing? Run with --ablation none.
tags: [trigger]
plugins: ["../../plugins/workflow", "../../plugins/rules"]
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

The design for moving webhook delivery into its own service got approved this morning. It touches the queue package, the retry logic and the API layer. Can you break it into beads and lay out how we'd land it?
