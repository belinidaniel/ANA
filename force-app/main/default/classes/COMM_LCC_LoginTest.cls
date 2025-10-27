/**
 * @author Daniel Lascas
 * @description COMM_LCC_Login test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    31/05/2024      100            Original version
 * Daniel Lascas    22/10/2024      96            Updated tests with key logic
 **/
@isTest
private class COMM_LCC_LoginTest {
    @TestSetup
    static void makeData() {
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = :COMM_DO_Profile.PROFILE_NAME_SYS_ADMIN];

        //Create User with Valid Password Expiration Date
        Long userSuffix = DateTime.now().getTime();
        String userName = 'testuser' + userSuffix;
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => userName + '@ana.pt.testlogin',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'Valid',
                'FirstName' => 'Test',
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER,
                'CommunityNickname' => userName,
                'Alias' => userName.right(8),
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => profileList[0].Id,
                'COMM_IsPasswordReseted__c' => true,
                'COMM_ResetPasswordEmailExpirationDate__c' => Datetime.now().addHours(1)
            }
        );

        //Create User with Expired Password Expiration Date
        userSuffix = DateTime.now().getTime();
        userName = 'test.expired' + userSuffix;
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => userName + '@ana.pt.testlogin',
                'Email' => 'test.expired@test.com.invalid',
                'LastName' => 'Expired',
                'FirstName' => 'Test',
                'COMM_LoginType__c' => COMM_DO_User.NORMAL_LOGIN_IDENTIFIER,
                'CommunityNickname' => userName,
                'Alias' => userName.right(8),
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => COMM_DO_User.EMAIL_ENCODINGKEY_PICKLIST_UTF8,
                'TimeZoneSidKey' => COMM_DO_User.TIME_ZONE_PICKLIST_PTLS,
                'ProfileId' => profileList[0].Id,
                'COMM_IsPasswordReseted__c' => true,
                'COMM_ResetPasswordEmailExpirationDate__c' => Datetime.now().addHours(-1)
            }
        );

        //Generate Test Encryption Key
        COMM_EmailTemplatesEncryptionSettings__c setting = new COMM_EmailTemplatesEncryptionSettings__c();
        setting.Name = 'Encrypt key test';
        setting.COMM_UserKey__c = '9wp6gqhzz8u07wpw';
        insert setting;
    }

    @isTest
    static void getKeys() {
        //Retrieve Key from Metadata
        String expectedLoginKey = COMM_EncryptionSetting__mdt.getInstance('Login')?.COMM_Value__c;
        String expectedResetKey = COMM_EncryptionSetting__mdt.getInstance('Reset')?.COMM_Value__c;
        Test.startTest();
        String loginKey = COMM_LCC_Login.getLoginKey();
        String resetKey = COMM_LCC_Login.getResetKey();
        Test.stopTest();
        Assert.areEqual(expectedLoginKey, loginKey, 'Obtained Login Key does not match expected');
        Assert.areEqual(expectedResetKey, resetKey, 'Obtained Reset Key does not match expected');
    }

    @isTest
    static void siteLoginTest() {
        //Scenario: User initiates login.
        //Expected: A null value is returned.

        COMM_EncryptionSetting__mdt testSettings = COMM_TestDataFactory.getTestEncryptionSetting();
        Map<String, Object> userData = new Map<String, Object>{
            'email' => 'test@test.com',
            'password' => 'testPass1.',
            'timestamp' => Datetime.now()
        };
        Blob testKey = EncodingUtil.base64Decode(testSettings.COMM_Value__c);
        Blob encryptedText = Crypto.encryptWithManagedIV('AES256', testKey, Blob.valueOf(JSON.serialize(userData)));
        String encryptedData = EncodingUtil.base64Encode(encryptedText);

        Test.startTest();
        String result = COMM_LCC_Login.siteLogin(null, encryptedData);
        Test.stopTest();

        Assert.isNull(result, 'expected login to return null');
    }

    @isTest
    static void siteLoginFailureTest() {
        //Scenario: User initiates login but no data was passed.
        //Expected: An error occured.
        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_LCC_Login.siteLogin(null, null);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void siteLoginTimeFailureTest() {
        //Scenario: User initiates login but timestamp is too old.
        //Expected: Login is skipped a null value returned.

        COMM_EncryptionSetting__mdt testSettings = COMM_TestDataFactory.getTestEncryptionSetting();

        Map<String, Object> userData = new Map<String, Object>{
            'email' => 'test@test.com',
            'password' => 'testPass1.',
            'timestamp' => Datetime.now().addSeconds(-Integer.valueOf(testSettings.COMM_Buffer__c) - 1)
        };
        Blob testKey = EncodingUtil.base64Decode(testSettings.COMM_Value__c);
        Blob encryptedText = Crypto.encryptWithManagedIV('AES256', testKey, Blob.valueOf(JSON.serialize(userData)));
        String encryptedData = EncodingUtil.base64Encode(encryptedText);

        Boolean errorOccured = false;
        Test.startTest();
        try {
            String result = COMM_LCC_Login.siteLogin(null, encryptedData);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void resetPasswordTest() {
        //Scenario: User initiates reset password. For Test Coverage.
        //Reset logic test is done in test class for COMM_SL_ResetPassword).
        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_LCC_Login.resetPassword('test@test.com', null);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void changePasswordTest() {
        //Scenario: User initiates change password. For Test Coverage.
        //Change logic test is done in test class for COMM_SL_ResetPassword).
        COMM_EncryptionSetting__mdt testSettings = COMM_TestDataFactory.getTestEncryptionSetting();
        Map<String, Object> userData = new Map<String, Object>{
            'userId' => fflib_IDGenerator.generate(User.sObjectType),
            'password' => 'testPass',
            'timestamp' => Datetime.now()
        };
        Blob testKey = EncodingUtil.base64Decode(testSettings.COMM_Value__c);
        Blob encryptedText = Crypto.encryptWithManagedIV('AES256', testKey, Blob.valueOf(JSON.serialize(userData)));
        String encryptedData = EncodingUtil.base64Encode(encryptedText);

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_LCC_Login.changePassword(encryptedData);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void changePasswordFailureTest() {
        //Scenario: User initiates change password but passed buffer time.
        //Expected: Change Password is skipped.
        COMM_EncryptionSetting__mdt testSettings = COMM_TestDataFactory.getTestEncryptionSetting();
        Map<String, Object> userData = new Map<String, Object>{
            'userId' => fflib_IDGenerator.generate(User.sObjectType),
            'password' => 'testPass',
            'timestamp' => Datetime.now().addSeconds(-Integer.valueOf(testSettings.COMM_Buffer__c) - 1)
        };
        Blob testKey = EncodingUtil.base64Decode(testSettings.COMM_Value__c);
        Blob encryptedText = Crypto.encryptWithManagedIV('AES256', testKey, Blob.valueOf(JSON.serialize(userData)));
        String encryptedData = EncodingUtil.base64Encode(encryptedText);

        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_LCC_Login.changePassword(encryptedData);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void validateResetTokenTest() {
        //Scenario: User opens password set page but with a valid Token.
        //Expected: User Data is returned (Id, Email, First and Last Name) for Password validation.

        //Obtain Test User with a valid reset time
        User testUser = [SELECT Id, Email, FirstName, LastName, COMM_ResetPasswordEmailExpirationDate__c FROM User WHERE Name = 'Test Valid' LIMIT 1];

        //Generate expected valid token
        COMM_SL_ResetPassword.TokenWrapper token = new COMM_SL_ResetPassword.TokenWrapper();
        token.userId = testUser.Id;
        token.requestDate = testUser.COMM_ResetPasswordEmailExpirationDate__c;
        String encryptedToken = COMM_GEN_Utility.encryptRecordIdentifier(JSON.serialize(token), COMM_GEN_Utility.USER_KEY_NAME);

        Test.startTest();
        List<String> resultList = COMM_LCC_Login.validateResetToken(encryptedToken);
        Test.stopTest();

        Assert.isFalse(resultList.isEmpty(), 'expected resulting list to not be empty');
        Assert.areEqual(testUser.Id, resultList[0], 'expected list to contain user\'s Id');
        Assert.areEqual(testUser.Email, resultList[1], 'expected list to contain user\'s email');
        Assert.areEqual(testUser.FirstName, resultList[2], 'expected list to contain user\'s first name');
        Assert.areEqual(testUser.LastName, resultList[3], 'expected list to contain user\'s last name');
    }

    @isTest
    static void validateResetTokenInvalidTest() {
        //Scenario: User opens password set page but with an invalid Token.
        //Expected: Exception is throwed.
        Boolean errorOccured = false;

        Test.startTest();
        try {
            COMM_LCC_Login.validateResetToken(null);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
    }

    @isTest
    static void validateResetTokenFailureTest() {
        //Scenario: User opens password set page with a valid token but reset timer has expired.
        //Expected: Exception is throwed.

        //Obtain Test User with expired reset time
        User testUser = [SELECT Id, COMM_ResetPasswordEmailExpirationDate__c FROM User WHERE Name = 'Test Expired' LIMIT 1];

        Boolean errorOccured = false;

        //Generate expected valid token
        COMM_SL_ResetPassword.TokenWrapper token = new COMM_SL_ResetPassword.TokenWrapper();
        token.userId = testUser.Id;
        token.requestDate = testUser.COMM_ResetPasswordEmailExpirationDate__c;
        String encryptedToken = COMM_GEN_Utility.encryptRecordIdentifier(JSON.serialize(token), COMM_GEN_Utility.USER_KEY_NAME);

        Test.startTest();
        try {
            COMM_LCC_Login.validateResetToken(encryptedToken);
        } catch (Exception e) {
            errorOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(errorOccured, 'expected an error to occur');
    }
}