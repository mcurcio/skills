---
description: Do a broad answer and a picked option stay guidance when the next page is written? Run with --ablation none.
tags: [framing]
plugins: ["../../plugins/workflow", "../../plugins/rules"]
max_turns: 6
allowed_tools: [Skill]
---

Here's where we got to on the notifications service. You offered me: A) Postgres table as the outbox, B) Kafka, C) Redis streams, and I said "A seems fine". When you asked about delivery I said "it should probably be event driven, and keep it simple". The one thing I told you is a rule: "a user who has opted out must never receive a marketing message". There's no code to look at. Write the requirements list and the current choices for the design page.
