/**
 * @author Daniel Lascas
 * @description OrgWideEmailAddress repository interface
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    27/02/2024       Original version
 **/
public interface COMM_IREP_OrgWideEmailAddress extends FW_ISObjectRep {
    /**
     * @description Retrieve the list of Organization Wide Email Address that is set
     * as the Default No-Reply Address
     *
     * @return List of Queried OrgWideEmailAddress Records
     **/
    List<OrgWideEmailAddress> getDefaultNoReplyAddress();
}