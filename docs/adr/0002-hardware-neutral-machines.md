# ADR 0002: Hardware-Neutral Machine Identities

**Status:** Accepted

## Context

AIEN is intended to run across heterogeneous hardware.

## Decision

Architecture uses Machine 1, Machine 2, etc. Hardware/vendor information is capability metadata. Core scheduling interfaces must not encode a vendor/product as identity.

## Consequences

Portable placement becomes possible; hardware-specific optimization lives behind accelerator/provider interfaces.
