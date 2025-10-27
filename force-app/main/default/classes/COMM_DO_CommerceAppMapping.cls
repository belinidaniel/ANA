/**
 * @author Daniel Lascas
 * @description COMM_CommerceAppMapping__mdt Custom metadata Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/04/2024       ECOMM-178: Original version
 **/
public inherited sharing class COMM_DO_CommerceAppMapping implements COMM_IDO_CommerceAppMapping {
    private final Map<String, List<COMM_CommerceAppMapping__mdt>> attributeMappingMap;

    private COMM_IREP_User userRep;
    private COMM_IREP_Account accountRep;

    @TestVisible
    private static final String CUSTOMER_TYPE_ATTRIBUTE = 'customerType';
    private static final String HAS_CREDIT_ATTRIBUTE = 'hasCredit';
    private static final String CONTACT_ID_ATTRIBUTE = 'contactId';

    /**
     * @description Class Constructor to initialize REP classes and Map
     */
    public COMM_DO_CommerceAppMapping() {
        this.userRep = new COMM_REP_User();
        this.accountRep = new COMM_REP_Account();
        this.attributeMappingMap = buildBySObjectMap();
    }

    @TestVisible
    private COMM_DO_CommerceAppMapping(COMM_IREP_User userRep, COMM_IREP_Account accountRep) {
        this.userRep = userRep;
        this.accountRep = accountRep;
        this.attributeMappingMap = buildBySObjectMap();
    }

    /**
     * @description Method to obtain user's account data in a Map structured as a JSON
     *
     * @param userId Id of the User to obtain account data.
     * @param attributesMap Map where the mapped values are stored
     * @return Map structured as a JSON with the mapped values
     */
    public Map<String, String> getAccountDataMapWithUserId(Id userId, Map<String, String> attributesMap) {
        List<User> userList = userRep.getUserAccountAndContactDataById(new Set<Id>{ userId });
        //Verify if User Record was found and has an Account
        if (!userList.isEmpty() && userList[0].AccountId != null) {
            Account accountData = userList[0].Account;
            //Verify if User's Account is a Person Account and has a Parent Account.
            if (accountData.IsPersonAccount && String.isNotBlank(accountData.COMM_ParentAccount__c)) {
                List<Account> accountList = accountRep.getAccountByIds(new Set<Id>{ accountData.COMM_ParentAccount__c });
                //Verify if User's Parent Account was found and is an Affiliate. If it is switch Account used to User's Parent Account.
                if (!accountList.isEmpty() && accountList[0].COMM_IsAffiliate__c) {
                    accountData = accountList[0];
                }
            }
            //Map Fields according to metadata
            attributesMap = mapAttributesFromSObject(accountData, attributesMap, accountData.IsPersonAccount);
            //Add Customer Type (B2C if Mapped Account is a Person Account, B2B if it's a Business Account)
            attributesMap.put(
                CUSTOMER_TYPE_ATTRIBUTE,
                accountData.IsPersonAccount ? COMM_DO_Account.ACCOUNT_TYPE_B2C : COMM_DO_Account.ACCOUNT_TYPE_B2B
            );
            //Add indication if Account has Credit
            attributesMap.put(
                HAS_CREDIT_ATTRIBUTE,
                String.valueOf(
                    accountData.COMM_PaymentMethod__c != null
                        ? accountData.COMM_PaymentMethod__c.contains(COMM_DO_Account.PAYMENT_METHOD_CREDIT)
                        : false
                )
            );
            //Add User's Contact Id
            attributesMap.put(CONTACT_ID_ATTRIBUTE, userList[0].ContactId);
        }

        return attributesMap;
    }

    /**
     * @description Method to map the values from a Salesforce SObject into the attributes Map to send
     * from the Commerce Connected App.
     *
     * @param sobjRecord The SObject whose values will be mapped to a JSON to sent to Commerce
     * @param attributesMap The attributes Map where the mapped values will be stored
     * @param isB2C Boolean to indicate if mapping process is for B2C Client (if true) or B2B (if false)
     **/
    public Map<String, String> mapAttributesFromSObject(SObject sobjRecord, Map<String, String> attributesMap, Boolean isB2C) {
        Set<String> innerMapNameSet = new Set<String>();
        String sobjectName = String.valueOf(sobjRecord.getSObjectType());

        //Perform mapping and store it into a Map with the structure of a JSON
        Map<String, Object> jsonMap = new Map<String, Object>();
        for (COMM_CommerceAppMapping__mdt mtdValue : attributeMappingMap.get(sobjectName)) {
            //Verify that Mapping applies (isB2C or not) and if Mapping is for an inner object
            if (Boolean.valueOf(mtdValue.COMM_IsB2CMapping__c) == isB2C && Boolean.valueOf(mtdValue.COMM_IsObjecField__c)) {
                String mapName = String.valueOf(mtdValue.COMM_CustomAttribute__c);
                if (!jsonMap.containsKey(mapName)) {
                    jsonMap.put(mapName, new Map<String, Object>());
                    innerMapNameSet.add(mapName);
                }
                ((Map<String, Object>) jsonMap.get(mapName)).put(mtdValue.COMM_ObjectAttributeName__c, sobjRecord.get(mtdValue.COMM_FieldApiName__c));
            } else if (Boolean.valueOf(mtdValue.COMM_IsB2CMapping__c) == isB2C) {
                //Verify that Mapping applies (isB2C or not)
                jsonMap.put(mtdValue.COMM_CustomAttribute__c, sobjRecord.get(mtdValue.COMM_FieldApiName__c));
            }
        }

        //Store Mapped Values to String Map.
        for (String mapKey : jsonMap.keySet()) {
            if (innerMapNameSet.contains(mapKey)) {
                //If Value is a Map, convert to string using serialize method for JSON.
                attributesMap.put(mapKey, JSON.serialize(jsonMap.get(mapKey)));
            } else {
                //If value isn't a Map then use String.valueOf to convert to String.
                attributesMap.put(mapKey, String.valueOf(jsonMap.get(mapKey)));
            }
        }
        return attributesMap;
    }

    /**
     * @description Method to create a Map where Key= SObject API Name
     * Value= COMM_CommerceAppMapping__mdt metadata record
     *
     * @return Map of Metadata where Key is the API Name of the SObject the mapping is set to
     **/
    private Map<String, List<COMM_CommerceAppMapping__mdt>> buildBySObjectMap() {
        Map<String, List<COMM_CommerceAppMapping__mdt>> mappingMap = new Map<String, List<COMM_CommerceAppMapping__mdt>>();
        for (COMM_CommerceAppMapping__mdt mdtValue : COMM_CommerceAppMapping__mdt.getAll().values()) {
            String sobjectName = String.valueOf(mdtValue.COMM_SObjectApiName__c);
            if (!mappingMap.containsKey(sobjectName)) {
                mappingMap.put(sobjectName, new List<COMM_CommerceAppMapping__mdt>());
            }
            mappingMap.get(sobjectName).add(mdtValue);
        }
        return mappingMap;
    }
}