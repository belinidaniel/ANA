/**
 * @author           Daniel Reto
 * @description      Service Layer Class with method to convert Address picklist Code to Label and the opposite as well
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Reto      22/04/2024       Original version
 **/
public without sharing class COMM_SL_ConvertPicklistCodeToLabel {

    /**
     * @description Method to convert Address Codes to Label and Label to Codes based on a Boolean field "countryCodeToLabel".
     *
     * @param inputList List of InputWrapper which contain the Address picklist Code or Label to convert and a Boolean value to identify which convertion to execute
     * @return List of OutputWrapper which contain the Address picklist Code or Label converted
     **/
    @InvocableMethod(
        label='Change picklist Code <=> Label'
        description='Action to change picklist code value to respective label + change picklist label value to respective code.'
    )
    public static List<OutputWrapper> changePicklistCodeToLabel(List<InputWrapper> inputList) {
        String countryCodeValue = inputList[0]?.countryCodeValue;
        String stateCodeValue = inputList[0]?.stateCodeValue;
        Boolean countryCodeToLabel = inputList[0].countryCodeToLabel;
        String outputCountryCodeValue;
        String outputStateCodeValue;

        List<OutputWrapper> outputValuesList = new List<OutputWrapper>();

        Schema.DescribeFieldResult countryCodeResult = User.CountryCode.getDescribe();
        List<Schema.PicklistEntry> pleCountryCodeList = countryCodeResult.getPicklistValues();
        for( Schema.PicklistEntry pleCountryCode : pleCountryCodeList){
            if(countryCodeToLabel){
                if(pleCountryCode.getValue() == countryCodeValue){
                    outputCountryCodeValue = pleCountryCode.getLabel();
                }
            } else {
                if(pleCountryCode.getLabel() == countryCodeValue){
                    outputCountryCodeValue = pleCountryCode.getValue();
                }
            }
        }

        Schema.DescribeFieldResult stateCodeResult = User.StateCode.getDescribe();
        List<Schema.PicklistEntry> pleStateCodeList = stateCodeResult.getPicklistValues();
        for( Schema.PicklistEntry pleStateCode : pleStateCodeList){
            if(countryCodeToLabel){
                if(pleStateCode.getValue() == stateCodeValue){
                    outputStateCodeValue = pleStateCode.getLabel();
                }
            } else {
                if(pleStateCode.getLabel() == stateCodeValue){
                    outputStateCodeValue = pleStateCode.getValue();
                }
            }
        }

        outputValuesList.add(new OutputWrapper(
            outputCountryCodeValue,
            outputStateCodeValue
        ));

        return outputValuesList;
    }

    public class InputWrapper {
        @InvocableVariable(label='Country Code/Label Value' description='Country Code current value' required=false)
        public String countryCodeValue;
        @InvocableVariable(label='State Code/Label Value' description='State Code current value' required=false)
        public String stateCodeValue;
        @InvocableVariable(label='Code to Label' description='Change value of Code to Label?' required=true)
        public Boolean countryCodeToLabel;
    }
    public class OutputWrapper {
        @InvocableVariable(label='Country Code/Label Value' description='Country Code current value' required=false)
        public String outputCountryCodeValue;
        @InvocableVariable(label='State Code/Label Value' description='State Code current value' required=false)
        public String outputStateCodeValue;
        public OutputWrapper(String outputCountryCodeValue, String outputStateCodeValue){
            this.outputCountryCodeValue = outputCountryCodeValue;
            this.outputStateCodeValue = outputStateCodeValue;
        }
    }
}