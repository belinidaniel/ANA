/**
 * @author Ricardo Dias
 * @description Pricing Webservice class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Ricardo Dias    23/02/2024       Original version
 * Ricardo Dias    08/04/2024       Rework service
 **/
@RestResource(urlMapping='/pricing/*')
global with sharing class COMM_WS_Pricing {
    /**
     * @description Handles the POST request to calculate pricing for products. It processes the request to extract product codes,
     * start and end dates, validates them, and calculates pricing for the given date range and products
     * On success, it returns pricing information based on the cheapeast price. On failure, it logs the error and returns an error response
     */
    @HttpPost
    global static void doPost() {
        COMM_SL_WS_Pricing pricingCalculationInstance = new COMM_SL_WS_Pricing();
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        RestContext.response.addHeader('Content-Type', 'application/json');

        try {
            // Parse the request body to a map
            Map<String, Object> requestMap = COMM_RestServices_Utility.parseRequest(req.requestBody.toString());

            //Retrives the calculatePricingResponse from Pricing SL Class
            Map<String, Object> responseMap = pricingCalculationInstance.calculatePricingResponse(requestMap);

            COMM_RestServices_Utility.setSuccessResponse(res, responseMap);
        } catch (Exception e) {
            // Log and respond with an error in case of exceptions
            COMM_GEN_Utility.logError(e, 'Pricing Service Error', 'COMM_WS_Pricing');
            COMM_RestServices_Utility.setErrorResponse(res, COMM_RestServices_Utility.BAD_REQUEST, '{"message": "' + e.getMessage() + '"}');
        }
    }
}