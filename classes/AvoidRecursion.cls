public Class AvoidRecursion{
    private static boolean beforeFirstRun = true;
    private static boolean afterFirstRun = true;
    public static Integer triggerCounter = 0;
    
    public static boolean isBeforeFirstRun(){
    if(beforeFirstRun){
      beforeFirstRun = false;
      return true;
    }else{
        return beforeFirstRun;
    }
    }
    public static boolean isAfterFirstRun(){
    if(afterFirstRun){
      afterFirstRun = false;
      return true;
    }else{
        return afterFirstRun;
    }
    }
}