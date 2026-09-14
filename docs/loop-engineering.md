# How the compatibility loop was run

The target was one local legacy game package on a particular Mac. Reusing its compiled gameplay was preferred because changing engines could change timing, collision, damage and character behavior.

Each iteration selected an observable failure or missing verification, recorded a falsifiable cause, made the smallest related change, ran relevant checks, inspected the actual Mac result, and saved a checkpoint. Compilation and menu appearance were intermediate milestones; a complete match and subsequent restart were required separately.

When original file access was incompatible with a signed application bundle, API-compatible storage helpers moved save and log writes into the app's own storage directory. The original compiled game and resources remained unchanged. Seed saves are imported only for a new storage directory; existing progress is retained.

The work proceeded from an Itachi-first playable slice to representative rules and broader content coverage, then packaging and delivery checks. A tested candidate was preserved before further experiments.

Human handfeel was deliberately postponed until machine-actionable implementation, diagnostics and verification were complete. There was no fixed seven-hour stop: elapsed time did not determine completion. A blocked dependency only paused work that required it. Synthetic input tests and model judgments were never treated as substitutes for user acceptance.

This repository contains the reusable code and a concise evidence summary, not private conversation history or a dump of all local diagnostics. Start by following the README in a fresh directory and testing the exact source package you own.
