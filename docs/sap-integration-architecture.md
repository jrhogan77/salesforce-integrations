# SAP Integration Architecture
### Salesforce to SAP ERP — Design Patterns & Decision Framework

---

## Overview

Integrating Salesforce with SAP ERP is one of the most complex and high-stakes integration challenges in the enterprise landscape. Data models differ fundamentally. Transaction semantics differ. Error handling expectations differ. This document captures the architectural decisions that govern reliable, maintainable Salesforce-SAP integration.

---

## Core Design Principles

1. **Event-driven over polling.** Polling SAP for changes wastes resources and creates timing gaps. Platform Events trigger Salesforce-side processing. SAP iDocs or BAPI callbacks trigger inbound writes.
2. **Idempotency is non-negotiable.** Every inbound write uses an External ID field and `upsert` — never blind `insert`. Duplicate events must be harmless.
3. **Correlation IDs propagate end to end.** Every transaction carries a correlation ID from origin to destination. When something fails, you can trace the full path in one query.
4. **Async by default for bulk.** Synchronous callouts for real-time point lookups. Queueable chains for bulk sync operations.
5. **Named Credentials only.** No SAP credentials in code, custom settings, or custom metadata values that could be exported. Named Credential stores the secret; Apex references the alias.

---

## Integration Topology

```
Salesforce                    Middleware (SAP BTP / MuleSoft)          SAP ERP
----------                    --------------------------------          -------
Platform Event  ─────────►   Orchestration Layer            ─────►   BAPI / iDoc
Apex Callout    ─────────►   Routing / Transform             ─────►   RFC Call
                ◄─────────   Response / Ack                  ◄─────   Return Structure
CDC Listener    ◄─────────   Inbound Webhook                 ◄─────   SAP Event
```

---

## Data Domain Mapping

| Salesforce Object | SAP Equivalent | Sync Direction | Pattern |
|---|---|---|---|
| Account | Customer Master (KNA1) | Bidirectional | Platform Event + BAPI |
| Opportunity | Sales Order (VBAK/VBAP) | SF to SAP | Apex Callout on Close |
| Product2 / PricebookEntry | Material Master (MARA) | SAP to SF | Scheduled Batch |
| Order | Delivery / Billing Doc | SAP to SF | iDoc inbound webhook |
| Case | SAP Service Notification | Bidirectional | Platform Event |

---

## Error Handling Strategy

**Transient failures (network timeout, SAP unavailable):**
- Retry via Queueable chain — max 3 attempts with exponential backoff concept
- After max retries, write to `Integration_Error_Log__c` with full request/response payload
- Platform Event published to notify monitoring flow

**Data validation failures (SAP rejects the payload):**
- Log the rejection with SAP return code and message
- Do not retry — human review required
- Flag the originating Salesforce record with an integration status field

**Idempotency violations (duplicate event received):**
- External ID upsert handles silently — no error, no duplicate record
- Log at INFO level for audit trail

---

## Naming Conventions

| Artifact | Pattern | Example |
|---|---|---|
| Named Credential | `SAP_[System]_[Environment]` | `SAP_ERP_Production` |
| Platform Event | `SAP_[Domain]_Event__e` | `SAP_CustomerSync_Event__e` |
| External ID Field | `SAP_[Object]_Id__c` | `SAP_Customer_Id__c` |
| Error Log Object | `Integration_Error_Log__c` | standard across all integrations |
| Correlation ID field | `Correlation_Id__c` | standard across all integration objects |
