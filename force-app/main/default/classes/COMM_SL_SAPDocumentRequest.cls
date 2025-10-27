/**
 * @author Ruben Rodrigues
 * @description SAP mulesoft endpoint request type to generate a fiscal document
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues      12/04/2024       Original version
 **/
public inherited sharing class COMM_SL_SAPDocumentRequest {
    public class OrderItems {
        public String location;
        public String productId;
        public String taxCode;
        public Decimal quantity;
        public String description;
        public Decimal totalNetAmount;
        public Decimal totalVatAmount;
        public String itemReference;
    }

    public String paymentMode;
    public String id;
    public String documentSerie;
    public String documentType;
    public String documentDate;
    public String billingDate;
    public Integer paymentDays;
    public String dueDate;
    public Decimal netAmount;
    public Decimal taxAmout;
    public Decimal vatDifferenceAmount;
    public String billingName;
    public String billingAddicionalName;
    public String billingEmail;
    public String billingAddress;
    public String billingPostalCode;
    public String billingCity;
    public String billingVat;
    public String billingCountry;
    public String reference;
    public String creditMemoPay; // used for Credit Memo Direct call from B2C (Edit Invoice)
    public List<OrderItems> orderItems;

    /**
     * @description Method to parse a JSON and generate an instance of the request class
     * @param json JSON as a String to be parsed
     * @return Instance of the Request Class
     */
    public static COMM_SL_SAPDocumentRequest parse(String json) {
        return (COMM_SL_SAPDocumentRequest) System.JSON.deserialize(json, COMM_SL_SAPDocumentRequest.class);
    }
}