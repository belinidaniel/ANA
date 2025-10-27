/**
 * @author           Diogo Gonçalves
 * @description      Invoice Line repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    01/04/2024     ECOMM-105: Original version
 **/
public inherited sharing class COMM_REP_InvoiceLine extends FW_SobjectRep implements COMM_IREP_InvoiceLine {
    /**
     * @description Retrieve a list of Invoice Lines that have a specific Invoice Ids, Item Type and Product Family
     * @param {List<String>} invoicesIds
     * @param {List<String>} itemTypes
     * @param {List<String>} productFamilies
     * @return {List<InvoiceLine>}
     */
    public List<InvoiceLine> getInvoiceLinesByFamilyAndType(List<String> invoiceIds, List<String> productFamilies, String entityItemType) {
        return [
            SELECT Id, ReferenceEntityItemId
            FROM InvoiceLine
            WHERE InvoiceId IN :invoiceIds AND Product2.Family IN :productFamilies AND ReferenceEntityItemType = :entityItemType
            WITH SECURITY_ENFORCED
        ];
    }
}