trigger CreditScoreRequestedTrigger on CreditScoreRequested__e (after insert) {

    Set<Id> customerIds = new Set<Id>();
    Map<Id, Id> loanByCustomer = new Map<Id, Id>();

    for (CreditScoreRequested__e evt : Trigger.new) {
        customerIds.add(evt.CustomerId__c);
        loanByCustomer.put(evt.CustomerId__c, evt.LoanRequestId__c);
    }

    try {
        Map<Id, Integer> scoresByCustomer = CreditScoreService.getBulkCreditScores(customerIds);

        List<Customer__c> custToUpdate = new List<Customer__c>();
        List<LoanRequest__c> loansToUpdate = new List<LoanRequest__c>();
        List<Audit__c> audits = new List<Audit__c>();

        for (Id custId : customerIds) {
            Integer score = scoresByCustomer.get(custId);
            Id loanId = loanByCustomer.get(custId);

            if (score != null) {
                custToUpdate.add(new Customer__c(Id = custId, CreditScore__c = score));
                loansToUpdate.add(new LoanRequest__c(Id = loanId, LoanStatus__c = 'Ready for Review'));

                audits.add(new Audit__c(
                    LoanRequest__c = loanId,
                    Customer__c    = custId,
                    Action__c      = 'Credit Score Checked',
                    Message__c    = String.valueOf(score),
                    Actor__c       = UserInfo.getUserId(),
                    OccurredAt__c  = System.now()
                ));
            } else {
                audits.add(new Audit__c(
                    LoanRequest__c = loanId,
                    Customer__c    = custId,
                    Action__c      = 'Credit Score Failed',
                    Message__c    = 'No score returned',
                    Actor__c       = UserInfo.getUserId(),
                    OccurredAt__c  = System.now()
                ));
            }
        }

        if (!custToUpdate.isEmpty()) update custToUpdate;
        if (!loansToUpdate.isEmpty()) update loansToUpdate;
        if (!audits.isEmpty()) insert audits;

    } catch (Exception ex) {
        DeadLetterQueueService.sendToDLQ(ex.getMessage(), 'Bulk Credit Score Callout failed');
    }
}
