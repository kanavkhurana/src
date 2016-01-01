/**
Purpose: 
Controller for the DonationWizard Visualforce Page
*/
public with sharing class DonationWizardController
{
    
    // Wrapper class for the Pie Chart
    public class PieWedgeData {
        
        public String name { get; set; }
        public Integer data { get; set; }
        
        public PieWedgeData(String name, Integer data) {
            this.name = name;
            this.data = data;
        }
    }
    //Entire Set of Bids - Items
    public List< BidWithItemsWrapper > completeWrapperList {get;set;}
    //Paginated Set of Bids - Items
    public List< BidWithItemsWrapper > paginatedWrapperList{get;set;}
    //Item categories
    public Set<String> itemCategories{get;set;}
    //Category Picklist value
    public String selectedCategory{get;set;}
    
    //List of Item to query
    transient public List<Item__c> itemList{get;set;}
    //Pie Data 
    public List<PieWedgeData> pieData{get;set;}
    //Donation in Context
    public Donation__c donation{get;set;}
    //Map Category Name > Total Amount
    public Map<String, Decimal> categoryTotalMap{get;set;}
    //Getter for categoryTotalMap 
    public Integer categoryTotalMapSize { get { return categoryTotalMap.size( ); } }
    //Is new Donation??
    public Boolean newPage{get;set;}
    //Custom Iterator to handle stateful Pagination
    PaginatingIterator page;
    
    public DonationWizardController(ApexPages.StandardController sc) 
    {
        //Variable Initialization
        /*************************/
        itemList = new List<Item__c>();
        completeWrapperList =  new List< BidWithItemsWrapper >();
        paginatedWrapperList = new List< BidWithItemsWrapper >();
        itemCategories = new Set<String>();
        Set<Id> itemIdsAlreadyQueried = new Set<Id>();
        /*************************/
        
        //Cover the possibility of the 'FOR UPDATE' query throwing a Locking exception
        try{
            
            //If Existing Donation
            if(sc.getId() != null){
                
                //Secure Lock on Donation
                donation = [SELECT Name, Donor__c, Status__c
                            FROM Donation__c
                            WHERE Id =: sc.getId()
                            FOR UPDATE];
                
                //Fetch All Bids under this Donation
                List<Bid__c> bids = [SELECT Id, Amount__c, Item__c, Item__r.Name, Item__r.Minimum_Bid__c,
                                     Item__r.Highest_Bid__c, Item__r.Category__c, Item__r.Closing_Date__c 
                                     FROM Bid__c
                                     WHERE Donation__c =: sc.getId()
                                     FOR UPDATE];
                
                //Add to completeWrapperList
                //Add to itemCategories
                //Add to itemIdsAlreadyQueried - don't want to query same items in a subsequent query
                for(Bid__c bid : bids)
                {
                    BidWithItemsWrapper bwi = new BidWithItemsWrapper(bid,bid.Item__r);
                    completeWrapperList.add(bwi);
                    if(!String.isBlank(bid.Item__r.Category__c)){
                        itemCategories.add(bid.Item__r.Category__c);
                    }
                    itemIdsAlreadyQueried.add(bid.Item__c);
                }
                
                newPage = FALSE;
            }
            //If New Donation
            else{
                
                donation = new Donation__c();
                //Fetch Donor Id if invoked from Contact Related List
                donation = (Donation__c)sc.getRecord();
                
                newPage = TRUE;
            }
            
            //Fetch Items with Close Date >= Today
            //Excluding items that have already been added above
            itemList = [SELECT Name, Minimum_Bid__c, Highest_Bid__c, Category__c, Closing_Date__c
                        FROM Item__c
                        WHERE Closing_Date__c >=: Date.today()
                        AND Id NOT IN: itemIdsAlreadyQueried
                        FOR UPDATE];
            
            system.debug('itemlist size: ' + itemList.size());
            
            //Add to completeWrapperList
            //Add to itemCategories
            for(Item__c item : itemList )
            {
                BidWithItemsWrapper bwi = new BidWithItemsWrapper(new Bid__c(Amount__c = 0.00),item);
                completeWrapperList.add(bwi);
                if(!String.isBlank(item.Category__c)){
                    itemCategories.add(item.Category__c);
                }
                
            }
            
            system.debug('ready to sort');
            
            //Sorting to be done on the basis of Minimum Bid - custom sort() implemented in Wrapper 
            completeWrapperList.sort();
            
            system.debug('completeWrapperList size: ' + completeWrapperList.size());
            
            //Initialize the paginatingIterator
            page = new PaginatingIterator (completeWrapperList); 
            
            system.debug('Calling next');
            //Call the next() method to initialize Page 1
            next();
        }
        //Catch the Lock exception 
        catch(Exception ex){
            //Display on the interface
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
        }
        
    }
    
    public Integer getCurrentPage(){
        return page.getCurrentPage();
    }
    public Integer getTotalNumberOfPages(){
        return Integer.valueOf(page.getTotalNumberOfPages());
    }
    
    //Returns the filtered Wrapper List
    public List<BidWithItemsWrapper> getFilteredWrapperList(){
        return page.filteredWrapperList;
    }
    public List<BidWithItemsWrapper> getCompleteWrapperList(){
        return this.completeWrapperList;
    }
    
    //Category dropdown getter
    public List<SelectOption> getCategories(){
        
        List<SelectOption> options = new List<SelectOption>();
        if(itemCategories.size() == 0){
            options.add(new SelectOption(System.Label.AllCategories, System.Label.AllCategories));
        }
        else{
            
            options.add(new SelectOption(System.Label.AllCategories, System.Label.AllCategories));
            
            for(String itemCategory : itemCategories){
                options.add(new SelectOption(itemCategory,itemCategory));
            }
        }
        return options;
    }
    
    //Pagination control methods
    /**************************/
    public Boolean isNotFirst {
        get 
        {
            return page.isNotFirst();
        }
        set;
    }
    
    public Boolean hasPrevious {
        get 
        {
            return page.hasPrevious();
        }
        set;
    }
    
    public Boolean hasNext {
        get 
        {
            return page.hasNext();
        }
        set;
    }
    
    public Boolean isNotLast {
        get 
        {
            return page.isNotLast();
        }
        set;
    }
    /****************************/
    
    //Pagination methods
    /***************************/
    public PageReference first() 
    {
        //Bid Amount != NULL
        if(itemListValidated()){
            paginatedWrapperList = page.first();
            //Refresh pie chart
            refreshPieData();
        }
        
        return null;
    }
    
    public PageReference previous() 
    {
        //Bid Amount != NULL
        if(itemListValidated()){
            
            paginatedWrapperList = page.previous();
            //Refresh pie chart
            refreshPieData();
        }
        
        return null;
        
    }
    
    public PageReference next() 
    {
        
        //Bid Amount != NULL
        if(itemListValidated()){
            paginatedWrapperList = page.next();
            //Refresh pie chart
            refreshPieData();
        }
        return null;
    }
    
    public PageReference last() 
    {
        //Bid Amount != NULL
        if(itemListValidated()){
            
            paginatedWrapperList = page.last();
            //Refresh pie chart
            refreshPieData();
        }
        return null;
        
    }
    /***************************/
    
    //Refreshes pie Data
    public void refreshPieData() {
        populateCategoryTotalMap();
        system.debug('categoryTotalMap: ' + categoryTotalMap);
        
        pieData = new List<PieWedgeData>();
        
        for(String category :  categoryTotalMap.keySet()){
            pieData.add(new PieWedgeData(category, (Integer)categoryTotalMap.get(category)));
        } 
    }
    
    //Utility method to recalculate category-wise Bid Totals
    public void populateCategoryTotalMap(){
        
        Decimal categoryTotal = 0.0;
        categoryTotalMap = new Map<String, Decimal>();
        
        system.debug('page.categoryItemMap: ' + page.categoryItemMap);
        
        for(String category : page.categoryItemMap.keySet()){
            
            if(category != NULL){
                categoryTotal = 0.0;
                
                system.debug('browsing category: ' + category);
                
                for(BidWithItemsWrapper bwi : page.categoryItemMap.get(category)){
                    
                    if(bwi.bid.Amount__c != NULL){
                        categoryTotal += bwi.bid.Amount__c;
                    }
                }
                
                //Only consider Category if Total is > 0
                if(categoryTotal > 0){
                    categoryTotalMap.put(category, categoryTotal);
                }
            }
        }
    }
    
    //Validation check ensuring NO AMOUNT fields are left blank
    public Boolean itemListValidated(){
        
        Boolean validation = TRUE;
        system.debug('paginatedWrapperList size: ' + paginatedWrapperList.size());
        
        for(BidWithItemsWrapper bwiToValidate : paginatedWrapperList ){
            
            if(bwiToValidate.bid.Amount__c == NULL){
                bwiToValidate.bid.Amount__c.addError(System.Label.ValueRequired);
                validation = FALSE;
                break;
            }
        }
        
        return validation;
        
    }
    
    //Validation check ensuring DONATION fields are not left blank
    public Boolean donationValidated(){
        
        Boolean validation = TRUE;
        
        system.debug('donation donor: ' + donation.Donor__c);
        system.debug('donation status: ' + donation.Status__c);
        
        if(donation.Donor__c == NULL){
            donation.Donor__c.addError(System.Label.ValueRequired);
            
            validation = FALSE;
        }
        
        if(donation.Status__c == NULL){
            donation.Status__c.addError(System.Label.ValueRequired);
            validation = FALSE;
        }
        
        return validation;
        
    }
    
    //Action method to filter the list of items
    public PageReference filterList(){
        
        system.debug('In filter List');
        system.debug('selected Category: ' + selectedCategory);
        
        //Item List Validation run
        if(itemListValidated()){
            
            //List filtered based on Selected Category
            page.filterList(selectedCategory);
            //Total number of pages recalculated
            page.recalculateTotalNumberOfPages();
            
            system.debug('Calling next()');
            //Next() called to initialize Page 1
            next();   
        }
        
        return null;
        
    }
    
    //Action method called from the 'Save' button
    public PageReference customSave()
    {
        Savepoint sp;
        
        //If the Item List and Donation have been validated - proceed
        if(itemListValidated() && donationValidated()){
            
            //Initialize a savepoint
            sp = Database.setSavepoint();
            
            try{
                
                system.debug('upserting donation: ' + donation);
                //Upsert donation
                upsert donation;
                
                //Collection of Bids To Insert or Update
                List<Bid__c> bidsToUpsert = new List<Bid__c>();
                //Collection of Bids To Delete
                List<Bid__c> bidsToDelete = new List<Bid__c>();
                //Map of row count in the Delete Map > row count on the CompleteWrapperList
                Map<Integer, Integer> deleteIndexMainIndexMap = new Map<Integer, Integer>();
                //Map of row count in the Upsert Map > row count on the CompleteWrapperList
                Map<Integer, Integer> upsertIndexMainIndexMap = new Map<Integer, Integer>();
                
                //Loop through completeWrapperList
                Integer mainIndexCounter = 0;
                Integer deleteIndexCounter = 0;
                Integer upsertIndexCounter = 0;
                for(BidWithItemsWrapper bwi: completeWrapperList){
                    
                    Bid__c bidToUpsert = new Bid__c();
                    bidToUpsert.Amount__c = bwi.bid.Amount__c;
                    bidToUpsert.Item__c = bwi.item.Id;
                    bidToUpsert.Donation__c = donation.Id;
                    
                    //If Existing Bid
                    if(bwi.bid.Id != NULL){
                        //If Amount = 0 > Deletion required
                        if(bwi.bid.Amount__c == 0.00){
                            bidsToDelete.add(bwi.bid);
                            deleteIndexMainIndexMap.put(deleteIndexCounter, mainIndexCounter);
                            deleteIndexCounter++;
                        }
                        //If Amount != 0 > Update required
                        else{
                            bidToUpsert.Id = bwi.bid.Id;
                            bidsToUpsert.add(bidToUpsert);
                            upsertIndexMainIndexMap.put(upsertIndexCounter, mainIndexCounter);
                            upsertIndexCounter++;
                        }
                    }
                    //If New Bid
                    else{
                        //If Amount != 0 > Insert required
                        if(bwi.bid.Amount__c != 0.00){
                            bidsToUpsert.add(bidToUpsert);
                            upsertIndexMainIndexMap.put(upsertIndexCounter, mainIndexCounter);
                            upsertIndexCounter++;
                        }
                    }
                    
                    mainIndexCounter++;
                }   
                
                Boolean errorDuringDML = FALSE;
                Integer counter = 0;
                
                //Perform deletion
                if(!bidsToDelete.isEmpty()){
                    
                    //Database DML used to process errors and display a user friendly message on the Interface
                    Database.DeleteResult[] deletionResultList = Database.delete(bidsToDelete, false);
                    
                    // Iterate through each returned result
                    for (Database.DeleteResult sr : deletionResultList) {
                        //If Deletion failed
                        if (!sr.isSuccess()) {
                            
                            Integer mainIndex = 0;
                            
                            //Fetch row Count in CompleteWrapperList
                            if(deleteIndexMainIndexMap.containsKey(counter)){
                                mainIndex = deleteIndexMainIndexMap.get(counter);
                            }
                            BidWithItemsWrapper errorBWI = completeWrapperList.get(mainIndex);
                            
                            String errorMessage = '';
                            
                            //get all errors               
                            for(Database.Error err : sr.getErrors()) {                   
                                errorMessage += err.getMessage();
                            }
                            
                            //Display error message for particular record and specify row number on top of the page
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.DeleteFailure_1 + ' ' + 
                                                                       (mainIndex+1) + ' ' + System.Label.DeleteFailure_2
                                                                       + errorBWI.item.Name + ' -> ' + errorMessage)) ;
                            
                            errorBWI.bid.Amount__c.addError(System.Label.GenericError);
                            errorDuringDML = TRUE;
                        }
                        counter++;
                        
                    }
                }
                
                //If No error during Delete - then proceed
                if(!errorDuringDML){
                    counter = 0;
                    
                    //Perform upsert
                    if(!bidsToUpsert.isEmpty()){
                        Database.UpsertResult[] upsertResultList = Database.upsert(bidsToUpsert, false);
                        
                        system.debug('upsertResultList:' + upsertResultList);
                        
                        for (Database.UpsertResult sr : upsertResultList) {
                            
                            //If Upsert failed
                            if (!sr.isSuccess()) {
                                Integer mainIndex = 0;
                                
                                //Fetch row Count in CompleteWrapperList
                                if(upsertIndexMainIndexMap.containsKey(counter)){
                                    mainIndex = upsertIndexMainIndexMap.get(counter);
                                }
                                BidWithItemsWrapper errorBWI = completeWrapperList.get(mainIndex);
                                
                                String errorMessage = '';
                                
                                //get all errors               
                                for(Database.Error err : sr.getErrors()) {                   
                                    errorMessage += err.getMessage();
                                }
                                
                                //Display error message for particular record and specify row number on top of the page
                                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.UpsertFailure_1 + ' ' + 
                                                                           (mainIndex+1) + ' ' + System.Label.UpsertFailure_2
                                                                           + errorBWI.item.Name + ' -> ' + errorMessage)) ;
                                
                                errorBWI.bid.Amount__c.addError(System.Label.GenericError);
                                errorDuringDML = TRUE;
                            }
                            counter++;
                        }
                    }
                }
                //If Deletion failed
                else{
                    //Rollback to savepoint
                    Database.rollback(sp);
                    //If New Page - clear the Donation's Id
                    if(newPage){
                        donation.Id = null;
                    }
                    
                    return null;
                }
                
                //If no error during Upsert - then proceed
                if(!errorDuringDML)
                {
                    //Redirect to Donation
                    return new PageReference('/' + donation.Id);
                }
                //If any error during Upsert
                else{
                    //Rollback to savepoint
                    Database.rollback(sp);
                    //If New Page - clear the Donation's Id
                    if(newPage){
                        donation.Id = null;
                    }
                    return null;
                }
            }
            //If any exception caught
            catch(Exception ex){
                //Display on the interface
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
                //Rollback to savepoint
                Database.rollback(sp);
                //If New Page - clear the Donation's Id
                if(newPage){
                    donation.Id = null;
                }
                return null;
            }
        }
        //If Item List or Donation validation did not succeed - display error message to user
        else{
            return null;
        }
    }
}