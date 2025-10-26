public with sharing class LoanRequestTriggerHandler {
    
    public static void handleAfterInsertOrUpdate(
        List<LoanRequest__c> newList,
    Map<Id, LoanRequest__c> oldMap
    ) {
        // Query for related Customer__r fields to avoid null values
        Map<Id, LoanRequest__c> lrMap = new Map<Id, LoanRequest__c>();
        for (LoanRequest__c lr : newList) {
            lrMap.put(lr.Id, lr);
        }
        List<LoanRequest__c> lrWithCustomer = [
            SELECT Id, LoanAmount__c, LoanStatus__c, Customer__c,
                   Customer__r.Name, Customer__r.Email__c, Customer__r.Branch__c
            FROM LoanRequest__c
            WHERE Id IN :lrMap.keySet()
        ];
        Map<Id, LoanRequest__c> lrWithCustomerMap = new Map<Id, LoanRequest__c>();
        for (LoanRequest__c lr : lrWithCustomer) {
            lrWithCustomerMap.put(lr.Id, lr);
        }
        
        List<Task> tasksToInsert = new List<Task>();
        List<Audit__c> auditsToInsert = new List<Audit__c>();
        List<LoanRequestApprovedEvent__e> approvalEvents = new List<LoanRequestApprovedEvent__e>();
        List<CreditScoreRequested__e> creditScoreEvents = new List<CreditScoreRequested__e>();
        
        for (LoanRequest__c lrOrig : newList) {
            LoanRequest__c lr = lrWithCustomerMap.get(lrOrig.Id);
            LoanRequest__c oldLr = oldMap != null ? oldMap.get(lr.Id) : null;
            
            // Rule 1: Loan amount above 250,000 => Create Task
            // Create a Task only for new LoanRequests or when LoanAmount__c changed to > 250,000
            if(lr.LoanAmount__c > 250000 && (oldLr == null || oldLr.LoanAmount__c <= 250000 )) {
                String branch = (lr.Customer__r != null) ? lr.Customer__r.Branch__c : null;
                
                tasksToInsert.add(new Task(
                    Subject = 'High Value Loan Request',
                Description = 'Loan Request exceeds 250,000. Branch: ' + branch,
                WhatId = lr.Id,
                OwnerId = UserInfo.getUserId()
                    ));
            }
            
            // Rule 2: Loan Approved => Fire event + Audit
            if (lr.LoanStatus__c == 'Approved' && (oldLr == null || oldLr.LoanStatus__c != 'Approved')) {
                LoanRequestApprovedEvent__e evt = new LoanRequestApprovedEvent__e(
                    CustomerId__c     = lr.Customer__c,
                LoanRequestId__c  = lr.Id,
                CustomerEmail__c  = (lr.Customer__r != null) ? lr.Customer__r.Email__c : null,
                CustomerName__c   = (lr.Customer__r != null) ? lr.Customer__r.Name : null
                    );
                approvalEvents.add(evt);
                
                auditsToInsert.add(new Audit__c(
                    Action__c      = 'Loan Approved',
                Customer__c   = lr.Customer__c,
                LoanRequest__c = lr.Id,
                Message__c     = 'Loan Request approved for ' + ((lr.Customer__r != null) ? lr.Customer__r.Name : 'Unknown'),
                OccurredAt__c  = System.now()
                    ));
            }
            
            // Rule 3: Loan Status change => Audit
            if (oldLr != null && lr.LoanStatus__c != oldLr.LoanStatus__c) {
                auditsToInsert.add(new Audit__c(
                    Action__c      = 'Loan Status Changed',
                Customer__c   = lr.Customer__c,
                LoanRequest__c = lr.Id,
                Message__c     = 'Status changed from ' + oldLr.LoanStatus__c + ' to ' + lr.LoanStatus__c,
                OccurredAt__c  = System.now()
                    ));
            }
            
            // Rule 4: Fire Credit Score Request Event when new LoanRequest is created
            if (oldLr == null) {
                creditScoreEvents.add(new CreditScoreRequested__e(
                    CustomerId__c    = lr.Customer__c,
                LoanRequestId__c = lr.Id
                    ));
            }
        }
        
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
        if (!auditsToInsert.isEmpty()) {
            insert auditsToInsert;
        }
        if (!approvalEvents.isEmpty()) {
            Database.SaveResult[] evRes = EventBus.publish(approvalEvents);
        }
        if (!creditScoreEvents.isEmpty()) {
            Database.SaveResult[] csRes = EventBus.publish(creditScoreEvents);
        }
    }
}