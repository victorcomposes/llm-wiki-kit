---
type: concept
date: 2026-01-01
tags: []
---

# Service Graph

Rolled-up view of service relationships.

```mermaid
graph LR
  SvcA[Svc.A] -->|emits events| SvcB[Svc.B]
```

| Service | calls | depends_on | emits_events_to | subscribes_to |
|---------|-------|------------|-----------------|---------------|
| [[Svc.A]] | | | [[Svc.B]] | |
| [[Svc.B]] | | | | |
