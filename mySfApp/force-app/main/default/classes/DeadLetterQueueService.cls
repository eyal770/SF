public with sharing class DeadLetterQueueService {
    @future(callout=true)
    public static void sendToDLQ(String errorMessage, String contextInfo) {
        sendToDLQ(errorMessage, contextInfo, null);
    }

    // Overload for dependency injection (mocking)
    public static void sendToDLQ(String errorMessage, String contextInfo, Http httpInstance) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:ExternalDLQ'); // Named Credential
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

            Map<String, Object> payload = new Map<String, Object>();
            payload.put('timestamp', String.valueOf(System.now()));
            payload.put('errorMessage', errorMessage);
            payload.put('context', contextInfo);

            req.setBody(JSON.serialize(payload));

            Http http = (httpInstance == null) ? new Http() : httpInstance;
            HttpResponse res = http.send(req);

            if (res.getStatusCode() >= 300) {
                System.debug('DLQ responded with error: ' + res.getBody());
            }
        } catch (Exception ex) {
            System.debug('Failed to send to DLQ: ' + ex.getMessage());
        }
    }
}
