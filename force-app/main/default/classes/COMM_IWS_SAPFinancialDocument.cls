/**
 * @author Daniel Lascas
 * @description SAP Financial Document Web Service interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/04/2024       ECOMM-194: Original version
 **/
public interface COMM_IWS_SAPFinancialDocument {
    /**
     * @description Method to send a request to SAP to generate an Invoice Document
     *
     * @param requestBodyMap Map with the body of the request
     * @return HTTP Response from SAP
     **/
    HttpResponse postFinancialDocument(Map<String, Object> requestBodyMap);

    /**
     * @description Method to send a request to SAP to get an Invoice Document
     *
     * @param requestMap Map with the request parameters
     * @return HTTP Response from SAP
     **/
    HttpResponse getFinancialDocument(Map<String, String> requestMap);
}