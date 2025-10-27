/**
 * @author Jose Passos
 * @description Model for availability request.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      11/03/2024       Original version
 * Jose Passos      29/04/2024       Changed to support SFCC before you go Page requirements
 **/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_WS_AvailabilityInput {
    global class Product {
        public String productId;
        global Datetime startDate;
        global Datetime endDate;
    }
    global List<Product> products;

    public static COMM_WS_AvailabilityInput parse(String json) {
        return (COMM_WS_AvailabilityInput) System.JSON.deserialize(json, COMM_WS_AvailabilityInput.class);
    }
}