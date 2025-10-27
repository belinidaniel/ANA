/**
 * @author Diogo Gonçalves
 * @description Model for Create Reseller Order request
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves      06/05/2024       Original version
 **/
public class COMM_WS_ResellerOrderInput {
    public String resellerId { get; set; }
    public String orderId { get; set; }
    public List<OrderItem> orderItems { get; set; }

    public class OrderItem {
        public String orderLineId { get; set; }
        public String bundleProductId { get; set; }
        public String bundleLineId { get; set; }
        public String productId { get; set; }
        public Datetime startDate { get; set; }
        public Datetime endDate { get; set; }
        public String passengerName { get; set; }
        public String licensePlate { get; set; }
    }

    public List<String> getErrors() {
        List<String> errors = new List<String>();

        // Validate mandatory fields in Order
        if (String.isBlank(resellerId)) {
            errors.add(COMM_CommerceAPI_Constants.BLANK_RESSELER);
        }
        if (String.isBlank(orderId)) {
            errors.add(COMM_CommerceAPI_Constants.BLANK_ORDER_ID);
        }
        if (this.orderItems == null || this.orderItems.isEmpty()) {
            errors.add(COMM_CommerceAPI_Constants.NO_ORDER_ITEMS);
        } else {
            errors.addAll(this.getOrderItemsErrors());
        }

        return errors;
    }

    public List<String> getOrderItemsErrors() {
        List<String> errors = new List<String>();
        for (OrderItem item : orderItems) {
            if (String.isBlank(item.orderLineId)) {
                errors.add(COMM_CommerceAPI_Constants.BLANK_ORDER_LINE_ID);
            }
            if (String.isBlank(item.productId)) {
                errors.add(COMM_CommerceAPI_Constants.BLANK_PRODUCT_ID);
            }
            if (item.startDate == null || item.endDate == null) {
                errors.add(COMM_CommerceAPI_Constants.BLANK_DATES);
            } else if (item.endDate < item.startDate) {
                errors.add(COMM_CommerceAPI_Constants.BAD_DATES);
            }
            if (String.isBlank(item.passengerName)) {
                errors.add(COMM_CommerceAPI_Constants.BLANK_PASSENGER_NAME);
            }
            if (String.isNotBlank(item.bundleProductId) && String.isBlank(item.bundleLineId)) {
                errors.add(COMM_CommerceAPI_Constants.BLANK_BUNDLE_LINE_ID);
            }
        }
        return errors;
    }

    public static COMM_WS_ResellerOrderInput parse(String jsonString) {
        return (COMM_WS_ResellerOrderInput) JSON.deserialize(jsonString, COMM_WS_ResellerOrderInput.class);
    }

    public List<String> getProductIds() {
        Set<String> productIds = new Set<String>();
        for (OrderItem item : this.orderItems) {
            productIds.add(item.productId);
            if (String.isNotBlank(item.bundleProductId)) {
                productIds.add(item.bundleProductId);
            }
        }
        return new List<String>(productIds);
    }

    /**
     * @description Get the bundle Ids purchased in the order
     */
    public Set<String> getBundleIds() {
        Set<String> bundleIds = new Set<String>();
        for (OrderItem item : this.orderItems) {
            if (String.isNotBlank(item.bundleProductId)) {
                bundleIds.add(item.bundleProductId);
            }
        }
        return bundleIds;
    }

    public Map<String, List<String>> getProductsByBundleId() {
        Map<String, List<String>> productsByBundleId = new Map<String, List<String>>();
        for (OrderItem item : this.orderItems) {
            if (String.isBlank(item.bundleProductId)) {
                continue;
            }
            String orderLineBundleId = item.orderLineId + ':' + item.bundleProductId; //ensures that the bundle Id is unique per OrderItem

            if (productsByBundleId.containsKey(orderLineBundleId)) {
                productsByBundleId.get(orderLineBundleId).add(item.productId);
            } else {
                productsByBundleId.put(orderLineBundleId, new List<String>{ item.productId });
            }
        }
        return productsByBundleId;
    }

    public Map<String, Integer> getProductQuantities() {
        Map<String, Integer> quantitiesByProduct = new Map<String, Integer>();
        for (OrderItem item : this.orderItems) {
            if (quantitiesByProduct.containsKey(item.productId)) {
                Integer currentQuantity = quantitiesByProduct.get(item.productId);
                quantitiesByProduct.put(item.productId, ++currentQuantity);
            } else {
                quantitiesByProduct.put(item.productId, 1);
            }
        }
        return quantitiesByProduct;
    }
}