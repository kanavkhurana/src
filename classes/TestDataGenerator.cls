/**
Purpose:
This class functions as a Data Factory that is called by the other test methods
This class also has certain utility methods that are called by the other test classes
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
    
    /**
    Data volumes to be used for the test class 'TestBackEndLogic'
    are specified in the numberOfDonations and numberOfBidsPerDonation final variables
    */
    
    //Tested Value for bulk operations = 20
    //Reduced to 2 for ease of deployment
    private static final Integer numberOfDonations = 2;
    
    private static final Integer numberOfBidsPerDonation = 50;

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
    //Util method for Donor Creation in Bulk
    public static List<Contact> CreateDonorsBulk(){

        List<Contact> donors = new List<Contact>();

        //Loop through number of Donors
        for(Integer i = 0; i < numberOfDonations ; i++ ){

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
     
     i. The Logic creates the Bids under the Donations with the Items taken from the items list - in order
     ii. Also, subsequent bids for the same item are created in increments of USD 1000
     iii. It's important to remember that the list that is returned WILL NOT CONTAIN more than 1 bid for the same item
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
     Util method for Bid Creation in Bulk

     @param donations - list of existing donations
     @param items - list of existing items
     @param bidsValid - Boolean that specified whether the created bids are valid, ie, is the Bid Amount > Item's Minimum Bid or not
     
     i. The Logic creates the Bids under the Donations with the Items taken from the items listin order
     ii. Also, subsequent bids for the same item are created in increments of USD 1000
     iii. Number of Items created is assumed to be = numberOfBidsPerDonation * numberOfDonations
     iv. It's important to remember that the list that is returned WILL NOT CONTAIN more than 1 bid for the same item
    */
    public static List<Bid__c> CreateBidsBulk(List<Donation__c> donations, List<Item__c> items, Boolean bidsValid){

        List<Bid__c> bids = new List<Bid__c>();

        if(TestDataGenerator.itemIdHighestBidMap == NULL){
            TestDataGenerator.itemIdHighestBidMap = new Map<Id, Decimal>();
        }

        Integer totalNumberOfBids = numberOfBidsPerDonation * donations.size();
        
        for(Integer bidCounter = 0; bidCounter < totalNumberOfBids ; bidCounter++){

            Item__c relatedItem = items.get(Math.mod(bidCounter,items.size()));

            Bid__c bid = new Bid__c(Item__c = relatedItem.Id,
                                Donation__c = donations.get(bidCounter / numberOfBidsPerDonation).Id
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
     /**
     Util method for Competing Bid Creation in Bulk

     @param donations - list of existing donations
     @param items - list of existing items
     
     The Logic creates the Bids under the Donations with the Items taken from the items list - in order -
     and assigns the Amount to match the Highest Bid for an item
    */
    public static List<Bid__c> CreateCompetingBidsBulk(List<Donation__c> donations, List<Item__c> items){
         
        List<Bid__c> bids = new List<Bid__c>();
       
        Integer totalNumberOfBids = numberOfBidsPerDonation * donations.size();
        
        for(Integer bidCounter = 0; bidCounter < totalNumberOfBids ; bidCounter++){

            Item__c relatedItem = items.get(Math.mod(bidCounter,items.size()));

            Bid__c bid = new Bid__c(Item__c = relatedItem.Id,
                                Donation__c = donations.get(bidCounter / numberOfBidsPerDonation).Id
                                );
            
            //Ensure that the amount chosen is equal to the Related Item's Highest Bid
            if(TestDataGenerator.itemIdHighestBidMap.containsKey(bid.Item__c)){
                bid.Amount__c = TestDataGenerator.itemIdHighestBidMap.get(bid.Item__c);
            }
                bids.add(bid);
            }

        return bids;

    }
    
    /**
     Util method for Item Highest Bid Map Creation from Bids

     @param bids - list of bids to process     
    */
    public static Map<Id, Decimal> CalculateItemHighestBidMapFromBids(List<Bid__c> bids){

        Map<Id, Decimal> itemHighestBidMapFromBids = new Map<Id, Decimal>();

        for(Bid__c bid : bids){
            if(itemHighestBidMapFromBids.containsKey(bid.Item__c)){
                Decimal highestBid = itemHighestBidMapFromBids.get(bid.Item__c);
                if(bid.Amount__c > highestBid){
                    itemHighestBidMapFromBids.put(bid.Item__c, bid.Amount__c);
                }
            }
            else{
                itemHighestBidMapFromBids.put(bid.Item__c, bid.Amount__c);
            }
        }

        return itemIdHighestBidMap;
    
    }

    /**
     Util method for Item Highest Bid Map Creation from Items

     @param items - list of items to process     
    */
    public static Map<Id, Decimal> CalculateItemHighestBidMapFromItems(List<Item__c> items){

     Map<Id, Decimal> itemHighestBidMapFromItems = new Map<Id, Decimal>();

        for(Item__c item : items){
            itemHighestBidMapFromItems.put(item.Id, item.Highest_Bid__c);
        }

        return itemHighestBidMapFromItems;

    }
    
    /**
     Util method for Donation Total Map Creation from Bids

     @param bids - list of bids to process     
    */
    public static Map<Id, Decimal> CalculateDonationTotalMapFromBids(List<Bid__c> bids){

        Map<Id, Decimal> donationTotalMap = new Map<Id, Decimal>();

        for(Bid__c bid : bids){
            if(donationTotalMap.containsKey(bid.Donation__c)){
                Decimal totalDonation = donationTotalMap.get(bid.Donation__c);
                totalDonation += bid.Amount__c;
                donationTotalMap.put(bid.Donation__c, totalDonation);
            }
            else{
                donationTotalMap.put(bid.Donation__c, bid.Amount__c);
            }
        }

        return donationTotalMap;
    }

    /**
     Util method for Donation Total Map Creation from Donations

     @param donations - list of donations to process     
    */
    public static Map<Id, Decimal> CalculateDonationTotalMapFromDonations(List<Donation__c> donations){

        Map<Id, Decimal> donationTotalMap = new Map<Id, Decimal>();

        for(Donation__c donation : donations){
            donationTotalMap.put(donation.Id, donation.Total_Donation__c);
        }

        return donationTotalMap;
    }
    /**
     Util method for Donation Total Map and Item Highest Bid Map Comparison

     @param map1, map2 - maps to compare
     @return Boolean - True - if totals/Highest Bids are matching, false otherwise  
     @assumption - both maps are of same size  
    */
    public static Boolean CompareMaps(Map<Id, Decimal> map1, Map<Id, Decimal> map2){

        for(Id id : map1.keySet()){
            if(map1.get(id) != map2.get(id)){
                return FALSE;
            }
        }

        return TRUE;
    }

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
     Util method for Item Creation in Bulk

     @param upperLimitForMinimumBid - is the upper limit for the Minimum Bid Value
     @param futureClosingDate - Boolean which specifies whether the Closing Date is a future date or not

     i. The logic uses a default Lower limit of 1000 for the Minimum Bid value
     ii. The total number of items created = numberOfDonations * numberOfBidsPerDonation, 
         and hence, It's important to remember that the list of bids created as a result of 'CreateBidsBulk'
         WILL NOT CONTAIN more than 1 bid for the same item
    */

    public static List<Item__c> CreateItemsBulk(Integer upperLimitForMinimumBid, Boolean futureClosingDate){

        List<Item__c> items = new List<Item__c>();
        itemMap = new Map<Id, Item__c>();

        for(Integer i = 0; i < numberOfDonations * numberOfBidsPerDonation ; i++){

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