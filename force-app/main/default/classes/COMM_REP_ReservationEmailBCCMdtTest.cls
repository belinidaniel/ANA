/**
 * @author Diogo Gonçalves
 * @description COMM_REP_ReservationEmailBCCMdt class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Diogo Gonçalves      09/09/2024    88            Original version
 **/
@isTest
public with sharing class COMM_REP_ReservationEmailBCCMdtTest {
    @isTest
    public static void shouldReturnBccAddresses() {
        COMM_IREP_ReservationEmailBCCMdt bccAddressesRepo = new COMM_REP_ReservationEmailBCCMdt();
        List<String> bccAddresses;
        Test.startTest();
        bccAddresses = bccAddressesRepo.getAllEmails();
        Test.stopTest();
        Assert.isNotNull(bccAddresses, 'bccAddresses should no be null');
        Assert.areEqual(new List<String>{ 'test@ana.pt' }, bccAddresses, 'BCC emails list no as expected');
    }
}