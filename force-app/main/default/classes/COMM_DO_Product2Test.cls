/**
 * @author           Daniel Reto
 * @description      COMM_DO_Product2 test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      24/06/2024      100            Original version
 * Jose Passos      12/07/2024      100            ECOMM-1711 - consider card types
 **/
@isTest
private class COMM_DO_Product2Test {
    @isTest
    static void getFilterProductFamilyAPITest() {
        List<String> productFamilyCodeList = new List<String>{ 'CARD', 'FASTTRACK', 'GIFTCARD', 'LOUNGE', 'PARKING', 'SUBSCRIPTION' };

        Test.startTest();
        List<String> productFamilyAPIList = COMM_DO_Product2.getFilterProductFamilyAPI(productFamilyCodeList);
        Test.stopTest();

        Assert.areEqual(COMM_DO_Product2.CATEGORY_CARD, productFamilyAPIList.get(0), 'expected value was "Card"');
        Assert.areEqual(COMM_DO_Product2.CATEGORY_FASTTRACK, productFamilyAPIList.get(1), 'expected value was "Fast Track"');
        Assert.areEqual(COMM_DO_Product2.CATEGORY_GIFTCARD, productFamilyAPIList.get(2), 'expected value was "Gift Card"');
        Assert.areEqual(COMM_DO_Product2.CATEGORY_LOUNGE, productFamilyAPIList.get(3), 'expected value was "Lounge"');
        Assert.areEqual(COMM_DO_Product2.CATEGORY_PARKING, productFamilyAPIList.get(4), 'expected value was "Parking"');
        Assert.areEqual(COMM_DO_Product2.CATEGORY_SUBSCRIPTION, productFamilyAPIList.get(5), 'expected value was "Subscription"');
    }

    @isTest
    static void getFilterProductFamilyCodesTest() {
        Set<String> productFamilyAPIList = new Set<String>{ 'Card', 'Fast Track', 'Gift Card', 'Lounge', 'Parking', 'Subscription' };

        Test.startTest();
        List<String> productFamilyCodesList = COMM_DO_Product2.getFilterProductFamilyCodes(productFamilyAPIList);
        Test.stopTest();

        Assert.areEqual('CARD', productFamilyCodesList.get(0), 'expected value was "CARD"');
        Assert.areEqual('FASTTRACK', productFamilyCodesList.get(1), 'expected value was "FASTTRACK"');
        Assert.areEqual('GIFTCARD', productFamilyCodesList.get(2), 'expected value was "GIFTCARD"');
        Assert.areEqual('LOUNGE', productFamilyCodesList.get(3), 'expected value was "LOUNGE"');
        Assert.areEqual('PARKING', productFamilyCodesList.get(4), 'expected value was "PARKING"');
        Assert.areEqual('SUBSCRIPTION', productFamilyCodesList.get(5), 'expected value was "SUBSCRIPTION"');
    }
}