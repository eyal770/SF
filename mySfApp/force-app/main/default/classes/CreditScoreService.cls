public with sharing class CreditScoreService {
    public static Map<Id, Integer> getBulkCreditScores(Set<Id> customerIds, Http httpInstance) {
        Map<Id, Integer> results = new Map<Id, Integer>();

        List<Customer__c> customers = [
            SELECT Id, NationalId__c FROM Customer__c WHERE Id IN :customerIds
        ];

        // Build request payload
        List<Object> payloadCustomers = new List<Object>();
        for (Customer__c c : customers) {
            payloadCustomers.add(new Map<String, Object>{ 'nationalId' => c.NationalId__c, 'sfId' => c.Id });
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:BankOfIsraelAPI/credit-scores');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{ 'customers' => payloadCustomers }));

        Http http = (httpInstance == null) ? new Http() : httpInstance;
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> apiResults = (List<Object>) parsed.get('results');
            for (Object o : apiResults) {
                Map<String, Object> entry = (Map<String, Object>) o;
                Id custId = (Id) entry.get('sfId');
                Integer score = Integer.valueOf(String.valueOf(entry.get('creditScore')));
                results.put(custId, score);
            }
        } else {
            throw new CalloutException('API failed: ' + res.getStatus() + ' ' + res.getBody());
        }

        return results;
    }
    // Overload for production usage
    public static Map<Id, Integer> getBulkCreditScores(Set<Id> customerIds) {
        return getBulkCreditScores(customerIds, null);
    }
}
