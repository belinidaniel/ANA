/**
 * @description Mock class for HTTP Callouts
 */
public class HttpResponseSuccessMock implements HttpCalloutMock {
    private String responseJson;

    public HttpResponseSuccessMock(String responseJson) {
        this.responseJson = responseJson;
    }

    /**
     * @description Method to setup HTTP Callout response mock
     *
     * @param request HTTP request for mock
     * @return mock HTTP response
     */
    public HttpResponse respond(HttpRequest request) {
        // Prepare responseBody mock
        HTTPResponse res = new HTTPResponse();
        res.setBody(responseJson);
        res.setStatusCode(200);
        return res;
    }
}