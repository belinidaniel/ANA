/**
 * @author João Silveirinha
 * @description Controller to get the Experience ID.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * João Silveirinha   03/06/2024       Original version
 */
public with sharing class COMM_LCC_Site {
    /**
     * @description Returns the Experience ID of the current community.
     * @return The Experience ID of the current community.
     */
    @AuraEnabled
    public static String getExperienceId() {
        String experienceId = System.Site.getExperienceId();
        return experienceId;
    }
}