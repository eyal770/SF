@isTest
private class LoanRequestApprovedEventTriggerTest {

    @isTest
    static void testEventTriggerSendsEmailOrCreatesNoFailureAudit() {
        // Create a customer to use as the event's CustomerId__c
        Customer__c cust = new Customer__c(Name = 'EvtTest Customer', Email__c = 'evt@test.example');
        insert cust;

        // Prepare platform event record
        LoanRequestApprovedEvent__e evt = new LoanRequestApprovedEvent__e(
            CustomerId__c = String.valueOf(cust.Id),
            LoanRequestId__c = 'a0B000000000001',
            CustomerEmail__c = 'unit@test.example',
            CustomerName__c = 'Unit Test Customer'
        );

        Test.startTest();
        // Publish the event
        Database.SaveResult[] results = EventBus.publish(new List<LoanRequestApprovedEvent__e>{ evt });
        Test.stopTest();

        // If email sending failed the trigger inserts Audit__c records with Action__c = 'Email Send Failed'
        Integer failCount = [SELECT count() FROM Audit__c WHERE Action__c = 'Email Send Failed'];
        System.assertEquals(0, failCount, 'There should be no failure audits after publishing the event in test context');
    }

    @isTest
    static void testEventWithNoEmailDoesNotSendOrFail() {
        Customer__c cust = new Customer__c(Name = 'EvtTest2', Email__c = 'evt2@test.example');
        insert cust;

        LoanRequestApprovedEvent__e evt = new LoanRequestApprovedEvent__e(
            CustomerId__c = String.valueOf(cust.Id),
            LoanRequestId__c = 'a0B000000000002',
            CustomerEmail__c = '',
            CustomerName__c = 'No Email Customer'
        );

        Test.startTest();
        Database.SaveResult[] results = EventBus.publish(new List<LoanRequestApprovedEvent__e>{ evt });
        Test.stopTest();

        // No emails attempted; ensure there are no Email Send Failed audits
        Integer failCount = [SELECT count() FROM Audit__c WHERE Action__c = 'Email Send Failed'];
        System.assertEquals(0, failCount, 'No failure audits should be created when CustomerEmail__c is empty');
    }
}
