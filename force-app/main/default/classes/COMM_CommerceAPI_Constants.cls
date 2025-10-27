public class COMM_CommerceAPI_Constants {
    public static final String BLANK_ORDER_ID = 'ANA-COMMAPI00001';
    public static final String RESELLER_NOT_FOUND = 'ANA-COMMAPI00002';
    public static final String BLANK_RESSELER = 'ANA-COMMAPI00003';
    public static final String BLANK_PRODUCT_ID = 'ANA-COMMAPI00004';
    public static final String PRODUCT_NOT_FOUND = 'ANA-COMMAPI00005';
    public static final String BLANK_DATES = 'ANA-COMMAPI00006';
    public static final String BAD_DATES = 'ANA-COMMAPI00007';
    public static final String NO_ORDER_ITEMS = 'ANA-COMMAPI00008';
    public static final String BLANK_ORDER_LINE_ID = 'ANA-COMMAPI00009';
    public static final String BLANK_PASSENGER_NAME = 'ANA-COMMAPI00010';
    public static final String BAD_BUNDLE = 'ANA-COMMAPI00011';
    public static final String RESELLER_SALESCHANNEL_NOT_FOUND = 'ANA-COMMAPI00012';
    public static final String PRICING_NOT_FOUND = 'ANA-COMMAPI00013';
    public static final String BLANK_BUNDLE_LINE_ID = 'ANA-COMMAPI00014';
    public static final String PAYMENT_GATEWAY_NOT_FOUND = 'ANA-COMMAPI00015';
    public static final String QUANTITY_EXCEEDS_LIMIT = 'ANA-COMMAPI00016';
    public static final String UNAUTHORIZED_PRODUCTS = 'ANA-COMMAPI00017';
    public static final String INVALID_ORDER_ITEMS = 'ANA-COMMAPI00018';
    public static final String BAD_ORDER_SUMMARY_ID = 'ANA-COMMAPI00019';
    public static final String INVALID_ORDERITEMSUMMARY_NOT_CANCELLED_ERROR = 'ANA-COMMAPI00020';

    public static final Map<String, String> ERROR_MESSAGE_MAP = new Map<String, String>{
        BLANK_ORDER_ID => 'orderId is mandatory',
        RESELLER_NOT_FOUND => 'Reseller id not found',
        BLANK_RESSELER => 'resellerId is mandatory',
        BLANK_PRODUCT_ID => 'productId is mandatory',
        PRODUCT_NOT_FOUND => 'Product id not found',
        BLANK_DATES => 'startDate and endDate are mandatory',
        BAD_DATES => 'endDate must be equal or greater than startDate',
        NO_ORDER_ITEMS => 'orderItems cannot be empty',
        BLANK_ORDER_LINE_ID => 'orderLineId is mandatory',
        BLANK_PASSENGER_NAME => 'passengerName is mandatory',
        BAD_BUNDLE => 'Bundle products are incorrect',
        QUANTITY_EXCEEDS_LIMIT => 'Product quantity requested exceeds daily limit',
        BLANK_BUNDLE_LINE_ID => 'Bundle Line Id is mandatory for bundles',
        UNAUTHORIZED_PRODUCTS => 'There are products that are not authorized for this reseller',
        RESELLER_SALESCHANNEL_NOT_FOUND => 'Internal error: Reseller sales channel not found',
        PRICING_NOT_FOUND => 'Internal error: Could find not the pricing for a product',
        PAYMENT_GATEWAY_NOT_FOUND => 'Internal error: Payment Gateway not found',
        INVALID_ORDER_ITEMS => 'Some Order Item Summary Ids do not exist or are already cancelled: ',
        BAD_ORDER_SUMMARY_ID => 'Order Summary Ids do not exist.',
        INVALID_ORDERITEMSUMMARY_NOT_CANCELLED_ERROR => 'Some Order Item Summary were not cancelled: '
    };
}