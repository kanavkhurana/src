//Visuaforce test
@isTest
public class DonationWizardTester{
public static testmethod void newDonationOnPageLoadTest()
{
//check if all items with close date in the future and related to bids are appearing on the page - Loading condition for new donation 

}

public static testmethod void existingDonationOnPageLoadTest(){
// check loading condition for existing donation
}
public static testmethod void itemsToBeLoadedTest(){
//check if all items whose closing date > today's date are appearing in the results

//check if order of items is as per minimum bid field
}

//Included above
/*public static testmethod void ()
//check if order of items is as per minimum bid field
*/

public static testmethod void categoriesToBeLoadedTest(){

//check if all categories have loaded
}

public static testmethod void itemIdToBeProcessedTest(){

//check if an amount field is modified - is value added to the back end?

}

public static testmethod void nextPageToBeShownTest(){

//check Nextpagination
}

public static testmethod void previousPageToBeShownTest(){
//check Previouspagination

}

public static testmethod void firstPageToBeShownTest(){

}

public static testmethod void lastPageToBeShownTest(){

//checkLastPagination
}

public static testmethod void firstButtonAppearingTest(){

//check FirstButtonAppearing
}

public static testmethod void lastButtonAppearingTest(){

//check LastButtonAppearing
}

public static testmethod void previousButtonAppearingTest(){

//check PreviousButtonAppearing

}

public static testmethod void nextButtonAppearingTest(){

//check NextButtonAppearing

}

public static testmethod void itemListFilteredCorrectlyTest(){

//check Filtering of Item list

}

public static testmethod void chartDisplayingCorrectlyTest(){
//chart working - refresh, etc. - including message to be displayed when no records exist

}

public static testmethod void cancelActionWorkingCorrectlyTest(){
//cancel working
}


public static testmethod void bidsDeletionTest(){

//deletion working - success and failure

}

public static testmethod void bidsInsertionTest(){

//insertion working - success and failure
}

public static testmethod void bidsUpdateTest(){

//update working - success and failure
}

public static testmethod void blankDonationValidationTest(){
//ERROR
//submitting a blank donation - either of the reqd fields are blank
}

public static testmethod void blankBidValidationTest(){
//ERROR
//submitting a blank bid - the amount field is blank
}

public static testmethod void blankBidFilterTest(){
//ERROR
//filtering a blank bid - the amount field is blank
}

public static testmethod void blankBidPaginationTest(){
//ERROR
//paginating a blank bid - the amount field is blank
}

}