/**
 * @author           Daniel Lascas
 * @description      COMM_TH_CustomerUpdateRequest test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    16/09/2024      100            Original version
 **/
@isTest
private class COMM_TH_CustomerUpdateRequestTest {
    @isTest
    static void insertTest() {
        COMM_CustomerUpdateRequest__e pEvent = new COMM_CustomerUpdateRequest__e();

        Test.startTest();
        Database.SaveResult result = EventBus.publish(pEvent);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'platform event was not published successfully');
    }
}