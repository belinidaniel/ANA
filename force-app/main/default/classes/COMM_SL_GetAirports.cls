/**
 * @author Carlos Fusco
 * @description Service Layer class to get Airports available for the Account on
 * new Subscriptions request process defined in Flow
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Carlos Fusco   21/03/2024       Original version
 **/
public inherited sharing class COMM_SL_GetAirports {
    /**
     * @description Get airport choices available for Account on new Subscription request
     *
     * @param pickListValues Muti-picklist airport values to handle
     * @return List of choices with the airports to display for selection on Flow
     */
    @InvocableMethod(label='Get Values from Multi-Select Picklist' description='Returns selected values on multi-picklist')
    public static List<List<COMM_SL_FlowChoice>> getValuesFromAirportsMultiPicklist(List<String> pickListValues) {
        List<COMM_SL_FlowChoice> pickListFlowChoices = new List<COMM_SL_FlowChoice>();
        Map<String, String> picklistLabelByValue = COMM_GEN_Utility.getPicklistMap(Schema.Account.COMM_Airport__c, false);

        if (String.isNotBlank(pickListValues.get(0))) {
            List<String> values = pickListValues.get(0).split(';');
            for (String value : values) {
                pickListFlowChoices.add(new COMM_SL_FlowChoice(picklistLabelByValue.get(value), value));
            }
        }

        return new List<List<COMM_SL_FlowChoice>>{ pickListFlowChoices };
    }
}