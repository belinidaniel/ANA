/**
 * @author Ruben Rodrigues
 * @description COMM_REP_ProductSetting test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Ruben Rodrigues 21/05/2024      100            Original version
 **/
@isTest
public class COMM_REP_ProductSettingTest {

    @testSetup
    static void setupTestData() {
        // Create test data for COMM_ProductSetting__c
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_ProductSetting__c',
            new Map<String, Object>{
                'Name' => 'Test Setting ProductCode',
                'COMM_FieldName__c' => 'ProductCode',
                'COMM_CoreEssential__c' => true,
                'COMM_CommerceEssential__c' => true,
                'COMM_FieldAPIName__c' => 'ProductCode'
            }
        );
    }
    
    @isTest
    static void testGetCoreEssentialFields() {
        // Instantiate the repository
        COMM_REP_ProductSetting repository = new COMM_REP_ProductSetting();
        
        // Call the method to be tested
        List<COMM_ProductSetting__c> coreEssentialFields = repository.getCoreEssentialFields();
        
        // Assert the results
        System.assertEquals(1, coreEssentialFields.size(), 'There should be 2 core essential fields');
        for (COMM_ProductSetting__c setting : coreEssentialFields) {
            System.assert(setting.COMM_CoreEssential__c, 'COMM_CoreEssential__c should be true');
        }
    }
    
    @isTest
    static void testGetCommerceEssentialFields() {
        // Instantiate the repository
        COMM_REP_ProductSetting repository = new COMM_REP_ProductSetting();
        
        // Call the method to be tested
        List<COMM_ProductSetting__c> commerceEssentialFields = repository.getCommerceEssentialFields();
        
        // Assert the results
        System.assertEquals(1, commerceEssentialFields.size(), 'There should be 2 commerce essential fields');
        for (COMM_ProductSetting__c setting : commerceEssentialFields) {
            System.assert(setting.COMM_CommerceEssential__c, 'COMM_CommerceEssential__c should be true');
        }
    }

    @isTest
    static void testGetFieldAPINames() {
        // Instantiate the repository
        COMM_REP_ProductSetting repository = new COMM_REP_ProductSetting();
        
        // Call the method to be tested
        List<COMM_ProductSetting__c> fieldAPINames = repository.getFieldAPINames();
        
        // Assert the results
        System.assertEquals(1, fieldAPINames.size(), 'There should be 3 records');
        for (COMM_ProductSetting__c setting : fieldAPINames) {
            System.assertNotEquals(null, setting.COMM_FieldAPIName__c, 'COMM_FieldAPIName__c should not be null');
        }
    }
}