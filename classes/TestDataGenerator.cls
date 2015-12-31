/**
Purpose:
This class functions as a Data Factory that is called by the other test methods
*/
@isTest
public class TestDataGenerator{
    //Internal Map of Items
    public static Map<Id, Item__c> itemMap;
    //Map of Item Id > Highest Bid
    public static Map<Id, Decimal> itemIdHighestBidMap;
    //Map of Donation Id > Total Donation
    public static Map<Id, Decimal> donationIdTotalMap;
    public static Integer numberOfBidsLessThanHighestBid = 0;
    //Internal count of users
    public static Integer userCount = 0;
    
    //Query the testVolume__c Custom setting to fetch data volumes to be created
    public static TestVolume__c testVolume{
        get{
            if(testVolume == NULL){

                testVolume = [SELECT NoOfBidsPerDonation__c, NoOfDonations__c, NoOfDonors__c, NoOfItems__c
                FROM TestVolume__c
                WHERE Name = 'TestVolume'
                LIMIT 1];
            }
            return testVolume;
        }
        set;
    }
    //Query User Profiles
    public static Map<String, Id> profileMap{
        get{
            if(profileMap == NULL){
                profileMap = new Map<String, Id>();
                List<Profile> profiles = [SELECT Name, Id FROM Profile];
                for(Profile p : profiles){
                    profileMap.put(p.Name, p.Id);
                }
            }
            return profileMap;
    }
    set;
    }
    //Debugging Util method to Serialize the various input Lists
    public static String SerializeObjects(List<sObject> list1, List<sObject> list2, List<sObject> list3, List<sObject> list4){

        String json1 = JSON.serializePretty(list1);
        String json2 = JSON.serializePretty(list2);
        String json3 = JSON.serializePretty(list3);
        String json4 = JSON.serializePretty(list4);

        return json1 + json2 + json3 + json4;

    }
    //Util method for Donor Creation
    public static List<Contact> CreateDonors(Integer noOfDonors){

        List<Contact> donors = new List<Contact>();

        //Loop through number of Donors
        for(Integer i = 0; i < noOfDonors ; i++ ){

            donors.add(new Contact(FirstName = 'Test', LastName = 'User ' + i));
        }

        return donors;
    }

    //Util method for Donation Creation
    //Pass a list of donors and this method creates 1 donation per donor
    public static List<Donation__c> CreateDonations(List<Contact> donors, Boolean statusBlank)
    {

        List<Donation__c> donations = new List<Donation__c>();

        for(Contact donor : donors)
        {
            if(statusBlank){
                donations.add(new Donation__c(Donor__c = donor.Id));
            }
            else{
                donations.add(new Donation__c(Status__c = 'New', Donor__c = donor.Id));
            }
        }   

        return donations;
    }
    /**
     Util method for Bid Creation

     @param donations - list of existing donations
     @param items - list of existing items
     @param noOfBidsPerDonation - the number of bids to be created for each donation
     @param bidsValid - Boolean that specified whether the created bids are valid, ie, is the Bid Amount > Item's Minimum Bid or not
     
     The Logic creates the Bids under the Donations with the Items taken from the items list - in order
     Also, subsequent bids for the same item are created in increments of USD 1000
    */
    public static List<Bid__c> CreateBids(List<Donation__c> donations, List<Item__c> items, Integer noOfBidsPerDonation,
                                          Boolean bidsValid){

        List<Bid__c> bids = new List<Bid__c>();

        if(TestDataGenerator.itemIdHighestBidMap == NULL){
            TestDataGenerator.itemIdHighestBidMap = new Map<Id, Decimal>();
        }

        Integer totalNumberOfBids = noOfBidsPerDonation * donations.size();
        
        for(Integer bidCounter = 0; bidCounter < totalNumberOfBids ; bidCounter++){

            Item__c relatedItem = items.get(Math.mod(bidCounter,items.size()));

            Bid__c bid = new Bid__c(Item__c = relatedItem.Id,
                                Donation__c = donations.get(bidCounter / noOfBidsPerDonation).Id
                                );
         if(bidsValid){
            
            //Ensure that the amount chosen is greater than the Related Item's Minimum Bid
            if(TestDataGenerator.itemIdHighestBidMap.containsKey(bid.Item__c)){
                bid.Amount__c = TestDataGenerator.itemIdHighestBidMap.get(bid.Item__c) + 1000;
                TestDataGenerator.itemIdHighestBidMap.put(bid.Item__c, bid.Amount__c);
            }
            else{
                bid.Amount__c = relatedItem.Minimum_Bid__c + 1000;
                TestDataGenerator.itemIdHighestBidMap.put(bid.Item__c, bid.Amount__c);
            }

            }
            else{
                //Reduce the amount by USD 1000 from the Related Item's Minimum Bid to make it invalid
                bid.Amount__c = relatedItem.Minimum_Bid__c - 1000;
            } 
                bids.add(bid);
            }

        return bids;
    }
    /**
     Util method for Competing Bid Creation

     @param donations - list of existing donations
     @param items - list of existing items
     @param noOfBidsPerDonation - the number of bids to be created for each donation
     
     The Logic creates the Bids under the Donations with the Items taken from the items list - in order -
     and assigns the Amount to match the Highest Bid for an item
    */
    public static List<Bid__c> CreateCompetingBids(List<Donation__c> donations, List<Item__c> items, Integer noOfBidsPerDonation){
         
        List<Bid__c> bids = new List<Bid__c>();
       
        Integer totalNumberOfBids = noOfBidsPerDonation * donations.size();
        
        for(Integer bidCounter = 0; bidCounter < totalNumberOfBids ; bidCounter++){

            Item__c relatedItem = items.get(Math.mod(bidCounter,items.size()));

            Bid__c bid = new Bid__c(Item__c = relatedItem.Id,
                                Donation__c = donations.get(bidCounter / noOfBidsPerDonation).Id
                                );
            
            //Ensure that the amount chosen is equal to the Related Item's Highest Bid
            if(TestDataGenerator.itemIdHighestBidMap.containsKey(bid.Item__c)){
                bid.Amount__c = TestDataGenerator.itemIdHighestBidMap.get(bid.Item__c);
            }
                bids.add(bid);
            }

        return bids;

    }
    /// ????? //
    /*public static List<Bid__c> CreateBidsBulk(List<Id> donationIds, List<Id> itemIds){
       

        List<Bid__c> bids = new List<Bid__c>();
        TestDataGenerator.itemIdHighestBidMap = new Map<Id, Decimal>();

        //Integer bidCounter = Integer.valueOf(Math.min(testVolume.NoOfBidsPerDonation__c,testVolume.NoOfItems__c)); 
        //Integer donationCounter = 0;
        Integer countInvalidBids = 0 ;
        Integer totalNumberOfBids = Integer.valueOf(testVolume.NoOfBidsPerDonation__c * testVolume.NoOfDonations__c);
        Integer bidCounter;
        for(bidCounter = 0; bidCounter < totalNumberOfBids ; bidCounter++){

            Bid__c bid = new Bid__c(Item__c = itemIds.get(Math.mod(bidCounter,Integer.valueof(testVolume.NoOfItems__c))),
                                Donation__c = donationIds.get(bidCounter / Integer.valueOf(testVolume.NoOfBidsPerDonation__c))
                                );
            Item__c relatedItem = itemMap.get(bid.Item__c);

            //if(countInvalidBids == noOfInvalidBids){
            
            //Ensure that the amount chosen is greater than the Related Item's Minimum Bid
            if(TestDataGenerator.itemIdHighestBidMap.containsKey(bid.Item__c)){
                bid.Amount__c = TestDataGenerator.itemIdHighestBidMap.get(bid.Item__c) + 1000;
                //Is this correct??
                //numberOfBidsLessThanHighestBid++ ;
            }
            else{
                bid.Amount__c = relatedItem.Minimum_Bid__c + 1000;
                TestDataGenerator.itemIdHighestBidMap.put(bid.Item__c, bid.Amount__c);
            }

            //}
            //else{
                //Reduce the amount by USD 1000 from the Related Item's Minimum Bid to make it invalid
                //bid.Amount__c = relatedItem.Minimum_Bid__c - 1000;
                //countInvalidBids++;
            //}

            bids.add(bid);
        }
       
        List<Bid__c> successfulBids = new List<Bid__c>();

        //Calculate Utility Maps that will be used for assertion
        //KK: To be created as separate functions in the test class
         successfulBids = CalculateItemIdHighestBidMap(bids);
        //No. of successful bids = Initial bids - numberofInvalidBids - numberOfBidsLessThanHighestBid

        //CalculateSuccessfulBids(bids);     
        CalculateDonationIdTotalMap(successfulBids);

        insert bids;
        return bids;

    }
    */

    // ?????  ////
    /* 
    public static List<Bid__c> CalculateItemIdHighestBidMap(List<Bid__c> bids){

    TestDataGenerator.itemIdHighestBidMap = new Map<Id, Decimal>();
    List<Bid__c> successfulBids = new List<Bid__c>();
    Set<Id> itemIdsCovered = new Set<Id>();

    for(Bid__c bid : bids){
            if(TestDataGenerator.itemIdHighestBidMap.containsKey(bid.Item__c)){
                Decimal highestBidAmount = TestDataGenerator.itemIdHighestBidMap.get(bid.Item__c);
                if(bid.Amount__c > highestBidAmount){
                    TestDataGenerator.itemIdHighestBidMap.put(bid.Item__c, bid.Amount__c);
                    //numberOfBidsLessThanHighestBid++;
                }
            }
        }
    
        for(Bid__c bid : bids){
                Decimal highestBidForItem = TestDataGenerator.itemIdHighestBidMap.get(bid.Item__c);
                if(bid.Amount__c < highestBidForItem){
                    //itemIdHighestBidMap.put(bid.Item__c, bid.Amount__c);
                    numberOfBidsLessThanHighestBid++;
                }
                else if(bid.Amount__c == highestBidForItem){
                    if(!itemIdsCovered.contains(bid.Item__c)){
                        successfulBids.add(bid);
                    }
                }
            }

        return successfulBids;
    }
    
    //These should only be the bids that were successfully inserted
    public static void CalculateDonationIdTotalMap(List<Bid__c> bids){

        donationIdTotalMap = new Map<Id, Decimal>();

        for(Bid__c bid : bids){
            if(donationIdTotalMap.containsKey(bid.Donation__c)){
                Decimal totalDonation = donationIdTotalMap.get(bid.Donation__c);
                totalDonation += bid.Amount__c;
                donationIdTotalMap.put(bid.Donation__c, totalDonation);
            }
        }
    }
    */

    /**
     Util method for Item Creation

     @param upperLimitForMinimumBid - is the upper limit for the Minimum Bid Value
     @param noOfItems - number of items to be created
     @param futureClosingDate - Boolean which specifies whether the Closing Date is a future date or not

     The logic uses a default Lower limit of 1000 for the Minimum Bid value
     
    */

    public static List<Item__c> CreateItems(Integer upperLimitForMinimumBid, Integer noOfItems, Boolean futureClosingDate){

        List<Item__c> items = new List<Item__c>();
        itemMap = new Map<Id, Item__c>();

        for(Integer i = 0; i < noOfItems ; i++){

            //Choosing Categories from Cat 1 - Cat 10
            Item__c item = new Item__c(Name = 'Item ' + i, 
                                  Category__c = 'Cat ' + (Math.round(Math.random()*9)  + 1),
                                Minimum_Bid__c = Math.round(Math.random()*upperLimitForMinimumBid) + 1000);
            
            if(futureClosingDate){
                item.Closing_Date__c = Date.today().addDays(10);
            }
            else{
                item.Closing_Date__c = Date.today().addDays(-10);
            }
            items.add(item);
        }

        return items;
    }

    /**
     Alternate Util method for a single Item Creation

     @param minimumBid - Minimum Bid
     @param cat - Category
     
    */
    public static Item__c CreateSingleItem(Decimal minimumBid, String cat){
        Item__c item = new Item__c(Closing_Date__c = Date.today(),
                                   Category__c = cat,
                                   Minimum_Bid__c = minimumBid);
        return item;
    }

    // ????? //
    /*public static List<Item__c> CreateItemsBulk(Integer upperLimitForMinimumBid){

        List<Item__c> items = new List<Item__c>();
        itemMap = new Map<Id, Item__c>();

        for(Integer i = 0; i < testVolume.NoOfItems__c ; i++){

            //Choosing Categories from Cat 1 - Cat 10
            items.add(new Item__c(Name = 'Item ' + i, 
                                  Category__c = 'Cat ' + (Math.round(Math.random()*9)  + 1),
                                  //Closing_Date__c = Date.today().addDays(Math.round(Math.random()*366)),
                                  Closing_Date__c = Date.today().addDays(10),
                                  Minimum_Bid__c = Math.round(Math.random()*upperLimitForMinimumBid) + 1000
                                  ));

        }

        insert items;

        //Item Map populated
        for(Item__c item : items){
            itemMap.put(item.Id, item);
        }

        return items;
    }
    */

    /**
     Util method for User Creation

     @param profileName - profile desired
    */
    public static User CreateUser(String profileName){

        User u = new User(profileId = profileMap.get(profileName), username = 'testuser' + userCount + '@advanceddev.org', email = 'testuser' + userCount + '@advanceddev.org',
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                           alias='tu'+userCount, lastname='user'+userCount);

        userCount++;

        return u;
    }

}