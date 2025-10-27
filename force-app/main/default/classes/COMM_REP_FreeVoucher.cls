/**
 * @author Daniel Lascas
 * @description COMM_FreeVoucher__c repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    23/10/2024       ECOMM-2248 - Original version
 **/
public inherited sharing class COMM_REP_FreeVoucher extends FW_SobjectRep implements COMM_IREP_FreeVoucher {
    /**
     * @description Retrieve a list of Free Vouchers by a set of Ids
     *
     * @param voucherIds Set of Free Voucher Id's to query
     * @return List of Free Voucher Records found
     **/
    public List<COMM_FreeVoucher__c> getVouchersByIds(Set<Id> voucherIds) {
        return [
            SELECT
                Id,
                COMM_ReservationName__c,
                COMM_StartDate__c,
                COMM_QRCodeImage__c,
                COMM_Product__r.Name,
                COMM_Product__r.Family,
                COMM_Product__r.COMM_SubCategory__c,
                COMM_Product__r.COMM_Airport__c,
                COMM_Product__r.COMM_TimeZoneByAirport__c
            FROM COMM_FreeVoucher__c
            WHERE Id IN :voucherIds
            WITH USER_MODE
        ];
    }
}