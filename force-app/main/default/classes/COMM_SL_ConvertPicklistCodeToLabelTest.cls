/**
 * @author           Daniel Reto
 * @description      COMM_SL_ConvertPicklistCodeToLabel test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      22/04/2024      100            Original version
 **/
@isTest
private class COMM_SL_ConvertPicklistCodeToLabelTest {
    @isTest
    static void ConvertPicklistCodeToLabelTest() {
        //Scenario: Convert Address Picklist Code to Label
        //Expected: Address Coutry Code and State Code respective Labels

        COMM_SL_ConvertPicklistCodeToLabel.InputWrapper testInput = new COMM_SL_ConvertPicklistCodeToLabel.InputWrapper();
        testInput.countryCodeToLabel = true;
        testInput.countryCodeValue = 'PT';
        testInput.stateCodeValue = 'PT';

        Boolean errorOccurred = false;
        List<COMM_SL_ConvertPicklistCodeToLabel.OutputWrapper> outputValuesList = new List<COMM_SL_ConvertPicklistCodeToLabel.OutputWrapper>();
        try {
            outputValuesList = COMM_SL_ConvertPicklistCodeToLabel.changePicklistCodeToLabel(new List<COMM_SL_ConvertPicklistCodeToLabel.InputWrapper>{ testInput });
        } catch (Exception e) {
            errorOccurred = true;
        }

        System.assert(!errorOccurred, 'expected no error to occur');
        System.assertEquals(outputValuesList.get(0).outputCountryCodeValue, 'Portugal', 'expected no error to occur');
        System.assertEquals(outputValuesList.get(0).outputStateCodeValue, 'Pistoia', 'expected no error to occur');
    }

    @isTest
    static void ConvertPicklistLabelToCodeTest() {
        //Scenario: Convert Address Picklist Code to Label
        //Expected: Address Coutry Code and State Code respective Labels

        COMM_SL_ConvertPicklistCodeToLabel.InputWrapper testInput = new COMM_SL_ConvertPicklistCodeToLabel.InputWrapper();
        testInput.countryCodeToLabel = false;
        testInput.countryCodeValue = 'Portugal';
        testInput.stateCodeValue = 'Pistoia';

        Boolean errorOccurred = false;
        List<COMM_SL_ConvertPicklistCodeToLabel.OutputWrapper> outputValuesList = new List<COMM_SL_ConvertPicklistCodeToLabel.OutputWrapper>();
        try {
            outputValuesList = COMM_SL_ConvertPicklistCodeToLabel.changePicklistCodeToLabel(new List<COMM_SL_ConvertPicklistCodeToLabel.InputWrapper>{ testInput });
        } catch (Exception e) {
            errorOccurred = true;
        }

        System.assert(!errorOccurred, 'expected no error to occur');
        System.assertEquals(outputValuesList.get(0).outputCountryCodeValue, 'PT', 'expected no error to occur');
        System.assertEquals(outputValuesList.get(0).outputStateCodeValue, 'PT', 'expected no error to occur');
    }
}