@isTest
private class LoanRequestTriggerHandlerTest {
    
    @isTest
    static void testHandleAfterUpdate_ApprovedCreatesAuditAndTask() {
        
        Customer__c cust = new Customer__c(Name = 'Test Customer Apex', Email__c = 'test@example.com');
        insert cust;
        Id custId = cust.Id;
        
        
        LoanRequest__c lr = new LoanRequest__c();
        lr.Customer__c = custId;
        lr.LoanAmount__c = 400000;
        lr.LoanStatus__c = 'Pending';
        insert lr;
        
        // Capture old version (as it was before update)
        LoanRequest__c oldLr = [SELECT Id, LoanStatus__c, LoanAmount__c FROM LoanRequest__c WHERE Id = :lr.Id];
        
        // Measure counts before update
        Integer beforeTasks = [SELECT count() FROM Task WHERE WhatId = :lr.Id AND Subject = 'High Value Loan Request'];
        Integer beforeApprovalAudits = [SELECT count() FROM Audit__c WHERE LoanRequest__c = :lr.Id AND Action__c = 'Loan Approved'];
        Integer beforeStatusAudits = [SELECT count() FROM Audit__c WHERE LoanRequest__c = :lr.Id AND Action__c = 'Loan Status Changed'];
        
        Test.startTest();
        lr.LoanStatus__c = 'Approved';
        update lr;
        Test.stopTest();
        
        // Measure counts after update
        Integer afterTasks = [SELECT count() FROM Task WHERE WhatId = :lr.Id AND Subject = 'High Value Loan Request'];
        Integer afterApprovalAudits = [SELECT count() FROM Audit__c WHERE LoanRequest__c = :lr.Id AND Action__c = 'Loan Approved'];
        Integer afterStatusAudits = [SELECT count() FROM Audit__c WHERE LoanRequest__c = :lr.Id AND Action__c = 'Loan Status Changed'];
        
        // Assert counts increased
        System.assert(afterTasks > beforeTasks, 'High value loan Task count should increase after update');
        System.assert(afterApprovalAudits > beforeApprovalAudits, 'Loan Approved audit count should increase after approval');
        System.assert(afterStatusAudits > beforeStatusAudits, 'Loan Status Changed audit count should increase after status change');
    }

    @isTest
    static void testHandleMissingCustomerDoesNotThrow() {
        // Attempt to create LoanRequest__c with missing Customer__c and verify insert fails
        Integer beforeAuditCount = [SELECT count() FROM Audit__c WHERE Action__c = 'Loan Approved'];

        LoanRequest__c lr = new LoanRequest__c();
        // Intentionally leave Customer__c blank to simulate missing required lookup
        lr.LoanAmount__c = 50000;
        lr.LoanStatus__c = 'Pending';

        Boolean threw = false;
        try {
            insert lr;
        } catch (DmlException ex) {
            threw = true;
            // dry-catch: ensure the DML failed due to required field
            System.assert(ex.getMessage().contains('REQUIRED_FIELD_MISSING') || ex.getMessage().contains('Required fields are missing'));
        }

        System.assert(threw, 'Insert should have thrown a DmlException due to missing Customer__c');

        // Ensure no Loan Approved audits were created
        Integer afterAuditCount = [SELECT count() FROM Audit__c WHERE Action__c = 'Loan Approved'];
        System.assertEquals(beforeAuditCount, afterAuditCount, 'No new Loan Approved audits should be created when insert fails');
    }
}