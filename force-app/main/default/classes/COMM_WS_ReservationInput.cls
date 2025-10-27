/**
 * @author Jose Passos
 * @description Model for reservation request.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      11/03/2024       Original version
 **/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class COMM_WS_ReservationInput {
    global class Product {
        global String actionRequestId;
        global String productId;
        global Datetime startDate;
        global Datetime endDate;
    }
    global String reservationId;
    global Integer expirationSeconds;
    global boolean extend;
    global List<Product> product;

    global COMM_WS_ReservationInput() {
        this.product = new List<Product>();
    }

    global void addProduct(String productId, Datetime startDate, Datetime endDate) {
        Product prod = new Product();
        prod.productId = productId;
        prod.startDate = startDate;
        prod.endDate = endDate;
        product.add(prod);
    }

    global void addProduct(String productId, Datetime startDate, Datetime endDate, String actionRequestId) {
        Product prod = new Product();
        prod.productId = productId;
        prod.startDate = startDate;
        prod.endDate = endDate;
        prod.actionRequestId = actionRequestId;
        product.add(prod);
    }

    public static COMM_WS_ReservationInput parse(String json) {
        return (COMM_WS_ReservationInput) System.JSON.deserialize(json, COMM_WS_ReservationInput.class);
    }
}