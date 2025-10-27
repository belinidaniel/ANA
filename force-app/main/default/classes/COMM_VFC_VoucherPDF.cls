/**
 * @author Diogo Gonçalves
 * @description Controller class for COMM_VFC_VoucherPDF
 *
 *  * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves  09/04/2024       ECOMM-105 Original version
 * Diogo Gonçalves  19/06/2024       ECOMM-1420 Change the name of the method getWithQRCode
 * Daniel Reto      21/08/2024       ECOMM-1945 TimeZone
 */
public without sharing class COMM_VFC_VoucherPDF {
    public Id orderSummaryId { get; set; }
    public List<OrderItemSummaryWrapper> orderItemSummaries { get; set; }
    public Integer orderItemTotal { get; set; }
    public Boolean hasFastTrack { get; set; }
    public Boolean hasLounge { get; set; }
    public Boolean hasParking { get; set; }

    /**
     * @description Constructor of the class. Set the variables used on the page
     *  based on the Order Summary Id
     * @param controller
     */
    public COMM_VFC_VoucherPDF(ApexPages.StandardController controller) {
        this.orderSummaryId = controller.getId();
        List<String> orderItemSummaryIdList = (ApexPages.currentPage().getParameters().get('orderItemSummaryId') == null)
            ? null
            : String.valueOf(ApexPages.currentPage().getParameters().get('orderItemSummaryId')).split(',');
        COMM_IREP_OrderItemSummary repository = new COMM_REP_OrderItemSummary();
        List<OrderItemSummary> orderItemSummaryList = repository.getForVoucherPDF(new List<String>{ orderSummaryId }, orderItemSummaryIdList);
        List<OrderItemSummaryWrapper> wrapperList = new List<OrderItemSummaryWrapper>();
        for (OrderItemSummary ois : orderItemSummaryList) {
            OrderItemSummaryWrapper oisWrapper = new OrderItemSummaryWrapper(
                ois,
                Datetime.valueOfGMT(ois.COMM_ReservationStart__c.format(COMM_GEN_Utility.TIMEZONE_DATETIME_FORMAT, ois.COMM_TimeZoneByAirport__c)),
                Datetime.valueOfGMT(ois.COMM_ReservationEnd__c.format(COMM_GEN_Utility.TIMEZONE_DATETIME_FORMAT, ois.COMM_TimeZoneByAirport__c))
            );
            wrapperList.add(oisWrapper);
        }
        this.orderItemSummaries = wrapperList;
        this.orderItemTotal = orderItemSummaries.size();
        this.hasFastTrack = false;
        this.hasLounge = false;
        this.hasParking = false;
        setVoucherTypeFlags();
    }

    /**
     * @description Sets the flags for Fast Track, Lounge and Parking.
     *  Is used to control the instructions to display
     *
     * @return void
     */
    private void setVoucherTypeFlags() {
        for (OrderItemSummaryWrapper ois : this.orderItemSummaries) {
            if (ois.orderItemSummaryRecord.Product2.Family.equals('Fast Track')) {
                this.hasFastTrack = true;
            } else if (ois.orderItemSummaryRecord.Product2.Family.equals('Lounge')) {
                this.hasLounge = true;
            } else if (ois.orderItemSummaryRecord.Product2.Family.equals('Parking')) {
                this.hasParking = true;
            }
        }
    }

    /**
     * @description Wrapper to store Order Item Summary with the respective Reservation Start and Reservation End dates
     */
    public class OrderItemSummaryWrapper {
        public OrderItemSummary orderItemSummaryRecord { get; set; }
        public DateTime reservationStartDate { get; set; }
        public DateTime reservationEndDate { get; set; }

        /**
         * @description Wrapper Constructor to hold the Order Item Summary record along with the respective dates
         * @param orderItemSummaryRecord Order Item Summary record
         * @param reservationStartDate Order Item Summary reservation start date on the correct timezone
         * @param reservationEndDate Order Item Summary reservation end date on the correct timezone
         */
        public OrderItemSummaryWrapper(OrderItemSummary orderItemSummaryRecord, DateTime reservationStartDate, DateTime reservationEndDate) {
            this.orderItemSummaryRecord = orderItemSummaryRecord;
            this.reservationStartDate = reservationStartDate;
            this.reservationEndDate = reservationEndDate;
        }
    }
}