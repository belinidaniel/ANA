/**
 * @author Jose Passos
 * @description Split String into List to invoke on Flows
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      12/04/2024      100            Original version
 **/
@isTest
private class COMM_StringToListConverterTest {
    @isTest
    static void convertStringToListTest() {
        // TO DO: implement unit test
        List<COMM_StringToListInput> inputList = new List<COMM_StringToListInput>();
        COMM_StringToListInput input = new COMM_StringToListInput();
        input.stringToSplit = 'String,To,Split';
        input.separator = ',';
        inputList.add(input);

        Test.startTest();
        List<COMM_StringToListOutput> outputList = COMM_StringToListConverter.convertStringToList(inputList);
        Test.stopTest();

        Assert.areEqual(3, outputList[0].stringList.size(), 'List size should be 3');
    }
}