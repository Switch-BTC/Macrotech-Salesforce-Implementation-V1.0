public without sharing class SAPCreateOrder {

    // Define a class to represent each Order Line Item for the SAP request
    public class SAPRequestPosition {
        public Integer positionNumber;
        public String materialNumber;
        public Integer quantity;
        public String unit;
    }

    // Define a class to represent the full SAP request
    public class SAPRequest {
        public String quoteNumber;
        public String soldToParty;
        public String shipToParty;
        public String salesOrg;
        public String distrChan;
        public String division;
        public String priceDate;
        public List<SAPRequestPosition> positions;
    }

    // Define a class to represent the SAP response
    public class SAPResponseResult {
        public String salesOrderNumber;
    }

    // Define a class to represent the full SAP response
    public class SAPResponse {
        public SAPResponseResult result;
        public Boolean success;
        public String message;
    }

    @InvocableMethod(label='Create Order in SAP' description='Create an Order in SAP and update the Order in Salesforce with the SAP Order Id')
    public static void createSAPOrder(List<Id> orderIds) {

        SAP_Info__c sapinfo = [SELECT Id, Name, Username__c, Password__c, Sales_Org__c, Distribution_Channel__c, Division__c FROM SAP_Info__c WHERE Name = 'Sandbox' LIMIT 1];

        // Query Orders and related fields needed for SAP call
        List<Order> orders = [SELECT Id, AccountId, EffectiveDate, Account.SAPID__c, Quote.Sold_To_Party__c, Quote.Ship_To_Party__c, Quote.Sales_Org__c, Quote.QuoteNumber,
                              (SELECT Id, Product2.ProductCode, Quantity, UnitPrice, Description FROM OrderItems)
                              FROM Order
                              WHERE Id IN :orderIds];

        if (orders.isEmpty()) {
            return;
        }

        try {
            // Build the SAP request
            SAPRequest sapRequest = new SAPRequest();

            // Check if SAPID is blank on the Account, use generic code 7000000 if so
            String sapId = orders[0].Account.SAPID__c;
            if (String.isBlank(sapId)) {
                throw new CalloutException('La Cuenta todavía no ha sido creada en SAP');
            }

            // Set soldToParty and shipToParty to SAPID or generic code
            sapRequest.quoteNumber = '';
            sapRequest.soldToParty = sapId;
            sapRequest.shipToParty = sapId;

            sapRequest.salesOrg = sapinfo.Sales_Org__c; // Sales organization
            sapRequest.distrChan = sapinfo.Distribution_Channel__c; // Distribution channel
            sapRequest.division = sapinfo.Division__c; // Division
            sapRequest.priceDate = String.valueOf(orders[0].EffectiveDate); // Price date
            sapRequest.positions = new List<SAPRequestPosition>();

            Integer positionCounter = 10;
            for (OrderItem oi : orders[0].OrderItems) {
                SAPRequestPosition position = new SAPRequestPosition();
                position.positionNumber = positionCounter;
                position.materialNumber = oi.Product2.ProductCode;
                position.quantity = Integer.valueOf(oi.Quantity);
                position.unit = 'UN'; // Customize this based on your org's configuration
                sapRequest.positions.add(position);
                positionCounter += 10;
            }

            // Serialize the request and pass it to the Queueable class
            String requestBody = JSON.serialize(sapRequest);
            System.debug('This is what is sent to SAP ' + requestBody );

            // Enqueue the Queueable class for processing
            System.enqueueJob(new SendToSAPQueueable(requestBody, orderIds, sapinfo.Username__c, sapinfo.Password__c));
        } catch (Exception e) {
            // Update the Order in Salesforce with the error message
            Order orderToUpdate = new Order(Id = orderIds[0]);
            orderToUpdate.SAP_Message__c = e.getMessage();
            update orderToUpdate;
        }
    }

    // Queueable class to make the callout to SAP
    public class SendToSAPQueueable implements Queueable, Database.AllowsCallouts {
        private String requestBody;
        private List<Id> orderIds;
        private String username;
        private String password;

        public SendToSAPQueueable(String requestBody, List<Id> orderIds, String username, String password) {
            this.requestBody = requestBody;
            this.orderIds = orderIds;
            this.username = username;
            this.password = password;
        }

        public void execute(QueueableContext context) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('http://sapsti.macrotech.com.do/sfapi/salesorder?sap-client=300'); // Replace with the actual endpoint
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

            // Encode the username and password
            String auth = username + ':' + password;
            String encodedAuth = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(auth));

            // Set the Authorization header
            req.setHeader('Authorization', encodedAuth);
            req.setBody(requestBody);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                SAPResponse sapResponse = (SAPResponse) JSON.deserialize(res.getBody(), SAPResponse.class);
                System.debug('This is the full JSON returned from SAP ' + res.getBody());

                if (sapResponse.success) {
                    // Update the Order in Salesforce with the SAP Order Id
                    Order orderToUpdate = new Order(Id = orderIds[0]);
                    orderToUpdate.salesOrderNumber__c = sapResponse.result.salesOrderNumber;
                    orderToUpdate.SAP_Message__c = sapResponse.message;
                    update orderToUpdate;
                } else {
                    // Update the Order in Salesforce with the SAP failure message
                    Order orderToUpdate = new Order(Id = orderIds[0]);
                    orderToUpdate.SAP_Message__c = sapResponse.message;
                    update orderToUpdate;
                }
            } else {
                // Update the Order in Salesforce with the failed callout status message
                Order orderToUpdate = new Order(Id = orderIds[0]);
                orderToUpdate.SAP_Message__c = 'Failed with status code: ' + res.getStatusCode();
                update orderToUpdate;

                throw new CalloutException('Failed with status code: ' + res.getStatusCode());
            }
        }
    }

    // Custom exception for error handling
    public class CalloutException extends Exception {}
}