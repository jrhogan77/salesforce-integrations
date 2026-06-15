public with sharing class ExternalApiResponse {

    public Integer statusCode    { get; private set; }
    public String  body          { get; private set; }
    public Boolean success       { get; private set; }
    public String  errorMessage  { get; private set; }
    public String  correlationId { get; set; }

    public ExternalApiResponse(HttpResponse res) {
        this.statusCode = res.getStatusCode();
        this.body       = res.getBody();
        this.success    = (statusCode >= 200 && statusCode < 300);
        if (!success) {
            this.errorMessage = 'HTTP ' + statusCode + ' - ' + res.getStatus() + ': ' + body;
        }
    }

    public Map<String,Object> getBodyAsMap() {
        if (String.isBlank(body)) return new Map<String,Object>();
        return (Map<String,Object>) JSON.deserializeUntyped(body);
    }

    public String getField(String key) {
        Map<String,Object> parsed = getBodyAsMap();
        return parsed.containsKey(key) ? String.valueOf(parsed.get(key)) : null;
    }
}
