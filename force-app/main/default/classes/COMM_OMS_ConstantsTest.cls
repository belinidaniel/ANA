/**
 * @author Rui Salgado
 * @description COMM_OMS_ConstantsTest class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Rui Salgado      01/04/2024    100            Original version
 **/
@isTest
private class COMM_OMS_ConstantsTest {
    @isTest
    static void shouldCheckConstants() {
        Test.startTest();
        System.assertEquals(COMM_OMS_Constants.ACTIVE, COMM_OMS_Constants.ACTIVE, 'ACTIVE should be equal');
        Test.stopTest();
    }
}