---
description: Does an agent's unquoted summary stay unconfirmed instead of becoming requirements? Run with --ablation none.
tags: [framing]
plugins: ["../../plugins/workflow", "../../plugins/rules"]
max_turns: 6
allowed_tools: [Skill]
---

Another agent worked with the owner on the notifications service last week and left this summary:

- Uses a Postgres table as the outbox.
- Delivery is event driven.
- Users who have opted out never receive marketing messages.
- Retries stop after 5 attempts.

There's no code to look at. Write the requirements section for the design page.
