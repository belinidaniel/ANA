/**
 * @author Jose Passos
 * @description Model for availability response.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      11/03/2024       Original version
 * Jose Passos      29/04/2024       Changed to support SFCC before you go Page requirements
 * Daniel Reto      07/05/2024       ECOMM-281
 **/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_WS_AvailabilityOutput {
    global class Product {
        global String productId;
        global Datetime startDate;
        global Datetime endDate;
        global Double available;
    }
    global List<Product> products;

    global class ProductRecord {
        // External reference which will contain Product Code and a Date (ProductCode_YYYYMMDD)
        global String externalId;
        // Contains the reservation hour (Hour_00, Hour_01, ...)
        global String locationIdentifier;
        // Max number of availability for current Product Code
        global Double onHand;
        // Number of capacities already reserved
        global Double reserved;
    }
    global class InventoryRecord {
        global List<ProductRecord> productList;
        global String productCode;
    }
    global List<InventoryRecord> inventory;

    public static COMM_WS_AvailabilityOutput parse(String json) {
        return (COMM_WS_AvailabilityOutput) System.JSON.deserialize(json, COMM_WS_AvailabilityOutput.class);
    }
}