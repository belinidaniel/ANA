/**
 * @author Jose Passos
 * @description Split String into List to invoke on Flows output
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos      12/04/2024       Original version
 **/
public class COMM_StringToListOutput {
    @AuraEnabled
    @InvocableVariable
    public List<String> stringList;
}