trigger LoanRequestApprovedEventTrigger on LoanRequestApprovedEvent__e (after insert) {
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (LoanRequestApprovedEvent__e evt : Trigger.new) {
        if (String.isNotBlank(evt.CustomerEmail__c)) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{evt.CustomerEmail__c});
            mail.setSubject('Loan Request Approved');
            mail.setPlainTextBody(
                'Hello ' + evt.CustomerName__c + 
                ', your loan request has been approved.'
            );
            emails.add(mail);
        }
    }

    if (!emails.isEmpty()) {
        try {
            Messaging.sendEmail(emails);
        } catch (Exception ex) {
            List<Audit__c> errorAudits = new List<Audit__c>();
            for (LoanRequestApprovedEvent__e evt : Trigger.new) {
                errorAudits.add(new Audit__c(
                    LoanRequest__c = evt.LoanRequestId__c,
                    Customer__c    = evt.CustomerId__c,
                    Action__c      = 'Email Send Failed',
                    Message__c    = ex.getMessage(),
                    Actor__c       = UserInfo.getUserId(),
                    OccurredAt__c  = System.now()
                ));
            }
            insert errorAudits;
        }
    }
}
