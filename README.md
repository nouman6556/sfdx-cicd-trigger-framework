# SFDX CI/CD + Trigger Framework + Platform Events

A starter Salesforce DX project that shows how I set up **enterprise Apex**: a one-trigger-per-object **trigger framework**, **event-driven integration** with Platform Events, and a **GitHub Actions** pipeline that runs static analysis, validates in a scratch org and runs Apex tests on every pull request.

> Portfolio / reference project. Clone it as a template for new Salesforce repos.

## What it demonstrates

**Trigger framework (`TriggerHandler`)**
- One trigger per object; all logic lives in a handler subclass with `beforeInsert`, `afterUpdate` and similar methods.
- Bypass switch per handler (`TriggerHandler.bypass('AccountTriggerHandler')`) for data loads and migrations.
- Recursion guard with a configurable max loop count.

**Event-driven integration**
- `AccountTriggerHandler` publishes `Integration_Event__e` (high-volume Platform Event, *publish after commit*) only when tracked fields change.
- `IntegrationEventTrigger` and `IntegrationEventHandler` show a subscriber. In production this is where MuleSoft, the Pub/Sub API or a Queueable callout picks up the change, keeping callouts out of the transaction.

**CI/CD (`.github/workflows/ci.yml`)**
1. **Static analysis:** Salesforce Code Analyzer (PMD and ESLint), with the HTML report uploaded as a build artifact.
2. **Validate:** JWT login to the Dev Hub, create a scratch org, deploy the source.
3. **Test:** `RunLocalTests` with code coverage, then the scratch org is deleted.

## Repo layout

```
force-app/main/default/
  classes/   TriggerHandler, AccountTriggerHandler, IntegrationEventPublisher,
             IntegrationEventHandler, TriggerFrameworkTest
  triggers/  AccountTrigger, IntegrationEventTrigger
  objects/   Integration_Event__e (Record_Id__c, Object_Name__c, Event_Type__c, Payload__c)
config/project-scratch-def.json
.github/workflows/ci.yml
```

## Enable the pipeline

1. Create a Connected App or External Client App in your Dev Hub with JWT bearer flow and upload a certificate.
2. Add these repository secrets: `SF_CONSUMER_KEY`, `SF_JWT_KEY` (the private key contents) and `SF_DEVHUB_USERNAME`.
3. Open a pull request against `main`.

Without the secrets, the pipeline still runs static analysis and skips the scratch-org stage.

## Local

```bash
sf org create scratch -f config/project-scratch-def.json -a tf -d
sf project deploy start -d force-app
sf apex run test -l RunLocalTests -w 10 -c
```

## Tech

Apex · Platform Events · Salesforce DX · GitHub Actions · Salesforce Code Analyzer (PMD) · Scratch Orgs · JWT OAuth
