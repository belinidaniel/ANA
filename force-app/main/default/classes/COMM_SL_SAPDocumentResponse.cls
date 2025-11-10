/**
 * @author Ruben Rodrigues
 * @description SAP mulesoft endpoint response type to generate a fiscal document
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues      12/04/2024       Original version
 **/
public inherited sharing class COMM_SL_SAPDocumentResponse {
    public String documentId;
    public String resultDesc;
    public String resultCode;

    public static COMM_SL_SAPDocumentResponse parse(String json) {
        return (COMM_SL_SAPDocumentResponse) System.JSON.deserialize(json, COMM_SL_SAPDocumentResponse.class);
    }
}