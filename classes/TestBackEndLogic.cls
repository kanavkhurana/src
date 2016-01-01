/**
Purpose:
This test class validates the custom update logic that is a part of the application
This entails the workings of the Bid Object, and it's impact on the Item and Donation objects
*/
@isTest
public class TestBackEndLogic{
    
    /**
    Only Bids with Amount > Item's Minimum Bid are acceptable 
    */
    public static testmethod void validBidTest(){
        
        //Create Donations, Bids and Items
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
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
    public static testmethod void invalidBidTest(){
        
        //Crete Donations, Bids and Items
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 4, FALSE);
        
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
    public static testmethod void donationTotalTest(){
        
        //Create donations, bids and items
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bids));
        
        //Insert bids
        Test.startTest();
        insert bids;
        Test.stopTest();
        
        //Query Bids to get total
        Decimal bidTotal = (Decimal)[SELECT SUM(Amount__c) bidTotal FROM Bid__c].get(0).get('bidTotal');
        //Query Donation to get total
        Decimal donationTotal = [SELECT Total_Donation__c FROM Donation__c WHERE Id =: donations.get(0).Id].Total_Donation__c;
        //Verify that both are the same
        system.assert(donationTotal == bidTotal);
        
    }
    
    /**
    Highest Bid is updated on the Item - Bids for Same item in separate Lists
    */
    public static testmethod void itemHighestBidNonCompeteTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        //Create a set of items
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids - for the same set of items
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        //Insert both bid Lists
        Test.startTest();
        insert bidList1;
        insert bidList2;
        Test.stopTest();
        
        //Those Bids that were inserted in the second Donation had a higher amount and hence their Amount should reflect
        //on the Item

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
    public static testmethod void itemHighestBidCompeteTest(){
        
        //Create 2 Donations each with bids
        List<Contact> donors = TestDataGenerator.CreateDonors(2);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        //Create a third set of Donations and Bids - for the same set of Items
        List<Contact> competingDonor = TestDataGenerator.CreateDonors(1);
        insert competingDonor;
        List<Donation__c> competingDonation = TestDataGenerator.CreateDonations(competingDonor, FALSE);
        insert competingDonation;
        
        //These bids will have the same amounts as the Item's Current Highest Bid
        List<Bid__c> compBidList = TestDataGenerator.CreateCompetingBids(competingDonation, items, 4);
        
        //Add all Bids to a single list
        bidList.addAll(compBidList);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList));
        
        //i. Those Bids that were inserted in the first Donation had lower amounts than the second Donation's Bids for the same item
        //and hence they will fail 
        //ii. The Bids made under the 3rd Donation had the same Bid Amounts as the second bid - hence, they too will fail
        try{
            Test.startTest();
            insert bidList;
            Test.stopTest();
        }
        catch(System.DmlException ex){
            system.debug('num errors: ' + ex.getNumDml());
            
            System.assert(ex.getNumDml() == 8);
            
            for (Integer i = 0; i < 4; i++) {
                System.assert(ex.getDmlIndex(i) == i);
            }
            for(Integer i = 4; i < 8;  i++){
                System.assert(ex.getDmlIndex(i) == (i+4));
            }
            
            System.assert(ex.getMessage().contains(System.Label.HighestBidError));
        }
        
    }
    /**
    Highest Bid is updated on the Item - Competing Bids for Same Item in a single List
    */
    public static testmethod void bidAmountChangeEffectOnItemTest(){
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        Test.startTest();
        insert bidList1;
        insert bidList2;
        
        //Change the Bids in the Second Donation to 0 - this should make the Item's highest bid equal to the Bids of the First Donation
        for(Bid__c bid : bidList2){
            bid.Amount__c = 0.00;
        }
        
        update bidList2;
        
        Test.stopTest();
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
    public static testmethod void bidAmountChangeEffectOnDonationTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        //insert bids
        Test.startTest();
        insert bidList1;
        insert bidList2;
        
        //Create a Map of Donation Id > Total Donation
        List<AggregateResult> donationTotalARList = [SELECT Donation__c, SUM(Amount__c) donationTotal
                                                     FROM Bid__c
                                                     GROUP BY Donation__c];
        
        Map<Id, Decimal> donationIdTotalMap = new Map<Id, Decimal>();
        
        for(AggregateResult donationTotalAR : donationTotalARList){
            donationIdTotalMap.put((Id)donationTotalAR.get('Donation__c'), (Decimal)donationTotalAR.get('donationTotal'));
        }

        //Query updated Donations
        Map<Id, Donation__c> updatedDonationMap = new Map<Id, Donation__c>([SELECT Id, Total_Donation__c FROM Donation__c]);
        
        //Verify that the Totals were updated correctly
        for(Id updatedDonationId : updatedDonationMap.keySet()){
            
            system.assert(updatedDonationMap.get(updatedDonationId).Total_Donation__c == donationIdTotalMap.get(updatedDonationId));
            
        }
        
        //Query all bids and increase their value
        List<Bid__c> insertedBids = [SELECT Id, Amount__c FROM Bid__c];
        
        //Change the bid Amount values
        for(Bid__c bid : insertedBids){
            bid.Amount__c = bid.Amount__c + 1000;
        }
        
        //Update Bids
        update insertedBids;
        Test.stopTest();
        
        //Create a fresh Map of Donation Id > Total Donation

        donationTotalARList = [SELECT Donation__c, SUM(Amount__c) donationTotal
                               FROM Bid__c
                               GROUP BY Donation__c];
        
        donationIdTotalMap = new Map<Id, Decimal>();
        
        for(AggregateResult donationTotalAR : donationTotalARList){
            donationIdTotalMap.put((Id)donationTotalAR.get('Donation__c'), (Decimal)donationTotalAR.get('donationTotal'));
        }
        
        //Fetch updated Donations
        updatedDonationMap = new Map<Id, Donation__c>([SELECT Id, Total_Donation__c FROM Donation__c]);
        
        //Verify that Totals were updated correctly
        for(Id updatedDonationId : updatedDonationMap.keySet()){
            
            system.assert(updatedDonationMap.get(updatedDonationId).Total_Donation__c == donationIdTotalMap.get(updatedDonationId));
            
        }
        
    }
    
    /**
    When the Donation Lookup changes - both the old and the New Donations are processed
    */
    public static testmethod void bidDonationLookupChangeTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        //Insert bids
        Test.startTest();
        insert bidList1;
        insert bidList2;
        
        //Create a Map of Donation Id > Total Donation
        List<AggregateResult> donationTotalARList = [SELECT Donation__c, SUM(Amount__c) donationTotal
                                                     FROM Bid__c
                                                     GROUP BY Donation__c];
        
        Map<Id, Decimal> donationIdTotalMap = new Map<Id, Decimal>();
        
        for(AggregateResult donationTotalAR : donationTotalARList){
            donationIdTotalMap.put((Id)donationTotalAR.get('Donation__c'), (Decimal)donationTotalAR.get('donationTotal'));
        }
        //Query Updated Donations
        List<Donation__c> updatedDonationList = [SELECT Id, Total_Donation__c FROM Donation__c];
        Map<Id, Donation__c> updatedDonationMap = new Map<Id, Donation__c>(updatedDonationList);
        
        //Validate that Totals updated correctly
        for(Id updatedDonationId : updatedDonationMap.keySet()){
            
            system.assert(updatedDonationMap.get(updatedDonationId).Total_Donation__c == donationIdTotalMap.get(updatedDonationId));
            
        }
        
        //Query all bids and increase their value
        List<Bid__c> insertedBids = [SELECT Id, Amount__c, Donation__c FROM Bid__c];
        system.debug('inserted bids before random: ' + insertedBids);
        
        Id randomDonationId;
        system.debug('updatedDonationList: ' + updatedDonationList);
        
        //Change the bid Donation lookups
        for(Bid__c bid : insertedBids){
            Id currentBidDonationId = bid.Donation__c;
            do{
                randomDonationId = updatedDonationList.get(Integer.valueOf(Math.random()*updatedDonationList.size())).Id;
            }while(randomDonationId == currentBidDonationId); 
            bid.Donation__c = randomDonationId;
        }
        
        system.debug('inserted bids after random: ' + insertedBids);
        
        //Update bids
        update insertedBids;
        Test.stopTest();
        
        //Create a fresh Map of Donation Id > Total Donation

        donationTotalARList = [SELECT Donation__c, SUM(Amount__c) donationTotal
                               FROM Bid__c
                               GROUP BY Donation__c];
        
        //Set Default Total Donation = 0 for all Donations
        donationIdTotalMap = new Map<Id, Decimal>();

        for(Donation__c donation : updatedDonationList){
            donationIdTotalMap.put(donation.Id, 0);
        }
        
        for(AggregateResult donationTotalAR : donationTotalARList){
            donationIdTotalMap.put((Id)donationTotalAR.get('Donation__c'), (Decimal)donationTotalAR.get('donationTotal'));
        }
        
        //Query Donations
        updatedDonationMap = new Map<Id, Donation__c>([SELECT Id, Total_Donation__c FROM Donation__c]);
        
        //Validate that the Totals updated correctly on All donations
        for(Id updatedDonationId : updatedDonationMap.keySet()){
            
            system.assert(updatedDonationMap.get(updatedDonationId).Total_Donation__c == donationIdTotalMap.get(updatedDonationId));
            
        }
        
    }
    
    /**
    When the Item Lookup changes - both the old and the New Items are processed
    */
    public static testmethod void bidItemLookupChangeTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        //insert bids
        Test.startTest();
        insert bidList1;
        insert bidList2;
        
        //Create a Map of Item Id > Highest Bid
        List<AggregateResult> itemHighestBidARList = [SELECT Item__c, MAX(Amount__c) itemHighestBid
                                                      FROM Bid__c
                                                      GROUP BY Item__c];
        
        Map<Id, Decimal> itemIdHighestBidMap = new Map<Id, Decimal>();
        
        for(AggregateResult itemHighestBid : itemHighestBidARList){
            itemIdHighestBidMap.put((Id)itemHighestBid.get('Item__c'), (Decimal)itemHighestBid.get('itemHighestBid'));
        }
        //Query items
        List<Item__c> updatedItemList = [SELECT Id, Highest_Bid__c FROM Item__c];

        Map<Id, Item__c> updatedItemMap = new Map<Id, Item__c>(updatedItemList);
        
        //Verify that the Highest Amount updated correctly
        for(Id updatedItemId : updatedItemMap.keySet()){
            
            system.assert(updatedItemMap.get(updatedItemId).Highest_Bid__c == itemIdHighestBidMap.get(updatedItemId));
            
        }
        
        bidList2.addAll(bidList1);
        system.debug('inserted bids before random: ' + bidList2);
        
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
        
        system.debug('inserted bids after random: ' + bidList2);
        
        //Update bids
        update bidList2;
        Test.stopTest();
        
        //Create a fresh Map of Item Id > Highest Bid
        itemHighestBidARList = [SELECT Item__c, MAX(Amount__c) itemHighestBid
                                FROM Bid__c
                                GROUP BY Item__c];
        
        itemIdHighestBidMap = new Map<Id, Decimal>();
        
        //Set Default Highest Bid = NULL for all Items
        for(Item__c item: updatedItemList){
            itemIdHighestBidMap.put(item.Id, NULL);
        }

        for(AggregateResult itemHighestBidAR : itemHighestBidARList){
            itemIdHighestBidMap.put((Id)itemHighestBidAR.get('Item__c'), (Decimal)itemHighestBidAR.get('itemHighestBid'));
        }
        
        system.debug('itemIdHighestBidMap: ' + itemIdHighestBidMap);

        //Get updated set of Items
        updatedItemMap = new Map<Id, Item__c>([SELECT Id, Highest_Bid__c FROM Item__c]);
        
        system.debug('updatedItemMap: ' + updatedItemMap);

        //Verify that the Highest Bid updated on all Items correctly
        for(Id updatedItemId : updatedItemMap.keySet()){
            
            system.assert(updatedItemMap.get(updatedItemId).Highest_Bid__c == itemIdHighestBidMap.get(updatedItemId));
            
        }
    }
    
    /**
    The Item updates in response to Deletion and Undeletion of bids
    */
    public static testmethod void bidDeleteUndeleteEffectOnItemTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        //insert bids
        Test.startTest();
        insert bidList1;
        insert bidList2;
        
        //Create a Map of Item Id > Highest Bid
        List<AggregateResult> itemHighestBidARList = [SELECT Item__c, MAX(Amount__c) itemHighestBid
                                                      FROM Bid__c
                                                      GROUP BY Item__c];
        
        Map<Id, Decimal> itemIdHighestBidMap = new Map<Id, Decimal>();
        
        for(AggregateResult itemHighestBidAR : itemHighestBidARList){
            itemIdHighestBidMap.put((Id)itemHighestBidAR.get('Item__c'), (Decimal)itemHighestBidAR.get('itemHighestBid'));
        }
        //Query the items
        List<Item__c> updatedItemList = [SELECT Id, Highest_Bid__c FROM Item__c];
        Map<Id, Item__c> updatedItemMap = new Map<Id, Item__c>(updatedItemList);
        
        //Verify that the Highest Bid updated correctly
        for(Id updatedItemId : updatedItemMap.keySet()){
            
            system.assert(updatedItemMap.get(updatedItemId).Highest_Bid__c == itemIdHighestBidMap.get(updatedItemId));
            
        }
        
        //Query all bids and delete them
        List<Bid__c> bidsToDelete = [SELECT Id FROM Bid__c];
        system.debug('bidsToDelete: ' + bidsToDelete);
        
        //Delete bids
        delete bidsToDelete;
        
        Test.stopTest();
        
        //Query items
        items = [SELECT Highest_Bid__c FROM Item__c];
        
        //The Highest Bid on All items has been updated to NULL
        for(Item__c item : items){
            system.assert(item.Highest_Bid__c == NULL);
        }
        
        //Restore bids
        List<Bid__c> restoredBids = [SELECT Id FROM Bid__c Where IsDeleted = TRUE ALL ROWS];
        undelete restoredBids;
        
        //Query items
        updatedItemList = [SELECT Id, Highest_Bid__c FROM Item__c];
        updatedItemMap = new Map<Id, Item__c>(updatedItemList);
        
        //The Original Highest Bid values have been updated on the Items
        for(Id updatedItemId : updatedItemMap.keySet()){
            system.assert(updatedItemMap.get(updatedItemId).Highest_Bid__c == itemIdHighestBidMap.get(updatedItemId));
        }
        
    }
    /**
    The Donation updates in response to Deletion and Undeletion of bids
    */
    public static testmethod void bidDeleteUndeleteEffectOnDonationTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        //insert bids
        Test.startTest();
        insert bidList1;
        insert bidList2;
        
        //Create a Map of Donation Id > Total Donation
        List<AggregateResult> donationTotalARList = [SELECT Donation__c, SUM(Amount__c) donationTotal
                                                     FROM Bid__c
                                                     GROUP BY Donation__c];
        
        Map<Id, Decimal> donationIdTotalMap = new Map<Id, Decimal>();
        
        for(AggregateResult donationTotalAR : donationTotalARList){
            donationIdTotalMap.put((Id)donationTotalAR.get('Donation__c'), (Decimal)donationTotalAR.get('donationTotal'));
        }
        //Query donations
        List<Donation__c> updatedDonationList = [SELECT Id, Total_Donation__c FROM Donation__c];

        Map<Id, Donation__c> updatedDonationMap = new Map<Id, Donation__c>(updatedDonationList);
        
        //Verify that the Total Donation updated correctly
        for(Id updatedDonationId : updatedDonationMap.keySet()){
            
            system.assert(updatedDonationMap.get(updatedDonationId).Total_Donation__c == donationIdTotalMap.get(updatedDonationId));
            
        }
        
        //Query all bids and delete them
        List<Bid__c> bidsToDelete = [SELECT Id, Amount__c, Donation__c FROM Bid__c];
        system.debug('bidsToDelete: ' + bidsToDelete);
        
        //Delete bids
        delete bidsToDelete;
        
        Test.stopTest();
        
        //Requery donations
        donations = [SELECT Total_Donation__c FROM Donation__c];
        
        //The Total Donation amounts have been cleared
        for(Donation__c donation : donations){
            system.assert(donation.Total_Donation__c == 0);
        }
        
        //Restore bids
        List<Bid__c> restoredBids = [SELECT Id FROM Bid__c Where IsDeleted = TRUE ALL ROWS];
        undelete restoredBids;
        
        updatedDonationList = [SELECT Id, Total_Donation__c FROM Donation__c];
        updatedDonationMap = new Map<Id, Donation__c>(updatedDonationList);
        
        //The Total Donation amounts have been restored
        for(Id updatedDonationId : updatedDonationMap.keySet()){
            system.assert(updatedDonationMap.get(updatedDonationId).Total_Donation__c == donationIdTotalMap.get(updatedDonationId));
        }
        
    }
    
    
}