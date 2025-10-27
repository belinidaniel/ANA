/**
 * @author           Miguel Freire
 * @description      Batch to create Users for Contacts and Person Contacts
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire    16/07/2024       Original version
 **/
public inherited sharing class COMM_Async_UserCreation extends FW_AsyncHandler implements Database.Batchable<SObject> {
    private COMM_IREP_Contact commRepContact;
    private COMM_IREP_User commRepUser;
    private COMM_DO_User commDoUser;

    /**
     * @description Class Constructor to initiate REP classes
     */
    public COMM_Async_UserCreation() {
        this.commRepContact = new COMM_REP_Contact();
        this.commRepUser = new COMM_REP_User();
        this.commDoUser = new COMM_DO_User();
    }

    @TestVisible
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private COMM_Async_UserCreation(
        COMM_REP_Contact commRepContact,
        COMM_REP_User commRepUser,
        COMM_DO_User commDoUser,
        FW_IREP_JobExecution jobExecutionRep,
        FW_IREP_Parameters parameterRep
    ) {
        this.commRepContact = commRepContact;
        this.commRepUser = commRepUser;
        this.commDoUser = commDoUser;
        this.jobExecutionRep = jobExecutionRep;
        this.parameterRep = parameterRep;
    }

    /**
     * @description Batch Start Method. According to the Batch Parameters, initiates query to obtain all records
     * of a specified SObject, whose specified Date Field has a date set a specific number of months ago.
     *
     * @param bc Context Information of the executed batch
     * @return Database.QueryLocator with the built query
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        setAsyncApexJobId(bc.getJobId());

        SObjectType sobjType = Schema.getGlobalDescribe().get('Contact');

        FW_QueryBuilder query = new FW_QueryBuilder(sobjType)
            .selectFields(
                new List<SObjectField>{ Contact.Id, Contact.FirstName, Contact.LastName, Contact.Email, Contact.COMM_MigrationCreateExternalUser__c }
            )
            .whereEquals('COMM_MigrationCreateExternalUser__c', 'TO PROCESS');

        return executeQuery(query);
    }

    /**
     * @description Method to execute Batch.
     * Create Users related to the retrieved Contacts and Person Accounts
     *
     * @param bc Batch context
     * @param contactList List of Contacts and Person Accounts from start
     */
    public void execute(Database.BatchableContext bc, List<Contact> contactList) {
        // List of Users related to the Contacts to insert
        List<User> usersToInsert = new List<User>();

        for (Contact contactRecord : contactList) {
            // Create User
            User userRecord = commDoUser.instantiateUser(
                contactRecord.FirstName,
                contactRecord.LastName,
                contactRecord.Email,
                COMM_DO_User.NORMAL_LOGIN_IDENTIFIER
            );
            userRecord.COMM_EmailValidationStatus__c = COMM_DO_User.EMAIL_VALIDATION_PICKLIST_VALIDATED;
            userRecord.ContactId = contactRecord.Id;
            userRecord.isActive = false;
            // Add User to List
            usersToInsert.add(userRecord);
            // Change Migration Create External User status to PROCESSED
            contactRecord.COMM_MigrationCreateExternalUser__c = 'PROCESSED';
        }
        // Insert Users
        commRepUser.insertSObjects(usersToInsert);
        // Update Contacts
        commRepContact.updateSObjects(contactList);
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