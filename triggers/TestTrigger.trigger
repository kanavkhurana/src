trigger TestTrigger on Bid__c (before insert, after insert) {


if(Trigger.isBefore){

Trigger.New[0].addError('custom exception');
Trigger.New[1].addError('custom exception');

}

else if(Trigger.isAfter){

system.debug(Trigger.New.size());

system.debug(Trigger.New);


}

}