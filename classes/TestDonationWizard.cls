/**
Purpose:
This test class validates the Donation Wizard logic that is a part of the application
Testing done for the Visulforce page is based on Custom Use Cases calling the non-bulk Data Creation methods
of the TestDataGenerator
However, manual testing has been done in the Org with the data volumes mentioned in the Assignment Document
*/
@isTest
public class TestDonationWizard{
    /**
    Wrappers for Items with Closing Date >= Today are created on New Donation Page Load
    */
    public static testmethod void newDonationOnPageLoadTest()
    {
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        List<Item__c> itemsWithAFutureClosingDate = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert itemsWithAFutureClosingDate;
        
        List<Item__c> itemsWithAPastClosingDate = TestDataGenerator.CreateItems(2000, 10, FALSE);
        insert itemsWithAPastClosingDate;
        
        //Open the Page
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Check if all items with a future closing date are being queried
        system.assert(donationWizard.completeWrapperList.size() == itemsWithAFutureClosingDate.size());
        
    }
    /**
    For Existing Donation Page Load, wrappers are created for
        - All Current Bids
        - Items with Closing Date >= Today
    */
    public static testmethod void existingDonationOnPageLoadTest(){
        
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        
        List<Item__c> itemsWithAFutureClosingDate = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert itemsWithAFutureClosingDate;
        
        List<Item__c> itemsWithAPastClosingDate = TestDataGenerator.CreateItems(2000, 10, FALSE);
        insert itemsWithAPastClosingDate;
        
        //Associate 10 bids with items that have a past closing date
        List<Bid__c> bids = TestDataGenerator.CreateBids(donations, itemsWithAPastClosingDate, 10, TRUE);
        insert bids;
        
        //Open the Page
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //The completeWrapperList will include existing bids, ie, 
        //10 Wrapper rows, EVEN IF THEIR Closing Dates are in the Past
        //Add to this, all items with a future closing date,
        //ie, 10 + 10 = 20
        system.assert(donationWizard.completeWrapperList.size() == 20);
        
    }
    /**
    Items to be loaded in order of Minimum Bid
    */
    public static testmethod void itemsToBeLoadedInOrderTest(){
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        List<Item__c> items = new List<Item__c>();
        
        //Creating 5 items
        //Using manual item creation here for ease of testing
        //Params passed are Minimum Bid and Category
        items.add(TestDataGenerator.CreateSingleItem(5000, 'Cat1'));
        items.add(TestDataGenerator.CreateSingleItem(4000, 'Cat1'));
        items.add(TestDataGenerator.CreateSingleItem(3000, 'Cat1'));
        items.add(TestDataGenerator.CreateSingleItem(2000, 'Cat1'));
        items.add(TestDataGenerator.CreateSingleItem(1000, 'Cat1'));
        
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        Integer bwiCounter = 0;

        //The wrapper list is sorted in ascending order of Minimum Bid
        for(BidWithItemsWrapper bwi : donationWizard.completeWrapperList){
            system.assert(bwi.item.Id == items.get(items.size() - bwiCounter - 1).Id);  
            bwiCounter++;
        }
        
    }
    
    /**
    All Item Categories to be loaded in the Dropdown value
    */
    public static testmethod void categoriesToBeLoadedTest(){
        
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        List<Item__c> items = new List<Item__c>();
        
        //Using manual item creation here for ease of testing
        items.add(TestDataGenerator.CreateSingleItem(5000,'Cat1'));
        items.add(TestDataGenerator.CreateSingleItem(4000,'Cat2'));
        items.add(TestDataGenerator.CreateSingleItem(3000,'Cat3'));
        items.add(TestDataGenerator.CreateSingleItem(2000,'Cat4'));
        items.add(TestDataGenerator.CreateSingleItem(1000,'Cat5'));
        
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        Set<String> categorySet = new Set<String>();
        
        //Get Categories from the Controller and Create a set
        for(SelectOption category : donationWizard.getCategories()){
            
            categorySet.add(category.getValue());
            
        }
        //Verify if all Item categories have been loaded
        for(Item__c item : items){
            system.assert(categorySet.contains(item.Category__c));
        }
        
    }
    
    /**
    Correct Page number to be shown
    */
    public static testmethod void correctPageNumberTest(){
        
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Page number 1 shown 
        system.assert(donationWizard.getCurrentPage() == 1);
        
        //Total no. of pages = 2 
        system.assert(donationWizard.getTotalNumberOfPages() == 2);
        
        //Next page
        donationWizard.next();
        
        //Page number 2 shown
        system.assert(donationWizard.getCurrentPage() == 2);
        
        
    }
    /**
    Next Page to be shown
    */
    public static testmethod void nextPageToBeShownTest(){
        
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //A total of 8 items inserted
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 8, TRUE);
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Check number of items shown on Page 1
        system.assert(donationWizard.paginatedWrapperList.size() == 5);
        
        //Call next()
        donationWizard.next();
        
        //Check number of items shown on Page 2
        system.assert(donationWizard.paginatedWrapperList.size() == 3);
        
    }
    
    /**
    Previous Page to be shown
    */
    public static testmethod void previousPageToBeShownTest(){
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //A total of 8 items to be inserted
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 8, TRUE);
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Check number of items shown on Page 1
        system.assert(donationWizard.paginatedWrapperList.size() == 5);
        
        //Call next()
        donationWizard.next();
        
        //Check number of items shown on Page 2
        system.assert(donationWizard.paginatedWrapperList.size() == 3);
        
        //Call previous()
        donationWizard.previous();
        
        //Back on Page 1
        system.assert(donationWizard.paginatedWrapperList.size() == 5);
        
    }
    
    /**
    First Page to be shown
    */
    public static testmethod void firstPageToBeShownTest(){
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
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
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Check number of items shown on Page 1
        system.assert(donationWizard.paginatedWrapperList.size() == 5);
        
        //Call next()
        donationWizard.next();
        
        //Check number of items shown on Page 2
        system.assert(donationWizard.paginatedWrapperList.size() == 5);
        
        //Call next()
        donationWizard.next();
        
        //Check number of items shown on Page 3
        system.assert(donationWizard.paginatedWrapperList.size() == 5);
        
        //Call first()
        donationWizard.first();
        
        system.debug('paginatedWrapperList: ' + donationWizard.paginatedWrapperList);
        
        Integer itemCounter = 0;
        
        //Bids for the First 5 Items to be shown
        for(BidWithItemsWrapper firstPage : donationWizard.paginatedWrapperList){
            system.assert(firstPage.item.Id == items.get(itemCounter).Id);
            itemCounter++;
        }
        
    }
    /**
    Last Page to be shown
    */
    public static testmethod void lastPageToBeShownTest(){
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
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
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Call last()
        donationWizard.last();
        
        system.debug('paginatedWrapperList: ' + donationWizard.paginatedWrapperList);
        
        Integer itemCounter = 0;
        
        //Bids for the Last 5 items to be shown
        for(BidWithItemsWrapper lastPage : donationWizard.paginatedWrapperList){
            system.assert(lastPage.item.Id == items.get(items.size() - 5 + itemCounter).Id);
            itemCounter++;
        }
    }
    
    /**
    First button to be shown?
    */
    public static testmethod void firstButtonAppearingTest(){
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //Creating 10 items, ie, 2 pages with 5 items each
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //First button should not be visible on the first page
        system.assert(!donationWizard.isNotFirst);
        
        //Next page
        donationWizard.next();
        
        //First button is visible now
        system.assert(donationWizard.isNotFirst);
        
    }
    /**
    Last button to be shown?
    */
    public static testmethod void lastButtonAppearingTest(){
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //Creating 10 items, ie, 2 pages with 5 items each
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Last button should be visible on the first page
        system.assert(donationWizard.isNotLast);
        
        //Next page
        donationWizard.last();
        
        //Last button should not be visible now
        system.assert(!donationWizard.isNotLast);
        
    }
    /**
    Previous button to be shown?
    */
    public static testmethod void previousButtonAppearingTest(){
        
        //Create test data        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //Creating 10 items, ie, 2 pages with 5 items each
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Previous button should not be visible on the first page
        system.assert(!donationWizard.hasPrevious);
        
        //Next page
        donationWizard.next();
        
        //Previous button is visible now
        system.assert(donationWizard.hasPrevious);
        
    }
    /**
    Next button to be shown?
    */
    public static testmethod void nextButtonAppearingTest(){
        
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //Creating 10 items, ie, 2 pages with 5 items each
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Next button should be visible on the first page
        system.assert(donationWizard.hasNext);
        
        //Next page
        donationWizard.last();
        
        //Next button should not be visible now
        system.assert(!donationWizard.hasNext);
        
    }
    /**
    Wrapper List to be filtered correctly based on Category
    */
    public static testmethod void itemListFilteredCorrectlyTest(){
        
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //Create 1000 items - 100 belonging to each category from 'Cat1' to 'Cat10'
        List<Item__c> items = new List<Item__c>();
        for(Integer i = 1 ; i <= 10 ; i++){
            for(Integer j = 0; j < 100; j++){
                items.add(TestDataGenerator.CreateSingleItem(1000, 'Cat ' + i));
            }
        }
        
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Verify initial size
        system.assert(donationWizard.getFilteredWrapperList().size() == 1000);
        
        //Select 'Cat 1'
        donationWizard.selectedCategory = 'Cat 1';
        
        //Filter the List of Items
        donationWizard.filterList();
        
        //Check Filtered List size of 100
        system.assert(donationWizard.getFilteredWrapperList().size() == 100);
        
        //Check if all Wrappers have Category = 'Cat 1'
        Boolean belongingToFilteredCategory = TRUE;
        
        for(BidWithItemsWrapper filteredWrapper : donationWizard.getFilteredWrapperList()){
            if(filteredWrapper.item.Category__c != 'Cat 1'){
                belongingToFilteredCategory = FALSE;
            }
        }

        system.assert(belongingToFilteredCategory);
        
    }
    
    /**
    Pie Chart display functionality
    */
    public static testmethod void chartDisplayingCorrectlyTest(){
        
        //Create Test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //Create a list of items - 100 each belonging to 10 Categories - from 'Cat 1' to 'Cat 10'
        List<Item__c> items = new List<Item__c>();
        for(Integer i = 1 ; i <= 10 ; i++){
            for(Integer j = 0; j < 100; j++){
                items.add(TestDataGenerator.CreateSingleItem(1000*i, 'Cat ' + i));
            }
        }
        
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Should see Message on Page load indicating that no bids have been made 
        system.assert(donationWizard.categoryTotalMapSize == 0);
        
        //Pie Chart is blank
        system.assert(donationWizard.pieData.isEmpty());
        
        //Bid USD 1000 on all items on Page 1
        //That would imply a USD 5000 increment for Cat 1
        for(BidWithItemsWrapper bwi: donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c = 1000;
        }
        
        //Next page
        donationWizard.next();
        
        //Message on page will disappear
        system.assert(donationWizard.categoryTotalMapSize > 0);
        
        //Pagination triggers pieData update
        
        //Piedata shows correct figure of 5,000 for Cat 1
        system.assert(donationWizard.pieData.size() == 1);
        system.assert(donationWizard.pieData.get(0).name == 'Cat 1');
        system.assert(donationWizard.pieData.get(0).data == 5000);
        
        //Bid USD 1000 on all items on Page 2
        //That would imply a USD 5000 increment for Cat 1
        for(BidWithItemsWrapper bwi: donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c = 1000;
        }
        
        //Next page
        donationWizard.next();
        
        //Pagination triggers pieData update

        //Piedata shows correct figure of 10,000 for Cat 1
        system.assert(donationWizard.pieData.size() == 1);
        system.assert(donationWizard.pieData.get(0).name == 'Cat 1');
        system.assert(donationWizard.pieData.get(0).data == 10000);
        
        //Bid USD 1000 on all items on Page 3
        //That would imply a USD 5000 increment for Cat 1
        for(BidWithItemsWrapper bwi: donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c = 1000;
        }
        
        //Filter List
        donationWizard.selectedCategory = 'Cat 1';
        donationWizard.filterList();
        
        //Filtering triggers pieData update

        //Piedata shows correct figure of 15,000 for Cat 1
        system.assert(donationWizard.pieData.size() == 1);
        system.assert(donationWizard.pieData.get(0).name == 'Cat 1');
        system.assert(donationWizard.pieData.get(0).data == 15000);
        
    }
    /**
    Any Existing Bids updated with an Amount of 0 on the UI to be deleted
    */
    public static testmethod void bidsSuccessfulDeletionTest(){
        
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        //Associate some bids with the created Donations
        List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 10, TRUE);
        insert bids;
        
        //Open the Donation Wizard in 'Edit' mode
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        Set<Id> bidIdSet = new Set<Id>();
        
        //Clear Amount values for Bids on Page 1
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c =  0.00;
            bidIdSet.add(bwi.bid.Id);
        }
        
        //Click the 'Save' button
        PageReference donationPage = donationWizard.customSave();
        
        //Redirected to Donation page
        Id donationId = (Id)donationPage.getUrl().split('/').get(1);
        system.assert(donationId.getSObjectType().getDescribe().getName() == 'Donation__c');
        
        //Verify if the bids have been deleted
        system.assert([SELECT Id FROM Bid__c WHERE Id IN: bidIdSet].isEmpty());
        
    }
    /**
    If Bid Deletion is unsuccessful - all changes to be rolled back
    Initially tried throwing a custom exception during Deletion of Bids in the Controller using 
    Test.IsRunningTest and Static variables - however, was facing concurrency issues when the various
    test methods were run in parallel - as one test method would reference the static variable
    value set by another
    Hence, chose to simulate the deletion error in another way
    */
   
    public static testmethod void bidsUnsuccessfulDeletionTest(){
        
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        //Associate bids with Donations
        List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 10, TRUE);
        insert bids;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        Set<Id> bidIdSet = new Set<Id>();
        
        //Clear Bids on Page 1
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c =  0.00;
            bidIdSet.add(bwi.bid.Id);
        }
        
        //Force delete all bids before calling the controller Save action to incur a Deletion exception
        delete bids;
        
        //Click the 'Save' button
        PageReference error = donationWizard.customSave();
        
        //Error caused - on same page
        system.assert(error == NULL);
        
        List<ApexPages.Message> messages = Apexpages.getMessages();
        
        //Verify that a deletion Exception was thrown
        Boolean deletionExceptionThrown = FALSE;
        
        for(ApexPages.Message message : messages){
            system.debug('message componentlabel: ' + message.getComponentLabel());
            system.debug('message detail: ' + message.getDetail());
            
            if(message.getDetail().contains('entity is deleted'))
            {
                deletionExceptionThrown = TRUE;
            }
        }
        
        system.assert(deletionExceptionThrown);
        
        
    }
    
    /**
    No bids to be inserted if the amounts are blank
    */
    public static testmethod void noBidsInsertionTest(){
        
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
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
    /**
    Bids to be inserted if Amount > 0 and Amount > Item's Minimum Bid 
    */
    public static testmethod void bidsSuccessfulInsertionTest(){
        
        //Create test data        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //Create 10 items, ie 5 shown per page
        //Parameters passed - Upper Limit for the Minimum Bid, Number Of Items
        //and whether the Items have a future closing Date or not
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Add Amount entries to Page 1
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            //Bidding USD 1000 higher than the upper Limit for the items
            bwi.bid.Amount__c = 3000;
        }
        
        //Next page
        donationWizard.next();
        
        //Add Amount entries to Page 2
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            //Bidding USD 1000 higher than the upper Limit for the items
            bwi.bid.Amount__c = 3000;
        }
        
        //Click on 'Save' button
        PageReference donationPage = donationWizard.customSave();
        
        //Redirected to Donation page
        Id donationId = (Id)donationPage.getUrl().split('/').get(1);
        
        system.assert(donationId.getSObjectType().getDescribe().getName() == 'Donation__c');
        
        //Verify if a donation was created
        Donation__c donation =  [SELECT Id FROM Donation__c WHERE Donor__c =: donors.get(0).Id];
        
        //Verify if bids were created under the donation
        system.assert([SELECT COUNT() FROM Bid__c WHERE Donation__c =: donation.Id] == 10);
        
    }
    
    /**
    No Bids to be inserted if Amount < Item's Minimum Bid
    */
    public static testmethod void bidsUnsuccessfulInsertionTest(){
        
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //Create 10 items, ie, 5 shown per page
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        //Generate Item Id > Minimum Bid Map
        Map<Id, Decimal> itemIdMinimumBidMap = new Map<Id, Decimal>();
        
        for(Item__c item : items){
            itemIdMinimumBidMap.put(item.Id, item.Minimum_Bid__c);
        }
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Update Bids on Page 1 with amounts less than the Item's minimum bid
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c =  itemIdMinimumBidMap.get(bwi.item.Id) - 500;
        }
        
        //Click the 'Save' button
        PageReference error = donationWizard.customSave();
        
        //Same page returned
        system.assert(error == NULL);
        
        List<Apexpages.Message> messages = ApexPages.getMessages();
        
        //Validate error message returned - Upsert Failure
        Boolean errorMessageReturned = FALSE;
        for(Apexpages.Message message : messages){
            if(message.getDetail().contains(System.Label.UpsertFailure_1)){
                errorMessageReturned = TRUE;
            }
        }
        
        system.assert(errorMessageReturned);
        
        //Verify that no bids have been inserted
        system.assert([SELECT COUNT() FROM Bid__c] == 0);
        
    }
    
    /**
    Existing bids to be updated if Amount > 0
    */
    public static testmethod void bidsSuccessfulUpdateTest(){
        
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        insert donations;
        
        //Create 10 items - 5 shown per page
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        List<Bid__c> bids = TestDataGenerator.CreateBids(donations, items, 10, TRUE);
        insert bids;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        Map<Id, Decimal> bidAmountMap = new Map<Id, Decimal>();
        
        //Update Bids on Page 1 - increase amount by 1000 USD
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c =  bwi.bid.Amount__c + 1000;
            bidAmountMap.put(bwi.bid.Id, bwi.bid.Amount__c);
        }
        
        //Next page
        donationWizard.next();
        
        //Update Bids on Page 2 - increase amount by 1000 USD
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c =  bwi.bid.Amount__c + 1000;
            bidAmountMap.put(bwi.bid.Id, bwi.bid.Amount__c);
        }
        
        //Click the 'Save' button
        PageReference donationPage = donationWizard.customSave();
        
        //Redirected to Donation page
        Id donationId = (Id)donationPage.getUrl().split('/').get(1);
        
        system.assert(donationId.getSObjectType().getDescribe().getName() == 'Donation__c');
        
        //Verify if the bids have updated
        //Query the bids from the DB
        Map<Id, Bid__c> bidDBMap = new Map<Id, Bid__c>([SELECT Id,Amount__c FROM Bid__c]);
        
        //Match bidDBMap with bidAmountMap
        for(Id bidId : bidDBMap.keySet()){
            system.assert(bidDBMap.get(bidId).Amount__c == bidAmountMap.get(bidId));
        }
        
    }
    /**
    If bid Update is unsuccessful - all changes to be rolled back
    Since we already covered the upsert scenario in the unsuccessfulInsert test, this has been skipped
    */
    public static testmethod void bidsUnsuccessfulUpdateTest(){
        
    }
    /**
    If Donation Upsert is unsuccessful - all changes to be rolled back
    Initially tried throwing a custom exception during Upsert of Donation in the Controller using 
    Test.IsRunningTest and Static variables - however, was facing concurrency issues when the various
    test methods were run in parallel - as one test method would reference the static variable
    value set by another
    Chose to simulate upsert error in another way   
    */
    public static testmethod void bidsUnsuccessfulDonationUpsertTest(){
        //Create test data
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //Start with a blank donation
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Pre-mention the Id of the donation record to force an error during donation upsert
        String invalidDonationId = Donation__c.SobjectType.getDescribe().getKeyPrefix();
        //Append 12 zeros to complete the Id length requirement
        invalidDonationId += '000000000000';
        
        //Mention id for donation
        donationWizard.donation.Id = invalidDonationId;
        
        //Error thrown by page
        PageReference error = donationWizard.customSave();
        
        //On same page
        system.assert(error == NULL);
        
        List<Apexpages.Message> messages = ApexPages.getMessages();
        
        //Verify the error message
        Boolean donationUpsertExceptionThrown = FALSE;
        
        for(ApexPages.Message message : messages){
            if(message.getDetail().contains('INVALID_CROSS_REFERENCE_KEY'))
            {
                donationUpsertExceptionThrown = TRUE;
            }
        }
        
        system.assert(donationUpsertExceptionThrown);
        
    }

    /**
     If the Donor lookup is blank - 'Save' stopped and error thrown
    */
    public static testmethod void blankDonationDonorValidationTest(){
        
        PageReference pageRef = Page.DonationWizard;
        Test.setCurrentPage(pageRef); 
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        
        //Start with a blank donation with Only the Status populated
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(new Donation__c(Status__c = 'New')));
        
        //Save the page
        PageReference error = donationWizard.customSave();
        
        //Error caused - On same page
        system.assert(error == NULL);
        
        List<Apexpages.Message> messages = ApexPages.getMessages();
        
        system.debug('error messages: ' + messages);
        
        //Verify the Field that caused the error
        system.assert(messages.get(0).getComponentLabel() == 'Donor');
        //Verify the error message
        system.assert(messages.get(0).getDetail() == System.Label.ValueRequired);
        
        //Specify a donor
        donationWizard.donation.Donor__c = donors.get(0).Id;
        
        Test.setCurrentPage(pageRef); 
        
        //Save the page
        PageReference donationPage = donationWizard.customSave();
        
        //Donation saves successfully
        Id donationId = (Id)donationPage.getUrl().split('/').get(1);
        system.assert(donationId.getSObjectType().getDescribe().getName() == 'Donation__c');
        
    }
    /**
     If the Donor Status is blank - 'Save' stopped and error thrown
    */
    public static testmethod void blankDonationStatusValidationTest(){
        
        PageReference pageRef = Page.DonationWizard;
        Test.setCurrentPage(pageRef); 
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        
        //Start with a blank donation with only the Donor lookup populated
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(new Donation__c(Donor__c = donors.get(0).Id)));
        
        //Save the page
        PageReference error = donationWizard.customSave();
        
        //Error caused - On same page
        system.assert(error == NULL);
        
        List<Apexpages.Message> messages = ApexPages.getMessages();
        
        system.debug('error messages: ' + messages);
        
        //Validate the Field that caused the error
        system.assert(messages.get(0).getComponentLabel() == 'Status');
        //Validate the error message
        system.assert(messages.get(0).getDetail() == System.Label.ValueRequired);
        
        //Specify a status
        donationWizard.donation.Status__c = 'New';
        
        Test.setCurrentPage(pageRef); 
        
        //Save the page
        PageReference donationPage = donationWizard.customSave();
        
        //Donation saves successfully
        Id donationId = (Id)donationPage.getUrl().split('/').get(1);
        system.assert(donationId.getSObjectType().getDescribe().getName() == 'Donation__c');
        
    }
    
    /**
     If the Bid Amount is blank for any item - 'Save' stopped and error thrown
    */
    public static testmethod void blankBidValidationTest(){
       
        PageReference pageRef = Page.DonationWizard;
        Test.setCurrentPage(pageRef); 
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //Create 10 items, ie 2 pages with 5 items shown per page
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Clearing bid Amount values on Page 1
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c = NULL;
        }
        
        //Click on the 'Save' button
        PageReference error = donationWizard.customSave();
        
        //Error caused - on same page
        system.assert(error == NULL);
        
        List<Apexpages.Message> messages = ApexPages.getMessages();
        
        //Validate the Field that caused the error
        system.assert(messages.get(0).getComponentLabel() == 'Amount');
        //Validate the error message
        system.assert(messages.get(0).getDetail() == System.Label.ValueRequired);
        
        //Refill bid Amount values on Page 1
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c = 0.00;
        }
        
        //Click on the 'Save' button
        PageReference donationPage = donationWizard.customSave();
        
        //Donation saves successfully
        Id donationId = (Id)donationPage.getUrl().split('/').get(1);
        system.assert(donationId.getSObjectType().getDescribe().getName() == 'Donation__c');
        
        
    }
    /**
     If the Bid Amount is blank for any item - Category filtering is stopped and an error is thrown
    */
    public static testmethod void blankBidFilterTest(){
        
        PageReference pageRef = Page.DonationWizard;
        Test.setCurrentPage(pageRef); 
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        
        //Create 10 items, ie 2 pages with 5 items shown per page
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Update bid Amount values on Page 1
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c = bwi.bid.Amount__c + 1000;
        }
        
        //Go to Next page
        donationWizard.next();
        
        List<Apexpages.Message> messages = ApexPages.getMessages();
        
        //Verify that there is no error
        system.assert(messages.isEmpty());
        
        //Clear amount values on Page 2
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c = NULL;
        }
        
        //Filter list based on a category
        donationWizard.selectedCategory = items.get(0).Category__c;
        donationWizard.filterList();
        
        //Verify that an error is thrown
        messages = ApexPages.getMessages();
        
        for(Apexpages.message msg : messages){
            system.debug('msg component: ' + msg.getComponentLabel());
            system.debug('msg detail: ' + msg.getDetail());
            
        }
        //Verify the Field that caused the error
        system.assert(messages.get(0).getComponentLabel() == 'Amount');
        //Verify the error message
        system.assert(messages.get(0).getDetail() == System.Label.ValueRequired);
    }
    /**
     If the Bid Amount is blank for any item - Pagination is stopped and an error is thrown
    */
    public static testmethod void blankBidPaginationTest(){
      
        PageReference pageRef = Page.DonationWizard;
        Test.setCurrentPage(pageRef); 
        
        List<Contact> donors = TestDataGenerator.CreateDonors(1);
        insert donors;
        List<Donation__c> donations = TestDataGenerator.CreateDonations(donors, FALSE);
        //Create 10 items, ie 2 pages with 5 items shown per page
        List<Item__c> items = TestDataGenerator.CreateItems(2000, 10, TRUE);
        insert items;
        
        DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donations.get(0)));
        
        //Update bid Amount values on Page 1
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c = bwi.bid.Amount__c + 1000;
        }
        
        //Next page
        donationWizard.next();
        
        List<Apexpages.Message> messages = ApexPages.getMessages();
        
        //No error while paginating
        system.assert(messages.isEmpty());
        
        //Clear amount values on Page 2
        for(BidWithItemsWrapper bwi : donationWizard.paginatedWrapperList){
            bwi.bid.Amount__c = NULL;
        }
        
        //Previous page
        donationWizard.previous();
        
        //Error while paginating
        messages = ApexPages.getMessages();
        
        for(Apexpages.message msg : messages){
            system.debug('msg component: ' + msg.getComponentLabel());
            system.debug('msg detail: ' + msg.getDetail());
            
        }
        //Verify the Field that caused the error
        system.assert(messages.get(0).getComponentLabel() == 'Amount');
        //Verify the error message
        system.assert(messages.get(0).getDetail() == System.Label.ValueRequired);
    }
    
    /**
     Since Controller has 'with sharing' enabled - the user only sees records he/she owns -
     as OWD is Private for Donations
    */
    public static testmethod void donationVisibleTest(){
        
        //Create two users with 'Auctioneer' profiles
        User auctioneer1 = TestDataGenerator.CreateUser('Auctioneer');
        User auctioneer2 = TestDataGenerator.CreateUser('Auctioneer');
        
        //Insert the users
        insert auctioneer1;
        insert auctioneer2;
        
        //system.debug('auctioneer1: ' + auctioneer1);
        //system.debug('auctioneer2: ' + auctioneer2);
        
        //Create 1 donation
        List<Contact> donorList1 = TestDataGenerator.CreateDonors(1);
        insert donorList1;
        List<Donation__c> donationList1 = TestDataGenerator.CreateDonations(donorList1, FALSE);
        
        //Change Donation Owner to Auctioneer 1
        donationList1.get(0).OwnerId = auctioneer1.Id;
        insert donationList1;
        
        //Create another donation
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
                DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donationList2.get(0)));
            }
        }
        catch(System.QueryException ex){
            system.assert(ex.getMessage().contains('List has no rows for assignment to SObject'));
        }
        
        //However, he can see his own Donation Records
        System.RunAs(auctioneer1){
            DonationWizardController donationWizard = new DonationWizardController(new ApexPages.StandardController(donationList1.get(0)));   
        }
    }
}