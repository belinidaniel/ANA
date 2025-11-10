/**
 * @author Daniel Lascas
 * @description Service Layer Class used to pass custom attributes (account information)
 * to Commerce on User Login
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer                Date            Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas            02/04/2024		ECOMM-178: Original version
 **/
public without sharing class COMM_SL_ConnectedAppCommerce extends Auth.ConnectedAppPlugin {
    /**
     * @description Method to verify if User is authorized to access using the connected app
     *
     * @param userId Id of the User logging in.
     * @param connectedAppId Id of the Connected App used for integration.
     * @param isAdminApproved Boolean indicating the approval state of the specified user
     * when the connected app requires approval.
     * @param context Context of the invocation.
     * @return Boolean indicating if Admin approved User
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public override Boolean authorize(Id userId, Id connectedAppId, Boolean isAdminApproved, Auth.InvocationContext context) {
        return isAdminApproved;
    }

    /**
     * @description Method to add custom attribute values to response sent to Commerce
     *
     * @param userId Id of the User logging in.
     * @param connectedAppId Id of the Connected App used for integration.
     * @param formulaDefinedAttributesMap Map with the attributes sent to commerce to be updated
     * @param context Context of the invocation.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public override Map<String, String> customAttributes(
        Id userId,
        Id connectedAppId,
        Map<String, String> formulaDefinedAttributesMap,
        Auth.InvocationContext context
    ) {
        return new COMM_DO_CommerceAppMapping().getAccountDataMapWithUserId(userId, formulaDefinedAttributesMap);
    }
}