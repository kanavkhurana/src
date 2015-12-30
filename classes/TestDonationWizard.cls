//Visuaforce test
@isTest
public class TestDonationWizard{
public static testmethod void newDonationOnPageLoadTest()
{
//check if all items with close date in the future are appearing on the page - Loading condition for new donation 
    //Navigate to existing contact
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;
 
    List<Item__c> itemsWithAFutureClosingDate = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert itemsWithAFutureClosingDate;

    List<Item__c> itemsWithAPastClosingDate = TestDataGenerator.CreateItems(2000, 10, FALSE);
    insert itemsWithAPastClosingDate;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Fetch lstWrapper size
    system.assert(donationWizard.lstWrapper.size() == itemsWithAFutureClosingDate.size());
   
}

public static testmethod void existingDonationOnPageLoadTest(){
// check loading condition for existing donation

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    insert donations;

    List<Item__c> itemsWithAFutureClosingDate = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert itemsWithAFutureClosingDate;

    List<Item__c> itemsWithAPastClosingDate = TestDataGenerator.CreateItems(2000, 10, FALSE);
    insert itemsWithAPastClosingDate;

    //Associate 10 bids with items that have a past closing date
    List<Bid__c> bids = TestDataGenerator.CreateBids(donations, itemsWithAPastClosingDate, 10, donations.size(), itemsWithAPastClosingDate.size(), TRUE);
    insert bids;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Fetch lstWrapper size - 
    //The lstWrapper will include existing bids, ie, 10 + all items with a future closing date, ie, 10 + 10 = 20
    system.assert(donationWizard.lstWrapper.size() == 20);
 
}
public static testmethod void itemsToBeLoadedInOrderTest(){
//check if order of items is as per minimum bid field
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;

    List<Item__c> items = new List<Item__c>();
    //Using manual item creation here for ease of testing

    items.add(TestDataGenerator.CreateSingleItem(5000, 'Cat1'));
    items.add(TestDataGenerator.CreateSingleItem(4000, 'Cat1'));
    items.add(TestDataGenerator.CreateSingleItem(3000, 'Cat1'));
    items.add(TestDataGenerator.CreateSingleItem(2000, 'Cat1'));
    items.add(TestDataGenerator.CreateSingleItem(1000, 'Cat1'));
    
    insert items;
    
    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    Integer bwiCounter = 0;
    for(BidWithItemsWrapper bwi : donationWizard.lstWrapper){
        system.assert(bwi.item.Id == items.get(items.size() - bwiCounter - 1).Id);  
        bwiCounter++;
    }

}

//Included above
//check if order of items is as per minimum bid field

public static testmethod void categoriesToBeLoadedTest(){

//check if all categories have loaded
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;

    List<Item__c> items = new List<Item__c>();
    //Using manual item creation here for ease of testing

    items.add(TestDataGenerator.CreateSingleItem(5000,'Cat1'));
    items.add(TestDataGenerator.CreateSingleItem(4000,'Cat2'));
    items.add(TestDataGenerator.CreateSingleItem(3000,'Cat3'));
    items.add(TestDataGenerator.CreateSingleItem(2000,'Cat4'));
    items.add(TestDataGenerator.CreateSingleItem(1000,'Cat5'));

    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    Set<String> categorySet = new Set<String>();

    //Get Categories from the Controller and Create a set
    for(SelectOption category : donationWizard.getCategories()){

        categorySet.add(category.getValue());

    }
    for(Item__c item : items){
        system.assert(categorySet.contains(item.Category__c));
    }

}

public static testmethod void correctPageNumberTest(){

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);

    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Page number 1 shown 
    system.assert(donationWizard.getCurrentPage() == 1);

    //Checking 2 pages 
    system.assert(donationWizard.getTotalNumberOfPages() == 2);
    
    //Next page
    donationWizard.next();

    //Page number 2 shown
    system.assert(donationWizard.getCurrentPage() == 2);


}
public static testmethod void nextPageToBeShownTest(){

    //check Nextpagination
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;

    List<Item__c> items = TestDataGenerator.CreateItems(2000, 8, TRUE);
    insert items;
    
    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Check number of items shown on Page 1
    system.assert(donationWizard.lstSetController.size() == 5);

    //Call next()
    donationWizard.next();

    //Check number of items shown on Page 2
    system.assert(donationWizard.lstSetController.size() == 3);

}

public static testmethod void previousPageToBeShownTest(){
//check Previouspagination
//check Nextpagination
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;

    List<Item__c> items = TestDataGenerator.CreateItems(2000, 8, TRUE);
    insert items;
    
    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Check number of items shown on Page 1
    system.assert(donationWizard.lstSetController.size() == 5);

    //Call next()
    donationWizard.next();

    //Check number of items shown on Page 2
    system.assert(donationWizard.lstSetController.size() == 3);

    //Call previous()
    donationWizard.previous();

    system.assert(donationWizard.lstSetController.size() == 5);

}

public static testmethod void firstPageToBeShownTest(){

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;

    List<Item__c> items = new List<Item__c>();
    
    //Page 1
    items.add(TestDataGenerator.CreateSingleItem(1000,'Cat1'));
    items.add(TestDataGenerator.CreateSingleItem(2000,'Cat2'));
    items.add(TestDataGenerator.CreateSingleItem(3000,'Cat3'));
    items.add(TestDataGenerator.CreateSingleItem(4000,'Cat4'));
    items.add(TestDataGenerator.CreateSingleItem(5000,'Cat5'));

    //Page 2
    items.add(TestDataGenerator.CreateSingleItem(6000,'Cat1'));
    items.add(TestDataGenerator.CreateSingleItem(7000,'Cat2'));
    items.add(TestDataGenerator.CreateSingleItem(8000,'Cat3'));
    items.add(TestDataGenerator.CreateSingleItem(9000,'Cat4'));
    items.add(TestDataGenerator.CreateSingleItem(10000,'Cat5'));

    //Page 3
    items.add(TestDataGenerator.CreateSingleItem(11000,'Cat1'));
    items.add(TestDataGenerator.CreateSingleItem(12000,'Cat2'));
    items.add(TestDataGenerator.CreateSingleItem(13000,'Cat3'));
    items.add(TestDataGenerator.CreateSingleItem(14000,'Cat4'));
    items.add(TestDataGenerator.CreateSingleItem(15000,'Cat5'));

    insert items;
    
    system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, new List<Bid__c>()));

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Check number of items shown on Page 1
    system.assert(donationWizard.lstSetController.size() == 5);

    //Call next()
    donationWizard.next();

    //Check number of items shown on Page 2
    system.assert(donationWizard.lstSetController.size() == 5);

    //Call previous()
    donationWizard.next();

    system.assert(donationWizard.lstSetController.size() == 5);

    //Call first()
    donationWizard.first();

    system.debug('lstSetController: ' + donationWizard.lstSetController);

    Integer itemCounter = 0;

    for(BidWithItemsWrapper firstPage : donationWizard.lstSetController){
        system.assert(firstPage.item.Id == items.get(itemCounter).Id);
        itemCounter++;
    }

}

public static testmethod void lastPageToBeShownTest(){

//checkLastPagination
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;

    List<Item__c> items = new List<Item__c>();
    
    //Page 1
    items.add(TestDataGenerator.CreateSingleItem(1000,'Cat1'));
    items.add(TestDataGenerator.CreateSingleItem(2000,'Cat2'));
    items.add(TestDataGenerator.CreateSingleItem(3000,'Cat3'));
    items.add(TestDataGenerator.CreateSingleItem(4000,'Cat4'));
    items.add(TestDataGenerator.CreateSingleItem(5000,'Cat5'));

    //Page 2
    items.add(TestDataGenerator.CreateSingleItem(6000,'Cat1'));
    items.add(TestDataGenerator.CreateSingleItem(7000,'Cat2'));
    items.add(TestDataGenerator.CreateSingleItem(8000,'Cat3'));
    items.add(TestDataGenerator.CreateSingleItem(9000,'Cat4'));
    items.add(TestDataGenerator.CreateSingleItem(10000,'Cat5'));

    //Page 3
    items.add(TestDataGenerator.CreateSingleItem(11000,'Cat1'));
    items.add(TestDataGenerator.CreateSingleItem(12000,'Cat2'));
    items.add(TestDataGenerator.CreateSingleItem(13000,'Cat3'));
    items.add(TestDataGenerator.CreateSingleItem(14000,'Cat4'));
    items.add(TestDataGenerator.CreateSingleItem(15000,'Cat5'));

    insert items;
    
    system.debug('Serialized output: ' + TestDataGenerator.SerializeObjects(donors, donations, items, new List<Bid__c>()));

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Call last()
    donationWizard.last();
    
    system.debug('lstSetController: ' + donationWizard.lstSetController);

    Integer itemCounter = 0;

    for(BidWithItemsWrapper lastPage : donationWizard.lstSetController){
        system.assert(lastPage.item.Id == items.get(items.size() - 5 + itemCounter).Id);
        itemCounter++;
    }
}

//check FirstButtonAppearing
public static testmethod void firstButtonAppearingTest(){

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;
    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //First button should not be visible on the first page
    system.assert(!donationWizard.isNotFirst);

    //Next page
    donationWizard.next();

    //First button is visible now
    system.assert(donationWizard.isNotFirst);

}

public static testmethod void lastButtonAppearingTest(){

//check LastButtonAppearing
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;
    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Last button should be visible on the first page
    system.assert(donationWizard.isNotLast);

    //Next page
    donationWizard.last();

    //Last button should not be visible now
    system.assert(!donationWizard.isNotLast);

}

public static testmethod void previousButtonAppearingTest(){

    //check PreviousButtonAppearing

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;
    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Previous button should not be visible on the first page
    system.assert(!donationWizard.hasPrevious);

    //Next page
    donationWizard.next();

    //Previous button is visible now
    system.assert(donationWizard.hasPrevious);

}

public static testmethod void nextButtonAppearingTest(){

//check NextButtonAppearing
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;
    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Next button should be visible on the first page
    system.assert(donationWizard.hasNext);

    //Next page
    donationWizard.last();

    //Next button should not be visible now
    system.assert(!donationWizard.hasNext);

}

public static testmethod void itemListFilteredCorrectlyTest(){

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);

    //insert donations;
//check Filtering of Item list
    //Create 1000 items - 100 belong to each category from Cat1 to Cat10
    List<Item__c> items = new List<Item__c>();
    for(Integer i = 1 ; i <= 10 ; i++){
        for(Integer j = 0; j < 100; j++){
            items.add(TestDataGenerator.CreateSingleItem(1000, 'Cat ' + i));
        }
    }

    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Verify initial size
    system.assert(donationWizard.getFilteredItemSet().size() == 1000);

    donationWizard.selectedCategory = 'Cat 1';
    //Filter the List of Items
    donationWizard.filterList();

    system.assert(donationWizard.getFilteredItemSet().size() == 100);

}

public static testmethod void chartDisplayingCorrectlyTest(){
//chart working - refresh, etc. - including message to be displayed when no records exist

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    
    //Create a list of items - 100 each belonging to 10 Categories
    List<Item__c> items = new List<Item__c>();
    for(Integer i = 1 ; i <= 10 ; i++){
        for(Integer j = 0; j < 100; j++){
            items.add(TestDataGenerator.CreateSingleItem(1000*i, 'Cat ' + i));
        }
    }

    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Should see Message on Page load indicating that no bids have been made 
    system.assert(donationWizard.categoryTotalMapSize == 0);

    //PieData is blank
    system.assert(donationWizard.pieData.isEmpty());

    //Bid on all items on Page 1 - ie, USD 5000 increment for Cat 1
    for(BidWithItemsWrapper bwi: donationWizard.lstSetController){
        bwi.bid.Amount__c = 1000;
    }

    //Next page
    donationWizard.next();

    //Message on page will disappear
    system.assert(donationWizard.categoryTotalMapSize > 0);

    system.debug('categoryTotalMapSize: ' + donationWizard.categoryTotalMapSize);
    system.debug('pieData: ' + donationWizard.pieData);
    
    //Piedata shows correct figure of 5,000 for Cat 1
    system.assert(donationWizard.pieData.size() == 1);
    system.assert(donationWizard.pieData.get(0).name == 'Cat 1');
    system.assert(donationWizard.pieData.get(0).data == 5000);

     //Bid on all items on Page 2 - ie, USD 5000 increment for Cat 1
    for(BidWithItemsWrapper bwi: donationWizard.lstSetController){
        bwi.bid.Amount__c = 1000;
    }
    
    //Next page
    donationWizard.next();

    //Piedata shows correct figure of 10,000 for Cat 1
    system.assert(donationWizard.pieData.size() == 1);
    system.assert(donationWizard.pieData.get(0).name == 'Cat 1');
    system.assert(donationWizard.pieData.get(0).data == 10000);

    //Bid on all items on Page 3 - ie, USD 5000 increment for Cat 1
    for(BidWithItemsWrapper bwi: donationWizard.lstSetController){
        bwi.bid.Amount__c = 1000;
    }

    //Filter List
    donationWizard.selectedCategory = 'Cat 1';
    donationWizard.filterList();

    //Piedata shows correct figure of 15,000 for Cat 1
    system.assert(donationWizard.pieData.size() == 1);
    system.assert(donationWizard.pieData.get(0).name == 'Cat 1');
    system.assert(donationWizard.pieData.get(0).data == 15000);

}

public static testmethod void bidsSuccessfulDeletionTest(){

//deletion working - success
//Still Pending 
    
    //update working - success and failure
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    insert donations;

    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    //Associate 10 bids with items that have a past closing date
    List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 10, donations.size(), items.size(), TRUE);
    insert bids;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    Set<Id> bidIdSet = new Set<Id>();

    //Clear Bids on Page 1
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        bwi.bid.Amount__c =  0.00;
        bidIdSet.add(bwi.bid.Id);
    }

    //Click the 'Save' button
    PageReference donationPage = donationWizard.customSave();

    Id donationId = (Id)donationPage.getUrl().split('/').get(1);
    system.assert(donationId.getSObjectType().getDescribe().getName() == 'Donation__c');

    //Verify if the bids have been deleted
    //Query the bids from the DB
    system.assert([SELECT Id FROM Bid__c WHERE Id IN: bidIdSet].isEmpty());
    
}

public static testmethod void bidsUnsuccessfulDeletionTest(){

//deletion working - success
//Still Pending 
    
    //update working - success and failure
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    insert donations;

    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    //Associate 10 bids with items that have a past closing date
    List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 10, donations.size(), items.size(), TRUE);
    insert bids;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    Set<Id> bidIdSet = new Set<Id>();

    //Clear Bids on Page 1
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        bwi.bid.Amount__c =  0.00;
        bidIdSet.add(bwi.bid.Id);
    }

    //Set Static variable to TRUE
    BidManager.coverDeletionBlock = TRUE;

    //Click the 'Save' button
    PageReference error = donationWizard.customSave();
    
    BidManager.coverDeletionBlock = FALSE;


    //Stay on same page
    system.assert(error == NULL);

    List<ApexPages.Message> messages = Apexpages.getMessages();

    //Verify that FakeException was thrown
     Boolean fakeExceptionThrown = FALSE;

    for(ApexPages.Message message : messages){
        if(message.getDetail().contains('This is a fake exception'))
        {
            fakeExceptionThrown = TRUE;
        }
    }

    system.assert(fakeExceptionThrown);

    //Verify that the bids have NOT been deleted
    system.assert([SELECT Id FROM Bid__c WHERE Id IN: bidIdSet].size() > 0);
    
}

//No bids will be inserted if the amounts are blank
public static testmethod void noBidsInsertionTest(){

    //insertion working - success and failure
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);

    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Click on 'Save' button
    PageReference donationPage = donationWizard.customSave();

    //Redirected to Donation page
    Id donationId = (Id)donationPage.getUrl().split('/').get(1);

    system.assert(donationId.getSObjectType().getDescribe().getName() == 'Donation__c');

    //Verify if a donation was created
    Donation__c donation =  [SELECT Id FROM Donation__c WHERE Donor__c =: donors.get(0).Id];
    
    //Verify that no bids were created under the donation
    system.assert([SELECT COUNT() FROM Bid__c WHERE Donation__c =: donation.Id] == 0);

}
public static testmethod void bidsSuccessfulInsertionTest(){

//insertion working - success

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);

    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Add Amount entries to Page 1
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        //Bidding USD 1000 higher than the upper Limit for the items
        bwi.bid.Amount__c = 3000;
    }

    //Next page
    donationWizard.next();

    //Add Amount entries to Page 2
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        //Bidding USD 1000 higher than the upper Limit for the items
        bwi.bid.Amount__c = 3000;
    }

    //Click on 'Save' button
    donationWizard.customSave();

    //Verify if a donation was created
    Donation__c donation =  [SELECT Id FROM Donation__c WHERE Donor__c =: donors.get(0).Id];
    
    //Verify if bids were created under the donation
    system.assert([SELECT COUNT() FROM Bid__c WHERE Donation__c =: donation.Id] == 10);

}

public static testmethod void bidsUnsuccessfulInsertionTest(){

    //insert working - failure
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;

    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    //Generate Item Id > Minimum Bid Map
    Map<Id, Decimal> itemIdMinimumBidMap = new Map<Id, Decimal>();
    
    for(Item__c item : items){
        itemIdMinimumBidMap.put(item.Id, item.Minimum_Bid__c);
    }
    //Generate some invalid Bids
    //List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 10, donations.size(), items.size(), FALSE);
    //insert bids;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));
    //Map<Id, Decimal> bidAmountMap = new Map<Id, Decimal>();

    //Update Bids on Page 1 with amounts less than the Item's minimum bid
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        bwi.bid.Amount__c =  itemIdMinimumBidMap.get(bwi.item.Id) - 500;
    }

    //Click the 'Save' button
    PageReference error = donationWizard.customSave();

    //Same page returned
    system.assert(error == NULL);

    List<Apexpages.Message> messages = ApexPages.getMessages();

    //Validate error message returned
    Boolean errorMessageReturned = FALSE;
    //system.assert(messages.get(0))
    for(Apexpages.Message message : messages){
        if(message.getDetail().contains(System.Label.UpsertFailure_1)){
            errorMessageReturned = TRUE;
        }
    }

    system.assert(errorMessageReturned);

    //Verify that no bids have been inserted
    system.assert([SELECT COUNT() FROM Bid__c] == 0);

}

public static testmethod void bidsSuccessfulUpdateTest(){

//update working - success 
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    insert donations;

    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    //Associate 10 bids with items that have a past closing date
    List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 10, donations.size(), items.size(), TRUE);
    insert bids;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));
    Map<Id, Decimal> bidAmountMap = new Map<Id, Decimal>();

    //Update Bids on Page 1 - increase amount by 1000 USD
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        bwi.bid.Amount__c =  bwi.bid.Amount__c + 1000;
        bidAmountMap.put(bwi.bid.Id, bwi.bid.Amount__c);
    }

    //Next page

    donationWizard.next();

    //Update Bids on Page 2 - increase amount by 1000 USD
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        bwi.bid.Amount__c =  bwi.bid.Amount__c + 1000;
        bidAmountMap.put(bwi.bid.Id, bwi.bid.Amount__c);
    }

    //Click the 'Save' button
    donationWizard.customSave();

    //Verify if the bids have updated
    //Query the bids from the DB
    Map<Id, Bid__c> bidDBMap = new Map<Id, Bid__c>([SELECT Id,Amount__c FROM Bid__c]);

    //Match bidDBMap with bidAmountMap
    for(Id bidId : bidDBMap.keySet()){
        system.assert(bidDBMap.get(bidId).Amount__c == bidAmountMap.get(bidId));
    }

}
//Since we have already covered the upsert block in the unsuccessfulInsert test, this has been skipped
//In order to execute this method - a FakeException would have to be thrown
public static testmethod void bidsUnsuccessfulUpdateTest(){

}

public static testmethod void fakeExceptionTest(){
    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;

    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    //insert donations;

    //Start with a blank donation
    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    CustomPaginationDemo.coverCatchBlock = TRUE;

    PageReference error = donationWizard.customSave();
    
    CustomPaginationDemo.coverCatchBlock = FALSE;

    //On same page
    system.assert(error == NULL);

    List<Apexpages.Message> messages = ApexPages.getMessages();

    Boolean fakeExceptionThrown = FALSE;

    for(ApexPages.Message message : messages){
        if(message.getDetail().contains('This is a fake exception'))
        {
            fakeExceptionThrown = TRUE;
        }
    }

    system.assert(fakeExceptionThrown);

}

public static testmethod void blankDonationDonorValidationTest(){
//ERROR
//submitting a blank donation - either of the reqd fields are blank
    
    PageReference pageRef = Page.ItemDisplay_v2;
    Test.setCurrentPage(pageRef); 

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;

    //Start with a blank donation
    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(new Donation__c(Status__c = 'New')));

    //Save the page
    donationWizard.customSave();

    List<Apexpages.Message> messages = ApexPages.getMessages();
    
    system.debug('error messages: ' + messages);
    
    system.assert(messages.get(0).getComponentLabel() == 'Donor');
    system.assert(messages.get(0).getDetail() == System.Label.ValueRequired);

    //Specify a donor
    donationWizard.donation.Donor__c = donors.get(0).Id;

    Test.setCurrentPage(pageRef); 

    //Save the page
    PageReference donationPage = donationWizard.customSave();
    //system.debug('donationPage: ' + JSON.serialize(donationPage));
    //system.debug('donationPage: ' + donationPage.getUrl());
    Id donationId = (Id)donationPage.getUrl().split('/').get(1);
    system.assert(donationId.getSObjectType().getDescribe().getName() == 'Donation__c');

}

public static testmethod void blankDonationStatusValidationTest(){
//ERROR
//submitting a blank donation - either of the reqd fields are blank
    
    PageReference pageRef = Page.ItemDisplay_v2;
    Test.setCurrentPage(pageRef); 

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;

    //Start with a blank donation
    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(new Donation__c(Donor__c = donors.get(0).Id)));

    //Save the page
    donationWizard.customSave();

    List<Apexpages.Message> messages = ApexPages.getMessages();
    
    system.debug('error messages: ' + messages);
    
    system.assert(messages.get(0).getComponentLabel() == 'Status');
    system.assert(messages.get(0).getDetail() == System.Label.ValueRequired);

    //Specify a donor
    donationWizard.donation.Status__c = 'New';

    Test.setCurrentPage(pageRef); 

    //Save the page
    PageReference donationPage = donationWizard.customSave();
    //system.debug('donationPage: ' + JSON.serialize(donationPage));
    //system.debug('donationPage: ' + donationPage.getUrl());
    Id donationId = (Id)donationPage.getUrl().split('/').get(1);
    system.assert(donationId.getSObjectType().getDescribe().getName() == 'Donation__c');

}

public static testmethod void blankBidValidationTest(){
//ERROR
//submitting a blank bid - the amount field is blank
    PageReference pageRef = Page.ItemDisplay_v2;
    Test.setCurrentPage(pageRef); 

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Clearing bid Amount values on Page 1
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        bwi.bid.Amount__c = NULL;
    }

    //Click on the 'Save' button
    PageReference error = donationWizard.customSave();

    //Stay on same page
    system.assert(error == NULL);

    List<Apexpages.Message> messages = ApexPages.getMessages();

    system.assert(messages.get(0).getComponentLabel() == 'Amount');
    system.assert(messages.get(0).getDetail() == System.Label.ValueRequired);

    //Refill bid Amount values on Page 1
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        bwi.bid.Amount__c = 0.00;
    }

    //Click on the 'Save' button
    PageReference donationPage = donationWizard.customSave();

    Id donationId = (Id)donationPage.getUrl().split('/').get(1);
    system.assert(donationId.getSObjectType().getDescribe().getName() == 'Donation__c');


}
    
public static testmethod void blankBidFilterTest(){
//ERROR
//filtering a blank bid - the amount field is blank

    PageReference pageRef = Page.ItemDisplay_v2;
    Test.setCurrentPage(pageRef); 

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Update bid Amount values on Page 1
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        bwi.bid.Amount__c = bwi.bid.Amount__c + 1000;
    }

    //Next page
    donationWizard.next();

    List<Apexpages.Message> messages = ApexPages.getMessages();

    system.assert(messages.isEmpty());

    //Clear amount values on Page 2
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        bwi.bid.Amount__c = NULL;
    }

    //Previous page
    //donationWizard.previous();
    donationWizard.selectedCategory = items.get(0).Category__c;
    donationWizard.filterList();

    messages = ApexPages.getMessages();

    for(Apexpages.message msg : messages){
        system.debug('msg component: ' + msg.getComponentLabel());
        system.debug('msg detail: ' + msg.getDetail());
            
    }
    system.assert(messages.get(0).getComponentLabel() == 'Amount');
    system.assert(messages.get(0).getDetail() == System.Label.ValueRequired);
}

public static testmethod void blankBidPaginationTest(){
//ERROR
//paginating a blank bid - the amount field is blank

    PageReference pageRef = Page.ItemDisplay_v2;
    Test.setCurrentPage(pageRef); 

    List<Contact> donors = TestDataGenerator.CreateDonors(1);
    insert donors;
    List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
    List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
    insert items;

    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donations.get(0)));

    //Update bid Amount values on Page 1
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        bwi.bid.Amount__c = bwi.bid.Amount__c + 1000;
    }

    //Next page
    donationWizard.next();

    List<Apexpages.Message> messages = ApexPages.getMessages();

    system.assert(messages.isEmpty());

    //Clear amount values on Page 2
    for(BidWithItemsWrapper bwi : donationWizard.lstSetController){
        bwi.bid.Amount__c = NULL;
    }

    //Previous page
    donationWizard.previous();

    messages = ApexPages.getMessages();

    for(Apexpages.message msg : messages){
        system.debug('msg component: ' + msg.getComponentLabel());
        system.debug('msg detail: ' + msg.getDetail());
            
    }
    system.assert(messages.get(0).getComponentLabel() == 'Amount');
    system.assert(messages.get(0).getDetail() == System.Label.ValueRequired);
}

//Since Controller has 'with sharing' enabled - the user only sees records he/she owns - as OWD is Private for Donations
public static testmethod void donationVisibleTest(){

User auctioneer1 = TestDataGenerator.CreateUser('Auctioneer');
User auctioneer2 = TestDataGenerator.CreateUser('Auctioneer');

insert auctioneer1;
insert auctioneer2;

system.debug('auctioneer1: ' + auctioneer1);
system.debug('auctioneer2: ' + auctioneer2);

 List<Contact> donorList1 = TestDataGenerator.CreateDonors(1);
insert donorList1;
List<Donation__c> donationList1 = TestDataGenerator.CreateDonations(donorList1, FALSE);

//Change Donation Owner to Auctioneer 1
donationList1.get(0).OwnerId = auctioneer1.Id;
insert donationList1;

List<Contact> donorList2 = new List<Contact>();
donorList2 = TestDataGenerator.CreateDonors(1);
insert donorList2;

List<Donation__c> donationList2 = new List<Donation__c>();
donationList2 = TestDataGenerator.CreateDonations(donorList2, FALSE);

//Change Donation Owner to Auctioneer 2
donationList2.get(0).OwnerId = auctioneer2.Id;
insert donationList2;

try{
//Auctioneer 1 should not see Auctioneer 2's donations on the DonationWizard
System.RunAs(auctioneer1) {
           CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donationList2.get(0)));
            
        }

}
catch(System.QueryException ex){
    system.assert(ex.getMessage().contains('List has no rows for assignment to SObject'));
}

//However, he can see his own Donation Records
System.RunAs(auctioneer1){
    CustomPaginationDemo donationWizard = new CustomPaginationDemo(new ApexPages.StandardController(donationList1.get(0)));

}

}

}