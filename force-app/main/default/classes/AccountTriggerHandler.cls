/**
 * Example handler: normalises data before save and publishes an
 * Integration_Event__e after save so downstream systems (MuleSoft, ERP)
 * receive changes asynchronously instead of through synchronous callouts.
 */
public with sharing class AccountTriggerHandler extends TriggerHandler {

    private static final Set<String> TRACKED_FIELDS = new Set<String>{ 'Name', 'Phone', 'Industry', 'BillingCity', 'BillingState' };

    protected override void beforeInsert(List<SObject> newRecords) {
        normalise((List<Account>) newRecords);
    }

    protected override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        normalise((List<Account>) newRecords);
    }

    protected override void afterInsert(List<SObject> newRecords) {
        IntegrationEventPublisher.publish(newRecords, 'CREATED');
    }

    protected override void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        List<SObject> changed = new List<SObject>();
        for (SObject rec : newRecords) {
            SObject old = oldRecords.get(rec.Id);
            for (String f : TRACKED_FIELDS) {
                if (rec.get(f) != old.get(f)) { changed.add(rec); break; }
            }
        }
        IntegrationEventPublisher.publish(changed, 'UPDATED');
    }

    private void normalise(List<Account> accounts) {
        for (Account a : accounts) {
            if (a.Name != null) { a.Name = a.Name.normalizeSpace(); }
            if (a.BillingState != null) { a.BillingState = a.BillingState.trim().toUpperCase(); }
            if (a.Phone != null) {
                String digits = a.Phone.replaceAll('[^0-9]', '');
                if (digits.length() == 10) {
                    a.Phone = '(' + digits.left(3) + ') ' + digits.mid(3, 3) + '-' + digits.right(4);
                }
            }
        }
    }
}
