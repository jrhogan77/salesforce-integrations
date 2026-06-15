public with sharing class HttpCalloutService {

    private static final Integer MAX_RETRIES = 3;

    public static ExternalApiResponse send(ExternalApiRequest request) {
        HttpRequest  req  = buildHttpRequest(request);
        Http         http = new Http();
        HttpResponse res;
        Integer      attempts = 0;

        while (attempts < MAX_RETRIES) {
            try {
                res = http.send(req);
                if (res.getStatusCode() < 500 && res.getStatusCode() != 429) break;
            } catch (CalloutException e) {
                if (attempts == MAX_RETRIES - 1) throw e;
            }
            attempts++;
        }

        ExternalApiResponse response = new ExternalApiResponse(res);
        response.correlationId = request.correlationId;
        log(request, response);
        return response;
    }

    private static HttpRequest buildHttpRequest(ExternalApiRequest request) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + request.namedCredential + request.path);
        req.setMethod(request.method);
        req.setTimeout(request.timeoutMs);
        req.setHeader('Content-Type',     'application/json');
        req.setHeader('Accept',           'application/json');
        req.setHeader('X-Correlation-Id', request.correlationId);
        if (request.headers != null) {
            for (String key : request.headers.keySet()) {
                req.setHeader(key, request.headers.get(key));
            }
        }
        if (String.isNotBlank(request.body)) {
            req.setBody(request.body);
        }
        return req;
    }

    private static void log(ExternalApiRequest req, ExternalApiResponse res) {
        System.debug(
            LoggingLevel.INFO,
            '[HttpCalloutService] correlationId=' + req.correlationId +
            ' credential='  + req.namedCredential +
            ' path='        + req.path +
            ' method='      + req.method +
            ' status='      + res.statusCode +
            ' success='     + res.success
        );
    }
}
