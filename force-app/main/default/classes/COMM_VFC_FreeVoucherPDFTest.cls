/**
 * @author Daniel Lascas
 * @description COMM_VFC_FreeVoucherPDF test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    24/10/2024      100            ECOMM-2248 - Original version
 **/
@isTest
private class COMM_VFC_FreeVoucherPDFTest {
    @TestSetup
    static void makeData() {
        Time testTime = Time.newInstance(1, 2, 3, 0);
        //Insert Lounge Product for testing
        Product2 loungeProduct = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Lounge Product',
                'ProductCode' => 'lounge2',
                'Description' => 'lounge',
                'IsActive' => false,
                'Family' => COMM_DO_Product2.CATEGORY_LOUNGE,
                'COMM_ValidFrom__c' => System.now().addSeconds(30),
                'COMM_ValidTo__c' => System.now().addDays(2),
                'COMM_Airport__c' => 'LIS',
                'COMM_Tax__c' => 'Continent',
                'COMM_Park__c' => 'p0',
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_OpeningOperatingHours__c' => testTime,
                'COMM_ClosingOperatingHours__c' => testTime,
                'COMM_SubCategory__c' => 'Lounge'
            }
        )[0];

        // Insert Child Product
        Product2 pForCap = (Product2) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Child',
                'ProductCode' => 'C2132',
                'Description' => 'Test Lounge',
                'IsActive' => true,
                'Family' => 'Lounge',
                'COMM_ValidFrom__c' => System.now().addMinutes(1),
                'COMM_ValidTo__c' => System.now().addDays(2),
                'COMM_Airport__c' => 'LIS',
                'COMM_Tax__c' => 'Continent',
                'COMM_OpeningOperatingHours__c' => testTime,
                'COMM_ClosingOperatingHours__c' => testTime,
                'COMM_ParentProduct__c' => loungeProduct.id,
                'COMM_SubCategory__c' => 'Lounge',
                'COMM_WhereProductAvailable__c' => COMM_DO_Product2.PRODUCT_AVAILABLE_IN_COMMERCE
            }
        )[0];

        //Insert Free Voucher Record
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_FreeVoucher__c',
            new Map<String, Object>{
                'COMM_ReservationName__c' => 'Joao Teste',
                'COMM_StartDate__c' => Datetime.now(),
                'COMM_Email__c' => 'joao.teste@test.invalid',
                'COMM_Language__c' => 'pt_PT',
                'COMM_Product__c' => pForCap.Id
            }
        );

        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Long suffix = DateTime.now().getTime();
        String userName = 'testuser' + suffix;
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'User',
            new Map<String, Object>{
                'Username' => 'testuser@ana.pt.test',
                'Email' => 'test@test.com.invalid',
                'LastName' => 'User',
                'FirstName' => 'Test',
                'CommunityNickname' => userName,
                'Alias' => 'testUser',
                'COMM_EffectiveAccountId__c' => fflib_idgenerator.generate(Account.SObjectType),
                'LanguageLocaleKey' => UserInfo.getLanguage(),
                'LocaleSidKey' => UserInfo.getLocale(),
                'EmailEncodingKey' => 'UTF-8',
                'TimeZoneSidKey' => 'Europe/Lisbon',
                'ProfileId' => profileList[0].Id
            }
        );
    }

    @isTest
    static void testVoucherPDF() {
        User userRecord = [SELECT Id FROM User WHERE email = 'test@test.com.invalid' LIMIT 1];
        // Run system as User
        System.runAs(userRecord) {
            Test.startTest();
            List<COMM_FreeVoucher__c> fvList = [SELECT Id FROM COMM_FreeVoucher__c LIMIT 1];
            Assert.areEqual(fvList.isEmpty(), false, 'Free Voucher not found.');

            ApexPages.StandardController stdController = new ApexPages.StandardController(fvList[0]);
            COMM_VFC_FreeVoucherPDF controller = new COMM_VFC_FreeVoucherPDF(stdController);
            Test.stopTest();
            Assert.areEqual(fvList[0].Id, controller.freeVoucherId, 'Expected to have Id of free voucher');
        }
    }
}