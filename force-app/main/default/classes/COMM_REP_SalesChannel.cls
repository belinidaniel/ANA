/**
 * @author Diogo Gonçalves
 * @description SalesChannel repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    22/05/2024       Original version
 **/
public inherited sharing class COMM_REP_SalesChannel extends FW_SobjectRep implements COMM_IREP_SalesChannel {
    /**
     * @description Retrieve a list of SalesChannel by a list of names
     *
     * @param name Set of Ids to query
     * @return List of SalesChannel Records found
     **/
    public List<SalesChannel> getByName(List<String> names) {
        return [
            SELECT Id
            FROM SalesChannel
            WHERE SalesChannelName = :names
            WITH USER_MODE
        ];
    }
}