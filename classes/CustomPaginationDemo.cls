//KK: Look at naming conventions, class, variable and method renaming
/*

*/
public with sharing class DonationWizardController
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
    //public static Boolean coverCatchBlock = FALSE;
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
    //public Id processedItemId{get;set;}
    //public Set<Id> itemIdsToProcess{get;set;}
    //public Map<Id,BidWithItemsWrapper> itemIdBWIMap{get;set;}

//public Decimal processedBidAmount{get;set;}


    CustomIterable obj;

    public DonationWizardController(ApexPages.StandardController sc) 
    {
        itemList = new List<Item__c>();
        lstWrapper =  new List< BidWithItemsWrapper >();
        lstSetController = new List< BidWithItemsWrapper >();
        itemCategories = new Set<String>();
        Set<Id> itemIdsAlreadyQueried = new Set<Id>();
        //itemIdsToProcess = new Set<Id>();
        //itemIdBWIMap = new Map<Id, BidWithItemsWrapper>();


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
                //itemIdBWIMap.put(bid.Item__c, bwi);
                if(!String.isBlank(bid.Item__r.Category__c)){
                    itemCategories.add(bid.Item__r.Category__c);
                }
                itemIdsAlreadyQueried.add(bid.Item__c);
            }

            newPage = FALSE;
        }
        else{

            donation = new Donation__c();
            donation = (Donation__c)sc.getRecord();

            newPage = TRUE;
        }
        
        system.debug('ready to fetch itemList');
        //Adding Items with Close Date >= Today
        //Excluding items that have already been added above
        itemList = [SELECT Name, Minimum_Bid__c, Highest_Bid__c, Category__c, Closing_Date__c
        FROM Item__c
        WHERE Closing_Date__c >=: Date.today()
        AND Id NOT IN: itemIdsAlreadyQueried
        ORDER BY Minimum_Bid__c];

        system.debug('itemlist size: ' + itemList.size());

        for(Item__c item : itemList )
        {
            BidWithItemsWrapper bwi = new BidWithItemsWrapper(new Bid__c(Amount__c = 0.00),item);
            lstWrapper.add(bwi);
            //itemIdBWIMap.put(item.Id, bwi);
            if(!String.isBlank(item.Category__c)){
                itemCategories.add(item.Category__c);
            }
            
        }

        system.debug('ready to sort');
        //KK: Sorting to be done on the basis of Minimum Bid
        lstWrapper.sort();

        //Index to be populated
        //for(BidWithItemsWrapper bwi : lstWrapper){
        //    bwi.index = index++;
        //}
        system.debug('lstWrapper: ' + lstWrapper);

        obj = new CustomIterable (lstWrapper); 

        system.debug('In constructor');
        system.debug('Calling next');
        next();

    }
    //Not working
    /*public void processBid(){

        system.debug('Selected Item Id: ' + processedItemId);
        itemIdsToProcess.add(processedItemId);

    }*/
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

            //system.debug('browsing bwi: ' + bwi);

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

    //KK:Chart loading on page load - but not refreshing as of now
public void refreshPieData() {
    populateCategoryTotalMap();
    system.debug('categoryTotalMap: ' + categoryTotalMap);

    pieData = new List<PieWedgeData>();

    for(String category :  categoryTotalMap.keySet()){
        pieData.add(new PieWedgeData(category, (Integer)categoryTotalMap.get(category)));
    } 
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

    system.debug('In controller > next');
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
    system.debug('lstSetController size: ' + lstSetController.size());

    for(BidWithItemsWrapper bwiToValidate : lstSetController ){

        if(bwiToValidate.bid.Amount__c == NULL){
            bwiToValidate.bid.Amount__c.addError(System.Label.ValueRequired);
            validation = FALSE;
            break;
        }
    }

    return validation;

}

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
public List<SelectOption> getCategories(){

    List<SelectOption> options = new List<SelectOption>();
    if(itemCategories.size() == 0){
                //options.add(new SelectOption(System.Label.NoItemsToBid,System.Label.NoItemsToBid));
                //selectedCategory = 'No items to bid on';
        options.add(new SelectOption(System.Label.AllCategories, System.Label.AllCategories));


    }
    else{

        options.add(new SelectOption(System.Label.AllCategories, System.Label.AllCategories));

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

public List<BidWithItemsWrapper> getFilteredItemSet(){
    return obj.itemList;
}
public List<BidWithItemsWrapper> getCompleteItemSet(){
    return this.lstWrapper;
}

public PageReference customSave()
{
    Savepoint sp;

    if(itemListValidated() && donationValidated()){

        //try{
        sp = Database.setSavepoint();

        try{
            
            /*if(Test.isRunningTest() && DonationWizardController.coverCatchBlock){
                throw new FakeException('This is a fake exception');
            }*/
            system.debug('upserting donation: ' + donation);
            //Upsert donation
            upsert donation;

         //system.debug('lstWrapper: ' + lstWrapper);
         //system.debug('lstSetController: ' + lstSetController);

         //system.debug('lstWrapper size: ' + lstWrapper.size());
         //system.debug('lstSetController size: ' + lstSetController.size());

            List<Bid__c> bidsToUpsert = new List<Bid__c>();
            List<Bid__c> bidsToDelete = new List<Bid__c>();
            Map<Integer, Integer> deleteIndexMainIndexMap = new Map<Integer, Integer>();
            Map<Integer, Integer> upsertIndexMainIndexMap = new Map<Integer, Integer>();
            
            //system.debug('itemIdsToProcess size: ' + itemIdsToProcess.size());

         //Loop through lstWrapper and save entities
            //for(Id itemIdToProcess : itemIdsToProcess){
            Integer mainIndexCounter = 0;
            Integer deleteIndexCounter = 0;
            Integer upsertIndexCounter = 0;
            for(BidWithItemsWrapper bwi: lstWrapper){

             //BidWithItemsWrapper bwi = itemIdBWIMap.get(itemIdToProcess);
             Bid__c bidToUpsert = new Bid__c();
             bidToUpsert.Amount__c = bwi.bid.Amount__c;
             bidToUpsert.Item__c = bwi.item.Id;
             bidToUpsert.Donation__c = donation.Id;

             if(bwi.bid.Id != NULL){
                if(bwi.bid.Amount__c == 0.00){
                    bidsToDelete.add(bwi.bid);
                    deleteIndexMainIndexMap.put(deleteIndexCounter, mainIndexCounter);
                    deleteIndexCounter++;
                }
                else{
                    bidToUpsert.Id = bwi.bid.Id;
                    bidsToUpsert.add(bidToUpsert);
                    upsertIndexMainIndexMap.put(upsertIndexCounter, mainIndexCounter);
                    upsertIndexCounter++;
                }
            }
            else{
                if(bwi.bid.Amount__c != 0.00){
                    bidsToUpsert.add(bidToUpsert);
                    upsertIndexMainIndexMap.put(upsertIndexCounter, mainIndexCounter);
                    upsertIndexCounter++;
                }
            }

            mainIndexCounter++;
        }   

        //delete bidsToDelete;
        //upsert bidsToUpsert;
        
        Boolean errorDuringDML = FALSE;
        Integer counter = 0;

        if(!bidsToDelete.isEmpty()){

            Database.DeleteResult[] deletionResultList = Database.delete(bidsToDelete, false);
            
            /*if(Test.isRunningTest()){
                deletionResultList.get(0).success = TRUE;
            }*/

            // Iterate through each returned result
            for (Database.DeleteResult sr : deletionResultList) {
                if (!sr.isSuccess()) {
                
                    //BidWithItemsWrapper errorBWI = itemIdBWIMap.get(bidsToDelete.get(counter).Item__c);
                    Integer mainIndex = 0;
                    
                    if(deleteIndexMainIndexMap.containsKey(counter)){
                        mainIndex = deleteIndexMainIndexMap.get(counter);
                    }
                    BidWithItemsWrapper errorBWI = lstWrapper.get(mainIndex);
                    
                    String errorMessage = '';

                    // Operation failed, so get all errors               
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
        
        if(!errorDuringDML){
            counter = 0;

            if(!bidsToUpsert.isEmpty()){
                Database.UpsertResult[] upsertResultList = Database.upsert(bidsToUpsert, false);

                system.debug('upsertResultList:' + upsertResultList);

                for (Database.UpsertResult sr : upsertResultList) {

                    if (!sr.isSuccess()) {
                        Integer mainIndex = 0;
                        
                        if(upsertIndexMainIndexMap.containsKey(counter)){
                            mainIndex = upsertIndexMainIndexMap.get(counter);
                        }
                        //BidWithItemsWrapper errorBWI = itemIdBWIMap.get(bidsToUpsert.get(counter).Item__c);
                        BidWithItemsWrapper errorBWI = lstWrapper.get(mainIndex);

                        String errorMessage = '';

                        // Operation failed, so get all errors               
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
        else{
            Database.rollback(sp);
            if(newPage){
                donation.Id = null;
            }

            return null;
        }
        
        if(!errorDuringDML)
        {
            //system.debug('upserting donation: ' + donation);
            //Upsert donation
            //upsert donation;
            
            return new PageReference('/' + donation.Id);
        }
        else{
            Database.rollback(sp);
            if(newPage){
                donation.Id = null;
            }
            return null;
        }
    }
    catch(Exception ex){
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
        Database.rollback(sp);
        if(newPage){
            donation.Id = null;
        }
        return null;
    }
}
else{
    return null;
}
         //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Insertion successful!'));

         //}
         /*catch(DmlException ex){
           system.debug('ex.getDmlFieldNames: ' + ex.getDmlFieldNames(0));
           system.debug('ex.getDmlFields: ' + ex.getDmlFields(0));
           system.debug('ex.getDmlId: ' + ex.getDmlId(0));
           system.debug('ex.getDmlIndex: ' + ex.getDmlIndex(0));
           system.debug('ex.getDmlMessage: ' + ex.getDmlMessage(0));
           system.debug('ex.getDmlStatusCode: ' + ex.getDmlStatusCode(0));
           system.debug('ex.getDmlType: ' + ex.getDmlType(0));
           system.debug('ex.getNumDml: ' + ex.getNumDml());
            
           //ApexPages.addMessages()
           Database.rollback(sp);
           return null;
         }
         catch(Exception ex){
           //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
           ApexPages.addMessages(ex);   
           Database.rollback(sp);
           return null;

         }
         */
     }
 }