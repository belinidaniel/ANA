/**
 * @author Daniel Lascas
 * @description Contact SObject Domain object class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    04/04/2024       ECOMM-708 - Original version
 **/
public inherited sharing class COMM_DO_Contact implements COMM_IDO_Contact {
    //Picklist Values for Preferred Contact Field
    public final static String PREFERRED_CONTACT_MOBILE = 'Mobile';
    public final static String PREFERRED_CONTACT_EMAIL = 'Email';
    //Picklist Values for Consent Fields
    public final static String CONSENT_YES = 'Yes';
    public final static String CONSENT_NO = 'No';
}