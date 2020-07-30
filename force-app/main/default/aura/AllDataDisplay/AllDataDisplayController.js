({
	loadWeatherData : function(component, event, helper) {
		var action = component.get("c.returnWeatherData");
		action.setParams({ city : 'Eustis', state : 'FL', country : 'US', metric : false});
		action.setCallback(this,function(response){
			if(response.getState()=="SUCCESS"){
                let hourList = response.getReturnValue()[0];
                let dayList = response.getReturnValue()[1];
				console.log("winner winner");
                component.set("v.dayList",dayList);
                component.set("v.hourList",hourList);
                
                component.set("v.sunrise",dayList[0].Sunrise__c);
                component.set("v.sunset",dayList[0].Sunset__c);
                component.set("v.high",dayList[0].High__c);
                component.set("v.low",dayList[0].Low__c);
                console.log(response.getReturnValue());
                console.log(component.get("v.low"));
			}
		});
		$A.enqueueAction(action);
	}
})