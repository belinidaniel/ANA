/**
 * @description Input class for Test Data Factory operations
 */
@suppressWarnings('PMD.ClassNamingConventionTest, PMD.ExcessivePublicCount')
@isTest
public class COMM_OMS_TestDataInput {
    /**
     * @description Contact input
     */
    public class ContactInput {
        public String lastName;
    }

    /**
     * @description Product input
     */
    public class ProductInput {
        public String name;
        public String productCode;
    }
}