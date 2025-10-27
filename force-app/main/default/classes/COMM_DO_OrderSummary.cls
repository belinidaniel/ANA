/**
 * @author           Daniel Reto
 * @description      Order Summary SObject Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      20/06/2024       Original version
 **/
public inherited sharing class COMM_DO_OrderSummary implements COMM_IDO_OrderSummary {
    //Case Status Picklist Values
    public final static string ACTIVE_STATUS = 'Active'; // VALUE NOT AVAILABLE 
    public final static string CREATED_STATUS = 'Created';
    public final static string PROCESSING_STATUS = 'Processing';
    public final static string PAID_STATUS = 'Paid';
    public final static string COMPLETED_STATUS = 'Completed';
    public final static string REFUNDED_STATUS = 'Refunded';
    public final static string CANCELLED_STATUS = 'Cancelled';
    public final static string ERROR_RESELLER_VOUCHER_STATUS = 'ERROR';
    public final static string RETRY_EXHAUSTED_RESELLER_VOUCHER_STATUS = 'RETRY_EXHAUSTED';
    public final static string SENT_RESELLER_VOUCHER_STATUS = 'SENT';

    /**
     * @description Get correct API values of Order Summay Status.
     * @param List<Double> statusCodeList - List of Status Code values
     * @return List<String> output with list of Strings with the correct Status Code API values
     */
    public static List<String> getFilterStatusAPI(List<Integer> statusCodeList){
        List<String> statusValuesList = new List<String>();
        Map<Integer, String> statusCodeMap = new Map<Integer, String>{
            0 => COMM_DO_OrderSummary.ACTIVE_STATUS,
            1 => COMM_DO_OrderSummary.CREATED_STATUS,
            2 => COMM_DO_OrderSummary.PROCESSING_STATUS,
            3 => COMM_DO_OrderSummary.PAID_STATUS,
            4 => COMM_DO_OrderSummary.COMPLETED_STATUS,
            5 => COMM_DO_OrderSummary.REFUNDED_STATUS,
            6 => COMM_DO_OrderSummary.CANCELLED_STATUS
        };

        for(Integer statusCode : statusCodeList){
            if(statusCodeMap.containsKey(statusCode)){
                statusValuesList.add(statusCodeMap.get(statusCode));
            }
        }

        return statusValuesList;
    }

    /**
     * @description Get correct API values of Order Summay Status.
     * @param String statusCode - Status Code value
     * @return List<String> output with list of Strings with the correct Status Code API values
     */
    public static Integer getFilterStatusCodes(String statusCode){
        Map<String, Integer> statusCodeMap = new Map<String, Integer>{
            COMM_DO_OrderSummary.ACTIVE_STATUS => 0,
            COMM_DO_OrderSummary.CREATED_STATUS => 1,
            COMM_DO_OrderSummary.PROCESSING_STATUS => 2,
            COMM_DO_OrderSummary.PAID_STATUS => 3,
            COMM_DO_OrderSummary.COMPLETED_STATUS => 4,
            COMM_DO_OrderSummary.REFUNDED_STATUS => 5,
            COMM_DO_OrderSummary.CANCELLED_STATUS => 6
        };

        return statusCodeMap.get(statusCode);
    }
}