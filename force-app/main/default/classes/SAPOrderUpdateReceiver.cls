@RestResource(urlMapping='/updateOrder')
global with sharing class SAPOrderUpdateReceiver {

    @HttpPost
    global static String updateOrder() {
        // Parse the incoming JSON request into a list of OrderStatusWrapper objects
        List<OrderStatusWrapper> orders = (List<OrderStatusWrapper>) JSON.deserialize(RestContext.request.requestBody.toString(), List<OrderStatusWrapper>.class);
        
        List<Order> ordersToUpdate = new List<Order>();
        
        try {
            // Iterate over each order in the incoming JSON
            for (OrderStatusWrapper orderWrapper : orders) {
                String documentSap = orderWrapper.documentSap;
                if (String.isBlank(documentSap)) continue; // Skip if documentSap is missing
                
                // Query for the corresponding Order record based on documentSap
                List<Order> existingOrders = [SELECT Id, Name, Status, salesOrderNumber__c, SAP_Message__c 
                                              FROM Order WHERE salesOrderNumber__c = :documentSap LIMIT 1];
                
                if (!existingOrders.isEmpty()) {
                    Order order = existingOrders[0];
                    
                    // Find the most recent status by sorting statuses based on createdDate
                    if (orderWrapper.statuses != null && !orderWrapper.statuses.isEmpty()) {
                        orderWrapper.statuses.sort();
                        OrderStatus latestStatus = orderWrapper.statuses[orderWrapper.statuses.size() - 1];
                        
                        // Update the order fields based on the latest status
                        order.Status = latestStatus.status;
                        //order.salesOrderNumber__c = latestStatus.statusId;
                        
                        // Add to list for bulk update
                        ordersToUpdate.add(order);
                    }
                }
            }
            
            // Perform the bulk update
            if (!ordersToUpdate.isEmpty()) {
                update ordersToUpdate;
            }
            
            return 'Order statuses updated successfully';
        } catch (Exception e) {
            System.debug('Error updating order statuses: ' + e.getMessage());
            return 'Failed to update order statuses: ' + e.getMessage();
        }
    }

    // Wrapper class for incoming JSON
    global class OrderStatusWrapper {
        public String documentSap;
        public List<OrderStatus> statuses;
    }
    
    // Wrapper class for individual status entries
    global class OrderStatus implements Comparable {
        public String status;
        public String statusId;
        public String createdDate;

        // Method to compare statuses based on createdDate for sorting
        public Integer compareTo(Object other) {
            OrderStatus otherStatus = (OrderStatus) other;
            DateTime thisDate = this.parseDateTime(this.createdDate);
            DateTime otherDate = this.parseDateTime(otherStatus.createdDate);
            return thisDate.getTime() > otherDate.getTime() ? 1 : -1;
        }

        // Helper method to parse date in 'yyyyMMdd HHmm' format to DateTime
        private DateTime parseDateTime(String dateString) {
            if (dateString == null || dateString.length() != 13) {
                throw new IllegalArgumentException('Invalid date format: ' + dateString);
            }
            String reformattedDate = dateString.substring(0, 4) + '-' + 
                                     dateString.substring(4, 6) + '-' + 
                                     dateString.substring(6, 8) + ' ' + 
                                     dateString.substring(9, 11) + ':' + 
                                     dateString.substring(11, 13) + ':00';
            return DateTime.valueOfGmt(reformattedDate);
        }
    }
}