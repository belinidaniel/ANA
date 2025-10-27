/**
 * @author Diogo Gonçalves
 * @description SalesChannel repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves    22/05/2024       Original version
 **/
public interface COMM_IREP_SalesChannel extends FW_ISObjectRep {
    /**
     * @description Retrieve a list of SalesChannel by a list of names
     *
     * @param name Set of Ids to query
     * @return List of SalesChannel Records found
     **/
    List<SalesChannel> getByName(List<String> names);
}