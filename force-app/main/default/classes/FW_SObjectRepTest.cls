/**
 * @author Miguel Freire
 * @description FW_SObjectRep test class
 *
 * Modification Log
 * ------------------------------------------------------------------------------------
 * Developer        Date            Coverage(%)    Description
 * -----------------------------------------------------------------------------------
 * Miguel Freire   21/05/2024          100         Original version
 **/
@isTest
public class FW_SObjectRepTest {
    @isTest
    static void insertSObjectsallOrNonefalseTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        List<Database.SaveResult> insertilist;
        Test.startTest();
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();
            insertilist = sobjectRepObject.insertSObjects(
                new List<Batch_Definition__c>{
                    new Batch_Definition__c(Batch_Name__c = 'test1', Class_Name__c = 'test1', SObject_API_Name__c = 'FW_SObjectRep'),
                    new Batch_Definition__c(Batch_Name__c = 'test2', Class_Name__c = 'test2', SObject_API_Name__c = 'FW_SObjectRep')
                }
            );
        }

        Test.stopTest();
        System.assertEquals(true, insertilist.size() > 0, 'Expected result: True');
    }

    @isTest
    static void insertSObjectsallOrNonetrueTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];

        Test.startTest();
        List<Database.SaveResult> srList;
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();
            srList = sobjectRepObject.insertSObjects(new List<Error_Log__c>{ new Error_Log__c(), new Error_Log__c() });
        }
        Test.stopTest();
        System.assertEquals(true, srList.size() > 0, 'Expected result: True');
    }

    @isTest
    static void updateSObjectsallOrNonefalseTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        List<Database.SaveResult> insertilist;
        Test.startTest();
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();

            Batch_Definition__c newBD = new Batch_Definition__c(
                Batch_Name__c = 'test1',
                Class_Name__c = 'test1',
                SObject_API_Name__c = 'FW_SObjectRep'
            );
            insert newBD;

            insertilist = sobjectRepObject.updateSObjects(new List<Batch_Definition__c>{ newBD });
        }
        Test.stopTest();
        System.assertEquals(true, insertilist.size() > 0, 'Expected result: True');
    }

    @isTest
    static void updateSObjectsallOrNonetrueTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        List<Error_Log__c> errorlist = [SELECT id FROM Error_Log__c LIMIT 1];
        List<Database.SaveResult> srList = new List<Database.SaveResult>();
        Test.startTest();
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();
            srList = sobjectRepObject.updateSObjects(errorlist);
        }
        Test.stopTest();
        System.assertNotEquals(1, srList.size(), 'Expected result: 1');
    }

    @isTest
    static void upsertSObjectsallOrNonefalseTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        List<Database.UpsertResult> insertilist;
        Test.startTest();
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();
            insertilist = sobjectRepObject.upsertSObjects(
                new List<Batch_Definition__c>{
                    new Batch_Definition__c(Batch_Name__c = 'test1', Class_Name__c = 'test1', SObject_API_Name__c = 'FW_SObjectRep'),
                    new Batch_Definition__c(Batch_Name__c = 'test2', Class_Name__c = 'test2', SObject_API_Name__c = 'FW_SObjectRep')
                }
            );
        }
        Test.stopTest();
        System.assertEquals(true, insertilist.size() > 0, 'Expected result: True');
    }

    @isTest
    static void upsertSObjectsallOrNonetrueTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        List<Error_Log__c> errorlist = [SELECT id FROM Error_Log__c LIMIT 1];
        List<Database.UpsertResult> srList = new List<Database.UpsertResult>();

        Test.startTest();
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();
            srList = sobjectRepObject.upsertSObjects(errorlist);
        }
        Test.stopTest();
        System.assertNotEquals(1, srList.size(), 'Expected result: 1');
    }

    @isTest
    static void upsertSObjectsByExternalIdTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        List<Database.UpsertResult> srList = new List<Database.UpsertResult>();
        Test.startTest();
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();
            srList = sobjectRepObject.upsertSObjects(FW_TestDataFactory.createBatchDefinition(1, false), Batch_Definition__c.Batch_Name__c);
        }
        Test.stopTest();
        System.assertEquals(1, srList.size(), 'Expected result: 1');
    }

    @isTest
    static void deleteSObjectsallOrNonefalseTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        List<Database.DeleteResult> insertilist;
        List<Error_Log__c> errorList = [SELECT id FROM Error_Log__c LIMIT 10000];
        Test.startTest();
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();
            insertilist = sobjectRepObject.deleteSObjects(errorList);

            FW_SObjectRep sobjectRepObject1 = new FW_SObjectRep();
            sobjectRepObject1.deleteSObjects(errorList);
        }
        Test.stopTest();
        System.assertEquals(false, insertilist.size() > 0, 'Expected result: False');
    }

    @isTest
    static void deleteSObjectsallOrNonetrueTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        List<Error_Log__c> errorList = [SELECT id FROM Error_Log__c LIMIT 10000];
        Test.startTest();
        List<Database.DeleteResult> srList;
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();
            srList = sobjectRepObject.deleteSObjects(errorList);
        }
        Test.stopTest();
        System.assertEquals(false, srList.size() > 0, 'Expected result: False');
    }

    //Test Methods for added Insert/Update with DMLOptions
    @isTest
    static void insertSObjectsdmlOptallOrNonefalseTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        List<Database.SaveResult> insertilist;
        Test.startTest();
        Database.DMLOptions dmlOptn = new Database.DMLOptions();
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();
            insertilist = sobjectRepObject.insertSObjects(
                new List<Batch_Definition__c>{
                    new Batch_Definition__c(Batch_Name__c = 'test1', Class_Name__c = 'test1', SObject_API_Name__c = 'FW_SObjectRep'),
                    new Batch_Definition__c(Batch_Name__c = 'test2', Class_Name__c = 'test2', SObject_API_Name__c = 'FW_SObjectRep')
                },
                dmlOptn
            );
        }

        Test.stopTest();
        System.assertEquals(true, insertilist.size() > 0, 'Expected result: True');
    }

    @isTest
    static void insertSObjectsdmlOptallOrNonetrueTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];

        Test.startTest();
        List<Database.SaveResult> srList;
        Database.DMLOptions dmlOptn = new Database.DMLOptions();
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();
            srList = sobjectRepObject.insertSObjects(new List<Error_Log__c>{ new Error_Log__c(), new Error_Log__c() }, dmlOptn);
        }
        Test.stopTest();
        System.assertEquals(true, srList.size() > 0, 'Expected result: True');
    }

    @isTest
    static void updateSObjectsdmlOptallOrNonefalseTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        List<Database.SaveResult> insertilist;
        Test.startTest();
        Database.DMLOptions dmlOptn = new Database.DMLOptions();
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();

            Batch_Definition__c newBD = new Batch_Definition__c(
                Batch_Name__c = 'test1',
                Class_Name__c = 'test1',
                SObject_API_Name__c = 'FW_SObjectRep'
            );
            insert newBD;

            insertilist = sobjectRepObject.updateSObjects(new List<Batch_Definition__c>{ newBD }, dmlOptn);
        }
        Test.stopTest();
        System.assertEquals(true, insertilist.size() > 0, 'Expected result: True');
    }

    @isTest
    static void updateSObjectsdmlOptallOrNonetrueTest() {
        User u = [SELECT id FROM User WHERE Profile.name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        List<Error_Log__c> errorlist = [SELECT id FROM Error_Log__c LIMIT 1];
        List<Database.SaveResult> srList = new List<Database.SaveResult>();
        Test.startTest();
        Database.DMLOptions dmlOptn = new Database.DMLOptions();
        System.runAs(u) {
            FW_SObjectRep sobjectRepObject = new FW_SObjectRep();
            srList = sobjectRepObject.updateSObjects(errorlist, dmlOptn);
        }
        Test.stopTest();
        System.assertNotEquals(1, srList.size(), 'Expected result: 1');
    }
}