/**
 * @author Tiago Santos
 * @description Model for edit invoice request.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Tiago Santos     20/07/2025       Original version
 **/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_WS_EditInvoiceInput {
    
    public String firstName {get; set;}
    public String lastName {get; set;}
    public String vatNumber {get; set;}
    public String address {get; set;}
    public String postalCode {get; set;}
    public String city {get; set;}
    public String country {get; set;}
    public String countryCode {get; set;}
    public String orderNumber {get; set;}

    public static COMM_WS_EditInvoiceInput parse(String json) {
        return (COMM_WS_EditInvoiceInput) System.JSON.deserialize(json, COMM_WS_EditInvoiceInput.class);
    }
}