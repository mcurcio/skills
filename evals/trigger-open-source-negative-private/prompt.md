---
description: Does rules:open-source stay quiet on private-repo work? Passes when the skill is not loaded. Run with --ablation none.
tags: [trigger]
plugins: ["../../plugins/rules"]
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

In my private home-automation repo, rename the config key nas_host to storage_host everywhere and update the README to match. This repo stays private.
