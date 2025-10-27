global class COMM_ConnectedAppCommerce extends Auth.ConnectedAppPlugin
{
    private static final String ACCOUNT_TYPE_B2C = 'B2C';
    private static final String ACCOUNT_TYPE_B2B = 'B2B';
    
    // Authorize the app if the user has achieved quota tracked in a custom field
    global override Boolean authorize(Id userId, Id connectedAppId, Boolean isAdminApproved, Auth.InvocationContext context) 
    {
        // Create a custom boolean field HasAchievedQuota__c on the user record 
        // and then uncomment the block below 
        // User u = [select id, HasAchievedQuota__c from User where id =: userId].get(0);
        // return u.HasAchievedQuota__c;
        
        return isAdminApproved;
    }
        
    // Call a flow during refresh
    global override void refresh(Id userId, Id connectedAppId, Auth.InvocationContext context)
    {
       try
       {
          Map<String, Object> inputVariables = new Map<String, Object>();
          inputVariables.put('userId', userId);
          inputVariables.put('connectedAppId', connectedAppId);
            
         // Create a custom trigger ready flow and uncomment the block below
         // Flow.Interview.MyCustomFlow interview = new Flow.Interview.MyCustomFlow(inputVariables);
         // interview.start();
        } catch ( Exception e ) {
           System.debug('FLOW Exception:' + e);
        }  
    }
                  
    global override Map<String,String> customAttributes(Id userId, Id connectedAppId,Map<String,String>
        formulaDefinedAttributes, Auth.InvocationContext context)         
    {  
        List<PermissionSetAssignment> psas = [SELECT id, PermissionSet.Name FROM PermissionSetAssignment 
        WHERE PermissionSet.IsOwnedByProfile = false AND (AssigneeId = :userId)];
        String permsets = '[';
        for (PermissionSetAssignment psa :psas)
        {
            permsets += psa.PermissionSet.Name + ';';
        }
        permsets += ']';
        formulaDefinedAttributes.put('PermissionSets', permsets);
        
        User currentUser = [SELECT ContactId, AccountId, Phone, Address FROM User WHERE Id = :userId];

        if (currentUser.AccountId != null) {
            // Check if the account associated with the user is a Person Account
            Boolean isPersonAccount = [SELECT IsPersonAccount FROM Account WHERE Id = :currentUser.AccountId].IsPersonAccount;
        
            if (isPersonAccount) {
                Account personAccount = [SELECT COMM_VATNumber__c,COMM_CompanyVATNumber__c, Phone,BillingAddress,BillingCountryCode, BillingPostalCode, BillingCity, BillingStreet, COMM_IsAffiliate__c, COMM_IndividualStaff__c,COMM_CompanyBillingAddress__c, COMM_CompanyBillingAddress__CountryCode__s,COMM_CompanyBillingAddress__PostalCode__s, COMM_CompanyBillingAddress__City__s, COMM_CompanyBillingAddress__Street__s, COMM_BillingFirstName__c, COMM_BillingLastName__c, COMM_CompanyName__c FROM Account WHERE Id = :currentUser.AccountId LIMIT 1];
                if (personAccount != null) {
                    formulaDefinedAttributes.put('accountId', String.valueOf(currentUser.AccountId));
                    
                    
                    Map<String, Object> companyBillingAddressMap = new Map<String, Object>();
                    companyBillingAddressMap.put('countryCode', personAccount.COMM_CompanyBillingAddress__CountryCode__s);
                    companyBillingAddressMap.put('postalCode', personAccount.COMM_CompanyBillingAddress__PostalCode__s);
                    companyBillingAddressMap.put('city', personAccount.COMM_CompanyBillingAddress__City__s);
                    companyBillingAddressMap.put('street', personAccount.COMM_CompanyBillingAddress__Street__s);
                    companyBillingAddressMap.put('firstName', personAccount.COMM_BillingFirstName__c);
                    companyBillingAddressMap.put('lastName', personAccount.COMM_BillingLastName__c);
                    companyBillingAddressMap.put('companyName', personAccount.COMM_CompanyName__c);
                    companyBillingAddressMap.put('vatNumber', personAccount.COMM_CompanyVATNumber__c);
                    
                    formulaDefinedAttributes.put('companyBillingAddress', JSON.serialize(companyBillingAddressMap));
                    
                    Map<String, Object> billingAddressMap = new Map<String, Object>();
                    billingAddressMap.put('countryCode', personAccount.BillingCountryCode);
                    billingAddressMap.put('postalCode', personAccount.BillingPostalCode);
                    billingAddressMap.put('city', personAccount.BillingCity);
                    billingAddressMap.put('street', personAccount.BillingStreet);
                    billingAddressMap.put('firstName', personAccount.COMM_BillingFirstName__c);
                    billingAddressMap.put('lastName', personAccount.COMM_BillingLastName__c);
                    billingAddressMap.put('vatNumber', personAccount.COMM_VATNumber__c);
                    
                    formulaDefinedAttributes.put('billingAddress', JSON.serialize(billingAddressMap));
                    
                    //formulaDefinedAttributes.put('companyBillingAddress', JSON.serialize(personAccount.COMM_CompanyBillingAddress__c));
                    //formulaDefinedAttributes.put('billingAddress', JSON.serialize(personAccount.BillingAddress));
                    
                    
                    formulaDefinedAttributes.put('customerType', ACCOUNT_TYPE_B2C);
                    formulaDefinedAttributes.put('isAffiliated', String.valueOf(personAccount.COMM_IsAffiliate__c)); 
                    formulaDefinedAttributes.put('isIndividualStaff', String.valueOf(personAccount.COMM_IndividualStaff__c)); 
                    formulaDefinedAttributes.put('phone', String.valueOf(personAccount.Phone));
                }
            } else {
                Account regularAccount = [SELECT Phone, COMM_IsAffiliate__c, COMM_IndividualStaff__c, BillingAddress FROM Account WHERE Id = :currentUser.AccountId LIMIT 1];
                if (regularAccount != null) {
                    formulaDefinedAttributes.put('accountId', String.valueOf(currentUser.AccountId));
                    //formulaDefinedAttributes.put('customAddress', String.valueOf(currentUser.Address));
                    formulaDefinedAttributes.put('billingAddress', JSON.serialize(regularAccount.BillingAddress));
                    formulaDefinedAttributes.put('customerType', ACCOUNT_TYPE_B2B);
                    formulaDefinedAttributes.put('isAffiliated', String.valueOf(regularAccount.COMM_IsAffiliate__c));
                    formulaDefinedAttributes.put('isIndividualStaff', String.valueOf(regularAccount.COMM_IndividualStaff__c));
                    formulaDefinedAttributes.put('phone', String.valueOf(regularAccount.Phone));
                }
            }
        }

		return formulaDefinedAttributes;
    
		}
	}