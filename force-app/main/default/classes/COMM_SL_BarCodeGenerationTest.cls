/**
 * @author Diogo Gonçalves
 * @description Barcode Generation Service Test class
 *
 * Modification Log
 * ----------------------------------------------------------------------------------------------
 * Developer        Date          Coverage(%)   Description
 * ----------------------------------------------------------------------------------------------
 * Diogo Gonçalves  17/04/2024    94           ECOMM-105: Original version
 **/
@isTest
private class COMM_SL_BarCodeGenerationTest {
    private static final List<String> FAKE_RESPONSE_DATA = new List<String>{
        '"content": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAA1JREFUGFdj+Gkf9x8ABmEClm+bvsMAAAAASUVORK5CYII="',
        '"fileType": "img/png"'
    };

    @isTest
    static void testGetBarCodeBase64() {
        // Create test data
        String codeText = 'TestCodeText';
        String format = 'QR_CODE';

        // Set up the mock callout environment
        Test.setMock(HttpCalloutMock.class, new HttpResponseSuccessMock('{' + String.join(FAKE_RESPONSE_DATA, ',') + '}'));

        // Call the method being tested
        COMM_SL_BarcodeResponse barCodeResponse = COMM_SL_BarCodeGeneration.getBarCodeBase64(codeText, format);

        // Verify the results
        Assert.areNotEqual(null, barCodeResponse.content, 'The base64 content should not be null.');
        Assert.areNotEqual(null, barCodeResponse.fileType, 'The file type should not be null.');
    }
}