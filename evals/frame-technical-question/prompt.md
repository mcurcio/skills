---
description: Does a question for the owner carry its own background and say what kind of answer it wants? Run with --ablation none.
tags: [framing]
plugins: ["../../plugins/workflow", "../../plugins/rules"]
max_turns: 6
allowed_tools: [Skill]
---

We're building an ingest service that hands photos to three resize workers. A worker sometimes crashes halfway through a photo. I don't follow the details of how queues deliver work, so ask me whatever you need from me about how the handoff should behave. There's no code to look at, so work from this.
