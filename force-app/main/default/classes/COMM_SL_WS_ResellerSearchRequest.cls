/**
 * @author Daniel Lascas
 * @description Reseller mulesoft endpoint request type to search for available
 * products
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas        20/05/2024       ECOMM-386 - Original version
 **/
public inherited sharing class COMM_SL_WS_ResellerSearchRequest {
    public String resellerId;
    public String airportId;
    public String productCategory;
    public Datetime startDate;
    public Datetime endDate;
    public Integer page;
    public Integer pageSize;

    /**
     * @description Method to parse a JSON and generate an instance of the request class
     * @param json JSON as a String to be parsed
     * @return Instance of the Request Class
     */
    public static COMM_SL_WS_ResellerSearchRequest parse(String json) {
        return (COMM_SL_WS_ResellerSearchRequest) System.JSON.deserialize(json, COMM_SL_WS_ResellerSearchRequest.class);
    }
}