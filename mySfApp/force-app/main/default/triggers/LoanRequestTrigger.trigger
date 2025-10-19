trigger LoanRequestTrigger on LoanRequest__c (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            LoanRequestTriggerHandler.handleAfterInsertOrUpdate(
                Trigger.new,
                Trigger.isUpdate ? Trigger.oldMap : null
            );
        }
    }
}
