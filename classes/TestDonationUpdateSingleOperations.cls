//Test class for update logic
//Separate methods for single and bulk tests should be written to validate functionality
//Single methods are as important as bulk methods
@isTest
public class TestDonationUpdateSingleOperations{
    
    public static testmethod void validBidTest(){
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bids));
        
        Test.startTest();
        insert bids;
        Test.stopTest();
        
        system.assert([SELECT COUNT() FROM Bid__c] == bids.size());
        
        
    }
    public static testmethod void invalidBidTest(){
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), FALSE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bids));
        
        try{
            Test.startTest();
            insert bids;
            Test.stopTest();
        }
        catch(System.DmlException ex){
            system.assert(ex.getNumDml() == bids.size());
            system.assert(ex.getMessage().contains(System.Label.MinimumBidError));
        } 
        
    }
    
    public static testmethod void donationTotalTest(){
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bids));
        
        Test.startTest();
        insert bids;
        Test.stopTest();
        
        //Query Bids to get total
        Decimal bidTotal = (Decimal)[SELECT SUM(Amount__c) bidTotal FROM Bid__c].get(0).get('bidTotal');
        //Query Donation to get total
        Decimal donationTotal = [SELECT Total_Donation__c FROM Donation__c WHERE Id =: donations.get(0).Id].Total_Donation__c;
        system.assert(donationTotal == bidTotal);
        
    }
    
    
    
    public static testmethod void itemHighestBidNonCompeteTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        Test.startTest();
        //Database.InsertResult[] resultList = Database.insert(bids, false);
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
        //Validate that the Items' Highest Bids match those of bidList2
        for(Item__c item : items){
            system.assert(item.Highest_Bid__c == bidList2.get(itemCounter).Amount__c);
            itemCounter++;
        }
        
    }
    
    //KK: May make sense to keep the variable values, ie, 4 or 2000 as either static finals or custom settings
    public static testmethod void itemHighestBidCompeteTest(){
        
        List<Contact> donors = TestDataGenerator.CreateDonors(2);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        List<Contact> competingDonor = TestDataGenerator.CreateDonors(1);
        insert competingDonor;
        List<Donation__c> competingDonation = TestDataGenerator.CreateDonations(competingDonor, FALSE);
        insert competingDonation;
        
        List<Bid__c> compBidList = TestDataGenerator.CreateCompetingBids(competingDonation, items, 4, competingDonation.size(), items.size());
        
        bidList.addAll(compBidList);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList));
        
        //Those Bids that were inserted in the first Donation had lower amounts than the second Donation's Bids for the same item
        //and hence they wil fail 
        //Also, the 3rd Donation had the same Bid Amounts as the second bid - hence, they too will fail
        try{
            Test.startTest();
            insert bidList;
            Test.stopTest();
        }
        catch(System.DmlException ex){
            system.debug('num errors: ' + ex.getNumDml());
            
            System.assert(ex.getNumDml() == 8);
            
            for (Integer i = 0; i < 4; i++) {
                // Process exception here
                System.assert(ex.getDmlIndex(i) == i);
            }
            for(Integer i = 4; i < 8;  i++){
                System.assert(ex.getDmlIndex(i) == (i+4));
            }
            
            System.assert(ex.getMessage().contains(System.Label.HighestBidError));
        }
        
    }
    
    //KK: May make sense to keep the variable values, ie, 4 or 2000 as either static finals or custom settings
    //KK: See if there's a way to reduce number of lines by creating reusable code??
    
    public static testmethod void bidAmountChangeEffectOnItemTest(){
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
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
    
    public static testmethod void bidAmountChangeEffectOnDonationTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        Test.startTest();
        //Database.InsertResult[] resultList = Database.insert(bids, false);
        insert bidList1;
        insert bidList2;
        
        List<AggregateResult> donationTotalARList = [SELECT Donation__c, SUM(Amount__c) donationTotal
                                                     FROM Bid__c
                                                     GROUP BY Donation__c];
        
        Map<Id, Decimal> donationIdTotalMap = new Map<Id, Decimal>();
        
        for(AggregateResult donationTotalAR : donationTotalARList){
            donationIdTotalMap.put((Id)donationTotalAR.get('Donation__c'), (Decimal)donationTotalAR.get('donationTotal'));
        }
        Map<Id, Donation__c> updatedDonationMap = new Map<Id, Donation__c>([SELECT Id, Total_Donation__c FROM Donation__c]);
        
        for(Id updatedDonationId : updatedDonationMap.keySet()){
            
            system.assert(updatedDonationMap.get(updatedDonationId).Total_Donation__c == donationIdTotalMap.get(updatedDonationId));
            
        }
        
        //Query all bids and increase their value
        List<Bid__c> insertedBids = [SELECT Id, Amount__c FROM Bid__c];
        
        //Change the bid Amount values
        for(Bid__c bid : insertedBids){
            bid.Amount__c = bid.Amount__c + 1000;
        }
        
        update insertedBids;
        Test.stopTest();
        
        donationTotalARList = [SELECT Donation__c, SUM(Amount__c) donationTotal
                               FROM Bid__c
                               GROUP BY Donation__c];
        
        donationIdTotalMap = new Map<Id, Decimal>();
        
        for(AggregateResult donationTotalAR : donationTotalARList){
            donationIdTotalMap.put((Id)donationTotalAR.get('Donation__c'), (Decimal)donationTotalAR.get('donationTotal'));
        }
        
        updatedDonationMap = new Map<Id, Donation__c>([SELECT Id, Total_Donation__c FROM Donation__c]);
        
        for(Id updatedDonationId : updatedDonationMap.keySet()){
            
            system.assert(updatedDonationMap.get(updatedDonationId).Total_Donation__c == donationIdTotalMap.get(updatedDonationId));
            
        }
        
    }
    
    public static testmethod void bidDonationLookupChangeTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        Test.startTest();
        //Database.InsertResult[] resultList = Database.insert(bids, false);
        insert bidList1;
        insert bidList2;
        
        List<AggregateResult> donationTotalARList = [SELECT Donation__c, SUM(Amount__c) donationTotal
                                                     FROM Bid__c
                                                     GROUP BY Donation__c];
        
        Map<Id, Decimal> donationIdTotalMap = new Map<Id, Decimal>();
        
        for(AggregateResult donationTotalAR : donationTotalARList){
            donationIdTotalMap.put((Id)donationTotalAR.get('Donation__c'), (Decimal)donationTotalAR.get('donationTotal'));
        }
        List<Donation__c> updatedDonationList = [SELECT Id, Total_Donation__c FROM Donation__c];
        Map<Id, Donation__c> updatedDonationMap = new Map<Id, Donation__c>(updatedDonationList);
        
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
        
        update insertedBids;
        Test.stopTest();
        
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
        
        updatedDonationMap = new Map<Id, Donation__c>([SELECT Id, Total_Donation__c FROM Donation__c]);
        
        for(Id updatedDonationId : updatedDonationMap.keySet()){
            
            system.assert(updatedDonationMap.get(updatedDonationId).Total_Donation__c == donationIdTotalMap.get(updatedDonationId));
            
        }
        
    }
    
    public static testmethod void bidItemLookupChangeTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        Test.startTest();
        //Database.InsertResult[] resultList = Database.insert(bids, false);
        insert bidList1;
        insert bidList2;
        
        List<AggregateResult> itemHighestBidARList = [SELECT Item__c, MAX(Amount__c) itemHighestBid
                                                      FROM Bid__c
                                                      GROUP BY Item__c];
        
        Map<Id, Decimal> itemIdHighestBidMap = new Map<Id, Decimal>();
        
        for(AggregateResult itemHighestBid : itemHighestBidARList){
            itemIdHighestBidMap.put((Id)itemHighestBid.get('Item__c'), (Decimal)itemHighestBid.get('itemHighestBid'));
        }
        List<Item__c> updatedItemList = [SELECT Id, Highest_Bid__c FROM Item__c];
        Map<Id, Item__c> updatedItemMap = new Map<Id, Item__c>(updatedItemList);
        
        for(Id updatedItemId : updatedItemMap.keySet()){
            
            system.assert(updatedItemMap.get(updatedItemId).Highest_Bid__c == itemIdHighestBidMap.get(updatedItemId));
            
        }
        
        //List<Bid__c> insertedBids = [SELECT Id, Amount__c, Item__c FROM Bid__c];
        bidList2.addAll(bidList1);
        system.debug('inserted bids before random: ' + bidList2);
        
        Id randomItemId;
        system.debug('updatedItemList: ' + updatedItemList);
        
        //Change the bid Item lookups
        for(Bid__c bid : bidList2){
            Id currentBidItemId = bid.Item__c;
            do{
                randomItemId = updatedItemList.get(Integer.valueOf(Math.random()*updatedItemList.size())).Id;
            }while(randomItemId == currentBidItemId); 
            bid.Item__c = randomItemId;
        }
        
        system.debug('inserted bids after random: ' + bidList2);
        
        update bidList2;
        Test.stopTest();
        
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

        updatedItemMap = new Map<Id, Item__c>([SELECT Id, Highest_Bid__c FROM Item__c]);
        
        system.debug('updatedItemMap: ' + updatedItemMap);

        for(Id updatedItemId : updatedItemMap.keySet()){
            
            system.assert(updatedItemMap.get(updatedItemId).Highest_Bid__c == itemIdHighestBidMap.get(updatedItemId));
            
        }
    }
    
    
    public static testmethod void bidDeleteUndeleteEffectOnItemTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        Test.startTest();
        insert bidList1;
        insert bidList2;
        
        List<AggregateResult> itemHighestBidARList = [SELECT Item__c, MAX(Amount__c) itemHighestBid
                                                      FROM Bid__c
                                                      GROUP BY Item__c];
        
        Map<Id, Decimal> itemIdHighestBidMap = new Map<Id, Decimal>();
        
        for(AggregateResult itemHighestBidAR : itemHighestBidARList){
            itemIdHighestBidMap.put((Id)itemHighestBidAR.get('Item__c'), (Decimal)itemHighestBidAR.get('itemHighestBid'));
        }
        List<Item__c> updatedItemList = [SELECT Id, Highest_Bid__c FROM Item__c];
        Map<Id, Item__c> updatedItemMap = new Map<Id, Item__c>(updatedItemList);
        
        for(Id updatedItemId : updatedItemMap.keySet()){
            
            system.assert(updatedItemMap.get(updatedItemId).Highest_Bid__c == itemIdHighestBidMap.get(updatedItemId));
            
        }
        
        //Query all bids and delete them
        List<Bid__c> bidsToDelete = [SELECT Id FROM Bid__c];
        system.debug('bidsToDelete: ' + bidsToDelete);
        
        delete bidsToDelete;
        
        Test.stopTest();
        
        items = [SELECT Highest_Bid__c FROM Item__c];
        
        for(Item__c item : items){
            system.assert(item.Highest_Bid__c == NULL);
        }
        
        //Restore bids
        List<Bid__c> restoredBids = [SELECT Id FROM Bid__c Where IsDeleted = TRUE ALL ROWS];
        undelete restoredBids;
        
        updatedItemList = [SELECT Id, Highest_Bid__c FROM Item__c];
        updatedItemMap = new Map<Id, Item__c>(updatedItemList);
        
        for(Id updatedItemId : updatedItemMap.keySet()){
            system.assert(updatedItemMap.get(updatedItemId).Highest_Bid__c == itemIdHighestBidMap.get(updatedItemId));
        }
        
    }
    
    public static testmethod void bidDeleteUndeleteEffectOnDonationTest(){
        
        //Create the First set of Donations and Bids
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 4, TRUE);
        insert items;
        List<Bid__c> bidList1 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList1));
        
        //Create the second set of Donations and Bids
        donors = new List<Contact>();
        donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        donations = new List<Donation__c>();
        donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        List<Bid__c> bidList2 = TestDataGenerator.CreateBids(donations, items, 4, donations.size(), items.size(), TRUE);
        
        system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bidList2));
        
        Test.startTest();
        insert bidList1;
        insert bidList2;
        
        List<AggregateResult> donationTotalARList = [SELECT Donation__c, SUM(Amount__c) donationTotal
                                                     FROM Bid__c
                                                     GROUP BY Donation__c];
        
        Map<Id, Decimal> donationIdTotalMap = new Map<Id, Decimal>();
        
        for(AggregateResult donationTotalAR : donationTotalARList){
            donationIdTotalMap.put((Id)donationTotalAR.get('Donation__c'), (Decimal)donationTotalAR.get('donationTotal'));
        }
        List<Donation__c> updatedDonationList = [SELECT Id, Total_Donation__c FROM Donation__c];
        Map<Id, Donation__c> updatedDonationMap = new Map<Id, Donation__c>(updatedDonationList);
        
        for(Id updatedDonationId : updatedDonationMap.keySet()){
            
            system.assert(updatedDonationMap.get(updatedDonationId).Total_Donation__c == donationIdTotalMap.get(updatedDonationId));
            
        }
        
        //Query all bids and delete them
        List<Bid__c> bidsToDelete = [SELECT Id, Amount__c, Donation__c FROM Bid__c];
        system.debug('bidsToDelete: ' + bidsToDelete);
        
        delete bidsToDelete;
        
        Test.stopTest();
        
        donations = [SELECT Total_Donation__c FROM Donation__c];
        
        for(Donation__c donation : donations){
            system.assert(donation.Total_Donation__c == 0);
        }
        
        //Restore bids
        List<Bid__c> restoredBids = [SELECT Id FROM Bid__c Where IsDeleted = TRUE ALL ROWS];
        undelete restoredBids;
        
        updatedDonationList = [SELECT Id, Total_Donation__c FROM Donation__c];
        updatedDonationMap = new Map<Id, Donation__c>(updatedDonationList);
        
        for(Id updatedDonationId : updatedDonationMap.keySet()){
            system.assert(updatedDonationMap.get(updatedDonationId).Total_Donation__c == donationIdTotalMap.get(updatedDonationId));
        }
        
    }
    
    
}