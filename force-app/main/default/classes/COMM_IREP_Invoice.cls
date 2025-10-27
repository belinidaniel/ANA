/**
 * @author Rui Salgado
 * @description Invoice selector interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024       Original version
 * Rui Salgado      19/04/2024       Added method getAllInvoiceBasedOnStatus
 * Daniel Reto      03/06/2024       New method: getForSAPInvoice
 * Hugo Manera      28/05/2025       New method: getForSearchInvoice
 **/
public interface COMM_IREP_Invoice extends FW_ISObjectRep {
    /**
     * @description Selects Invoice records based on the Id list
     * @param invoiceIds List of the Ids
     * @return List of Invoice
     */
    List<Invoice> getByIds(List<String> invoiceIds);
    /**
     * @description Selects Invoice to communicate with CPMS
     * @param invoiceIds List of the Ids
     * @return List of Invoice
     */
    List<Invoice> getForCPMS(List<Id> invoiceIds, String family, String productType);

    /**
     * @description Selects Invoice records to send to SAP based on the Id list
     * @param invoiceIds List of the Ids
     * @return List of Invoice
     **/
    List<Invoice> getForSAPInvoice(List<String> invoiceIds);
    /**
     * @description Selects Invoice records to send to SAP based on the Id list
     * @param invoiceIds List of the Ids
     * @param dateClause Date Clause to include on Query
     * @return List of Invoice
     **/
    List<Invoice> getForSAPInvoice(Set<Id> invoiceIds, String dateClause);

    /**
     * @description Retrieves the invoice records to to send for Commerce side while doing a Search Invoice
     * @param COMM_WS_SearchInvoicesInput inputRequest
     * @param String invoiceExtraFilter : request key matched with Salesforce Field to add on Invoice query filter
     * @return {List<Invoice>}
     */
    List<Invoice> getForSearchInvoice(COMM_WS_SearchInvoicesInput inputRequest, String invoiceExtraFilter);
}