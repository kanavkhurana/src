@isTest
public class TestDataGenerator{
    public static Map<Id, Item__c> itemMap;
    public static Map<Id, Decimal> itemIdHighestBidMap;
    public static Map<Id, Decimal> donationIdTotalMap;
    public static Integer numberOfBidsLessThanHighestBid = 0;

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
    public static String SerializeObjects(List<sObject> list1, List<sObject> list2, List<sObject> list3, List<sObject> list4){

        String json1 = JSON.serializePretty(list1);
        String json2 = JSON.serializePretty(list2);
        String json3 = JSON.serializePretty(list3);
        String json4 = JSON.serializePretty(list4);

        return json1 + json2 + json3 + json4;

    }
    public static List<Contact> CreateDonors(Integer noOfDonors){

        List<Contact> donors = new List<Contact>();

    //Loop through number of Donors
        for(Integer i = 0; i < noOfDonors ; i++ ){

            donors.add(new Contact(FirstName = 'Test', LastName = 'User ' + i));
        }

    //SetDefaultFields('Contact', donors);
        //insert donors;
        return donors;

    }
      public static List<Contact> CreateDonorsBulk(){

        List<Contact> donors = new List<Contact>();

    //Loop through number of Donors
        for(Integer i = 0; i < testVolume.NoOfDonations__c ; i++ ){

            donors.add(new Contact(FirstName = 'Test', LastName = 'User ' + i));
        }

    //SetDefaultFields('Contact', donors);
        //insert donors;
        return donors;

    }



    //Pass donors and this method creates 1 donation per donor
    //KK: Is this acceptable or do we keep this configurable??
    public static List<Donation__c> CreateDonations(List<Contact> donors)
    {

        List<Donation__c> donations = new List<Donation__c>();

//query from CS = Number Of Donations2

        //for(Integer i = 0; i < testVolume.NoOfDonations__c ; i++ ){
        for(Contact donor : donors)
        {
            donations.add(new Donation__c(Status__c = 'New', Donor__c = donor.Id));
        }   

        //insert donations;
        return donations;
    }


    //Taken care in above function
    /*public static void LinkDonorToDonation(Id donorId, Donation__c donation){

        
        donation.Donor__c = donorId;

    }*/

    //noOfInvalidBids indicates the number of Bids whose amount will be less than equal to Item > Highest Bid or Less than Minimum Bid
    //KK: noOfInvalidBids to be shifted to the Custom setting?
    //KK: Can Limit CreateBids to Only creation of Bids
    //KK: Can create another method called ProcessBids to calculate the other metrics - Yes - the processing should be done separately
    //Must explain logic for creation of bids - very crucial
    public static List<Bid__c> CreateBids(List<Donation__c> donations, List<Item__c> items, Integer noOfBidsPerDonation,
                                          Integer noOfDonations,
                                          Integer noOfItems,
                                          Boolean bidsValid){

        List<Bid__c> bids = new List<Bid__c>();

        if(itemIdHighestBidMap == NULL){
            itemIdHighestBidMap = new Map<Id, Decimal>();
        }

        //Integer bidCounter = Integer.valueOf(Math.min(testVolume.NoOfBidsPerDonation__c,testVolume.NoOfItems__c)); 
        //Integer donationCounter = 0;
        Integer countInvalidBids = 0 ;
        Integer totalNumberOfBids = noOfBidsPerDonation * noOfDonations;
        
        for(Integer bidCounter = 0; bidCounter < totalNumberOfBids ; bidCounter++){

            Item__c relatedItem = items.get(Math.mod(bidCounter,noOfItems));

            Bid__c bid = new Bid__c(Item__c = relatedItem.Id,
                                Donation__c = donations.get(bidCounter / noOfBidsPerDonation).Id
                                );
         if(bidsValid){
            
            //Ensure that the amount chosen is greater than the Related Item's Minimum Bid
            if(itemIdHighestBidMap.containsKey(bid.Item__c)){
                bid.Amount__c = itemIdHighestBidMap.get(bid.Item__c) + 1000;
                itemIdHighestBidMap.put(bid.Item__c, bid.Amount__c);
                //Is this correct??
                //numberOfBidsLessThanHighestBid++ ;
            }
            else{
                bid.Amount__c = relatedItem.Minimum_Bid__c + 1000;
                itemIdHighestBidMap.put(bid.Item__c, bid.Amount__c);
            }

            }
            else{
                //Reduce the amount by USD 1000 from the Related Item's Minimum Bid to make it invalid
                bid.Amount__c = relatedItem.Minimum_Bid__c - 1000;
            }
                
                bids.add(bid);
            }

         
        //List<Bid__c> successfulBids = new List<Bid__c>();

        //Calculate Utility Maps that will be used for assertion
        //KK: To be created as separate functions in the test class
        // successfulBids = CalculateItemIdHighestBidMap(bids);
        //No. of successful bids = Initial bids - numberofInvalidBids - numberOfBidsLessThanHighestBid

        //CalculateSuccessfulBids(bids);     
        //CalculateDonationIdTotalMap(successfulBids);

        //insert bids;
        return bids;

    }
    //Make the last 2 item cycles having the same amount
    
    public static List<Bid__c> CreateCompetingBids(List<Donation__c> donations, List<Item__c> items, Integer noOfBidsPerDonation,
                                                   Integer noOfDonations,
                                                   Integer noOfItems){
            /*for(bidCounter = 0 ; bidCounter < noOfItems * 2 ; bidCounter ++){
                //get amount from highest bid map that you have constructed
                Bid__c bid = bids.get(totalNumberOfBids - bidCounter - 1);
                bid.Amount__c = itemIdHighestBidMap.get(bid.Item__c);
            }*/
         List<Bid__c> bids = new List<Bid__c>();

        //if(itemIdHighestBidMap == NULL){
         //   itemIdHighestBidMap = new Map<Id, Decimal>();
        //}

        //Integer bidCounter = Integer.valueOf(Math.min(testVolume.NoOfBidsPerDonation__c,testVolume.NoOfItems__c)); 
        //Integer donationCounter = 0;
        Integer totalNumberOfBids = noOfBidsPerDonation * noOfDonations;
        
        for(Integer bidCounter = 0; bidCounter < totalNumberOfBids ; bidCounter++){

            Item__c relatedItem = items.get(Math.mod(bidCounter,noOfItems));

            Bid__c bid = new Bid__c(Item__c = relatedItem.Id,
                                Donation__c = donations.get(bidCounter / noOfBidsPerDonation).Id
                                );
         //if(bidsValid){
            
            //Ensure that the amount chosen is greater than the Related Item's Minimum Bid
            if(itemIdHighestBidMap.containsKey(bid.Item__c)){
                bid.Amount__c = itemIdHighestBidMap.get(bid.Item__c);
                //Is this correct??
                //numberOfBidsLessThanHighestBid++ ;
            }
            //else{
            //    bid.Amount__c = relatedItem.Minimum_Bid__c + 1000;
            //    itemIdHighestBidMap.put(bid.Item__c, bid.Amount__c);
            //}

            //}
            //else{
                //Reduce the amount by USD 1000 from the Related Item's Minimum Bid to make it invalid
            //    bid.Amount__c = relatedItem.Minimum_Bid__c - 1000;
            //}
                
                bids.add(bid);
            }

         
        //List<Bid__c> successfulBids = new List<Bid__c>();

        //Calculate Utility Maps that will be used for assertion
        //KK: To be created as separate functions in the test class
        // successfulBids = CalculateItemIdHighestBidMap(bids);
        //No. of successful bids = Initial bids - numberofInvalidBids - numberOfBidsLessThanHighestBid

        //CalculateSuccessfulBids(bids);     
        //CalculateDonationIdTotalMap(successfulBids);

        //insert bids;
        return bids;

    }
    public static List<Bid__c> CreateBidsBulk(List<Id> donationIds, List<Id> itemIds){

        List<Bid__c> bids = new List<Bid__c>();
        itemIdHighestBidMap = new Map<Id, Decimal>();

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
            if(itemIdHighestBidMap.containsKey(bid.Item__c)){
                bid.Amount__c = itemIdHighestBidMap.get(bid.Item__c) + 1000;
                //Is this correct??
                //numberOfBidsLessThanHighestBid++ ;
            }
            else{
                bid.Amount__c = relatedItem.Minimum_Bid__c + 1000;
                itemIdHighestBidMap.put(bid.Item__c, bid.Amount__c);
            }

            //}
            //else{
                //Reduce the amount by USD 1000 from the Related Item's Minimum Bid to make it invalid
                //bid.Amount__c = relatedItem.Minimum_Bid__c - 1000;
                //countInvalidBids++;
            //}

            bids.add(bid);
        }
        /*
         //Make the last 2 item cycles having the same amount
            for(bidCounter = 0 ; bidCounter < testVolume.NoOfItems__c * 2 ; bidCounter ++){
                //get amount from highest bid map that you have constructed
                bid = new Bid__c();
                bid = bids.get(totalNumberOfBids - bidCounter - 1);
                bid.Amount__c = itemIdHighestBidMap.get(bid.Item__c);
            } 
            */
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

    //Taken care in above function

    /*public static void LinkBidToDonationAndItem(Bid__c bid, Id donationId, Id itemId){

        bid.Donation__c = donationId;
        bid.Item__c = itemId;

    }*/
    
    //Should these utility methods be part of the main test class?
    public static List<Bid__c> CalculateItemIdHighestBidMap(List<Bid__c> bids){

    itemIdHighestBidMap = new Map<Id, Decimal>();
    List<Bid__c> successfulBids = new List<Bid__c>();
    Set<Id> itemIdsCovered = new Set<Id>();

    for(Bid__c bid : bids){
            if(itemIdHighestBidMap.containsKey(bid.Item__c)){
                Decimal highestBidAmount = itemIdHighestBidMap.get(bid.Item__c);
                if(bid.Amount__c > highestBidAmount){
                    itemIdHighestBidMap.put(bid.Item__c, bid.Amount__c);
                    //numberOfBidsLessThanHighestBid++;
                }
            }
        }
    
        for(Bid__c bid : bids){
                Decimal highestBidForItem = itemIdHighestBidMap.get(bid.Item__c);
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

    //All items created with blank Highest Bid as that will be populated by our Logic
    
    //Should we give flexibility of giving count of number of Items with a Highest Bid and 
    //a count of items without a Highest Bid?
    public static List<Item__c> CreateItems(Integer upperLimitForMinimumBid, Integer noOfItems){

        List<Item__c> items = new List<Item__c>();
        itemMap = new Map<Id, Item__c>();

        for(Integer i = 0; i < noOfItems ; i++){

            //Choosing Categories from Cat 1 - Cat 10
            items.add(new Item__c(Name = 'Item ' + i, 
                                  Category__c = 'Cat ' + (Math.round(Math.random()*9)  + 1),
                                  Closing_Date__c = Date.today().addDays(Math.round(Math.random()*366)),
                                  Minimum_Bid__c = Math.round(Math.random()*upperLimitForMinimumBid)
                                  ));

        }

        //insert items;

        //Item Map populated
        /*for(Item__c item : items){
            itemMap.put(item.Id, item);
        }*/

        return items;
    }

    public static List<Item__c> CreateItemsBulk(Integer upperLimitForMinimumBid){

        List<Item__c> items = new List<Item__c>();
        itemMap = new Map<Id, Item__c>();

        for(Integer i = 0; i < testVolume.NoOfItems__c ; i++){

            //Choosing Categories from Cat 1 - Cat 10
            items.add(new Item__c(Name = 'Item ' + i, 
                                  Category__c = 'Cat ' + (Math.round(Math.random()*9)  + 1),
                                  Closing_Date__c = Date.today().addDays(Math.round(Math.random()*366)),
                                  Minimum_Bid__c = Math.round(Math.random()*upperLimitForMinimumBid)
                                  ));

        }

        insert items;

        //Item Map populated
        for(Item__c item : items){
            itemMap.put(item.Id, item);
        }

        return items;
    }

//Not using as of now
//To set default fields
    /*
    public static Boolean SetDefaultFields(String objecttype, List<SObject> theobjects)
    {
        List<StaticResource> resources = [Select Body from StaticResource where Name = 'DefaultValues' ];
        if(resources.size()==0) return false;
        String contents = resources[0].Body.ToString();
        if(contents==null) return false;
        List<String> lines = contents.split('\\n');
        for(String line:lines)
        {
            List<String> entries = line.split(':');
            try
            {
                if(entries[0]==objecttype)
                {
                    List<String> fieldinfo = entries[1].split('=');
                    for(SObject obj: theobjects)
                    {
                        obj.put(fieldinfo[0], fieldinfo[1]);    // Implemented only for strings
                    }
                }
            }
            catch(Exception ex){}
        }
        return false;
    }
    */

}