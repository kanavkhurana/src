/**
Purpose:
Since there was a requirement of maintaining the state of the Amount field values on Pagination and Filtering,
the StandardSetController could not be used. Hence, it was decided to use a custom iterator to implement the functionality
*/
global class PaginatingIterator implements Iterator<List<BidWithItemsWrapper>>
{ 
    
    /********IMPORTANT***********/
    //The complete List when Category = '--Any Type--'
    //The filtered List when Category != '--Any Type--'
    public list<BidWithItemsWrapper> filteredWrapperList{get; set;}
    /****************************/

    //Always the Complete List
    public list<BidWithItemsWrapper> completeWrapperList{get;set;}
    
    //The paginated Wrapper List
    List<BidWithItemsWrapper> paginatedWrapperList{get; set;}
    
    //Category Item Map - utilised when filtering based on Category
    public Map< String, List<BidWithItemsWrapper>> categoryItemMap{get;set;}
    
    //Pointer to current Wrapper row 
    Integer wrapperPointer {get; set;} 
    
    //Number of items per page
    Integer setPageSize {get; set;} 
    
    Integer totalNumberOfPages{get;set;}
    Integer currentPage{get;set;}
    
    public PaginatingIterator(List<BidWithItemsWrapper> completeWrapperList)
    {
        //Variable Initialization
        /*************************/
        filteredWrapperList = new List<BidWithItemsWrapper >(); 
        paginatedWrapperList = new List<BidWithItemsWrapper >();   
        this.completeWrapperList = new List<BidWithItemsWrapper>();
        categoryItemMap = new Map<String, List<BidWithItemsWrapper>>();
        /*************************/
        
        //FilteredWrapperList initialized - to start with - this will be = completeWrapperList
        this.filteredWrapperList = completeWrapperList;
        //CompleteWrapperList initialized
        this.completeWrapperList = filteredWrapperList;
        
        //Create Map of Category > Wrapper List
        for(BidWithItemsWrapper bwi : filteredWrapperList )
        {
            if(categoryItemMap.containsKey(bwi.Item.Category__c)){
                List<BidWithItemsWrapper> bwiListForACategory = categoryItemMap.get(bwi.item.Category__c);
                bwiListForACategory.add(bwi);
                categoryItemMap.put(bwi.item.Category__c, bwiListForACategory);
                
            }
            else{
                List<BidWithItemsWrapper> bwiListForACategory = new List<BidWithItemsWrapper>();
                bwiListForACategory.add(bwi);
                categoryItemMap.put(bwi.item.Category__c, bwiListForACategory);
            }
        }
        
        system.debug('filteredWrapperList.Size() = ' + filteredWrapperList.size());
        setPageSize = 5;
        wrapperPointer = 0;  
        
        //Calculate total Number of Pages
        totalNumberOfPages = Integer.valueOf(Math.ceil( (Decimal) filteredWrapperList.size() / (Decimal) setPageSize ));
        //Initialize currentPage to 1
        currentPage = 1;
    }   
    
    public Integer getCurrentPage(){
        return this.currentPage;
    }
    public Integer getTotalNumberOfPages(){
        return this.totalNumberOfPages;
    }

    public void recalculateTotalNumberOfPages(){
        
        totalNumberOfPages = Integer.valueOf(Math.ceil( (Decimal) filteredWrapperList.size() / (Decimal) setPageSize ));
        
    }
    //Pagination control methods
    /**************************/
    global boolean isNotFirst(){     
        system.debug('isNotFirst() was called!');
        
        if(currentPage == 1) {
            return false; 
        } else {
            return true; 
        }
    }   
    
    global boolean hasPrevious(){     
        system.debug('hasPrevious() was called!');
        system.debug('I am in hasPrevious ' + wrapperPointer);
        if(wrapperPointer <= setPageSize) {
            return false; 
        } else {
            return true; 
        }
    }   
    
    global boolean hasNext(){ 
        system.debug('hasNext() was called!');
        if(wrapperPointer >= filteredWrapperList.size()) {
            return false; 
        } else {
            return true; 
        }
    } 
    
    global boolean isNotLast(){     
        system.debug('isNotLast() was called!');
        
        if(currentPage == totalNumberOfPages) {
            return false; 
        } else {
            return true; 
        }
    }  
    /**************************/

    //Pagination methods
    /***************************/
    //Return the first Page of Wrappers
    public List<BidWithItemsWrapper> first(){       
        
        paginatedWrapperList = new list<BidWithItemsWrapper >(); 
        Integer size = filteredWrapperList.size();
        
        if(size <= setPageSize){
            wrapperPointer = size;
        }
        else{
            wrapperPointer = setPageSize;
        }
        
        //Extract the desired page from the filteredWrapperList
        for(integer start = 0; start < wrapperPointer; ++start)
        {
            paginatedWrapperList.add(filteredWrapperList[start]);
        } 
        //Update currentPage
        currentPage = 1;
        
        return paginatedWrapperList;
        
    }
    
    //Return the previous Page of Wrappers
    public List<BidWithItemsWrapper > previous(){      
        paginatedWrapperList = new list<BidWithItemsWrapper >(); 
        Integer size = filteredWrapperList.size(); 
        
        if(wrapperPointer == size)
        {
            if(math.mod(size, setPageSize) > 0)
            {    
                wrapperPointer = size - math.mod(size, setPageSize);
            }
            else
            {
                wrapperPointer = (size - setPageSize);
            } 
        }
        else
        {
            wrapperPointer = (wrapperPointer - setPageSize);
        }
        
        for(integer start = (wrapperPointer - setPageSize); start < wrapperPointer; ++start)
        {
            paginatedWrapperList.add(filteredWrapperList[start]);
        } 
        //Update currentPage
        currentPage = (Math.mod(wrapperPointer, setPageSize) == 0) ? (wrapperPointer / setPageSize) : ((wrapperPointer / setPageSize) + 1);
            
        return paginatedWrapperList;
    }  
    
    //Return the Next page of Wrappers
    public List<BidWithItemsWrapper> next(){       
        
        paginatedWrapperList = new list<BidWithItemsWrapper >(); 
        Integer startNumber;
        Integer size = filteredWrapperList.size(); 
        
        if(hasNext())
        {  
            if(size <= (wrapperPointer + setPageSize))
            {
                startNumber = wrapperPointer;
                wrapperPointer = size;
            }
            else
            {
                wrapperPointer = (wrapperPointer + setPageSize);
                startNumber = (wrapperPointer - setPageSize);
            }
            
            for(integer start = startNumber; start < wrapperPointer; start++)
            {
                paginatedWrapperList.add(filteredWrapperList[start]);
            }
        } 
        //Update currentPage
        currentPage = (Math.mod(wrapperPointer, setPageSize) == 0) ? (wrapperPointer / setPageSize) : ((wrapperPointer / setPageSize) + 1);
            
        return paginatedWrapperList;
    } 
    
    //Return the last Page of Wrappers
    public list<BidWithItemsWrapper> last(){       
        
        paginatedWrapperList = new list<BidWithItemsWrapper >(); 
        Integer size = filteredWrapperList.size(); 
        wrapperPointer = size;
        
        for(integer start = setPageSize * (totalNumberOfPages - 1); start < wrapperPointer; start++)
        {
            paginatedWrapperList.add(filteredWrapperList[start]);
        }
        
        //Update currentPage
        currentPage = totalNumberOfPages;
        
        return paginatedWrapperList;
        
    }
    /************************************/

    //Filter the Wrapper List based on the Selected Category
    public void filterList(String filter){       
        
        system.debug('selected filter: ' + filter);
        system.debug('categoryItemMap: ' + categoryItemMap);
        if(filter == System.Label.AllCategories){
            filteredWrapperList = completeWrapperList;
            
        }
        else{
            
            filteredWrapperList = categoryItemMap.get(filter);
            
        }
        system.debug('New Item List:' + filteredWrapperList);
        system.debug('completeWrapperList: ' + completeWrapperList);
        
        //Reset the wrapperPointer 
        wrapperPointer = 0;
    } 
}