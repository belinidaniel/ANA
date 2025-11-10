/**
 * @author Daniel Lascas
 * @description Trigger handler for the User sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024	    ECOMM-700: Original version
 **/
public class COMM_TH_User extends FW_TriggerHandler {
    private List<User> newList;

    /**
     * @description Class Constructor to obtain Records from Trigger
     */
    public COMM_TH_User() {
        this.newList = (List<User>) Trigger.new;
    }

    protected override void executeAfterInsert() {
        //Verify if Running User is a Internal User or a Community User.
        //Skip Logic for Community User since he doesn't have permissions required.
        if (Auth.CommunitiesUtil.isInternalUser()) {
            //Execute Logic to give Partner Admin's the necessary Permission Set
            new COMM_TW_User_VerifyPartnerPermission().execute(newList, false);
        }
        new COMM_TW_User_AddToPublicGroup().execute(newList);
    }

    protected override void executeAfterUpdate() {
        //Verify if Running User is a Internal User or a Community User.
        //Skip Logic for Community User since he doesn't have permissions required.
        if (Auth.CommunitiesUtil.isInternalUser()) {
            //Execute Logic to give Partner Admin's the necessary Permission Set
            new COMM_TW_User_VerifyPartnerPermission().execute(newList, true);
        }
    }
}