/**
 * @author Rui Salgado
 * @description OMS Constants
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 **/
public class COMM_OMS_Constants {
    public static final String ACTIVE = 'Active',
        TEST = 'Test',
        POST = 'POST',
        CONTENT_TYPE = 'Content-Type',
        APPLICATION_JSON = 'application/json',
        UNKNOWN = 'Unknown',
        CONNECT_API_ERROR = 'CONNECT_API_ERROR',
        CONNECT_API_ERROR_MESSAGE = 'Connect REST API returned an unexpected error',
        PAYMENT_REFUND_ACTION = 'PAYMENT_REFUND',
        PAYGATE_GATEWAY_NAME = 'PayGate',
        GIFTCARD_GATEWAY_NAME = 'GiftCard',
        ANA_AEROPORTOS = 'ANA Aeroportos';

    public static final Integer HTTP_INTERNAL_ERROR_CODE = 500,
        HTTP_SUCCESS_CODE = 200,
        HTTP_ACCEPTED = 202,
        HTTP_CREATED = 201,
        HTTP_NO_CONTENT = 204;

    // UnifiedSettings Variables
    public static final String HTTP_LOG_ENABLED = 'HttpLogEnabled',
        HTTP_REQUEST_LOG_ENABLED = 'HttpRequestLogEnabled',
        HTTP_RESPONSE_LOG_ENABLED = 'HttpResponseLogEnabled';
}