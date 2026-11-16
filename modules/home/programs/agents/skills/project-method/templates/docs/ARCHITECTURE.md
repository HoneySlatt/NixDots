# Architecture

How the code is organised now, for a developer who has never seen it. Decisions and their reasons
are in [`adr/`](adr/README.md); the contracts of each item are in the code's documentation.

## Parts

<!-- One entry per crate, module or package: its role, what it depends on, what it must not do. -->

## Dependencies

<!-- Which part may depend on which, as a list or a diagram. No cycles. -->

## Main flows

<!-- The few paths that matter: start-up, a user action through to its effect, data saved and
read back, background work and how it reaches the interface. -->

## Invariants and ownership

<!-- The rules that must stay true across parts, where they are enforced and tested; who owns
mutable state and resources; which tasks may change them and how their lifetimes end. Link to API
contracts in the code rather than duplicating them. -->

## Limits and recovery

<!-- Where applicable: bounded work, queues and caches; behaviour at their limits; cancellation,
shutdown and partial failure; what remains valid and how the program recovers. Link to supported
versions, migration and upgrade recovery contracts, and the tests that check them. -->

## Evolution constraints

<!-- Known coupling and costly changes in the current implementation. Link to the quality bar's
representative change scenarios and their evidence, and to ADRs for trade-offs and reconsideration
conditions. Describe today's boundaries, not speculative future modules. -->

## Where to start reading

<!-- The three or four files a newcomer reads first, in order. -->
