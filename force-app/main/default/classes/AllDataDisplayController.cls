public with sharing class AllDataDisplayController {
    @AuraEnabled
    public static List<List<Object>> returnWeatherData(String city, String state, String country, Boolean metric){
        CalloutGenerator.getNewWeatherData(city, state, country, metric);
        String searchLocation = city +','+ state +','+ country;
        List<Object> hourReturn = [SELECT Snow_Depth__c, Temperature__c, Wind_Chill__c,Wind_Gust__c, Wind_Heading__c, Wind_Speed__c, Air_Pressure__c, Amount_of_Precipitation__c , Chance_of_Precipitation__c, Cloud_Cover__c, Conditions__c, Daily__c, Datetime__c, Heat_Index__c, Humidity__c FROM One_Hour_Forecast__c WHERE Daily__r.Location__r.Name=:searchLocation];
        List<Object> dayReturn = [SELECT Sunrise__c, Sunset__c, Low__c, High__c FROM One_Day_Forecast__c WHERE Location__r.Name=:searchLocation];
        return new List<List<Object>>{hourReturn,dayReturn};
    }
}