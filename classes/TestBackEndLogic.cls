/**
Purpose:
This test class validates the custom update logic that is a part of the application
This entails the workings of the Bid Object, and it's impact on the Item and Donation objects
All these tests have been written as Bulk tests with the use Cases calling the bulk Data Creation methods of the TestDataGenerator
Although, as Salesforce Governor Limits restrict the number of records that can be part of a DML statemet, the volumes used here are
less than those specified in the Assignment Document.
However, manual testing has been done in the Org with the data volumes mentioned in the Assignment Document
*/
@isTest
public class TestBackEndLogic{
    
    /**
    Only Bids with Amount > Item's Minimum Bid are acceptable 
    */
    public static testmethod void validBidBulkTest(){
        
        //Create Donations, Bids and Items
        List<Contact> donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItemsBulk(2000, TRUE);
        insert items;
        List<Bid__c> bids = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bids));
        
        //Insert bids
        Test.startTest();
        insert bids;
        Test.stopTest();
        
        //Validate that all Bids were inserted successfully
        system.assert([SELECT COUNT() FROM Bid__c] == bids.size());
        
        
    }
    
    /**
    Bids with Amount < Item's Minimum Bid are not acceptable
    */
    public static testmethod void invalidBidBulkTest(){
        
        //Crete Donations, Bids and Items
        List<Contact> donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItemsBulk(2000, TRUE);
        insert items;
        List<Bid__c> bids = TestDataGenerator.CreateBidsBulk(donations, items, FALSE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bids));
        
        //insert bids
        try{
            Test.startTest();
            insert bids;
            Test.stopTest();
        }
        //No bids are inserted, as their Amount < Item's Minimum Bid
        catch(System.DmlException ex){
            system.assert(ex.getNumDml() == bids.size());
            system.assert(ex.getMessage().contains(System.Label.MinimumBidError));
        } 
        
    }

    /**
    Total Amount of All bids is updated on the Related Donation
    */
    public static testmethod void donationTotalBulkTest(){
        
        //Create donations, bids and items
        List<Contact> donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItemsBulk(2000, TRUE);
        insert items;
        List<Bid__c> bids = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bids));
        
        //Insert bids
        Test.startTest();
        insert bids;
        Test.stopTest();
        
        //Get Donation Total Map from Bids
        Map<Id, Decimal> donationTotalFromBids = TestDataGenerator.CalculateDonationTotalMapFromBids(bids);
        
        //Query Donation to get Donation Total Map
        Map<Id, Decimal> donationTotalFromDonations = TestDataGenerator.CalculateDonationTotalMapFromDonations([SELECT Id, Total_Donation__c FROM Donation__c]);
        
        Boolean totalMismatch = FALSE;

        //Verify that both Maps are the same
        
        system.assert(TestDataGenerator.CompareMaps(donationTotalFromBids, donationTotalFromDonations ));
        
    }
    
    /**
    Highest Bid is updated on the Item - Bids for Same item in separate Lists
    */
    public static testmethod void itemHighestBidNonCompeteBulkTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        //Create a set of items
        List<Item__c> items = TestDataGenerator.CreateItemsBulk(2000, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids - for the same set of items
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        //Insert both bid Lists
        Test.startTest();
        insert bidList1;
        insert bidList2;
        Test.stopTest();
        
        //Those Bids that were inserted in the second Donation had a higher amount
        //and hence their Amount should reflect on the Item

        //Query All items
        items = new List<Item__c>();
        items = [SELECT Highest_Bid__c FROM Item__c];
        
        system.debug('items: ' + items);
        
        Integer itemCounter = 0;
        //Validate that the Items' Highest Bids match those of the second Bid List
        for(Item__c item : items){
            system.assert(item.Highest_Bid__c == bidList2.get(itemCounter).Amount__c);
            itemCounter++;
        }
        
    }

    /**
    Highest Bid is updated on the Item - Competing Bids for Same Item in a single List
    */
    public static testmethod void itemHighestBidCompeteBulkTest(){
        
        //Create Test Data
        List<Contact> donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItemsBulk(2000, TRUE);
        insert items;
        List<Bid__c> bidList = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        Integer firstBidListSize = bidList.size();

        //Create a second set of Donations and Bids - for the same set of Items
        List<Contact> competingDonor = TestDataGenerator.CreateDonorsBulk();
        insert competingDonor;
        List<Donation__c> competingDonation = TestDataGenerator.CreateDonations(competingDonor, FALSE);
        insert competingDonation;
        
        //These bids will have the same amounts as the Item's Current Highest Bid
        List<Bid__c> compBidList = TestDataGenerator.CreateCompetingBidsBulk(competingDonation, items);
        

        //Add all Bids to a single list
        bidList.addAll(compBidList);
        
        //system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList));
        
        //The Bids added in the compBidList had the same Bid Amounts as the bids in the bidList - hence, they will fail
        try{
            Test.startTest();
            insert bidList;
            Test.stopTest();
        }
        catch(System.DmlException ex){
            system.debug('num errors: ' + ex.getNumDml());
            system.debug('ex.getMessage(): ' + ex.getMessage());

            System.assert(ex.getNumDml() == compBidList.size());
            
            for (Integer i = 0; i < compBidList.size(); i++) {
                System.assert(ex.getDmlIndex(i) == firstBidListSize + i);
            }
            
            System.assert(ex.getMessage().contains(System.Label.HighestBidError));
        }
        
    }

    /**
    Highest Bid is updated on the Item - Competing Bids for Same Item in a single List
    */
    public static testmethod void bidAmountChangeEffectOnItemBulkTest(){
        
        List<Contact> donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItemsBulk(2000, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        //system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        //system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        Test.startTest();
        insert bidList1;
        insert bidList2;
        
        //Change the Bids in the Second Donation to 0 -
        //this should make the Item's highest bid equal to the Bids of the First Donation
        for(Bid__c bid : bidList2){
            bid.Amount__c = 0.00;
        }
        
        Test.stopTest();
        
        update bidList2;
        
        Integer itemCounter = 0;
        
        //Query items
        Map<Id, Item__c> itemMap = new Map<Id, Item__c>(items);
        items = new List<Item__c>();
        items = [SELECT Id, Highest_Bid__c FROM Item__c WHERE Id IN: itemMap.keySet()];
        
        for(Item__c item : items){
            system.assert(item.Highest_Bid__c == bidList1.get(itemCounter).Amount__c);
            itemCounter++;
        }
        
    }
    
    /**
    When the bid Amount changes - the Total donation value is updated correctly on the related Donation
    */
    public static testmethod void bidAmountChangeEffectOnDonationBulkTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItemsBulk(2000, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        //system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        //system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        //insert bids
        Test.startTest();
        insert bidList1;
        insert bidList2;
        
        //Combine the 2 bid lists
        bidList2.addAll(bidList1);

        //Create a Map of Donation Id > Total Donation from the Bids
        Map<Id, Decimal> donationTotalMapFromBids = TestDataGenerator.CalculateDonationTotalMapFromBids(bidList2);

        //Create a Map of Donation Id > Total Donation from the Donations
        Map<Id, Decimal> donationTotalMapFromDonations = TestDataGenerator.CalculateDonationTotalMapFromDonations([SELECT Id, Total_Donation__c FROM Donation__c]);
        
        //Verify that the Totals were updated correctly
        system.assert(TestDataGenerator.CompareMaps(donationTotalMapFromBids, donationTotalMapFromDonations));
        
        //Change the bid Amount values for all bids
        for(Bid__c bid : bidList2){
            bid.Amount__c = bid.Amount__c + 1000;
        }
        
        Test.stopTest();

        //Update Bids
        update bidList2;
        
        //Create a fresh Map of Donation Id > Total Donation from Bids
        donationTotalMapFromBids = TestDataGenerator.CalculateDonationTotalMapFromBids(bidList2);
        
        //Create a fresh Map of Donation Id > Total Donation from Donations
        donationTotalMapFromDonations = TestDataGenerator.CalculateDonationTotalMapFromDonations([SELECT Id, Total_Donation__c FROM Donation__c]);

        //Verify that the Totals were updated correctly
        system.assert(TestDataGenerator.CompareMaps(donationTotalMapFromBids, donationTotalMapFromDonations));
        
    }

    /**
    When the Donation Lookup changes - both the old and the New Donations are processed
    */
    public static testmethod void bidDonationLookupChangeBulkTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItemsBulk(2000, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        //system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        //system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        //Insert bids
        Test.startTest();
        insert bidList1;
        insert bidList2;
        
        //Combine the two Lists

        bidList2.addAll(bidList1);

        //Create a Map of Donation Id > Total Donation From Bids
        Map<Id, Decimal> donationTotalMapFromBids = TestDataGenerator.CalculateDonationTotalMapFromBids(bidList2);
        
        //Create a Map of Donation Id > Total Donation From Donations
        Map<Id, Decimal> donationTotalMapFromDonations = TestDataGenerator.CalculateDonationTotalMapFromDonations([SELECT Id, Total_Donation__c FROM Donation__c]);
        //Query Updated Donations
        List<Donation__c> updatedDonationList = [SELECT Id, Total_Donation__c FROM Donation__c];
       
        //Validate that Totals updated correctly
        system.assert(TestDataGenerator.CompareMaps(donationTotalMapFromBids, donationTotalMapFromDonations));
        
        Id randomDonationId;
        //system.debug('updatedDonationList: ' + updatedDonationList);
        
        //Change the bid Donation lookups
        for(Bid__c bid : bidList2){
            Id currentBidDonationId = bid.Donation__c;
            do{
                randomDonationId = updatedDonationList.get(Integer.valueOf(Math.random()*updatedDonationList.size())).Id;
            }while(randomDonationId == currentBidDonationId); 
            bid.Donation__c = randomDonationId;
        }
        
        //system.debug('inserted bids after random: ' + insertedBids);
        
        Test.stopTest();

        //Update bids
        update bidList2;
        
        //Create a fresh Map of Donation Id > Total Donation from Bids
        donationTotalMapFromBids = new Map<Id, Decimal>();
    
        //Set Default Total Donation = 0 for all Donations
        for(Donation__c donation : updatedDonationList){
            donationTotalMapFromBids.put(donation.Id, 0);
        }
        
        donationTotalMapFromBids.putAll(TestDataGenerator.CalculateDonationTotalMapFromBids(bidList2));
        
        //Create a fresh Map of Donation Id > Total Donation from Donations
        donationTotalMapFromDonations = new Map<Id, Decimal>();

        donationTotalMapFromDonations =  TestDataGenerator.CalculateDonationTotalMapFromDonations([SELECT Id, Total_Donation__c FROM Donation__c]);
        //Validate that the Totals updated correctly on All donations
        system.assert(TestDataGenerator.CompareMaps(donationTotalMapFromDonations, donationTotalMapFromBids));
        
    }

    /**
    When the Item Lookup changes - both the old and the New Items are processed
    */
    public static testmethod void bidItemLookupChangeBulkTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItemsBulk(2000, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        //system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        //system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        //insert bids
        Test.startTest();
        insert bidList1;
        insert bidList2;
        
        //Combine the 2 Lists

        bidList2.addAll(bidList1);

        List<Item__c> updatedItemList = [SELECT Id, Highest_Bid__c FROM Item__c];
        
        //Create a Map of Item Id > Highest Bid from Bids
        Map<Id, Decimal> itemIdHighestBidMapFromBids = new Map<Id, Decimal>();

        itemIdHighestBidMapFromBids = TestDataGenerator.CalculateItemHighestBidMapFromBids(bidList2);

        //Create a Map of Item Id > Highest Bid from Items
        Map<Id, Decimal> itemIdHighestBidMapFromItems = TestDataGenerator.CalculateItemHighestBidMapFromItems([SELECT Id, Highest_Bid__c FROM Item__c]);
        
        //Verify that the Highest Amount updated correctly
        system.assert(TestDataGenerator.CompareMaps(itemIdHighestBidMapFromBids, itemIdHighestBidMapFromItems));

        //system.debug('inserted bids before random: ' + bidList2);
        
        Id randomItemId;
        system.debug('updatedItemList: ' + updatedItemList);
        
        //Change the bid Item lookups on all Bids
        for(Bid__c bid : bidList2){
            Id currentBidItemId = bid.Item__c;
            do{
                randomItemId = updatedItemList.get(Integer.valueOf(Math.random()*updatedItemList.size())).Id;
            }while(randomItemId == currentBidItemId); 
            bid.Item__c = randomItemId;
        }
        
        //system.debug('inserted bids after random: ' + bidList2);
        
        Test.stopTest();
        
        //Update bids
        update bidList2;
        
        //Create a fresh Map of Item Id > Highest Bid from Bids
        itemIdHighestBidMapFromBids = new Map<Id, Decimal>();

        //Set Default Highest Bid = NULL for all Items
        for(Item__c item: updatedItemList){
            itemIdHighestBidMapFromBids.put(item.Id, NULL);
        }

        itemIdHighestBidMapFromBids.putAll(TestDataGenerator.CalculateItemHighestBidMapFromBids(bidList2));
        
        //Create a fresh Map of Item Id > Highest Bid from Items

        itemIdHighestBidMapFromItems = new Map<Id, Decimal>();

        itemIdHighestBidMapFromItems = TestDataGenerator.CalculateItemHighestBidMapFromItems([SELECT Id, Highest_Bid__c FROM Item__c]);

        //Verify that the Highest Bid updated on all Items correctly
        TestDataGenerator.CompareMaps(itemIdHighestBidMapFromItems, itemIdHighestBidMapFromBids);
    }

    /**
    The Item updates in response to Deletion and Undeletion of bids
    */
    public static testmethod void bidDeleteUndeleteEffectOnItemBulkTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItemsBulk(2000, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        //system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //insert bids
        Test.startTest();
        insert bidList1;
        
        //Create a Map of Item Id > Highest Bid from Bids
        Map<Id, Decimal> itemIdHighestBidMapFromBids = new Map<Id, Decimal>();

        itemIdHighestBidMapFromBids = TestDataGenerator.CalculateItemHighestBidMapFromBids(bidList1);
        
        //Create a Map of Item Id > Highest Bid from Items
        List<Item__c> updatedItemList = [SELECT Id, Highest_Bid__c FROM Item__c];
        
        Map<Id, Decimal> itemIdHighestBidMapFromItems = TestDataGenerator.CalculateItemHighestBidMapFromItems([SELECT Id, Highest_Bid__c FROM Item__c]);
        //Verify that the Highest Bid updated correctly
        system.assert(TestDataGenerator.CompareMaps(itemIdHighestBidMapFromBids, itemIdHighestBidMapFromItems));
        
        //Query all bids and delete them
        List<Bid__c> bidsToDelete = [SELECT Id FROM Bid__c];
        //system.debug('bidsToDelete: ' + bidsToDelete);
        
        Test.stopTest();
        
        //Delete bids
        delete bidsToDelete;
        
        //Query items
        items = [SELECT Highest_Bid__c FROM Item__c];
        
        //The Highest Bid on All items has been updated to NULL as a result of the deletion
        for(Item__c item : items){
            system.assert(item.Highest_Bid__c == NULL);
        }
        
        //Restore bids
        List<Bid__c> restoredBids = [SELECT Id FROM Bid__c Where IsDeleted = TRUE ALL ROWS];
        undelete restoredBids;
        
        //Create a fresh Map of Item Id > Highest Bid from Items
        itemIdHighestBidMapFromItems = TestDataGenerator.CalculateItemHighestBidMapFromItems([SELECT Id, Highest_Bid__c FROM Item__c]);
        
        //The Original Highest Bid values have been updated on the Items
        system.assert(TestDataGenerator.CompareMaps(itemIdHighestBidMapFromBids, itemIdHighestBidMapFromItems));
        
    }
    
    /**
    The Donation updates in response to Deletion and Undeletion of bids
    */

    public static testmethod void bidDeleteUndeleteEffectOnDonationBulkTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonorsBulk();
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItemsBulk(2000, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBidsBulk(donations, items, TRUE);
        
        //system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        Test.startTest();
        insert bidList1;
      
        //Create a Map of Donation Id > Total Donation from Bids
        Map<Id, Decimal> donationIdTotalMapFromBids = new Map<Id, Decimal>();
        
        donationIdTotalMapFromBids = TestDataGenerator.CalculateDonationTotalMapFromBids(bidList1);
        
        //Create a Map of Donation Id > Total Donation from Donations
        Map<Id, Decimal> donationIdTotalMapFromDonations = TestDataGenerator.CalculateDonationTotalMapFromDonations([SELECT Id, Total_Donation__c FROM Donation__c]);
        //Verify that the Total Donation updated correctly
        system.assert(TestDataGenerator.CompareMaps(donationIdTotalMapFromBids, donationIdTotalMapFromDonations));
        
        //Query all bids and delete them
        List<Bid__c> bidsToDelete = [SELECT Id, Amount__c, Donation__c FROM Bid__c];
        //system.debug('bidsToDelete: ' + bidsToDelete);
        
        Test.stopTest();
        
        //Delete bids
        delete bidsToDelete;
        
        //Requery donations
        donations = [SELECT Total_Donation__c FROM Donation__c];
        
        //The Total Donation amounts have been cleared as a result of the deletion
        for(Donation__c donation : donations){
            system.assert(donation.Total_Donation__c == 0);
        }
        
        //Restore bids
        List<Bid__c> restoredBids = [SELECT Id FROM Bid__c Where IsDeleted = TRUE ALL ROWS];
        undelete restoredBids;
        
        //Create a fresh Map of Donation Id > Total Donation from Donations
        donationIdTotalMapFromDonations = TestDataGenerator.CalculateDonationTotalMapFromDonations([SELECT Id, Total_Donation__c FROM Donation__c]);
        
        //The Total Donation amounts have been restored
        TestDataGenerator.CompareMaps(donationIdTotalMapFromBids, donationIdTotalMapFromDonations);
        
    }
}