/**
 * @author Daniel Lascas
 * @description COMM_GEN_Utility test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/02/2024      67             Original version
 * Miguel Freire    23/03/2024      67             Add method getTokenValueFromPageReferenceTest
 * Rui Salgado      05/04/2024      76             Add method shouldConvertListToMap
 * Daniel Reto      05/04/2024      76             Add method getMonthValueToAddTest
 * Diogo Gonçalves  17/04/2024      61             Add method getTextFieldValuesTest and generateQRCodeImageTest
 * Diogo Gonçalves  06/05/2024      65             Add method getIdsOfGivenSObjectTypeTest
 * Daniel Reto      13/05/2024     	76			   Add methods generateHrefSiteEmailTemplate, generateHrefEmailTemplate and getEmailsFromQueue
 * Daniel Reto      20/06/2024      73             Add method generateDateTimeDataTypeTest
 **/
@isTest
private class COMM_GEN_UtilityTest {
    @testSetup
    static void setup() {
        COMM_TestDataFactory.insertRecords(1, true, 'Account', new Map<String, Object>{ 'FirstName' => 'Name', 'LastName' => '1' });
        COMM_TestDataFactory.insertRecords(1, true, 'Account', new Map<String, Object>{ 'FirstName' => 'Name', 'LastName' => '2' });
        COMM_TestDataFactory.insertRecords(1, true, 'Account', new Map<String, Object>{ 'FirstName' => 'Name', 'LastName' => '3' });
    }

    @isTest
    static void isChangedTest() {
        //Scenario: Account is updated. First update is to change Phone, second update no change is done. Lastly Account is inserted.
        //Expected: Change detected in first update, no change in second update. Change detected when insert is done.
        Account oldAccount = new Account(Name = 'teste');
        //Phone differs from oldAccount Phone
        Account newAccount1 = new Account(Name = 'teste', Phone = '219122345');
        //Phone doesnt differ from oldAccount Phone
        Account newAccount2 = new Account(Name = 'teste');
        //check if Phone changed or not
        Assert.isTrue(COMM_GEN_Utility.isChangedField(newAccount1, oldAccount, 'Phone'), 'The field has changed');
        Assert.isFalse(COMM_GEN_Utility.isChangedField(newAccount2, oldAccount, 'Phone'), 'The field didnt change');
        Assert.isTrue(COMM_GEN_Utility.isChangedField(newAccount1, null, Account.Phone), 'The field has changed');
    }

    @isTest
    static void getRecordTypeIdByDevNameTest() {
        List<RecordType> existingRecordTypeList = [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Case' LIMIT 1];
        Assert.isFalse(existingRecordTypeList.isEmpty(), 'no Record Types available for testing');

        String developerName = existingRecordTypeList[0].DeveloperName;
        SObjectType sobj = Schema.getGlobalDescribe().get(existingRecordTypeList[0].SobjectType);

        Test.startTest();
        Id idResult = COMM_GEN_Utility.getRecordTypeIdByDevName(sobj, developerName);
        Test.stopTest();

        Assert.areEqual(existingRecordTypeList[0].Id, idResult, 'Record Type Id does not match expected');
    }

    @isTest
    static void getValueForFieldTypeTest() {
        Test.startTest();
        Object convertedFieldAsBoolean = COMM_GEN_Utility.getValueForFieldType('Product2', 'IsActive', 'true');
        Object convertedFieldAsDecimal = COMM_GEN_Utility.getValueForFieldType('Account', 'AnnualRevenue', '100.05');
        Object convertedFieldAsDate = COMM_GEN_Utility.getValueForFieldType('Account', 'LastActivityDate', '2024-04-23');
        Object convertedFieldAsDatetime = COMM_GEN_Utility.getValueForFieldType('Account', 'CreatedDate', '2024-04-23 9:00:00');
        Object convertedFieldAsDouble = COMM_GEN_Utility.getValueForFieldType('Account', 'BillingLatitude', '100.05');
        Object convertedFieldAsString = COMM_GEN_Utility.getValueForFieldType('Account', 'Name', 'account name');
        Test.stopTest();

        Assert.isTrue(convertedFieldAsBoolean instanceof Boolean, 'Expected value to be stored in a boolean type variable');
        Assert.isTrue(convertedFieldAsDecimal instanceof Decimal, 'Expected value to be stored in a decimal type variable');
        Assert.isTrue(convertedFieldAsDate instanceof Date, 'Expected value to be stored in a date type variable');
        Assert.isTrue(convertedFieldAsDatetime instanceof Datetime, 'Expected value to be stored in a datetime type variable');
        Assert.isTrue(convertedFieldAsDouble instanceof Double, 'Expected value to be stored in a double type variable');
        Assert.isTrue(convertedFieldAsString instanceof String, 'Expected value to be stored in a string type variable');
    }

    @isTest
    static void base64TextTest() {
        String testString = 'Testing base64 encoding';
        String encondedText = COMM_GEN_Utility.convertToBase64(testString);
        String decodedText = COMM_GEN_Utility.decodeBase64(encondedText);

        Assert.areNotEqual(testString, encondedText, 'encoded text still matches inicial text');
        Assert.areEqual(testString, decodedText, 'decoded text does not match inicial text');
    }

    @isTest
    static void getPicklistMapTest() {
        Schema.SObjectField picklistField = Schema.Account.COMM_Airport__c;

        Test.startTest();
        Map<String, String> picklistLabelByValue = COMM_GEN_Utility.getPicklistMap(picklistField, false);
        Test.stopTest();

        Assert.isFalse(picklistLabelByValue.isEmpty(), 'map with picklist field label by value should be populated');
    }

    @isTest
    static void getTokenValueFromPageReferenceTest() {
        //Scenario: Given a specif string it returns the specific value of token
        //Expected: Returns the token value
        String stringValue = 'https://test?dXNlcklk=expectedResult';

        Test.startTest();
        String tokenValue = COMM_GEN_Utility.getTokenValueFromPageReference(stringValue);
        Test.stopTest();

        Assert.areEqual(tokenValue, 'expectedResult', 'Token returned matches expectedResult');
    }

    /**
     * @description Test method of COMM_GEN_Utility.convertListToMap
     */
    @isTest
    static void shouldConvertListToMap() {
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 3];

        Test.startTest();
        Map<String, Sobject> mapAccountsByName = COMM_GEN_Utility.convertListToMap(accounts, 'Name');
        Test.stopTest();
        System.debug(mapAccountsByName);
        System.assert(mapAccountsByName.get('Name 1') != null, 'Name 1 not found');
        System.assert(mapAccountsByName.get('NameX') == null, 'Name X found');
        System.assert(mapAccountsByName.get('Name 2') != null, 'Name 2 not found');
        System.assert(mapAccountsByName.get('Name 3') != null, 'Name 3 not found');
    }

    /**
     * @description Test method for COMM_GEN_Utility.getTextFieldValues
     */
    @isTest
    static void getTextFieldValuesTest() {
        List<Account> accounts = new List<Account>{ new Account(Name = 'A'), new Account(Name = 'B'), new Account(Name = 'C') };
        insert accounts;
        Test.startTest();
        List<String> accountNames = (List<String>) COMM_GEN_Utility.getTextFieldValues(accounts, 'Name');
        Test.stopTest();

        Assert.areEqual(3, accountNames.size(), 'Wrong number of names.');
    }

    /**
     * @description Test method for COMM_GEN_Utility.generateQRCodeImage
     */
    @isTest
    static void generateQRCodeImageTest() {
        List<String> qrcodeResponseData = new List<String>{
            '"content": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdj+Gkf9x8ABmEClm+bvsMAAAAASUVORK5CYII="',
            '"fileType": "img/png"'
        };
        Test.setMock(HttpCalloutMock.class, new HttpResponseSuccessMock('{' + String.join(qrcodeResponseData, ',') + '}'));
        Test.startTest();

        String result = COMM_GEN_Utility.generateQRCodeImage('test');

        Test.stopTest();

        Assert.isNotNull(result, 'Wrong result.');
    }

    /**
     * @description Test method of COMM_GEN_Utility.getMonthValueToAdd
     */
    @isTest
    static void getMonthValueToAddTest() {
        Test.startTest();
        Integer monthValue = COMM_GEN_Utility.getMonthValueToAdd(COMM_DO_Subscription.PERIODICITY_YEARLY);
        Test.stopTest();
        System.assertEquals(12, monthValue, 'Month wrongly calculated.');
    }

    /**
     * @description Test method of COMM_GEN_Utility.getIdsOfGivenSObjectType
     */
    @isTest
    static void getIdsOfGivenSObjectTypeTest() {
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id FROM Account LIMIT 3]);
        List<String> objectIds = COMM_GEN_Utility.getIdsOfGivenSObjectType(new List<Id>(accounts.keySet()), Schema.Account.SObjectType);
        Assert.areEqual(3, objectIds.size(), 'Wrong number of Ids returned.');
    }

    /**
     * @description Test method of COMM_GEN_Utility.generateHrefSiteEmailTemplate
     */
    @isTest
    static void generateHrefSiteEmailTemplateTest() {
        Account accountRecord = [SELECT Id, Name FROM Account LIMIT 1];
        String expectedValue =
            '<li><a href="' +
            COMM_GEN_Utility.getExperiencrSiteUrl() +
            '/detail/' +
            accountRecord.Id +
            '">' +
            accountRecord.Name +
            '</a></li>';
        Test.startTest();
        String returnValue = COMM_GEN_Utility.generateHrefSiteEmailTemplate(
            accountRecord.Id,
            accountRecord.Name,
            COMM_GEN_Utility.getExperiencrSiteUrl()
        );
        Test.stopTest();
        System.assertEquals(expectedValue, returnValue, 'String wrongly calculated.');
    }

    /**
     * @description Test method of COMM_GEN_Utility.generateHrefEmailTemplate
     */
    @isTest
    static void generateHrefEmailTemplateTest() {
        Account accountRecord = [SELECT Id, Name FROM Account LIMIT 1];
        String expectedValue =
            '<li><a href="' +
            URL.getOrgDomainURL().toExternalForm() +
            '/' +
            accountRecord.Id +
            '">' +
            accountRecord.Name +
            '</a></li>';
        Test.startTest();
        String returnValue = COMM_GEN_Utility.generateHrefEmailTemplate(accountRecord.Id, accountRecord.Name);
        Test.stopTest();
        System.assertEquals(expectedValue, returnValue, 'String wrongly calculated.');
    }

    /**
     * @description Test method of COMM_GEN_Utility.generateHrefEmailTemplate
     */
    @isTest
    static void getEmailsFromQueueTest() {
        List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'COMM_SubscriptionRequestANAAdmin'];
        Set<Id> userIds = new Set<Id>();
        //Check expected member number. Only Users added directly are counted.
        for (GroupMember member : groupMembers) {
            String memberId = member.UserOrGroupId;
            if (memberId.startsWith('005')) {
                userIds.add(member.UserOrGroupId);
            }
        }
        Test.startTest();
        List<String> returnValue = COMM_GEN_Utility.getEmailsFromQueue('COMM_SubscriptionRequestANAAdmin');
        Test.stopTest();
        System.assertEquals(userIds.size(), returnValue.size(), 'String wrongly calculated.');
    }

    @isTest
    static void valueEncryptionTest() {
        //Scenario: A value is to be encrypted.
        //Expected: Value is encrypted and decrypting value should return original value.

        //Generate Test Encryption Key
        COMM_EmailTemplatesEncryptionSettings__c setting = new COMM_EmailTemplatesEncryptionSettings__c();
        setting.Name = 'Encrypt key test';
        setting.COMM_UserKey__c = '9wp6gqhzz8u07wpw';
        insert setting;

        String originalValue = 'test_value';

        Test.startTest();
        String encryptedValue = COMM_GEN_Utility.encryptRecordIdentifier(originalValue, 'COMM_UserKey__c');
        String decryptedValue = COMM_GEN_Utility.decryptRecordIdentifier(encryptedValue, 'COMM_UserKey__c');
        Test.stopTest();

        Assert.areNotEqual(originalValue, encryptedValue, 'encrypted value should be different from original value');
        Assert.areEqual(originalValue, decryptedValue, 'decrypted value does not match original value');
    }

    /**
     * @description Test method of COMM_GEN_Utility.generateDateTimeDataType
     */
    @isTest
    static void generateDateTimeDataTypeTest() {
        Date dt = Date.newInstance(Date.today().year(), Date.today().month(), Date.today().day());
        Test.startTest();
        Datetime returnValue = COMM_GEN_Utility.generateDateTimeDataType(dt);
        Test.stopTest();
        System.assertEquals(
            Datetime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()),
            returnValue,
            'DateTime wrongly calculated.'
        );
    }

    @isTest
    static void validateVatTest() {
        //Call VAT Validation Test

        Test.startTest();
        Boolean validationResult = COMM_GEN_Utility.validateVAT('2191', 'PT');
        Test.stopTest();

        Assert.isFalse(validationResult, 'expected validation to fail');
    }

    @isTest
    static void decryptStringWithAESTest() {
        Blob encodedKey = Crypto.generateAesKey(256);
        String secretKey = EncodingUtil.base64Encode(encodedKey);
        String originalText = 'This is an encryption test';
        Blob encryptedText = Crypto.encryptWithManagedIV('AES256', encodedKey, Blob.valueOf(originalText));
        String encryptedTextAsString = EncodingUtil.base64Encode(encryptedText);
        Test.startTest();
        String decryptedText = COMM_GEN_Utility.decryptStringWithAES(encryptedTextAsString, secretKey);
        Test.stopTest();

        Assert.areEqual(originalText, decryptedText, 'decrypted value does not match original');
    }

    @isTest
    static void generateQRCodeValueTest() {
        String family = COMM_DO_Product2.CATEGORY_LOUNGE;
        String subCategory = 'Lounge Child';
        String airportCode = 'OPO';
        Datetime reservationDate = Datetime.now();
        String timeZoneByAirport = 'Europe/Lisbon';

        Test.startTest();
        String QRCodeString = COMM_GEN_Utility.generateQRCodeValue(family, subCategory, airportCode, reservationDate, timeZoneByAirport);
        Test.stopTest();

        Assert.isTrue(QRCodeString != null, 'Expected QRCodeString to be generated');
    }
}