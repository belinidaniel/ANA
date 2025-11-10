/**
 * @author Daniel Lascas
 * @description COMM_SL_ConnectedAppCommerce test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    03/04/2024      100            ECOMM-178: Original version
 **/
@isTest
private class COMM_SL_ConnectedAppCommerceTest {
    private final static fflib_ApexMocks MOCKS = new fflib_ApexMocks();
    private final static COMM_IDO_CommerceAppMapping COMMERCE_MAPPING_DO = (COMM_DO_CommerceAppMapping) MOCKS.mock(COMM_DO_CommerceAppMapping.class);
    private final static COMM_IREP_Account ACCOUNT_REP = (COMM_REP_Account) MOCKS.mock(COMM_REP_Account.class);
    private final static COMM_IREP_User USER_REP = (COMM_REP_User) MOCKS.mock(COMM_REP_User.class);

    @isTest
    static void authorizeTest() {
        Test.startTest();
        COMM_SL_ConnectedAppCommerce worker = new COMM_SL_ConnectedAppCommerce();
        Boolean result = worker.authorize(fflib_IDGenerator.generate(User.sObjectType), null, true, null);
        Test.stopTest();

        Assert.isTrue(result, 'expected authorization to be approved');
    }

    @isTest
    static void getAttributeMapTest() {
        //Scenario: FOR TEST COVERAGE. ATTRIBUTE MAPPING TEST IS DONE IN COMM_DO_CommerceAppMappingTest
        //Expected: Empty Map is returned.
        Test.startTest();
        Map<String, String> resultMap = new COMM_SL_ConnectedAppCommerce()
            .customAttributes(fflib_IDGenerator.generate(User.sObjectType), null, new Map<String, String>(), null);
        Test.stopTest();

        Assert.isTrue(resultMap.isEmpty(), 'expected empty map due to User not existing');
    }
}