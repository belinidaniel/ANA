/**
 * @author           Daniel Lascas
 * @description      COMM_DO_PortalValidationSetting test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Daniel Lascas    21/03/2024      100            Original version
 * Miguel Freire    23/03/2024      100             Added getPortalSettingByEnvironmentIdTest and getPortalSettingByEnvironmentIdFailureTest
 **/
@isTest
private class COMM_DO_PortalValidationSettingTest {
    @isTest
    static void getPortalSettingTest() {
        //Retrieve setting using Community Name and Process Name
        COMM_PortalValidationSetting__mdt expectedSetting = COMM_PortalValidationSetting__mdt.getAll().values()[0];

        Test.startTest();
        COMM_PortalValidationSetting__mdt actualSetting = COMM_DO_PortalValidationSetting.getPortalSetting(
            expectedSetting.COMM_Community__c,
            expectedSetting.COMM_Process__c
        );
        Test.stopTest();

        Assert.areEqual(expectedSetting, actualSetting, 'setting does not match expected');
    }

    @isTest
    static void getPortalSettingFailureTest() {
        //Retrieve setting using Community Name and Process Name for a Setting that doesn't exist

        Test.startTest();
        COMM_PortalValidationSetting__mdt actualSetting = COMM_DO_PortalValidationSetting.getPortalSetting('null_community', 'null_process');
        Test.stopTest();

        Assert.isNull(actualSetting, 'expected a null setting');
    }

    @isTest
    static void getPortalSettingByEnvironmentIdTest() {
        //Retrieve setting using EnvironmentId
        String expectedId = UserInfo.getOrganizationId();
        Test.startTest();
        COMM_PortalValidationSetting__mdt actualSetting = COMM_DO_PortalValidationSetting.getPortalSettingByEnvironmentId(expectedId);
        Test.stopTest();

        Assert.areEqual(expectedId, actualSetting.COMM_EnvironmentId__c, 'setting does not match expected');
    }

    @isTest
    static void getPortalSettingByEnvironmentIdFailureTest() {
        //Retrieve setting using EnvironmentId for a Setting that doesn't exist

        Test.startTest();
        COMM_PortalValidationSetting__mdt actualSetting = COMM_DO_PortalValidationSetting.getPortalSettingByEnvironmentId('null_environmentId');
        Test.stopTest();

        Assert.isNull(actualSetting, 'expected a null setting');
    }
}