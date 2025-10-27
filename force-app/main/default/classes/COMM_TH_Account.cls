/**
 * @author Daniel Lascas
 * @description Trigger handler for the Account sobject
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/05/2024	    ECOMM-194: Original version
 **/
public class COMM_TH_Account extends FW_TriggerHandler {
    private List<Account> newList;
    private Map<Id, Account> oldMap;

    /**
     * @description Class Constructor to obtain Records from Trigger
     */
    public COMM_TH_Account() {
        this.newList = (List<Account>) Trigger.New;
        this.oldMap = (Map<Id, Account>) Trigger.oldMap;
    }

    protected override void executeBeforeInsert() {
        //Execute Logic to validate Account's VAT Number
        new COMM_TW_Account_ValidateVAT().execute(newList, null);
        //Execute Logic to update Airport Field
        new COMM_TW_Account_AirportUpdate().execute(newList, null);
    }

    protected override void executeBeforeUpdate() {
        //Execute Logic to validate Account's VAT Number
        new COMM_TW_Account_ValidateVAT().execute(newList, oldMap);
        //Execute Logic to update Airport Field
        new COMM_TW_Account_AirportUpdate().execute(newList, oldMap);
        //Execute Logic to sync data with Commerce
        new COMM_TW_Account_CustomerSyncWithCommerce().execute(newList, oldMap);
    }
}