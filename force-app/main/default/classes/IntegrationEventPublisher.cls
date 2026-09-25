public with sharing class IntegrationEventPublisher {

    @TestVisible
    private static List<Integration_Event__e> published = new List<Integration_Event__e>();

    public static void publish(List<SObject> records, String eventType) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Integration_Event__e> events = new List<Integration_Event__e>();
        for (SObject rec : records) {
            events.add(new Integration_Event__e(
                Record_Id__c = rec.Id,
                Object_Name__c = rec.getSObjectType().getDescribe().getName(),
                Event_Type__c = eventType,
                Payload__c = JSON.serialize(rec, true)
            ));
        }
        List<Database.SaveResult> results = EventBus.publish(events);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'Event publish failed for ' + events[i].Record_Id__c + ': ' + results[i].getErrors());
            }
        }
        published.addAll(events);
    }
}
