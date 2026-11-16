# Architecture decision records

An ADR records one decision: its context, the decision, the alternatives rejected and the
consequences. Once accepted, only its status changes.

- A decision changed, even in part, is a new ADR that supersedes the old one and states the whole
  rule then in force on its topic: its status is `Accepted; supersedes NNNN`, the old one's
  `Superseded by NNNN`. One ADR is read for a topic, never a chain of amendments.
- An ADR that holds several topics and changes on one of them alone is superseded in part: the new
  one states that topic's rule whole, `Accepted; supersedes in part NNNN (the topic)`, the old one
  `…; superseded in part by NNNN (the topic)`, and stays in force for the rest.
- An ADR that adds a decision without changing one names the older in its context alone.
- A precision decided while a milestone runs goes in the milestone's plan or in a new ADR, never
  into an older ADR's status.

New ADRs copy [`0000-template.md`](0000-template.md) and take the next free number. The index
below is written by `scripts/adr-index.py --write`; `scripts/check.sh` checks it.

| ADR | Title | Status |
|---|---|---|
