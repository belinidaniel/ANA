/**
 * @author Daniel Lascas
 * @description PermissionSet SObject Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    02/04/2024       ECOMM-700: Original version
 **/
public inherited sharing class COMM_DO_PermissionSet implements COMM_IDO_PermissionSet {
    public static final String PARTNER_ADMIN_PERMISSION_SET = 'COMM_PartnerAdmin';
    public static final String SUPER_PARTNER_ADMIN_PERMISSION_SET = 'COMM_SuperPartnerAdmin';
}