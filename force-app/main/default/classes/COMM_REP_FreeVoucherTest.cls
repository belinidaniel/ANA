/**
 * @author Daniel Lascas
 * @description COMM_REP_FreeVoucher test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    24/10/2024      100            ECOMM-2248 - Original version
 **/
@isTest
private class COMM_REP_FreeVoucherTest {
    private final static COMM_REP_FreeVoucher VOUCHER_REP = new COMM_REP_FreeVoucher();

    @TestSetup
    static void makeData() {
        //Insert a test Free Voucher Record
        COMM_TestDataFactory.insertRecords(
            1,
            true,
            'COMM_FreeVoucher__c',
            new Map<String, Object>{
                'COMM_ReservationName__c' => 'Joao Teste',
                'COMM_StartDate__c' => Datetime.now(),
                'COMM_Email__c' => 'joao.teste@test.invalid',
                'COMM_Language__c' => 'pt_PT'
            }
        );
    }

    @isTest
    static void getVouchersByIdsTest() {
        List<COMM_FreeVoucher__c> expectedList = [SELECT Id FROM COMM_FreeVoucher__c LIMIT 1];

        Test.startTest();
        List<COMM_FreeVoucher__c> actualList = VOUCHER_REP.getVouchersByIds(new Set<Id>{ expectedList[0].Id });
        Test.stopTest();

        Assert.areEqual(expectedList[0].Id, actualList[0].Id, 'obtained record does not match expected');
    }
}