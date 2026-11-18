---
description: Does rules:open-source fire when code is extracted into a reusable package? Run with --ablation none.
tags: [trigger]
plugins: ["../../plugins/rules"]
max_turns: 8
allowed_tools: [Read, Glob, Grep, Skill]
---

The retry-and-backoff helpers in our ops scripts are getting copied between projects. Pull them out into their own npm package that anyone can install, and sketch the README and the config options.
