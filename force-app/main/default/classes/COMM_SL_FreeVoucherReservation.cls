/**
 * @author Daniel Lascas
 * @description Service class to handle Free Voucher Reservations
 * for Fast-track and lounges.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    22/10/2024       ECOMM-2248: Original version
 **/
public with sharing class COMM_SL_FreeVoucherReservation {
    private static final String QR_CODE_VALUE_ERR_MESSAGE = 'QR Code value was not generated. Check the product SubCategory, Airport and Reservation Date.';
    private static final String QR_CODE_IMG_ERR_MESSAGE = 'QR Code image was not create.';

    /**
     * @description: method to create reservation vouchers on Free Voucher records,
     * @param voucherIds List of Free Voucher Record Ids.
     * @return List of Free Voucher Records with updated QR Code.
     */
    @InvocableMethod(
        category='Free Voucher'
        label='Create Free Reservation Vouchers'
        description='Create Reservation (lounge and fast-track) to be used in the QR Codes'
    )
    public static List<COMM_FreeVoucher__c> createFreeReservationVouchers(List<Id> voucherIds) {
        //Initialize REP
        COMM_IREP_FreeVoucher freeVoucherRep = new COMM_REP_FreeVoucher();

        List<COMM_FreeVoucher__c> toUpdateList = setReservationVoucherCodes(freeVoucherRep.getVouchersByIds(new Set<Id>(voucherIds)));
        if (!toUpdateList.isEmpty()) {
            freeVoucherRep.updateSObjects(toUpdateList);
        }
        return toUpdateList;
    }

    /**
     * @description: Method to set voucher codes on free voucher records.
     *
     * @param voucherList List of Free Voucher records to update.
     * @return List of updated voucher records.
     */
    private static List<COMM_FreeVoucher__c> setReservationVoucherCodes(List<COMM_FreeVoucher__c> voucherList) {
        List<COMM_FreeVoucher__c> updatedList = new List<COMM_FreeVoucher__c>();
        for (COMM_FreeVoucher__c fvRec : voucherList) {
            setQRCode(fvRec);
            updatedList.add(fvRec);
        }
        return updatedList;
    }

    /**
     * @description Set the QR Code value and image on the COMM_FreeVoucher__c.
     *
     * @param fvRecord Free Voucher Record to be set with QR Code.
     */
    private static void setQRCode(COMM_FreeVoucher__c fvRecord) {
        String qrCode = COMM_GEN_Utility.generateQRCodeValue(
            fvRecord.COMM_Product__r.Family,
            fvRecord.COMM_Product__r.COMM_SubCategory__c,
            fvRecord.COMM_Product__r.COMM_Airport__c,
            fvRecord.COMM_StartDate__c,
            fvRecord.COMM_Product__r.COMM_TimeZoneByAirport__c
        );
        if (String.isBlank(qrCode)) {
            throw new COMM_SL_CreateVoucherException(QR_CODE_VALUE_ERR_MESSAGE);
        }

        fvRecord.COMM_QRCode__c = qrCode;
        fvRecord.COMM_QRCodeImage__c = COMM_GEN_Utility.generateQRCodeImage(fvRecord.COMM_QRCode__c);

        if (String.isBlank(fvRecord.COMM_QRCodeImage__c)) {
            throw new COMM_SL_CreateVoucherException(QR_CODE_IMG_ERR_MESSAGE);
        }
    }
}