/**
    * @description   Utility class to create records for tests
    * @testClass     N/A
    * Modification Log 
	* ------------------------------------------------------------------------------------  
	* Developer                       Date                Description  
    * ------------------------------------------------------------------------------------ 
*/
@isTest
public without sharing class FW_TestDataFactory{

    public static List<Batch_Definition__c> createBatchDefinition(Integer numberOfRecords, Boolean doInsert) {
        List<Batch_Definition__c> objList = new List<Batch_Definition__c>();
        
        for(Integer i = 0; i < numberOfRecords; i++) {
            objList.add(new Batch_Definition__c(
                Batch_Name__c = 'Test ' + i,
                Class_Name__c = 'Test ' + i,
                SObject_API_Name__c = 'Batch_Definition__c'
            ));
        }

        if(doInsert && !objList.isEmpty()) {
            insert objList;
        }
        return objList;
    }

    public static void createDisableErrorLogging() {
        insert new FW_DisableErrorLogging__c(
            All__c = true,
            CalloutException__c = true,
            DMLException__c = true,
            QueryException__c = true
        );
    }

    public static List<Error_Log__c> createErrorLog(Integer numberOfRecords, Boolean doInsert) {
        List<Error_Log__c> objList = new List<Error_Log__c>();
        
        for(Integer i = 0; i < numberOfRecords; i++){
            objList.add(new Error_Log__c());
        }

        if(doInsert && !objList.isEmpty()) {
            insert objList;
        }
        return objList;
    }

    public static List<Job_Execution__c> createJobExecution(Integer numberOfRecords, Boolean doInsert, String objRecordTypeName, Id batchDefinitionId) {
        Id rTypeId = getRecordTypeIdByDevName('Job_Execution__c', objRecordTypeName);
        
        List<Job_Execution__c> objList = new List<Job_Execution__c>();
        
        for(Integer i = 0; i < numberOfRecords; i++) {
            objList.add(new Job_Execution__c(
              Run_With_Defaults__c = true,
              RecordTypeId = rTypeId,
              Batch_Definition__c = batchDefinitionId
            ));
        }

        if(doInsert && !objList.isEmpty()) {
            insert objList;
        }
        return objList;
    }

    public static List<Parameters__c> createParameter(Integer numberOfRecords, Boolean doInsert) {
        List<Parameters__c> objList = new List<Parameters__c>();
        
        for(Integer i = 0; i < numberOfRecords; i++) {
            objList.add(new Parameters__c());
        }

        if(doInsert && !objList.isEmpty()) {
            insert objList;
        }
        return objList;
    }

     public static List<User> createUsers(Integer numberOfRecords, Boolean doInsert, String userProfileName, Id contactId) {
        Id userProfileId = [SELECT Id FROM Profile WHERE Name = :userProfileName LIMIT 1].Id;
        List<User> objList = new List<User>();
        
        for(Integer i = 0; i < numberOfRecords; i++) {
            objList.add(new User(
                LastName            = 'Test Last Name ' + i,
                Alias               = string.valueof(Math.abs(Crypto.getRandomLong())).substring(0, 6),
                Username            = string.valueof(Math.abs(Crypto.getRandomLong())).substring(0, 6) + i + '@test.com',
                CommunityNickname   = string.valueof(Math.abs(Crypto.getRandomLong())).substring(0, 6) + i,
                ProfileId           = userProfileId,
                Email               = 'testemail' + i + '@test.com',
                TimeZoneSidKey      = 'Europe/Paris',
                LocaleSidKey        = 'fr_BE', 
                EmailEncodingKey    = 'ISO-8859-1',
                LanguageLocaleKey   = 'en_US',
                ContactId           = contactId
            ));
        }

        if(doInsert && !objList.isEmpty()) {
            insert objList;
        }

        return objList;
    }

    public static FW_TriggerHandlerSettings__c createTriggerHandlerSettingInactive(Boolean doAll, Boolean doInsert) {

        FW_TriggerHandlerSettings__c triggerHandlerSettings = new FW_TriggerHandlerSettings__c();
        SObjectType accountType = Schema.getGlobalDescribe().get('FW_TriggerHandlerSettings__c');
        Map<String,Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();
        
        for(Schema.SObjectField sfield : mfields.Values()) {
            schema.describefieldresult dfield = sfield.getDescribe();
            string namefield = dfield.getname();
            if(namefield.endsWith('__c')) {
                triggerHandlerSettings.put(namefield, false);
            }        
        }
        triggerHandlerSettings.put('All__c', doAll);

        if(doInsert) {
            insert triggerHandlerSettings;
        }
        return triggerHandlerSettings;
    }

    public static List<CleanErrorLogBatchSettings__c> createCleanErrorLogBatchSettings(Integer numberOfRecords, Boolean doInsert) {
        List<CleanErrorLogBatchSettings__c> objList = new List<CleanErrorLogBatchSettings__c>();
        
        for(Integer i = 0; i < numberOfRecords; i++) {
            objList.add(new CleanErrorLogBatchSettings__c(
              Name = 'Default',
              NumberOfDays__c = 2
            ));
        }

        if(doInsert && !objList.isEmpty()) {
            insert objList;
        }
        return objList;
    }

    private static Id getRecordTypeIdByDevName(String sObjType, String devName){

        Id recTypeId = null;

        try {
            final Map<String, Schema.SObjectType> sObjectTypeMap = Schema.getGlobalDescribe();
            if (sObjectTypeMap.containsKey(sObjType)) {
                final Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = sObjectTypeMap.get(sObjType).getDescribe().getRecordTypeInfosByDeveloperName();
                if (recordTypeInfoMap.containsKey(devName)) {
                    recTypeId = recordTypeInfoMap.get(devName).getRecordTypeId();
                }
            }
        } catch (Exception e) {
            System.debug( e.getLineNumber() + ' ' + e.getMessage());
        }

        return recTypeId;
    }
}