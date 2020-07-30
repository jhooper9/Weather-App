public class CalloutGenerator {
    private static HttpResponse callSetup(String endpoint){
        Http httpController = new Http();
        HttpRequest request = new HttpRequest();
        request.setHeader('x-rapidapi-host', 'visual-crossing-weather.p.rapidapi.com');
        request.setHeader('x-rapidapi-key', 'abc224bcd8mshea53e7a216e28cep148300jsn3fcaea9545fd');
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        return httpController.send(request);
    }
    private static String makeCallout(String city, String state, String country, Boolean metric){
        String units = 'unitGroup=us';
        if(metric) units = 'unitGroup=metric';
        String locationString;
        if(state!=null) locationString = city.replace(' ', '%20') + ',' + state.replace(' ', '%20') + ',' + country.replace(' ', '%20');
        else locationString = city.replace(' ', '%20') + ',' + country.replace(' ', '%20');
        String inputString = 'https://visual-crossing-weather.p.rapidapi.com/forecast?contentType=json&' +
            'shortColumnNames=false&' + units + '&location=' + locationString + '&aggregateHours=1';
        HttpResponse response = callSetup(inputString);
        String stringToReplace = city+','+state+','+country;
        //System.debug(response.getBody());
        String bodyString = (response.getBody()).replaceAll(stringToReplace, 'city');
        bodyString = bodyString.replaceAll('datetime":', 'datetimeM":');
        return bodyString;
        
    }
    public static void getNewWeatherData(String city, String state, String country, Boolean metric){
        String response = makeCallout(city,state,country,metric);
        WeatherDataResponse wDR = (WeatherDataResponse)JSON.deserialize(response, WeatherDataResponse.class);
        WeatherDataResponse.City cityData = wDR.locations.city;
        String locationName = city+','+state+','+country;
        List<Location__c> locList = [SELECT Id FROM Location__c WHERE Name =: locationName];
        Location__c loc;
        if(locList.size()==0){
            loc = new Location__c(Name=locationName);
            INSERT loc;
        } else {
            loc = locList[0];
        }
        DELETE [SELECT Id FROM One_Day_Forecast__c WHERE Location__c=:loc.Id];
        List<One_Day_Forecast__c> daily = new List<One_Day_Forecast__c>();
        Date endDate = DateTime.newInstance((cityData.values[cityData.values.size()-1]).datetimeM).Date();
        Date currentDate = Date.today();
        List<Integer> rTime = getTimeValues(cityData.currentConditions.sunrise);
        List<Integer> sTime = getTimeValues(cityData.currentConditions.sunset);
        while(currentDate<endDate){
            //TODO include total percent chance for rainfall
            daily.add(new One_Day_Forecast__c(Location__c=loc.Id,Date__c=currentDate,
                                              sunrise__c=currentDate==Date.today()? Time.newInstance(rTime[0], rTime[1], rTime[2], 0):null,
                                              sunset__c=currentDate==Date.today()? Time.newInstance(sTime[0], sTime[1], sTime[2], 0):null));
            currentDate = currentDate.addDays(1);
        }
        INSERT daily;
        
        Integer dayIndex = 0;
        List<One_Hour_Forecast__c> hourly = new List<One_Hour_Forecast__c>();
        for(WeatherDataResponse.HourlyCondition h : cityData.values) {
            DateTime hourlyDateTime = DateTime.newInstance(h.datetimeM);
            if(daily[dayIndex].date__c!=hourlyDateTime.date()&&dayIndex<daily.size()-1) {
                dayIndex++;
            }
            hourly.add(new One_Hour_Forecast__c(Snow_Depth__c = h.snowdepth, Temperature__c = h.temp, Wind_Chill__c = h.windchill,
                                                Wind_Gust__c = h.wgust, Wind_Heading__c = h.wdir, Wind_Speed__c = h.wspd,
                                                Air_Pressure__c = h.sealevelpressure, Amount_of_Precipitation__c = h.precip,
                                                Chance_of_Precipitation__c = h.pop, Cloud_Cover__c = h.cloudcover, Conditions__c = h.conditions,
                                                Datetime__c = hourlyDateTime, Heat_Index__c = h.heatindex, 
                                                Humidity__c = h.humidity, Daily__c = daily[dayIndex].Id
            ));
            //System.debug('Indx: ' + hourlyDateTime.time() +' -- '+ h.pop +' -- '+ totalPop);
        }
        INSERT hourly;
    }
    
    /* The timeString parameter has to be in the format '2020-07-29T20:19:39-04:00'
     * return value is in the format [hour,minute,second,timezone-hour,timezone-minute]
     */
    private static List<Integer> getTimeValues(String timeString){
        List<String> timeOnly = timeString.split('T');
        List<String> digitList = timeOnly[1].splitByCharacterType();
        List<Integer> intList = new List<Integer>();
        for(String s : digitList){
            if(s.isNumeric()){
                intList.add(Integer.valueOf(s));
            }
        }
        return intList;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}