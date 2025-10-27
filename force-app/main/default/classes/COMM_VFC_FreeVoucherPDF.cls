/**
 * @author Daniel Lascas
 * @description Controller class for COMM_VFC_FreeVoucherPDF
 *
 *  * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    23/10/2024       ECOMM-2248: Original version
 */
public with sharing class COMM_VFC_FreeVoucherPDF {
    public Id freeVoucherId { get; set; }
    public COMM_FreeVoucher__c freeVoucher { get; set; }
    public Datetime reservationStartDate { get; set; }
    public Boolean hasFastTrack { get; set; }
    public Boolean hasLounge { get; set; }

    /**
     * @description Constructor of the class. Set the variables used on the page
     * based on the Free Voucher Record Id
     *
     * @param controller Visualforce Controller
     */
    public COMM_VFC_FreeVoucherPDF(ApexPages.StandardController controller) {
        this.freeVoucherId = controller.getId();
        COMM_IREP_FreeVoucher repository = new COMM_REP_FreeVoucher();
        List<COMM_FreeVoucher__c> freeVoucherList = repository.getVouchersByIds(new Set<Id>{ freeVoucherId });
        if (!freeVoucherList.isEmpty()) {
            COMM_FreeVoucher__c freeVoucherRecord = freeVoucherList[0];
            this.freeVoucher = freeVoucherRecord;
            this.reservationStartDate = Datetime.valueOfGMT(
                freeVoucherRecord.COMM_StartDate__c.format(
                    COMM_GEN_Utility.TIMEZONE_DATETIME_FORMAT,
                    freeVoucherRecord.COMM_Product__r?.COMM_TimeZoneByAirport__c
                )
            );
            this.hasFastTrack = COMM_DO_Product2.CATEGORY_FASTTRACK.equals(freeVoucherRecord.COMM_Product__r?.Family);
            this.hasLounge = COMM_DO_Product2.CATEGORY_LOUNGE.equals(freeVoucherRecord.COMM_Product__r?.Family);
        }
    }
}