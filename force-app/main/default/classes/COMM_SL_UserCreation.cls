/**
 * @author Carlos Fusco
 * @description Service Layer Class with method to create an User record.
 * For use in flows.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco    21/06/2024       Original version
 **/
public inherited sharing class COMM_SL_UserCreation {
    public class InputWrapper {
        @InvocableVariable(label='Contact Id' description='Id of the Contact to associate on User')
        public Id contactId;
        @InvocableVariable(label='Contact First Name' description='First Name of the Contact to associate on User')
        public String firstName;
        @InvocableVariable(label='Contact Last Name' description='Last Name of the Contact to associate on User')
        public String lastName;
        @InvocableVariable(label='Contact Email' description='Email of the Contact to associate on User')
        public String email;
        @InvocableVariable(label='Contact Language' description='Language used for User Contact')
        public String language;
    }

    private static COMM_IREP_Profile profileRep = new COMM_REP_Profile();
    private final static string NORMAL_LOGIN_IDENTIFIER = 'Normal';
    private final static string TIME_ZONE_PICKLIST_PTLS = 'Europe/Lisbon';
    private final static string EMAIL_ENCODINGKEY_PICKLIST_UTF8 = 'UTF-8';

    /**
     * @description Set User record to create and link on a Contact record.
     *
     * @param inputWrapperList List of InputWrapper with variables defined from Flow.
     */
    @InvocableMethod(label='Create User from Contact' description='Action to create User record based on Contact details')
    public static void createUserFromContact(List<InputWrapper> inputWrapperList) {
        COMM_DO_User doUser = new COMM_DO_User();
        InputWrapper inputWrapper = inputWrapperList.get(0);
        FW_ISObjectRep sObjectRep = new FW_SObjectRep();

        User userToCreate = doUser.instantiateUser(inputWrapper.firstName, inputWrapper.lastName, inputWrapper.email, NORMAL_LOGIN_IDENTIFIER);
        userToCreate.ContactId = inputWrapper.contactId;

        if (String.isNotBlank(inputWrapper.language)) {
            userToCreate.LanguageLocaleKey = inputWrapper.language;
        }

        try {
            sObjectRep.insertSObjects(new List<User>{ userToCreate });
            COMM_DO_Email.encodeIdAndSetEmail(userToCreate, null, COMM_DO_Email.EMAIL_TEMPLATE_AFFILIATE_EMAIL_VALIDATION, false);
        } catch (Exception e) {
            COMM_GEN_Utility.logError(e, 'User creation createUserFromContact error', 'COMM_SL_UserCreation');
        }
    }
}