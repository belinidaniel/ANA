/**
 * @author Daniel Lascas
 * @description COMM_FreeVoucher__c repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    23/10/2024       ECOMM-2248 - Original version
 **/
public interface COMM_IREP_FreeVoucher extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of Free Vouchers by a set of Ids
     *
     * @param voucherIds Set of Free Voucher Id's to query
     * @return List of Free Voucher Records found
     **/
    List<COMM_FreeVoucher__c> getVouchersByIds(Set<Id> voucherIds);
}