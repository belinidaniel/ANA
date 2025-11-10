/**
 * @author           Diogo Gonçalves
 * @description      Invoice Line repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    01/04/2024     ECOMM-105: Original version
 **/
public interface COMM_IREP_InvoiceLine extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of Invoice Lines that have a specific Invoice Ids, Item Type and Product Family
     * @param {List<String>} invoicesIds
     * @param {List<String>} itemTypes
     * @param {List<String>} productFamilies
     * @return {List<InvoiceLine>}
     */
    List<InvoiceLine> getInvoiceLinesByFamilyAndType(List<String> invoiceIds, List<String> productFamilies, String entityItemType);
}