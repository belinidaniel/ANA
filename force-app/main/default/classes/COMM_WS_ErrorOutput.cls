/**
 * @author Jose Passos
 * @description Model for availability error on request.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Jose Passos    11/03/2024       Original version
 **/
@SuppressWarnings('PMD.AvoidGlobalModifier')
public class COMM_WS_ErrorOutput {
    public String errorCode;
    public String message;

    public static List<COMM_WS_ErrorOutput> parse(String json) {
        return (List<COMM_WS_ErrorOutput>) System.JSON.deserialize(json, List<COMM_WS_ErrorOutput>.class);
    }
}