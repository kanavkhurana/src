//Test class for update logic
//Separate methods for single and bulk tests should be written to validate functionality
//Single methods are as important as bulk methods
@isTest
public class DonationUpdateSingleOperations{
    

public static testmethod void donationTotalTest(){

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors);
    insert donations;
    List<Item__c> items = TestDataGenerator.CreateItems(2000, 4);
    insert items;
    List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 5, donations.size(), items.size(), TRUE);
    
    system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, bids));

    Test.startTest();
    insert bids;
    Test.stopTest();

    //Query Bids to get total
    Integer bidTotal = (Integer)[SELECT SUM(Amount__c) bidTotal FROM Bid__c].get(0).get('bidTotal');
    system.assert(donations.get(0).Total_Donation__c == bidTotal);

}


}