# Salesforce Integrations
### Enterprise Integration Architecture

This repository documents and demonstrates integration architecture patterns connecting Salesforce to critical external enterprise systems. The focus is real-time reliability, fault tolerance, and operational observability — not just getting data from A to B, but keeping it synchronized at scale under production pressure.

---

## Integration Domains

### SAP / ERP Ecosystem
Bidirectional data synchronization between Salesforce and SAP ERP landscapes, including:
- Customer and Account master data alignment
- Order lifecycle orchestration across SAP SD and Salesforce CPQ/Commerce
- Real-time inventory availability surfacing in Salesforce from SAP MM
- SAP Integration Suite (BTP) middleware orchestration patterns

**Architecture approach:** Event-driven where possible. Platform Events for outbound Salesforce triggers. SAP iDocs and BAPIs for inbound ERP writes. Named Credentials for all HTTP callout surface.

---

### REST / SOAP API Patterns
Standardized Apex callout architecture applicable across any external API:

```
classes/
├── HttpCalloutService.cls      — Base callout handler (Named Credential, retry, logging)
├── HttpCalloutServiceTest.cls  — Mock-based test coverage
├── ExternalApiRequest.cls      — Typed request wrapper
└── ExternalApiResponse.cls     — Typed response wrapper with error surface
```

**No hardcoded endpoints. No credentials in code.** Named Credentials only.

---

### Event-Driven Architecture
Platform Events and Change Data Capture (CDC) patterns for decoupled, asynchronous integration:

- Platform Event publish/subscribe patterns across org boundaries
- CDC listeners for external system sync without polling
- Queueable chain architecture for reliable async processing with retry
- Dead letter handling — failed events logged and re-processable

---

### Middleware Orchestration
Architecture patterns for Salesforce as both orchestrator and participant in multi-system workflows:

- Salesforce to Middleware to SAP (BTP / MuleSoft pattern)
- Inbound webhook handling with idempotency keys
- Correlation ID propagation across system boundaries for end-to-end traceability

---

## Reliability Standards

| Concern | Approach |
|---|---|
| Authentication | Named Credentials — no secrets in code |
| Retry Logic | Queueable chains with attempt counter |
| Error Logging | Custom Integration_Log__c object or platform logging |
| Idempotency | External ID fields + upsert over insert |
| Observability | Request/response logging on all callouts |
| Governor Limits | Async-first for bulk operations |

---

## About

Built by **Jason Hogan** — Salesforce Solutions Architect & AI Engineer based in St. George, Utah.

- LinkedIn: [jason-hogan1](https://www.linkedin.com/in/jason-hogan1/)
- GitHub: [@jrhogan77](https://github.com/jrhogan77)
- Email: jrhogan.tbd@gmail.com
