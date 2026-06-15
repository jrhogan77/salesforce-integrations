# Event-Driven Integration Patterns
### Platform Events, CDC, and Async Architecture in Salesforce

---

## Why Event-Driven

Synchronous integrations couple systems tightly — when the downstream system is slow or unavailable, the Salesforce transaction fails. Event-driven architecture decouples the publish from the consume. The Salesforce transaction completes. The downstream system processes when it's ready. Failures are isolated and retryable without user impact.

---

## Platform Events

Platform Events are Salesforce's native pub/sub mechanism. They are schema-defined, governor-limit-friendly, and deliverable across org boundaries.

### Publish Pattern (Apex)

```apex
List<SAP_CustomerSync_Event__e> events = new List<SAP_CustomerSync_Event__e>();
for (Account acc : changedAccounts) {
    events.add(new SAP_CustomerSync_Event__e(
        Account_Id__c     = acc.Id,
        SAP_Customer_Id__c = acc.SAP_Customer_Id__c,
        Correlation_Id__c  = generateCorrelationId(),
        Operation__c       = 'UPSERT'
    ));
}
List<Database.SaveResult> results = EventBus.publish(events);
```

### Subscribe Pattern (Apex Trigger on Platform Event)

```apex
trigger SAP_CustomerSync_EventTrigger on SAP_CustomerSync_Event__e (after insert) {
    new SAPCustomerSyncHandler().processEvents(Trigger.new);
}
```

**Key rules:**
- Platform Event triggers run in their own transaction — they cannot roll back the publishing transaction
- Use `ReplayId` for durable subscriptions — events are retained for 72 hours (default) or 24 hours (high volume)
- Publish failures do not throw — always check `Database.SaveResult` for errors

---

## Change Data Capture (CDC)

CDC streams record changes (create, update, delete, undelete) from Salesforce to external subscribers without custom trigger code. Best used when the external system needs a reliable change feed without polling.

### When to use CDC over Platform Events

| Use CDC when... | Use Platform Events when... |
|---|---|
| External system needs raw field-level change data | You need to control exactly what is published |
| No custom logic needed on publish | Publish is conditional on business rules |
| Subscriber is an external system (MuleSoft, BTP) | Subscriber is Apex or Flow within Salesforce |

---

## Queueable Chain Pattern

For multi-step async processing where each step depends on the previous:

```apex
public class Step1Queueable implements Queueable, Database.AllowsCallouts {
    private List<Id> recordIds;

    public Step1Queueable(List<Id> recordIds) {
        this.recordIds = recordIds;
    }

    public void execute(QueueableContext ctx) {
        // Step 1 processing...

        // Chain to step 2 if records remain
        if (!recordIds.isEmpty()) {
            System.enqueueJob(new Step2Queueable(recordIds));
        }
    }
}
```

**Governor limit awareness:**
- Maximum 1 chained Queueable enqueue per execution context in synchronous context
- In async context (already in a Queueable): 1 additional enqueue allowed
- Batch Apex: use `Database.executeBatch` inside `finish()` for continuation patterns

---

## Dead Letter Handling

Events that fail processing must not disappear silently.

**Pattern:**
1. Wrap subscriber logic in try/catch
2. On catch: write to `Integration_Error_Log__c` with full event payload, error message, and retry count
3. Scheduled job queries error log for retryable failures and re-publishes the event
4. Non-retryable failures (data validation) flagged for human review — no auto-retry

This ensures every integration failure is visible, auditable, and actionable.
