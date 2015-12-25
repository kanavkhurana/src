@isTest
public class TestDataGenerator{

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
    public static List<Contact> CreateDonors(){

        List<Contact> donors = new List<Contact>();

    //query from CS = NumberOfDonors
        /*if(testVolume == NULL){

            testVolume = [SELECT NoOfBidsPerDonation__c, NoOfDonations__c, NoOfDonors__c, NoOfItems__c
            FROM TestVolume__c
            WHERE Name = 'TestVolume'
            LIMIT 1];
        }*/

    //Loop through number of Donors
        for(Integer i = 0; i < testVolume.NoOfDonors__c ; i++ ){

            donors.add(new Contact(FirstName = 'Test', LastName = 'User ' + i));
        }

    //SetDefaultFields('Contact', donors);
        insert donors;
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

        insert donations;
        return donations;
    }


    //Taken care in above function
    /*public static void LinkDonorToDonation(Id donorId, Donation__c donation){

        
        donation.Donor__c = donorId;

    }*/

    public static List<Bid__c> CreateBids(List<Id> donationIds, List<Id> itemIds, Integer upperLimitForAmount){

        List<Bid__c> bids = new List<Bid__c>();

        Integer bidCounter = Integer.valueOf(Math.min(testVolume.NoOfBidsPerDonation__c,testVolume.NoOfItems__c)); 

        for(Integer i = 0; i < bidCounter ; i++){

            bids.add(new Bid__c(Amount__c = Math.round(Math.random()*upperLimitForAmount),
                                Item__c = itemIds.get(i),
                                Donation__c = donationIds.get(i)
                                ));

        }   

        insert bids;
        return bids;

    }

    //Taken care in above function

    /*public static void LinkBidToDonationAndItem(Bid__c bid, Id donationId, Id itemId){

        bid.Donation__c = donationId;
        bid.Item__c = itemId;

    }*/

    public static List<Item__c> CreateItems(Integer upperLimitForMinimumBid){

        List<Item__c> items = new List<Item__c>();

        for(Integer i =0; i< testVolume.NoOfItems__c ; i++){

            //Choosing Categories from Cat 1 - Cat 10
            items.add(new Item__c(Name = 'Item ' + i, 
                                  Category__c = 'Cat ' + (Math.round(Math.random()*9)  + 1),
                                  Closing_Date__c = Date.today().addDays(Math.round(Math.random()*366)),
                                  Minimum_Bid__c = Math.round(Math.random()*upperLimitForMinimumBid)
                                  ));

        }

        insert items;
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