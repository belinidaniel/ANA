/**
 * @author Diogo Gonçalves
 * @description Model for OCAPI Gift Certificate object.
 * Suppress Reason: OCAPI response does not follow the same naming convention of PMD.
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date             Description
 * -----------------------------------------------------------------------------------
 * Diogo Gonçalves      19/04/2024       Original version
 * Diogo Gonçalves      17/09/2024       ECOMM-481: Changed the API endpoint
 **/
@SuppressWarnings('PMD.FieldNamingConventions')
public class COMM_SL_GiftCertificateWrapper {
    public List<GiftCertificate> giftCertificates;
    public List<GiftCertificate> created;

    public COMM_SL_GiftCertificateWrapper() {
        this.giftCertificates = new List<GiftCertificate>();
    }

    /**
     * @descrition Add GiftCertificate object to the list giftCertificates.
     * @param giftCertificate
     */
    public void addGiftCertificate(GiftCertificate giftCertificate) {
        this.giftCertificates.add(giftCertificate);
    }

    public class GiftCertificate {
        public String code;
        public Double amount;
        public String recipientEmail;
        public String recipientName;
        public String senderName;
        public String orderNumber;
        public Boolean sendEmail;
        public String description;
    }
}