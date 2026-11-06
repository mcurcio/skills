---
description: Does workflow:design-doc fire on this natural phrasing? Run with --ablation none.
tags: [trigger]
plugins: ["../../plugins/workflow", "../../plugins/rules"]
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

Before we build the new permissions model I want to see the options at the domain level and pick one. Today it's one admin flag per user, and about 40 customers now need per-team roles. There's no code to look at, so work from this. Put together what I need to decide.
