public class CaseTriggerHandler {
    
    public static void beforeInsert(List<Case> lstCase){
        restrictCaseCreation(lstCase);
    }
    
    public static void afterInsert(List<Case> lstCase){
        
    }
    public static void afterUpdate(List<Case> lstCase, Map< Id, Case> oldMap){
        caseCreationInOrder(lstCase, oldMap);
        markUnsuccessfully(lstCase, oldMap);
    }
    public static void markUnsuccessfully(List<Case> lstCase, Map< Id, Case> mapOfOld ){
        Set<String> parentIds = new Set<String>();
        
        list<case> lstOfAllRelatedCases = new list<case>();
        for(Case c: lstCase){
            if(c.ParentId != null && c.Status == 'Closed – Unsuccessfully' && c.Status != mapOfOld.get(c.id).Status){
                //c.Status = 'Closed – Unsuccessfully';  
                parentIds.add(c.ParentId);             
            }
        }
        List<Case> lstRelatedCases = [Select id, Status,ParentId from case where ParentId IN:parentIds AND Status !='Closed – Successfully'];
        for(Case cc: lstRelatedCases){
            cc.Status = 'Closed – Unsuccessfully';
            lstOfAllRelatedCases.add(cc);
            System.debug('cc--'+cc);
        }
        if(lstOfAllRelatedCases.size() > 0){
            update lstOfAllRelatedCases;
        }        
    }
    public static void caseCreationInOrder(List<Case> lstCase, Map<Id, Case> oldMap ){
        
        list<case> lstOfChildCasees = new list<case>();
        list<case> lstOfMarkedSuccessCasees = new list<case>();
        //Get all custom metadata
        Map<String, Order_Of_Tasks__mdt> mapOrderOfTasks = Order_Of_Tasks__mdt.getAll();
        
        Decimal countOrder;
        if( lstCase[0] != null && lstCase[0].GroupBy__c != null && lstCase[0].GroupBy__c != '' && lstCase[0].ParentId != null )              
        lstOfMarkedSuccessCasees = [ Select id from case where parentid=:lstCase[0].ParentId AND GroupBy__c=:lstCase[0].GroupBy__c AND Status='Closed – Successfully'];
        
        for(String eachMap : mapOrderOfTasks.keySet()){
            for(case each : lstCase )
            {
                if( each.Order__c != null )
                    countOrder=each.Order__c+1;
                
                if( (each.Status== 'Closed – Successfully' && ( each.ParentId== null ) &&  mapOrderOfTasks.get(eachMap).Order__c==1 )) //&& mapOrderOfTasks.get(eachMap).Record_Type_Name__c==each.RecordType.Name)  )
                {
                    case objChildCase = new case();
                    objChildCase.ParentId= each.Id;
                    objChildCase.GroupBy__c= mapOrderOfTasks.get(eachMap).Associated_With__c;
                    objChildCase.RelatedTo__c=mapOrderOfTasks.get(eachMap).Related_To__c;
                    objChildCase.Order__c=mapOrderOfTasks.get(eachMap).Order__c;
                    objChildCase.RecordTypeId =   mapOrderOfTasks.get(eachMap).RecordTypeId__c;
                    lstOfChildCasees.add(objChildCase);
                    
                }
                    if( (each.Status== 'Closed – Successfully' && each.GroupBy__c != null && each.GroupBy__c != '' )  && lstOfMarkedSuccessCasees.size()>0 && ( each.ParentId != null) &&  mapOrderOfTasks.get(eachMap).Order__c ==countOrder && countOrder<= 10 )
                {
                    case objChildCase = new case();
                    objChildCase.ParentId = each.ParentId;
                    objChildCase.GroupBy__c= mapOrderOfTasks.get(eachMap).Associated_With__c;
                    objChildCase.RelatedTo__c=mapOrderOfTasks.get(eachMap).Related_To__c;
                    objChildCase.Order__c=mapOrderOfTasks.get(eachMap).Order__c;
                    objChildCase.RecordTypeId =   mapOrderOfTasks.get(eachMap).RecordTypeId__c;
                    lstOfChildCasees.add(objChildCase);
                }
                
                if( each.Status== 'Closed – Successfully' && (each.GroupBy__c == null || each.GroupBy__c == '' )  && ( each.ParentId != null) &&  mapOrderOfTasks.get(eachMap).Order__c ==countOrder && countOrder<= 10 )
                {
                    case objChildCase = new case();
                    objChildCase.ParentId = each.ParentId;
                    objChildCase.GroupBy__c= mapOrderOfTasks.get(eachMap).Associated_With__c;
                    objChildCase.RelatedTo__c=mapOrderOfTasks.get(eachMap).Related_To__c;
                    objChildCase.Order__c=mapOrderOfTasks.get(eachMap).Order__c;
                    objChildCase.RecordTypeId =   mapOrderOfTasks.get(eachMap).RecordTypeId__c;
                    lstOfChildCasees.add(objChildCase);
                }
            }
        }
        if(lstOfChildCasees != null && lstOfChildCasees.size() > 0)
            insert lstOfChildCasees;
    }
    
    public static void restrictCaseCreation(List<Case> lstCase){
        for(Case c: lstCase){
            if(c.Status != 'Closed – Successfully' && c.ParentId != null && c.Parent_Case_Status__c == 'New'){
                System.debug('c.Status--'+c.Status);
                c.addError('You are not allowed to create a new Case until the predecessor ones are Closed – Successfully');
            }
        }
    }
    
    
}
