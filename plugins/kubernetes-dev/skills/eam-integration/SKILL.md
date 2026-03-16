---
name: eam-integration
description: Use when building software that interacts with Imprivata OneSign/EAM - API selection, authentication flows, data models, and integration patterns
---

# EAM Integration

Guide for building software that integrates with Imprivata OneSign/Enterprise
Access Management (EAM).

## Knowledge Base References

Detailed documentation in Basic Memory:

| Topic | Location |
|-------|----------|
| API Surfaces | `knowledge/products/onesign-eam/apis` |
| Authentication | `knowledge/products/onesign-eam/authentication` |
| Data Models | `knowledge/products/onesign-eam/data-models` |
| Deployment | `knowledge/products/onesign-eam/deployment` |
| STORM Research | `knowledge/research/storm-research-imprivata-one-sign-eam` |

Use `build_context_basic-memory` with these paths to load detailed reference.

## API Selection

Choose the appropriate API paradigm for your integration:

| Use Case | API | Transport |
|----------|-----|-----------|
| Agent-to-appliance communication | SOAP | HTTPS/443 |
| Modern service integration | REST | HTTPS/443 |
| Browser-based interaction | Endpoint Web API | JavaScript |
| Local component IPC | Secure IPC | Named Pipes |
| Mobile/cloud connections | Applex Protocol | WebSocket |
| Cloud service messaging | Interplex Protocol | Kafka |
| Federated authentication | WS-Trust | SOAP/HTTP |

### SOAP API (Primary for Agent Work)

- Namespace:
  `urn:ImprivataSOAPService`
- 200+ message types across categories:
  Authentication, Biometrics, SSO, Policy, Admin
- JWT token-based authentication
- Certificate-based mutual authentication

### REST API (Modern Integrations)

- Base path:
  `/rest/v1/*`
- 10+ endpoints converted from SOAP
- Endpoints:
  `/users`, `/computers`, `/policies`, `/applications`

### Secure IPC (Local Components)

- Transport:
  Named Pipes with AES-256
- Magic number:
  "EACP" (Endpoint Agent Communication Protocol)
- CBOR encoding for serialization
- Auto-reconnect with 600s timeout

## Authentication Integration

### Modality Values

Use these values when working with authentication modalities:

| Modality | Value | EPCS 2nd Factor |
|----------|-------|-----------------|
| Password | 0 | No (1st only) |
| Fingerprint | 1 | Yes |
| DigiPass Token | 2 | Yes |
| Prox Card | 3 | No |
| Smart Card USB | 4 | Yes |
| Q&A | 5 | No |
| Smart Card PIV | 6 | Yes |
| Imprivata ID | 7 | Yes |
| PIN | 8 | No (1st only) |
| FIDO2/Passkey | 11 | Yes |

### Policy Hierarchy

**Computer policies override user policies.** This is intentional for
location-aware security in clinical environments.

### MFA/EPCS Requirements

EPCS compliance requires two distinct factors.
Valid combinations:

- Password + Fingerprint
- Password + Smart Card
- Password + Imprivata ID
- Password + FIDO2

## Data Model Essentials

### Key Tables

| Table | Purpose |
|-------|---------|
| SUBSCRIBERS | User identities |
| ACCOUNT_CREDENTIALS | SSO credentials (encrypted) |
| APPLICATIONS | SSO application profiles |
| FINGERPRINTS | Biometric templates (encrypted) |
| AUTH_AUTHCOMBINATIONS | MFA combinations |

### Critical Constraints

- **Primary keys**:
  UUID (VARCHAR2(36))
- **40+ encrypted columns**:
  AES-256 with realm-specific keys
- **Soft deletes**:
  `DELETED` column pattern
- **Timestamps**:
  UCTS for conflict resolution

### Caching Behavior

- Pre-2024:
  Global 1500-entry cache (thrashing issues)
- 2024+:
  SingleRequestDataCache (ThreadLocal, per-request)

## SSO Credential Flow

5-stage injection process:

```text
1. Application Detection  → Probe identifies target app
2. Profile Lookup         → Retrieve APG profile
3. Credential Retrieval   → Decrypt from ACCOUNT_CREDENTIALS
4. Field Mapping          → Map to form fields
5. Injection              → Fill via appropriate method
```

Injection methods:
Windows Messages, UI Automation, GDI, Browser Extension, HLLAPI

## Security Layers

4-layer encryption model:

| Layer | Protection |
|-------|------------|
| Transport | TLS 1.2/1.3 |
| Application | JWT tokens with role claims |
| Database | AES-256 encrypted columns |
| Credential | Additional password encryption |

Compliance:
FIPS 140-2 Level 1, NIST 800-63-3 AAL 2

## Architecture Quick Reference

### G4 Two-Tier Model

| Component | Role |
|-----------|------|
| Database Appliances | Data storage, replication |
| Service Appliances | Stateless request handling |

- Multi-master Oracle Streams replication
- UCTS conflict resolution (highest timestamp wins)
- ~5,000 agents per service appliance

### Known Performance Hot Spots

| Component | Issue |
|-----------|-------|
| ClientPing40 | Frequent SOAP polling |
| Hostname lookups | DNS latency |
| Encrypted columns | Cannot be indexed |

## Common Integration Patterns

### Healthcheck Agent

Query appliance status, validate connectivity, check service health.
See:
`journal/arcs/multi-session-arc-eam-healthcheck-agent`

### Credential Retrieval

1. Authenticate via SOAP API
2. Get JWT token
3. Query ACCOUNT_CREDENTIALS for application
4. Decrypt using session key

### Policy Evaluation

1. Get user policies (SOAP:
   GetUserPolicy)
2. Get computer policies (SOAP:
   GetComputerPolicy)
3. Merge with computer policies taking precedence
