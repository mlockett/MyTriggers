/**
* MyTriggers - adapted from TriggerX (2013) by Sebastian Wagner
* Copyright (c) 2018 appero GmbH. All rights reserved.
*
* This work is licensed under the terms of the MIT license.  
* For a copy, see <LICENCE> in this repository or   
* <https://opensource.org/licenses/MIT>.
*
* @created: 8-2018
* @author: info@appero.com
*
* @Description Lightweight Custom Metadata driven Trigger Framework that scales to your needs. Provided with <3 by appero.com
*/
public class JSONObject {
    public class JSONObjectException extends Exception {}

    public static String NameSpacePrefix {
        get {
            if (NameSpacePrefix == null) {
                NameSpacePrefix = JSONObject.class.getName().substringBefore('.JSONObject');
                NameSpacePrefix = NameSpacePrefix.length() > 0 && NameSpacePrefix != 'JSONObject' ? NameSpacePrefix + '__' : '';
            }
            return NameSpacePrefix;
        }
        private set;
    }
    
    @TestVisible
    private Map<String,Object> propertyMap = new Map<String,Object>(); 
    
    public JSONObject(String singleObjectJSON) {
        try {
            JSON.deserializeUntyped(singleObjectJSON);
        } catch (Exception e) {
            throw new JSONObjectException('This is not a valid JSON String.');
        }
        
        try {
            propertyMap = (Map<String,Object>)JSON.deserializeUntyped(singleObjectJSON);
        } catch (Exception e) {
            throw new JSONObjectException('A single JSON Object is expected. The JSON String contains a list of Objects.');
        }
    }
    
    public JSONObject(Object anyObject) {
        this(JSON.serialize(anyObject));
    }
    
    public Boolean hasProperty(String propertyName) {
        return propertyMap.get(propertyName) != null ? true : false; 
    }
    
    public Object get(String propertyName) {
        return propertyMap.get(propertyName);
    }
    
    public void set(String propertyName, Object value) {
        propertyMap.put(propertyName, value);
    }

    public void set(String propertyName, Object value, Boolean appendNamespace) {
        if(appendNamespace){
            propertyName = NameSpacePrefix + propertyName;
        }
        propertyMap.put(propertyName, value);
    }
    
    public Object deserialize(System.Type apexType) {
        return JSON.deserializeStrict(toJSON(), apexType);
    }
    
    @TestVisible
    private String toJSON() {
        return JSON.serialize(propertyMap);
    }

    @TestVisible
    private static Boolean hasProperty(String json, String propertyName) {
        return json.contains(propertyName);
    }
}