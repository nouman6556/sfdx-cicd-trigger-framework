/**
 * Subscriber for Integration_Event__e. In production this would call an
 * external API via a Named Credential (Queueable + Database.AllowsCallouts)
 * or be consumed directly by MuleSoft / CometD / Pub/Sub API.
 * Here it records a Task on the Account as an audit trail.
 */
public with sharing class IntegrationEventHandler {

    public static void handle(List<Integration_Event__e> events) {
        List<Task> audit = new List<Task>();
        for (Integration_Event__e e : events) {
            if (e.Object_Name__c == 'Account' && e.Record_Id__c != null) {
                audit.add(new Task(
                    WhatId = e.Record_Id__c,
                    Subject = 'Integration sync: ' + e.Event_Type__c,
                    Status = 'Completed',
                    ActivityDate = Date.today()
                ));
            }
        }
        if (!audit.isEmpty()) {
            insert audit;
        }
    }
}
