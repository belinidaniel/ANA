/**
 * @author Jose Passos
 * @description Split String into List to invoke on Flows
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      12/04/2024       Original version
 **/
public class COMM_StringToListConverter {
    /**
     * @description This method receives a list of aggregated strings and a separator and returns a List of strings split by a specified separator
     * @param List<COMM_StringToListInput> inputList of concatenated strings to be split and the separator character to split
     * @return List<COMM_StringToListOutput> List of strings separated
     */
    @InvocableMethod(
        category='Utility'
        label='Convert Comma Separated String to List'
        description='Converts a comma separated string into a List<String>'
    )
    public static List<COMM_StringToListOutput> convertStringToList(List<COMM_StringToListInput> inputList) {
        List<COMM_StringToListOutput> outputList = new List<COMM_StringToListOutput>();
        COMM_StringToListOutput output;
        for (COMM_StringToListInput input : inputList) {
            output = new COMM_StringToListOutput();
            if (input.stringToSplit != '' && input.separator != '') {
                output.stringList = new List<String>();
                output.stringList.addAll(input.stringToSplit.split(input.separator));
            }
            outputList.add(output);
        }
        return outputList;
    }
}