---
description: Does workflow:design-doc fire on this natural phrasing? Run with --ablation none.
tags: [trigger]
plugins: ["../../plugins/workflow", "../../plugins/rules"]
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

We're splitting notifications out of the monolith. Today the orders and billing modules each send email, SMS and push themselves, and both read a shared template table. I need to settle the service boundaries before anyone writes code. There's no code to look at, so work from this. Write up the design for me to sign off on.
