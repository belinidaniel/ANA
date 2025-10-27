/**
 * @author Daniel Lascas
 * @description Trigger handler for the COMM_CustomerUpdateRequest__e
 * Platform Event Object
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    16/09/2024	    Original version
 **/
public class COMM_TH_CustomerUpdateRequest extends FW_TriggerHandler {
    private List<COMM_CustomerUpdateRequest__e> newList;

    /**
     * @description Class Constructor to obtain Records from Trigger
     */
    public COMM_TH_CustomerUpdateRequest() {
        this.newList = (List<COMM_CustomerUpdateRequest__e>) Trigger.New;
    }

    protected override void executeAfterInsert() {
        //Execute Logic to start customer update calls
        new COMM_TW_CustomerUpdateRequest_CallUpdate().execute(newList);
    }
}