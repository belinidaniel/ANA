/**
 * @author Daniel Lascas
 * @description COMM_DO_ProductSyncFieldConvert test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    15/04/2024      100            ECOMM-808: Original version
 **/
@isTest
private class COMM_DO_ProductSyncFieldConvertTest {
    private static final COMM_DO_ProductSyncFieldConvert CONVERT_DO = new COMM_DO_ProductSyncFieldConvert();
    @isTest
    static void conversionTest() {
        //Scenario: Commerce requires diferent values from the ones used in Code
        //Expected: Value is converted
        List<COMM_ProductSynchronizationFieldConvert__mdt> metadataList = COMM_ProductSynchronizationFieldConvert__mdt.getAll().values();
        Map<String, Object> valueMap = new Map<String, Object>{
            metadataList[0].COMM_IntegrationApiName__c => metadataList[0].COMM_SalesforceValue__c
        };
        Test.startTest();
        CONVERT_DO.verifyValueConversion(valueMap);
        Test.stopTest();

        Assert.areEqual(
            metadataList[0].COMM_CommerceValue__c,
            valueMap.get(metadataList[0].COMM_IntegrationApiName__c),
            'expected value to be converted'
        );
    }

    @isTest
    static void noConversionTest() {
        //Scenario: Map has no values that require conversion
        //Expected: Value is not converted
        Map<String, Object> valueMap = new Map<String, Object>{ 'c_testField' => 'testValue' };
        Test.startTest();
        CONVERT_DO.verifyValueConversion(valueMap);
        Test.stopTest();

        Assert.areEqual(1, valueMap.size(), 'map size does not match expected');
        Assert.areEqual('testValue', valueMap.get('c_testField'), 'expected value to not change');
    }
}