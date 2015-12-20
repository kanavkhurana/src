//KK: Look at naming conventions, class, variable and method renaming
public with sharing class CustomPaginationDemo
{

   // Wrapper class
    public class PieWedgeData {

        public String name { get; set; }
        public Integer data { get; set; }

        public PieWedgeData(String name, Integer data) {
            this.name = name;
            this.data = data;
        }
    }

public List< BidWithItemsWrapper > lstWrapper {get;set;}
public List< BidWithItemsWrapper > lstSetController{get;set;}
public Set<String> itemCategories{get;set;}
public String selectedCategory{get;set;}
transient public List<Item__c> itemList{get;set;}
public List<PieWedgeData> pieData{get;set;}

public Donation__c donation{get;set;}
public Map<String, Decimal> categoryTotalMap{get;set;}
public Integer categoryTotalMapSize { get { return categoryTotalMap.size( ); } }
public Boolean newPage{get;set;}
public Id processedItemId{get;set;}
public Set<Id> itemIdsToProcess{get;set;}
public Map<Id,BidWithItemsWrapper> itemIdBWIMap{get;set;}

//public Decimal processedBidAmount{get;set;}


CustomIterable obj;

    public CustomPaginationDemo(ApexPages.StandardController sc) 
    {
        itemList = new List<Item__c>();
        lstWrapper =  new List< BidWithItemsWrapper >();
        lstSetController = new List< BidWithItemsWrapper >();
        itemCategories = new Set<String>();
        Set<Id> itemIdsAlreadyQueried = new Set<Id>();
        itemIdsToProcess = new Set<Id>();

        if(sc.getId() != null){
        
        donation = [SELECT Name, Donor__c, Status__c, 
                    (SELECT Id, Amount__c, Item__c, Item__r.Name, Item__r.Minimum_Bid__c,
                    Item__r.Highest_Bid__c, Item__r.Category__c, Item__r.Closing_Date__c 
                    FROM Bids__r
                    ORDER BY Item__r.Minimum_Bid__c)
                    FROM Donation__c
                    WHERE Id =: sc.getId()];

        for(Bid__c bid : donation.Bids__r)
        {
            BidWithItemsWrapper bwi = new BidWithItemsWrapper(bid,bid.Item__r);
            lstWrapper.add(bwi);
            itemIdBWIMap.put(bid.Item__c, bwi);

            itemCategories.add(bid.Item__r.Category__c);
            itemIdsAlreadyQueried.add(bid.Item__c);
        }

        newPage = FALSE;
        }
        else{

            donation = new Donation__c();
            donation = (Donation__c)sc.getRecord();

            newPage = TRUE;
        }
        
        //Adding Items with Close Date >= Today
        //Excluding items that have already been added above
        itemList = [SELECT Name, Minimum_Bid__c, Highest_Bid__c, Category__c, Closing_Date__c
                    FROM Item__c
                    WHERE Closing_Date__c >=: Date.today()
                    AND Id NOT IN: itemIdsAlreadyQueried
                    ORDER BY Minimum_Bid__c];

        for(Item__c item : itemList )
        {
            BidWithItemsWrapper bwi = new BidWithItemsWrapper(new Bid__c(Amount__c = 0.00),item);
            lstWrapper.add(bwi);
            itemIdBWIMap.put(item.Id, bwi);
            itemCategories.add(item.Category__c);
            
        }

        //KK: Sorting to be done on the basis of Minimum Bid
        lstWrapper.sort();

        system.debug('lstWrapper: ' + lstWrapper);

        obj = new CustomIterable (lstWrapper); 

        system.debug('In constructor');
        system.debug('Calling next');
        next();
       
    }
    public void processBid(){

        system.debug('Selected Item Id: ' + processedItemId);
        itemIdsToProcess.add(processedItemId);
        //system.debug('Selected Bid Amount: ' + processedBidAmount);

        //Segregate change into deletion, update and insertion
        /*if(bwi.bid.Id != NULL){
                if(bwi.bid.Amount__c == 0.00){
                    bidsToDelete.add(bwi.bid);
                }
                else{
                    bidToUpsert.Id = bwi.bid.Id;
                    bidsToUpsert.add(bidToUpsert);
                }
             }
             else{
                if(bwi.bid.Amount__c != 0.00){
                    bidsToUpsert.add(bidToUpsert);
                }
             }*/
             
    }
    public Integer getCurrentPage(){
        return obj.getCurrentPage();
    }
    public Integer getTotalNumberOfPages(){
        return Integer.valueOf(obj.getTotalNumberOfPages());
    }
    

    public void populateCategoryTotalMap(){

      Decimal categoryTotal = 0.0;
      categoryTotalMap = new Map<String, Decimal>();

      system.debug('obj.categoryItemMap: ' + obj.categoryItemMap);

      for(String category : obj.categoryItemMap.keySet()){

            categoryTotal = 0.0;

            system.debug('browsing category: ' + category);

            for(BidWithItemsWrapper bwi : obj.categoryItemMap.get(category)){

                system.debug('browsing bwi: ' + bwi);

                categoryTotal += bwi.bid.Amount__c;
            }

            //Only consider Category if Total is > 0
            if(categoryTotal > 0){
                categoryTotalMap.put(category, categoryTotal);
            }

      }

    }

    //KK:Chart loading on page load - but not refreshing as of now
    public void refreshPieData() {
        populateCategoryTotalMap();
        system.debug('categoryTotalMap: ' + categoryTotalMap);

        pieData = new List<PieWedgeData>();
       
        for(String category :  categoryTotalMap.keySet()){
            pieData.add(new PieWedgeData(category, (Integer)categoryTotalMap.get(category)));
        } 

        /*pieData.add(new PieWedgeData('Jan', 30));
        pieData.add(new PieWedgeData('Feb', 15));
        pieData.add(new PieWedgeData('Mar', 10));
        pieData.add(new PieWedgeData('Apr', 20));
        pieData.add(new PieWedgeData('May', 20));
        pieData.add(new PieWedgeData('Jun', 5));
        */
        //return pieData;
    }
    public Boolean isNotFirst {
            get 
            {
                return obj.isNotFirst();
            }
            set;
        }
    
          public Boolean hasPrevious {
            get 
            {
                return obj.hasPrevious();
            }
            set;
        }
        
        public Boolean hasNext {
            get 
            {
                return obj.hasNext();
            }
            set;
        }

         public Boolean isNotLast {
            get 
            {
                return obj.isNotLast();
            }
            set;
        }
       
        public PageReference first() 
        {
            if(itemListValidated()){
                lstSetController = obj.first();
                refreshPieData();
            }

            return null;


        }

        public PageReference previous() 
        {
            if(itemListValidated()){

            lstSetController = obj.previous();
            refreshPieData();
            }

            return null;

        }

        public PageReference next() 
        {

            if(itemListValidated()){
                lstSetController = obj.next();
                refreshPieData();
            }
            return null;
            
        }

        public PageReference last() 
        {
            if(itemListValidated()){

            lstSetController = obj.last();
            refreshPieData();
            }
            return null;

        }
        
        public Boolean itemListValidated(){

            Boolean validation = TRUE;

            for(BidWithItemsWrapper bwiToValidate : lstSetController ){

                if(bwiToValidate.bid.Amount__c == NULL){
                    bwiToValidate.bid.Amount__c.addError('You must enter a value');
                    validation = FALSE;
                    break;
                }
            }

            return validation;

        }

        public Boolean donationValidated(){

            Boolean validation = TRUE;

            if(donation.Donor__c == NULL){
                donation.Donor__c.addError('You must enter a value');

                validation = FALSE;
            }
            system.debug('donation status: ' + donation.Status__c);

            if(donation.Status__c == NULL){
                donation.Status__c.addError('You must enter a value');
                validation = FALSE;
            }

            return validation;

        }
        public List<SelectOption> getCategories(){
        
            List<SelectOption> options = new List<SelectOption>();
            if(itemCategories.size() == 0){
                options.add(new SelectOption('No items to bid on','No items to bid on'));
                //selectedCategory = 'No items to bid on';

            }
            else{
            
            options.add(new SelectOption('--Any Type--','--Any Type--'));

            for(String itemCategory : itemCategories){
                options.add(new SelectOption(itemCategory,itemCategory));
            }
            
            //selectedCategory = '--Any Type--';
            }
            
            return options;

        }
        
        public PageReference filterList(){
        
        system.debug('In filter List');
        system.debug('selected Category: ' + selectedCategory);

        if(itemListValidated()){

        obj.filterList(selectedCategory);
        obj.recalculateTotalNumberOfPages();

        system.debug('Calling next()');
        next();   
        }

        return null;

        }
       
        public PageReference customSave()
        {
            Savepoint sp;
        
         if(itemListValidated() && donationValidated()){

        try{
        sp = Database.setSavepoint();

        //Upsert donation
        upsert donation;

         //system.debug('lstWrapper: ' + lstWrapper);
         //system.debug('lstSetController: ' + lstSetController);

         //system.debug('lstWrapper size: ' + lstWrapper.size());
         //system.debug('lstSetController size: ' + lstSetController.size());
         
         List<Bid__c> bidsToUpsert = new List<Bid__c>();
         List<Bid__c> bidsToDelete = new List<Bid__c>();
         
         system.debug('itemIdsToProcess size: ' + itemIdsToProcess.size());

         //Loop through lstWrapper and save entities
         for(Id itemIdToProcess : itemIdsToProcess){
             
             BidWithItemsWrapper bwi = itemIdBWIMap.get(itemIdToProcess);
             Bid__c bidToUpsert = new Bid__c();
             bidToUpsert.Amount__c = bwi.bid.Amount__c;
             bidToUpsert.Item__c = bwi.item.Id;
             bidToUpsert.Donation__c = donation.Id;

             if(bwi.bid.Id != NULL){
                if(bwi.bid.Amount__c == 0.00){
                    bidsToDelete.add(bwi.bid);
                }
                else{
                    bidToUpsert.Id = bwi.bid.Id;
                    bidsToUpsert.add(bidToUpsert);
                }
             }
             else{
                if(bwi.bid.Amount__c != 0.00){
                    bidsToUpsert.add(bidToUpsert);
                }
             }
             
         }   
         
         delete bidsToDelete;
         upsert bidsToUpsert;
         //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Insertion successful!'));
         return new PageReference('/' + donation.Id);

         }
         catch(Exception ex){
           //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
           ApexPages.addMessages(ex);
           Database.rollback(sp);
           return null;

         }
        }
        else{
            return null;
        }
      
        }
        
        //KK: Using the standard 'Cancel' action
        /*public void cancel()
        {
            
        }*/
    
}