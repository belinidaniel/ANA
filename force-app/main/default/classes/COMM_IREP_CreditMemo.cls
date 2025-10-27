/**
 * @author Diogo Gonçalves
 * @description CreditMemo repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    29/04/2024       Original version
 * Daniel Reto        28/05/2024       New method: getForSAPCreditMemo
 * Daniel Reto        03/06/2024       New method: getForSAPCreditMemo
 **/
public interface COMM_IREP_CreditMemo extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of CreditMemo by a set of Ids
     *
     * @param ids Set of Ids to query
     * @return List of CreditMemo Records found
     **/
    List<CreditMemo> getByIds(List<String> ids);
    /**
     * @description Selects Credit Memo records to send to SAP based on the Id list
     * @param creditMemoIds List of the Ids
     * @return List of Credit Memo
     **/
    List<CreditMemo> getForSAPCreditMemo(List<String> creditMemoIds);
    /**
     * @description Selects Credit Memo records to send to SAP based on the Id list and Date
     * @param creditMemoIds List of the Ids
     * @param dateClause Date Clause to include on Query
     * @return List of Credit Memo
     **/
    List<CreditMemo> getForSAPCreditMemo(Set<Id> creditMemoIds, String dateClause);
}