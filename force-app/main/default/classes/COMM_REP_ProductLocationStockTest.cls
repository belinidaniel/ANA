/**
 * @author           Daniel Reto
 * @description      COMM_REP_ProductLocationStock test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      13/05/2024      100            ECOMM-281,282,283: Original version
 **/
@isTest
private class COMM_REP_ProductLocationStockTest {
    private final static COMM_REP_ProductLocationStock PRODUCTLOCATIONSTOCK_REP = new COMM_REP_ProductLocationStock();

    @TestSetup
    static void makeData() {

        Time myTime = Time.newInstance(1, 2, 3, 0);
        // Insert Product
        List<Product2> productList = (List<Product2>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'Product2',
            new Map<String, Object>{
                'Name' => 'Subscription Service',
                'ProductCode' => 'P0',
                'Description' => 'Subscription Service',
                'IsActive' => false,
                'Family' => 'Subscription',
                'COMM_Alarmistic__c' => 75,
                'COMM_WhereProductAvailable__c' => 'Subscriptions Portal',
                'COMM_ValidFrom__c' => System.now().addSeconds(30),
                'COMM_ValidTo__c' => System.now().addDays(2),
                'COMM_Airport__c' => 'LIS',
                'COMM_Tax__c' => 'Continent',
                'COMM_Park__c' => 'p0',
                'COMM_CPMS__c' => 'SKIDATA',
                'COMM_OpeningOperatingHours__c' => myTime,
                'COMM_ClosingOperatingHours__c' => myTime,
                'COMM_SubCategory__c' => 'Park',
                'RecordTypeId' => Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('COMM_Subscription').RecordTypeId
            }
        );
        
        // Insert Product Location Stock
        List<COMM_ProductLocationStock__c> productLocationStockList = (List<COMM_ProductLocationStock__c>) COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_ProductLocationStock__c',
            new Map<String, Object>{
                'COMM_Location__c' => COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION,
                'COMM_StockDate__c' => System.today(),
                'COMM_Product__c' => productList.get(0).Id,
                'COMM_ProductLocation__c' => productList.get(0).ProductCode + '_' + String.valueOf(System.now().formatGMT(COMM_OCI_Constants.DATE_FORMAT)) + '_' + COMM_OCI_Constants.PRODUCT_FAMILY_SUBSCRIPTION,
                'COMM_ReservedStock__c' => 90,
                'COMM_StockOnHand__c' => 100
            }
        );
    }

    @isTest
    static void getProductLocationStockToEraseTest() {
        
        List<COMM_ProductLocationStock__c> expectedProductLocationStockList = [
            SELECT Id, COMM_Product__c, COMM_Product__r.Name, COMM_Product__r.COMM_Alarmistic__c, toLabel(COMM_Product__r.Family)
            FROM COMM_ProductLocationStock__c
            LIMIT 1];

        Test.startTest();
        List<COMM_ProductLocationStock__c> actualList = PRODUCTLOCATIONSTOCK_REP.getProductLocationStockToErase();
        Test.stopTest();

        Assert.areEqual(expectedProductLocationStockList, actualList, 'retrieved ProductLocationStock does not match expected');
    }

    @isTest
    static void getProductLocationStockToEraseTwoParametersTest() {
        Product2 productRecord = [
            SELECT Id
            FROM Product2
            LIMIT 1].get(0);
        
        List<COMM_ProductLocationStock__c> expectedProductLocationStockList = [
            SELECT Id
            FROM COMM_ProductLocationStock__c
            LIMIT 1];

        Test.startTest();
        List<COMM_ProductLocationStock__c> actualList = PRODUCTLOCATIONSTOCK_REP.getProductLocationStockToErase(new List<String>{ productRecord.Id }, System.today().addDays(1));
        Test.stopTest();

        Assert.areEqual(expectedProductLocationStockList, actualList, 'retrieved ProductLocationStock does not match expected');
    }
    
}