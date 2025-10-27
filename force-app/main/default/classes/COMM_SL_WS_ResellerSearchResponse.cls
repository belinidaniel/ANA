/**
 * @author Daniel Lascas
 * @description Reseller mulesoft endpoint response type to search for available
 * products
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas        20/05/2024       ECOMM-386 - Original version
 * Daniel Reto          25/10/2024       ECOMM-327: Commerce API update
 **/
public inherited sharing class COMM_SL_WS_ResellerSearchResponse {
    public class BundleProduct {
        public String productId;
        public String productName;
        public Integer productQuantity;
        public String category;
        public Datetime startDate;
        public Datetime endDate;
    }

    public class Product {
        public String productId;
        public String productName;
        public String airportId;
        public String category;
        public Datetime startDate;
        public Datetime endDate;
        public Decimal minResellerPrice;
        public Integer stockAvailability;
        public Integer resellerAvailability;
        public List<BundleProduct> bundleProduct;
    }

    public Integer page;
    public Integer pageSize;
    public Integer totalPages;
    public List<Product> product;

    /**
     * @description Method to parse a JSON and generate an instance of the request class
     * @param json JSON as a String to be parsed
     * @return Instance of the Request Class
     */
    public static COMM_SL_WS_ResellerSearchResponse parse(String json) {
        return (COMM_SL_WS_ResellerSearchResponse) System.JSON.deserialize(json, COMM_SL_WS_ResellerSearchResponse.class);
    }
}