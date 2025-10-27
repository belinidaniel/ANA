/**
 * @author Nuno Beato
 * @description Service Layer class to clear Product Reservation for new Subscriptions request
 * process defined in Flow
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Nuno Beato       05/04/2024       Original version
 **/
public inherited sharing class COMM_SL_ClearProductReservations {
    /**
     * @description Wrapper definition with variable set from Flow
     */
    public class InputWrapper {
        @InvocableVariable(label='Codes' description='Product Codes')
        public List<String> productCodeList;
        @InvocableVariable(label='Start Date' description='Start Date')
        public Datetime startDate;
        @InvocableVariable(label='End Date' description='End Date')
        public Datetime endDate;
    }

    /**
     * @description Set product reservation
     *
     * @param inputWrappers List of InputWrapper with variable defined from Flow
     * @return List of choices with the options to display for selection on Flow
     */
    @InvocableMethod(label='Release Product Reservations' description='Release Product Reservation depending on chosen product code')
    public static void releaseProductReservations(List<InputWrapper> inputWrappers) {
        InputWrapper input = inputWrappers.get(0);
        releaseReservations(input.productCodeList, input.startDate, input.endDate);
    }

    /**
     * @description Call OCI reservation service
     *
     * @param productCodeList Product code List to clear reservations
     * @param startDate First date of reservations to clear
     * @param endDate Last date of reservations to clear
     */
    @future(callout=true)
    private static void releaseReservations(List<String> productCodeList, Datetime startDate, Datetime endDate) {
        COMM_WS_ReservationInput input = new COMM_WS_ReservationInput();
        input.product = new List<COMM_WS_ReservationInput.Product>();

        for (String productCode : productCodeList) {
            COMM_WS_ReservationInput.Product product = new COMM_WS_ReservationInput.Product();
            product.productId = productCode;
            product.startDate = startDate;
            product.endDate = endDate;
            input.product.add(product);
        }

        COMM_SL_WS_OCIReservations ociReservation = new COMM_SL_WS_OCIReservations();
        if(!Test.isRunningTest()){
            ociReservation.release(input);
        }
    }
}