/**
 * @author Jose Passos
 * @description Split String into List to invoke on Flows input
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      12/04/2024       Original version
 **/
public class COMM_StringToListInput {
    @AuraEnabled
    @InvocableVariable
    public String stringToSplit;
    @AuraEnabled
    @InvocableVariable
    public String separator;
}