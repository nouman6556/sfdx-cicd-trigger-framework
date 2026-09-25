@IsTest
private class TriggerFrameworkTest {

    @IsTest
    static void insertNormalisesAndPublishes() {
        Test.startTest();
        insert new Account(Name = '  Acme   Health  ', Phone = '312.555.0100', BillingState = ' il ');
        Test.stopTest(); // delivers platform events

        Account a = [SELECT Name, Phone, BillingState FROM Account LIMIT 1];
        Assert.areEqual('Acme Health', a.Name);
        Assert.areEqual('(312) 555-0100', a.Phone);
        Assert.areEqual('IL', a.BillingState);
        Assert.areEqual(1, IntegrationEventPublisher.published.size());
        Assert.areEqual(1, [SELECT COUNT() FROM Task WHERE WhatId = :a.Id AND Subject = 'Integration sync: CREATED']);
    }

    @IsTest
    static void updateOnlyPublishesTrackedChanges() {
        Account a = new Account(Name = 'Globex');
        insert a;
        IntegrationEventPublisher.published.clear();

        Test.startTest();
        a.Description = 'untracked field';
        update a;
        Integer afterUntracked = IntegrationEventPublisher.published.size();
        a.Industry = 'Healthcare';
        update a;
        Test.stopTest();

        Assert.areEqual(0, afterUntracked, 'Untracked change should not publish');
        Assert.areEqual(1, IntegrationEventPublisher.published.size());
        Assert.areEqual('UPDATED', IntegrationEventPublisher.published[0].Event_Type__c);
    }

    @IsTest
    static void bypassSkipsHandler() {
        TriggerHandler.bypass('AccountTriggerHandler');
        Assert.isTrue(TriggerHandler.isBypassed('AccountTriggerHandler'));
        insert new Account(Name = 'Spaced   Out');
        TriggerHandler.clearBypass('AccountTriggerHandler');

        Assert.areEqual('Spaced   Out', [SELECT Name FROM Account LIMIT 1].Name, 'Handler bypassed, so no normalisation');
        Assert.areEqual(0, IntegrationEventPublisher.published.size());
    }

    @IsTest
    static void runOutsideTriggerIsNoOp() {
        new AccountTriggerHandler().setMaxLoops(1).run();
        Assert.areEqual(0, IntegrationEventPublisher.published.size());
    }
}
