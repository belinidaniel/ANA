/**
 * @author Daniel Lascas
 * @description COMM_TW_Case_GenerateInvoice test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    08/04/2024      100            ECOMM-194: Original version
 **/
@isTest
private class COMM_TW_Case_GenerateInvoiceTest {
    @isTest
    static void generateEventTest() {
        //Scenario: A New Subscription Request Case is updated as concluded
        //Expected: Platform Event to generate invoice record is created

        Case oldCase = (Case) COMM_TestDataFactory.insertRecords(
            1,
            false,
            'Case',
            new Map<String, Object>{
                'Id' => fflib_IDGenerator.generate(Case.sObjectType),
                'Status' => COMM_DO_Case.IN_APPROVAL_STATUS,
                'RecordTypeId' => COMM_GEN_Utility.getRecordTypeIdByDevName(Case.sObjectType, COMM_DO_Case.SUBSCRIPTION_REQUEST_RT)
            }
        )[0];

        Case newCase = oldCase.clone(true);
        newCase.Status = COMM_DO_Case.PROCESS_CONCLUDED_STATUS;

        Map<Id, Case> oldCaseMap = new Map<Id, Case>{ oldCase.Id => oldCase };
        List<Case> newCaseList = new List<Case>{ newCase };

        Test.startTest();
        COMM_TW_Case_GenerateInvoice worker = new COMM_TW_Case_GenerateInvoice();
        worker.execute(newCaseList, oldCaseMap);
        Integer dmlExecuted = Limits.getDMLStatements();
        Test.stopTest();

        Assert.areEqual(1, dmlExecuted, 'Expected one Platform Event to be published');
    }
}