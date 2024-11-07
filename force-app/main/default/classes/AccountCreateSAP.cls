public class AccountCreateSAP {

    // Define the structure for the JSON to be sent to SAP
    public class SAPClient {
        public String idSalesforce;
        public String codClient;
        public String identification;
        public String typeCompFisc;
        public String title;
        public String name;
        public String name2;
        public String search1;
        public String search2;
        public String city;
        public String sector;
        public String street;
        public String houseNumber;
        public String cellNumber;
        public String telNumber;
        public String email;
        public String salesAgent;
        public String salesOfv;
        public String salesGrp;
        public String salesZon;
        public String priceList;
        public String paymentTerms;
        public String quoteId;  // Added field for QuoteId
    }

    // Invocable method to be called from Process Builder or Flow
    @InvocableMethod(label='Create Account in SAP' description='Sends an Account related to the provided Quote ID to SAP for creation')
    public static void sendAccountToSAP(List<Id> quoteIds) {
        // Ensure a Quote ID is provided
        if (quoteIds == null || quoteIds.isEmpty()) {
            throw new CustomException('No Quote ID provided');
        }

        // Retrieve the Account related to the provided Quote ID(s)
        List<Quote> quotes = [SELECT Id, Cliente__c FROM Quote WHERE Id IN :quoteIds];
        List<Id> accountIds = new List<Id>();
        for (Quote quote : quotes) {
            if (quote.Cliente__c != null) {
                accountIds.add(quote.Cliente__c);
            }
        }

      

        // Retrieve Account details
        List<Account> accounts = [SELECT Id, Name, Phone, BillingCity, BillingStreet, BillingPostalCode, BillingState, BillingCountry, SAPID__c, No_Identificaci_n__c, Lista_de_tipos_comprobantes__c, Salutation__c, salesOfv__c, Sales_Group__c, Sales_Zone__c, priceList__c, paymentTerms__c, SGR_Response__c FROM Account WHERE Id IN :accountIds];

        // Iterate through Accounts and prepare SAPClient data
        for (Account acc : accounts) {
            SAPClient sapClient = new SAPClient();
            sapClient.idSalesforce = acc.Id;
            sapClient.codClient = acc.SAPID__c;
            sapClient.identification = acc.No_Identificaci_n__c;
            sapClient.typeCompFisc = acc.Lista_de_tipos_comprobantes__c; 
            sapClient.title = acc.Salutation__c; 
            sapClient.name = acc.Name; 
            sapClient.city = acc.BillingCity;
            sapClient.sector = acc.BillingState;
            sapClient.street = acc.BillingStreet;
            sapClient.telNumber = acc.Phone;
            sapClient.salesAgent = '2'; 
            sapClient.salesOfv = acc.salesOfv__c; 
            sapClient.salesGrp = acc.Sales_Group__c;
            sapClient.salesZon = acc.Sales_Zone__c;
            sapClient.priceList = acc.priceList__c;
            sapClient.paymentTerms = acc.paymentTerms__c;
            sapClient.quoteId = quoteIds.get(0);  // Using the first QuoteId for simplicity, as we expect one

            // Serialize the SAPClient object to JSON
            String jsonBody = JSON.serialize(sapClient);

            // Make the callout to SAP via a future method
            postToSAP(jsonBody, acc.Id, quotes[0].Id);
        }
    }

    // Helper method to post the serialized JSON data to SAP (using Future to make the callout)
    @Future(callout=true)
    public static void postToSAP(String jsonBody, Id accountId, Id quoteId) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('http://sapsti.macrotech.com.do/sfapi/client/?sap-client=300'); // Replace with the actual SAP endpoint
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            
            // Set Basic Auth header (username:password encoded in Base64)
            String username = 'INTER_SF'; // Replace with actual username
            String password = 'Macro.tech@*2024'; // Replace with actual password
            String auth = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
            req.setHeader('Authorization', auth);

            // Set the body of the request with the serialized JSON string
            req.setBody(jsonBody);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                // Parse the response and extract codClient
                SAPAccountResponse SAPclient = SAPAccountResponse.fromJSON(res.getBody());
                
                String codClient = SAPclient.result.codClient;
                String message = SAPclient.message;
                
                if (!String.isBlank(codClient)) {
                    // Update SAPID__c field on the Account
                    Account acc = [SELECT Id, SAPID__c, SAP_Error__c FROM Account WHERE Id = :accountId];
                    acc.SAPID__c = codClient;
                    acc.SAP_Error__c = message;
                    update acc;
                    System.debug('Successfully created client in SAP with codClient: ' + codClient);

                    // Invoke the flow and pass the QuoteId
                    Map<String, Object> flowInputs = new Map<String, Object>();
                    flowInputs.put('recordId', quoteId);
                    
                    // Flow names must match the exact name specified in the related list of the custom metadata
                    Flow.Interview interview = Flow.Interview.createInterview('Create_Order', flowInputs);
                    interview.start();  // Start the flow
                    System.debug('Flow called successfully with QuoteId: ' + quoteId);
                }
            } else {
                // Write error message to SGR_Response__c field on Account
                Account acc = [SELECT Id, SAP_Error__c FROM Account WHERE Id = :accountId];
                acc.SAP_Error__c = 'Failed to create client in SAP: ' + res.getBody();
                update acc;
                System.debug('Failed to create client in SAP: ' + res.getBody());
            }
        } catch (Exception e) {
            // Write error message to SGR_Response__c field on Account in case of exception
            Account acc = [SELECT Id, SAP_Error__c FROM Account WHERE Id = :accountId];
            acc.SAP_Error__c = 'Error in posting to SAP: ' + e.getMessage();
            update acc;
            System.debug('Error in posting to SAP: ' + e.getMessage());
        }
    }

    // Custom exception for error handling
    public class CustomException extends Exception {}
}