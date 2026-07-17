---
type: service
date: 2026-01-01
tags: []
service: Svc.A
calls: []
depends_on: []
emits_events_to: [[Svc.B]]
subscribes_to: []
---

# Svc.A

Service A. Emits events consumed by Svc.B.

Implementation note: see [[ghost-page]] for the retry design.
