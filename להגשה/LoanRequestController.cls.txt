public with sharing class LoanRequestController {

    /**
     * Saves a LoanRequest__c record.
     * If a Customer__c with the given name doesn't exist, creates one.
     * @param customerName - Customer__c.Name
     * @param loanAmount   - LoanRequest__c.LoanAmount__c
     * @param loanStatus   - LoanRequest__c.LoanStatus__c
     * @return Id of the created LoanRequest__c
     */
    @AuraEnabled
    public static Id saveLoanRequest(String customerName, Decimal loanAmount, String loanStatus) {
        if (String.isBlank(customerName)) {
            throw new AuraHandledException('Customer name is required.');
        }
        if (loanAmount == null || loanAmount <= 0) {
            throw new AuraHandledException('Loan amount must be greater than zero.');
        }
        if (String.isBlank(loanStatus)) {
            throw new AuraHandledException('Loan status is required.');
        }

        // Find or create customer by name (demo logic)
        Id customerId;
        List<Customer__c> existing = [
            SELECT Id
            FROM Customer__c
            WHERE Name = :customerName
            LIMIT 1
        ];
        if (existing.isEmpty()) {
            Customer__c c = new Customer__c(Name = customerName);
            insert c;
            customerId = c.Id;
        } else {
            customerId = existing[0].Id;
        }

        LoanRequest__c lr = new LoanRequest__c(
            Customer__c   = customerId,
            LoanAmount__c = loanAmount,
            LoanStatus__c     = loanStatus
        );
        insert lr;
        return lr.Id;
    }

    /**
     * Retrieves a LoanRequest__c by Id, including customer name.
     */
    @AuraEnabled(cacheable=true)
    public static LoanRequest__c getLoanRequestById(Id loanRequestId) {
        if (loanRequestId == null) {
            throw new AuraHandledException('Loan request Id is required.');
        }
        return [
            SELECT Id, Customer__c, Customer__r.Name, LoanAmount__c, LoanStatus__c, CreatedDate
            FROM LoanRequest__c
            WHERE Id = :loanRequestId
            LIMIT 1
        ];
    }
}
