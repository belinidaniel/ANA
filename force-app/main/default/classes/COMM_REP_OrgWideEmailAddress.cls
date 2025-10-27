/**
 * @author Daniel Lascas
 * @description OrgWideEmailAddress repository
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    27/02/2024       Original version
 **/
public inherited sharing class COMM_REP_OrgWideEmailAddress extends FW_SobjectRep implements COMM_IREP_OrgWideEmailAddress {
    private static final String DEFAULT_NO_REPLY = 'DefaultNoreply';

    /**
     * @description Retrieve the list of Organization Wide Email Address that is set
     * as the Default No-Reply Address
     *
     * @return List of Queried OrgWideEmailAddress Records
     **/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<OrgWideEmailAddress> getDefaultNoReplyAddress() {
        return [SELECT Id FROM OrgWideEmailAddress WHERE Purpose = :DEFAULT_NO_REPLY];
    }
}