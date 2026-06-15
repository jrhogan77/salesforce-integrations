public with sharing class ExternalApiRequest {

    public String             namedCredential { get; set; }
    public String             path            { get; set; }
    public String             method          { get; set; }
    public String             body            { get; set; }
    public Map<String,String> headers         { get; set; }
    public Integer            timeoutMs       { get; set; }
    public String             correlationId   { get; set; }

    public ExternalApiRequest(String namedCredential, String path, String method) {
        this.namedCredential = namedCredential;
        this.path            = path;
        this.method          = method;
        this.headers         = new Map<String,String>();
        this.timeoutMs       = 30000;
        this.correlationId   = generateCorrelationId();
    }

    public ExternalApiRequest withBody(String body) {
        this.body = body;
        return this;
    }

    public ExternalApiRequest withHeader(String key, String value) {
        this.headers.put(key, value);
        return this;
    }

    public ExternalApiRequest withTimeout(Integer ms) {
        this.timeoutMs = ms;
        return this;
    }

    private String generateCorrelationId() {
        return EncodingUtil.convertToHex(Crypto.generateAesKey(128)).substring(0, 16);
    }
}
