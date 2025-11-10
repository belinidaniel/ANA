/**
 * @author Jose Passos
 * @description Class with OCI constants.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer            Date                Description
 * -----------------------------------------------------------------------------------
 * Jose Passos          11/03/2024          Original version
 * Jose Passos          28/03/2024          Add OCI process status constants
 * Jose Passos          30/04/2024          Add more error codes
 **/
public class COMM_OCI_Constants {
    public static final Integer MAX_REQUESTS = 100, MAX_EXPIRATION_SECONDS = 14400;

    public static final String INVENTORY_API = 'Inventory_API',
        CALLOUT_RESERVATION = 'B2C_API_Reserve',
        CALLOUT_RELEASE = 'B2C_API_Release',
        INVENTORY_API_COMMERCE = 'B2CCommerceAPI',
        INVENTORY_API_CONNECT = 'ConnectAPI',
        PRODUCT2_FAMILY_SUBSCRIPTION = 'Subscription',
        OCI_LOCATION_SUBSCRIPTIONS = 'Subscriptions',
        DATE_FORMAT = 'yyyyMMdd',
        OCI_LOCATION_HOUR_PATTERN = 'Hour_';

    /**
     * description OCI error codes and respective error message
     */
    public static final String ERROR_EXCEPTION_FOUND = 'ANA-OCI00000',
        ERROR_INVALID_DATE = 'ANA-OCI00001',
        ERROR_INV_NULL_START_DATE = 'ANA-OCI00002',
        ERROR_INV_NULL_END_DATE = 'ANA-OCI00003',
        ERROR_INVALID_EXPIRATION_SECONDS = 'ANA-OCI00010',
        ERROR_INVALID_PRODUCT = 'ANA-OCI00050',
        ERROR_INV_NULL_PRODUCT = 'ANA-OCI00051',
        ERROR_GET_PRICE = 'ANA-OCI00090',
        ERROR_RESERVATION_FAILED = 'ANA-OCI00100',
        ERROR_RESERVE_ROLLBACK_FAILED = 'ANA-OCI00150',
        ERROR_RELEASE_FAILED = 'ANA-OCI00200';

    /**
     * description OCI error codes and respective error message
     */
    public static final Map<String, String> OCI_ERROR_CODES = new Map<String, String>{
        ERROR_EXCEPTION_FOUND => 'Unexpected Exception',
        ERROR_INVALID_DATE => 'Start date must be equal or greater than End date',
        ERROR_INV_NULL_START_DATE => 'Start date cannot be null',
        ERROR_INV_NULL_END_DATE => 'End date cannot be null',
        ERROR_INVALID_EXPIRATION_SECONDS => 'Expiration Secconds must be lower or equal than ' +
        MAX_EXPIRATION_SECONDS +
        ' seconds',
        ERROR_INVALID_PRODUCT => 'Product does not exist or is Inactive:',
        ERROR_INV_NULL_PRODUCT => 'Product list cannot be null',
        ERROR_GET_PRICE => 'Error getting Price. Details:',
        ERROR_RESERVATION_FAILED => 'Reservation failed',
        ERROR_RESERVE_ROLLBACK_FAILED => 'Rollback Reserved Records failed',
        ERROR_RELEASE_FAILED => 'Release failed'
    };

    /**
     * description OCI stock Upload Constants
     */
    public static final String PROCESS_STATUS_NOT_PROCESSED = 'NOT PROCESSED',
        PROCESS_STATUS_PENDING = 'PENDING',
        PROCESS_STATUS_RUNNING = 'RUNNING',
        PROCESS_STATUS_COMPLETED = 'COMPLETED',
        PROCESS_STATUS_FAILED = 'FAILED',
        PRODUCT_FAMILY_PARKING = 'Parking',
        PRODUCT_FAMILY_LOUNGE = 'Lounge',
        PRODUCT_FAMILY_FAST_TRACK = 'Fast Track',
        PRODUCT_FAMILY_SUBSCRIPTION = 'Subscription';
}