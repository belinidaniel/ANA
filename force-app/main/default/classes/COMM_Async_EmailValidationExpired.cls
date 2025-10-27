/**
 * @author           Miguel Freire
 * @description      Batch to obfuscate a user when the email validation date expired
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire    18/03/2024       Original version
 **/
public inherited sharing class COMM_Async_EmailValidationExpired extends FW_AsyncHandler implements Database.Batchable<SObject> {
    private COMM_IREP_User commRepUser;
    private COMM_IREP_Account commRepAccount;

    /**
     * @description Class Constructor to initiate REP classes
     */
    public COMM_Async_EmailValidationExpired() {
        this.commRepUser = new COMM_REP_User();
        this.commRepAccount = new COMM_REP_Account();
    }

    @TestVisible
    private COMM_Async_EmailValidationExpired(
        COMM_REP_User commRepUser,
        COMM_REP_Account commRepAccount,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.commRepUser = commRepUser;
        this.commRepAccount = commRepAccount;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Method to start Batch.
     *
     * @param bc Batch context
     * @return List of users that the validation email has expired
     */
    public List<User> start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());
        // Query Users where email validation link has expired and email validation status is 'In Validation'
        return commRepUser.getUserByInValidationExpiredEmail(true);
    }

    /**
     * @description Method to execute Batch.
     * Obfuscates the users and deletes the related accounts
     *
     * @param bc Batch context
     * @param userList List of users from start
     */
    public void execute(Database.BatchableContext bc, List<User> userList) {
        // Set of Ids of Accounts related to the Users to delete
        Set<Id> accountsToDeleteIds = new Set<Id>();
        // Obfuscate Users
        for (User userRecord : userList) {
            // Add Account Id's to Set
            accountsToDeleteIds.add(userRecord.accountId);
            System.UserManagement.obfuscateUser(userRecord.Id);
        }
        List<Account> accountsToDelete = new List<Account>();
        //Set for deletion Accounts without Orders (accounts with orders can't be deleted)
        for (Account accountRecord : commRepAccount.getAccountsAndOrdersByIds(accountsToDeleteIds)) {
            if (accountRecord.Orders.isEmpty()) {
                accountsToDelete.add(accountRecord);
            }
        }
        if (!accountsToDelete.isEmpty()) {
            // Delete Accounts
            commRepAccount.deleteSObjects(accountsToDelete);
        }
    }

    /**
     * @description Finish method empty.
     *
     * @param bc Batch context
     */
    public void finish(Database.BatchableContext bc) {
        finishBatch(bc.getJobId());
    }
}