# ADR 0011: An Inference Context Is Model State

**Status:** Accepted

## Context

Diagrams have placed Cortex, AEGIS, RSI, and the composition host on the same physical KV pool as the agents. An inference context had started to mean "anything that participates in AIENOS."

## Decision

An inference context names the state of one model computation. Inference clients are native chat, the AEGIS agent loop, and subagents. They share one inference runtime, one scheduler, and one KV pool. Cortex is the memory system. AEGIS is the effect boundary. RSI is the promotion loop. The composition host exposes or hosts inference clients. The lower three may invoke an inference client. Invocation does not make them inference contexts.

## Consequences

Sharing the KV pool is a property of inference clients and the contexts they fork. Memory, authorization, and promotion sit beside that runtime.
