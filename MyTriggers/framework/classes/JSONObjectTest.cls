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
@IsTest
public class JSONObjectTest {
    private static final Account newAccount = new Account(Name = 'Johnson Inc.', 
                                                          Industry = 'Publishing',
                                                          Type = 'Customer');

    public static final String accountJSON = JSON.serialize(newAccount);
    public static final String accountListJSON = JSON.serialize(new List<Account>{newAccount});
    public static final String noJSONAtAll = 'Abced,[,[,{}/@""';
     
    @IsTest
    public static void constructorJSON_Error_InvalidJSON() {
       Exception e;
        try {
            new JSONObject(noJSONAtAll);
        } catch (Exception ex) {
            e = ex;
        }
        System.assert(e!=null,'Exception expected');
        System.assert(e.getMessage().containsIgnoreCase('valid'),'valid must be part of error message');
    }
    
    
    @IsTest
    public static void constructorJSON_Error_ReceivedList() {
        Exception e;
        try {
            new JSONObject(accountListJSON);
        } catch (Exception ex) {
            e = ex;
        }
        System.assert(e!=null,'Exception expected');
        System.assert(e.getMessage().containsIgnoreCase('list'),'List error message must be shown');
    }
    
    @IsTest
    public static void constructorJSON_Success() {
        Exception e;
        JSONObject jAccount; 
        try {
            jAccount = new JSONObject(accountJSON);
        } catch (Exception ex) {
            e = ex;
        }
        System.assert(e==null,'No Exception allowed');
        System.assertEquals('Publishing',String.valueOf(jAccount.propertyMap.get('Industry')),'Expected Value Publishing needs to be returned');
    }
    
    @IsTest
    public static void constructorAnyObject_Success() {
        Exception e;
        JSONObject jAccount; 
        try {
            jAccount = new JSONObject(newAccount);
        } catch (Exception ex) {
            e = ex;
        }
        System.assert(e==null,'No Exception allowed');
        System.assertEquals('Publishing',String.valueOf(jAccount.propertyMap.get('Industry')),'Expected Value Publishing needs to be returned');
    }
    
    @IsTest
    public static void getProperty_ReturnsNullIfPropertyNotFound() {
        JSONObject jAccount = new JSONObject(accountJSON);
        System.assertEquals(null, jAccount.get('InvalidKey'),'Null return value expected');
    }
    
    
    @IsTest
    public static void getProperty_Success() {
        JSONObject jAccount = new JSONObject(accountJSON);
        System.assertNotEquals(null, jAccount.get('Industry'),'No null return accepted');
        System.assertEquals('Publishing',String.valueOf(jAccount.get('Industry')),'Expected Value Publishing needs to be returned');
    }
    
    @IsTest
    public static void setProperty_AlreadyPresent() {
        JSONObject jAccount = new JSONObject(accountJSON);
        jAccount.set('Industry','Media');
        System.assertEquals('Media',String.valueOf(jAccount.get('Industry')),'Expected Value Media needs to be returned');
    }
    
    @IsTest
    public static void setProperty_NewProperty() {
        JSONObject jAccount = new JSONObject(accountJSON);
        jAccount.set('Description','Test Account');
        System.assertEquals('Test Account',String.valueOf(jAccount.get('Description')),'Expected Value Media needs to be returned');
    }
    
    @IsTest
    public static void hasProperty() {
        JSONObject jAccount = new JSONObject(accountJSON);
        System.assertEquals(true, jAccount.hasProperty('Industry'),'Must return true');
    }
    
    @IsTest
    public static void castBackToSObject() {
        JSONObject jAccount = new JSONObject(accountJSON);
        jAccount.set('Industry','Media');
        jAccount.set('Description','Test Account');
        Account myAccount = (Account)jAccount.deserialize(Account.class);
        insert myAccount;
        System.assert(myAccount.Id!=null,'Successful insert expected');
    }
}